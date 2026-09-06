import Foundation

/// Persists and retrieves user preferences (Requirements 6.1 – 6.5).
public protocol SettingsRepository {

    /// Returns the current stored settings, or the default `UserSettings` if none are saved yet.
    func load() -> UserSettings

    /// Persists the given settings immediately.
    func save(_ settings: UserSettings)

    /// Generic utility to save a specific value for a key.
    func saveValue(_ value: Any?, forKey key: String)

    /// Generic utility to load a specific value for a key.
    func loadValue(forKey key: String) -> Any?
}
