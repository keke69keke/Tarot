import Foundation
import TarotCore

/// UserDefaults-based implementation of SettingsRepository.
/// Persists UserSettings properties using UserDefaults as the storage mechanism.
/// Validates: Requirements 6.1, 6.2, 6.3, 6.4, 6.5.
public class UserDefaultsSettingsRepository: SettingsRepository {
    
    // MARK: - UserDefaults Keys
    
    private enum Keys {
        static let allowReversedCards = "allowReversedCards"
        static let selectedLanguage = "selectedLanguage"
        static let cardBackDesign = "cardBackDesign"
        static let activeDeck = "activeDeck"
        static let appearance = "appearance"
        static let dailyNotificationHour = "dailyNotificationHour"
        static let notificationsEnabled = "notificationsEnabled"
        static let activeTabs = "activeTabs"
        static let inactiveTabs = "inactiveTabs"
        static let openAIKey = "openAIKey"
        static let userName = "userName"
        static let biorhythmBirthDate = "biorhythmBirthDate"
        static let natalBirthDate = "natalBirthDate"
        static let natalBirthTime = "natalBirthTime"
        static let natalPlace = "natalPlace"
        // AI Provider
        static let aiProvider = "aiProvider"
        static let aiBaseURL = "aiBaseURL"
        static let aiModelName = "aiModelName"
        static let aiApiKey = "aiApiKey"
    }
    
    // MARK: - Properties
    
    private let userDefaults: UserDefaults
    private let keychain: KeychainServiceProtocol
    
    // MARK: - Initialization
    
    /// Initializes the repository with the specified UserDefaults instance.
    /// - Parameter userDefaults: The UserDefaults instance to use for persistence. Defaults to .standard.
    public init(userDefaults: UserDefaults = .standard, keychain: KeychainServiceProtocol = KeychainService()) {
        self.userDefaults = userDefaults
        self.keychain = keychain
    }
    
    // MARK: - SettingsRepository Protocol
    
    /// Returns the current stored settings, or the default `UserSettings` if none are saved yet.
    public func load() -> UserSettings {
        let allowReversedCards = userDefaults.object(forKey: Keys.allowReversedCards) as? Bool ?? UserSettings().allowReversedCards
        
        let languageRawValue = userDefaults.string(forKey: Keys.selectedLanguage) ?? UserSettings().selectedLanguage.rawValue
        let selectedLanguage = Language(rawValue: languageRawValue) ?? UserSettings().selectedLanguage
        
        let cardBackRawValue = userDefaults.string(forKey: Keys.cardBackDesign) ?? UserSettings().cardBackDesign.rawValue
        let cardBackDesign = CardBackDesign(rawValue: cardBackRawValue) ?? UserSettings().cardBackDesign
        
        let activeDeckRawValue = userDefaults.string(forKey: Keys.activeDeck) ?? UserSettings().activeDeck.rawValue
        let activeDeck = DeckType(rawValue: activeDeckRawValue) ?? UserSettings().activeDeck

        let appearanceRawValue = userDefaults.string(forKey: Keys.appearance) ?? UserSettings().appearance.rawValue
        let appearance = Appearance(rawValue: appearanceRawValue) ?? UserSettings().appearance

        let dailyNotificationHour = userDefaults.object(forKey: Keys.dailyNotificationHour) as? Int ?? UserSettings().dailyNotificationHour
        
        let notificationsEnabled = userDefaults.object(forKey: Keys.notificationsEnabled) as? Bool ?? UserSettings().notificationsEnabled
        
        let activeTabsRaw = userDefaults.stringArray(forKey: Keys.activeTabs) ?? UserSettings().activeTabs.map { $0.rawValue }
        let activeTabs = activeTabsRaw.compactMap { AppTab(rawValue: $0) }
        
        let inactiveTabsRaw = userDefaults.stringArray(forKey: Keys.inactiveTabs) ?? UserSettings().inactiveTabs.map { $0.rawValue }
        let inactiveTabs = inactiveTabsRaw.compactMap { AppTab(rawValue: $0) }

        // Ensure mandatory tabs are always visible (migration from older installs)
        let defaultActiveTabs = UserSettings().activeTabs
        var updatedActiveTabs = activeTabs.isEmpty ? defaultActiveTabs : activeTabs
        // Auto-migrate: asegurar que horoscope y chat siempre estén activos (migración v2)
        let mandatoryTabs = AppTab.mandatoryTabs
        for tab in mandatoryTabs where !updatedActiveTabs.contains(tab) {
            updatedActiveTabs.append(tab)
        }
        // Preserve user-defined tab order (do NOT sort by default order)
        // Límite de tabs activos. OJO: 8, no 5. La app no usa la barra del
        // sistema (`TabView` + `.tabItem`), sino una barra propia con scroll
        // horizontal (`SlidingTabBar`), así que no existe el desbordamiento a
        // "Más" que justificaba el límite de 5 en versiones anteriores.
        let clamped = Self.clampTabs(active: updatedActiveTabs, inactive: inactiveTabs, mandatory: mandatoryTabs)
        let finalInactiveTabs = clamped.inactive
        updatedActiveTabs = clamped.active

        let openAIKey = keychain.read(Keys.openAIKey) ?? ""
        let userName = userDefaults.string(forKey: Keys.userName) ?? ""
        let biorhythmBirthDate = userDefaults.object(forKey: Keys.biorhythmBirthDate) as? Date
        let natalBirthDate = userDefaults.object(forKey: Keys.natalBirthDate) as? Date
        let natalBirthTime = userDefaults.object(forKey: Keys.natalBirthTime) as? Date
        let natalPlace = userDefaults.string(forKey: Keys.natalPlace) ?? ""

        // AI Provider
        let aiProviderRaw = userDefaults.string(forKey: Keys.aiProvider) ?? AIProvider.openAI.rawValue
        let aiProvider = AIProvider(rawValue: aiProviderRaw) ?? .openAI
        let aiBaseURL = userDefaults.string(forKey: Keys.aiBaseURL) ?? ""
        let aiModelName = userDefaults.string(forKey: Keys.aiModelName) ?? ""
        let aiApiKey = keychain.read(Keys.aiApiKey) ?? ""

        return UserSettings(
            allowReversedCards: allowReversedCards,
            selectedLanguage: selectedLanguage,
            cardBackDesign: cardBackDesign,
            activeDeck: activeDeck,
            appearance: appearance,
            dailyNotificationHour: dailyNotificationHour,
            notificationsEnabled: notificationsEnabled,
            openAIKey: openAIKey,
            activeTabs: updatedActiveTabs,
            inactiveTabs: finalInactiveTabs,
            userName: userName,
            biorhythmBirthDate: biorhythmBirthDate,
            natalBirthDate: natalBirthDate,
            natalBirthTime: natalBirthTime,
            natalPlace: natalPlace,
            aiProvider: aiProvider,
            aiBaseURL: aiBaseURL,
            aiModelName: aiModelName,
            aiApiKey: aiApiKey
        )
    }
    
    /// Persists the given settings immediately.
    public func save(_ settings: UserSettings) {
        userDefaults.set(settings.allowReversedCards, forKey: Keys.allowReversedCards)
        userDefaults.set(settings.selectedLanguage.rawValue, forKey: Keys.selectedLanguage)
        userDefaults.set(settings.cardBackDesign.rawValue, forKey: Keys.cardBackDesign)
        userDefaults.set(settings.activeDeck.rawValue, forKey: Keys.activeDeck)
        userDefaults.set(settings.appearance.rawValue, forKey: Keys.appearance)
        userDefaults.set(settings.dailyNotificationHour, forKey: Keys.dailyNotificationHour)
        userDefaults.set(settings.notificationsEnabled, forKey: Keys.notificationsEnabled)
        userDefaults.set(settings.userName, forKey: Keys.userName)
        if let d = settings.biorhythmBirthDate { userDefaults.set(d, forKey: Keys.biorhythmBirthDate) } else { userDefaults.removeObject(forKey: Keys.biorhythmBirthDate) }
        if let d = settings.natalBirthDate { userDefaults.set(d, forKey: Keys.natalBirthDate) } else { userDefaults.removeObject(forKey: Keys.natalBirthDate) }
        if let d = settings.natalBirthTime { userDefaults.set(d, forKey: Keys.natalBirthTime) } else { userDefaults.removeObject(forKey: Keys.natalBirthTime) }
        userDefaults.set(settings.natalPlace, forKey: Keys.natalPlace)

        // Sanitiza al guardar: sin duplicados ni solapamientos (prevalece
        // `active`), tabs obligatorios siempre activos y límite respetado.
        let mandatory = AppTab.mandatoryTabs
        var activeTabsToSave = settings.activeTabs
        for tab in mandatory where !activeTabsToSave.contains(tab) {
            activeTabsToSave.append(tab)
        }
        // Preserve user-defined tab order
        let inactiveBeforeClamp = settings.inactiveTabs.filter { !mandatory.contains($0) }
        let clamped = Self.clampTabs(active: activeTabsToSave, inactive: inactiveBeforeClamp, mandatory: mandatory)
        activeTabsToSave = clamped.active
        let inactiveTabsToSave = clamped.inactive

        userDefaults.set(activeTabsToSave.map { $0.rawValue }, forKey: Keys.activeTabs)
        userDefaults.set(inactiveTabsToSave.map { $0.rawValue }, forKey: Keys.inactiveTabs)
        _ = keychain.write(settings.openAIKey, for: Keys.openAIKey)

        // AI Provider
        userDefaults.set(settings.aiProvider.rawValue, forKey: Keys.aiProvider)
        userDefaults.set(settings.aiBaseURL, forKey: Keys.aiBaseURL)
        userDefaults.set(settings.aiModelName, forKey: Keys.aiModelName)
        _ = keychain.write(settings.aiApiKey, for: Keys.aiApiKey)
    }

    public func saveValue(_ value: Any?, forKey key: String) {
        userDefaults.set(value, forKey: key)
    }

    public func loadValue(forKey key: String) -> Any? {
        userDefaults.object(forKey: key)
    }

    // MARK: - Tab Limit

    /// Limita los tabs activos a `maxActive`. Mantiene siempre los tabs
    /// obligatorios activos; los excedentes vuelven a `inactiveTabs`.
    /// Sanitiza ambas listas: elimina duplicados y solapamientos (prevalece
    /// `active`) que installs antiguas pudieron persistir.
    /// - Returns: Tupla `(active, inactive)` con `active.count <= maxActive`.
    public static func clampTabs(
        active: [AppTab],
        inactive: [AppTab],
        mandatory: [AppTab] = AppTab.mandatoryTabs,
        maxActive: Int = 8
    ) -> (active: [AppTab], inactive: [AppTab]) {
        var seen = Set<AppTab>()
        let sanitizedActive = active.filter { seen.insert($0).inserted }
        let sanitizedInactive = inactive.filter { seen.insert($0).inserted }
        guard sanitizedActive.count > maxActive else { return (sanitizedActive, sanitizedInactive) }
        // Conserva el orden: los primeros `maxActive` tras respetar mandatory al frente
        var ordered = sanitizedActive.filter { mandatory.contains($0) }
        for tab in sanitizedActive where !ordered.contains(tab) {
            if ordered.count >= maxActive { break }
            ordered.append(tab)
        }
        let overflow = sanitizedActive.filter { !ordered.contains($0) }
        var finalInactive = sanitizedInactive
        for tab in overflow where !finalInactive.contains(tab) {
            finalInactive.append(tab)
        }
        return (ordered, finalInactive)
    }
}
