import Foundation

/// A saved Tarot reading in the user's personal journal (Requirement 3).
public struct JournalEntry: Identifiable {

    public let id: UUID
    public let spread: Spread
    public let savedAt: Date
    public let moonPhase: String
    public var reflectionPrompt: String?
    public var reflectionResponse: String?
    public var isDreamReading: Bool
    public var dreamThemes: String?

    /// Personal reflections. Maximum 2 000 characters (Requirement 3.2).
    public var notes: String

    /// Whether this entry has been synced to the user's iCloud account (Requirement 3.7).
    public var isSyncedToCloud: Bool

    public init(
        id: UUID = UUID(),
        spread: Spread,
        savedAt: Date = Date(),
        moonPhase: String = "Unknown",
        reflectionPrompt: String? = nil,
        reflectionResponse: String? = nil,
        isDreamReading: Bool = false,
        dreamThemes: String? = nil,
        notes: String = "",
        isSyncedToCloud: Bool = false
    ) {
        // Enforce the 2 000-character limit defensively.
        self.id = id
        self.spread = spread
        self.savedAt = savedAt
        self.moonPhase = moonPhase
        self.reflectionPrompt = reflectionPrompt
        self.reflectionResponse = reflectionResponse
        self.isDreamReading = isDreamReading
        self.dreamThemes = dreamThemes
        self.notes = String(notes.prefix(2000))
        self.isSyncedToCloud = isSyncedToCloud
    }
}
