import Foundation
import TarotCore

/// A record of a dream, separate from a standard Tarot reading.
/// The "Oneiric Bridge" uses these entries to find spiritual synchronicity.
public struct DreamEntry: Identifiable, Codable, Equatable {
    public let id: UUID
    public let savedAt: Date
    public var dreamText: String
    public var emotionalTone: String?
    public var identifiedSymbols: [String]
    public var linkedReadingId: UUID?

    public init(
        id: UUID = UUID(),
        savedAt: Date = .now,
        dreamText: String,
        emotionalTone: String? = nil,
        identifiedSymbols: [String] = [],
        linkedReadingId: UUID? = nil
    ) {
        self.id = id
        self.savedAt = savedAt
        self.dreamText = dreamText
        self.emotionalTone = emotionalTone
        self.identifiedSymbols = identifiedSymbols
        self.linkedReadingId = linkedReadingId
    }
}
