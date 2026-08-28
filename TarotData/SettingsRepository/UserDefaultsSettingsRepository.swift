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
        let mandatoryTabs: [AppTab] = [.learn, .horoscope, .chat]
        for tab in mandatoryTabs where !updatedActiveTabs.contains(tab) {
            updatedActiveTabs.append(tab)
        }
        // Preserve user-defined tab order (do NOT sort by default order)
        // Límite iOS: máximo 5 tabs activos (más de 5 → iOS muestra "Más")
        let clamped = Self.clampTabs(active: updatedActiveTabs, inactive: inactiveTabs, mandatory: mandatoryTabs)
        let finalInactiveTabs = clamped.inactive
        updatedActiveTabs = clamped.active

        let openAIKey = keychain.read(Keys.openAIKey) ?? ""
        let userName = userDefaults.string(forKey: Keys.userName) ?? ""
        let biorhythmBirthDate = userDefaults.object(forKey: Keys.biorhythmBirthDate) as? Date
        let natalBirthDate = userDefaults.object(forKey: Keys.natalBirthDate) as? Date
        let natalBirthTime = userDefaults.object(forKey: Keys.natalBirthTime) as? Date
        let natalPlace = userDefaults.string(forKey: Keys.natalPlace) ?? ""

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
            natalPlace: natalPlace
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

        // Ensure mandatory tabs are always in activeTabs and never in inactiveTabs when saving
        let defaultActiveTabs = UserSettings().activeTabs
        var activeTabsToSave = settings.activeTabs
        let mandatory: [AppTab] = [.learn, .horoscope, .chat]
        for tab in mandatory where !activeTabsToSave.contains(tab) {
            activeTabsToSave.append(tab)
        }
        // Preserve user-defined tab order
        let inactiveTabsToSave = settings.inactiveTabs.filter { !mandatory.contains($0) }

        userDefaults.set(activeTabsToSave.map { $0.rawValue }, forKey: Keys.activeTabs)
        userDefaults.set(inactiveTabsToSave.map { $0.rawValue }, forKey: Keys.inactiveTabs)
        _ = keychain.write(settings.openAIKey, for: Keys.openAIKey)
    }

    // MARK: - Tab Limit

    /// iOS muestra "Más" con más de 5 tabs. Mantiene siempre los tabs
    /// obligatorios activos; los excedentes vuelven a `inactiveTabs`.
    /// - Returns: Tupla `(active, inactive)` con `active.count <= 5`.
    public static func clampTabs(
        active: [AppTab],
        inactive: [AppTab],
        mandatory: [AppTab] = [.learn],
        maxActive: Int = 8
    ) -> (active: [AppTab], inactive: [AppTab]) {
        guard active.count > maxActive else { return (active, inactive) }
        // Conserva el orden: los primeros `maxActive` tras respetar mandatory al frente
        var ordered = active.filter { mandatory.contains($0) }
        for tab in active where !ordered.contains(tab) {
            if ordered.count >= maxActive { break }
            ordered.append(tab)
        }
        let overflow = active.filter { !ordered.contains($0) }
        return (ordered, inactive + overflow)
    }
}