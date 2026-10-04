// Tests: saneo de activeTabs/inactiveTabs — deduplicación, solapamiento
// (prevalece active), tabs obligatorios y límite de tabs activos.
// Reproduce el estado corrupto real observado en producción
// (un mismo tab repetido en inactiveTabs y además presente en activeTabs).

import XCTest
@testable import TarotCore
@testable import TarotData

private final class StubKeychainService: KeychainServiceProtocol {
    private var store: [String: String] = [:]
    func read(_ key: String) -> String? { store[key] }
    @discardableResult func write(_ value: String, for key: String) -> Bool {
        store[key] = value
        return true
    }
    func delete(_ key: String) -> Bool { store.removeValue(forKey: key) != nil }
}

final class TabSanitizationTests: XCTestCase {

    private func makeRepository(suiteName: String) -> UserDefaultsSettingsRepository {
        let suite = UserDefaults(suiteName: suiteName)!
        suite.removePersistentDomain(forName: suiteName)
        return UserDefaultsSettingsRepository(userDefaults: suite, keychain: StubKeychainService())
    }

    // MARK: - clampTabs

    func testClampTabsRemovesDuplicatesFromInactive() {
        let clamped = UserDefaultsSettingsRepository.clampTabs(
            active: [.reading, .library],
            inactive: [.biorhythm, .biorhythm, .biorhythm, .ask],
            mandatory: [.learn, .horoscope, .chat]
        )
        XCTAssertEqual(clamped.inactive.filter { $0 == .biorhythm }.count, 1,
                       "Los duplicados de inactiveTabs deben colapsar a uno")
    }

    func testClampTabsRemovesOverlapPreferringActive() {
        // Estado de la captura: Biorritmo activo en la barra Y además 3 veces en ocultos.
        let clamped = UserDefaultsSettingsRepository.clampTabs(
            active: [.reading, .library, .daily, .settings, .biorhythm, .chat, .horoscope, .learn],
            inactive: [.biorhythm, .biorhythm, .biorhythm, .ask, .soulLink, .reference, .natal],
            mandatory: [.learn, .horoscope, .chat]
        )
        XCTAssertFalse(clamped.inactive.contains(.biorhythm),
                       "Un tab activo no debe aparecer en inactiveTabs")
        XCTAssertTrue(clamped.active.contains(.biorhythm))
        XCTAssertEqual(Set(clamped.active).count, clamped.active.count, "activeTabs sin duplicados")
        XCTAssertEqual(Set(clamped.inactive).count, clamped.inactive.count, "inactiveTabs sin duplicados")
    }

    func testClampTabsOverflowsIntoInactiveWithoutDuplicates() {
        var active: [AppTab] = [.learn, .horoscope, .chat, .reading, .library, .daily, .settings, .journal, .biorhythm, .natal]
        var inactive: [AppTab] = [.biorhythm, .ask]
        // Dos ciclos de clamp sobre el mismo estado deben ser idempotentes
        // (antes, cada ciclo acumulaba otra copia del excedente en inactive).
        for _ in 0..<3 {
            let clamped = UserDefaultsSettingsRepository.clampTabs(
                active: active, inactive: inactive, mandatory: [.learn, .horoscope, .chat]
            )
            active = clamped.active
            inactive = clamped.inactive
        }
        XCTAssertLessThanOrEqual(active.count, 8)
        XCTAssertEqual(Set(inactive).count, inactive.count, "El excedente no debe duplicarse entre ciclos")
        XCTAssertEqual(inactive.filter { $0 == .biorhythm }.count, 1)
        for mandatory in [.learn, .horoscope, .chat] as [AppTab] {
            XCTAssertTrue(active.contains(mandatory), "Los tabs obligatorios permanecen activos")
        }
    }

    // MARK: - load() extremo a extremo con estado persistido corrupto

    func testLoadHealsCorruptedPersistedTabs() {
        let repo = makeRepository(suiteName: "tab-sanitize-heal-\(UUID().uuidString)")
        // Exactamente el estado inyectado en el simulador (captura del usuario)
        repo.saveValue(["reading", "library", "daily", "settings", "biorhythm", "chat", "horoscope", "learn"], forKey: "activeTabs")
        repo.saveValue(["biorhythm", "biorhythm", "biorhythm", "ask", "soulLink", "reference", "natal"], forKey: "inactiveTabs")

        let settings = repo.load()

        XCTAssertEqual(settings.activeTabs.filter { $0 == .biorhythm }.count, 1)
        XCTAssertFalse(settings.inactiveTabs.contains(.biorhythm))
        XCTAssertEqual(Set(settings.activeTabs).count, settings.activeTabs.count)
        XCTAssertEqual(Set(settings.inactiveTabs).count, settings.inactiveTabs.count)
        for mandatory in [.learn, .horoscope, .chat] as [AppTab] {
            XCTAssertTrue(settings.activeTabs.contains(mandatory))
            XCTAssertFalse(settings.inactiveTabs.contains(mandatory))
        }
    }

    func testSaveWritesSanitizedTabs() {
        let repo = makeRepository(suiteName: "tab-sanitize-save-\(UUID().uuidString)")
        var settings = UserSettings()
        settings.activeTabs = [.reading, .biorhythm, .biorhythm]
        settings.inactiveTabs = [.biorhythm, .biorhythm, .ask]

        repo.save(settings)
        let reloaded = repo.load()

        XCTAssertEqual(reloaded.activeTabs.filter { $0 == .biorhythm }.count, 1)
        XCTAssertFalse(reloaded.inactiveTabs.contains(.biorhythm))
        XCTAssertFalse(reloaded.inactiveTabs.contains(.ask) && reloaded.activeTabs.contains(.ask))
    }
}
