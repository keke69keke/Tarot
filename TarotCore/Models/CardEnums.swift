import Foundation

// MARK: - CardSuit
public enum CardSuit: String, CaseIterable, Codable {
    case wands = "wands"
    case cups = "cups"
    case swords = "swords"
    case pentacles = "pentacles"
}

// MARK: - ArcanaType
public enum ArcanaType: String, Codable {
    case major
    case minor
}

// MARK: - CardGroup
public enum CardGroup: Hashable {
    case majorArcana
    case minorArcana(suit: CardSuit)
}

// MARK: - CardOrientation (FIX: Add Codable)
public enum CardOrientation: String, Codable {
    case upright
    case reversed
}
