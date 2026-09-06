import Foundation
import SwiftUI

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

// MARK: - CardOrientation
public enum CardOrientation: String, Codable {
    case upright
    case reversed
}

// MARK: - Planet
public enum Planet: String, CaseIterable, Codable {
    case sun, moon, mercury, venus, mars, jupiter, saturn, uranus, neptune, pluto

    public var localizedName: String {
        switch self {
        case .sun: return "Sol"
        case .moon: return "Luna"
        case .mercury: return "Mercurio"
        case .venus: return "Venus"
        case .mars: return "Marte"
        case .jupiter: return "Júpiter"
        case .saturn: return "Saturno"
        case .uranus: return "Urano"
        case .neptune: return "Neptuno"
        case .pluto: return "Plutón"
        }
    }
}

// MARK: - SoulState
public enum SoulState: String, CaseIterable, Codable {
    case calm, elevated, stressed, unknown

    public var moodDescription: String {
        switch self {
        case .calm: return "The user is in a state of deep peace and openness."
        case .elevated: return "The user is energetic and focused."
        case .stressed: return "The user is experiencing high tension or anxiety."
        case .unknown: return "The user's current state is neutral or unknown."
        }
    }
}

// MARK: - CosmicColor
public enum CosmicColor: Equatable {
    case tarotBackground
    case tarotGold
    case white
    case orange
    case blue
    case purple
    case gray
    case magenta
    case indigo
    case red
    case green
    case custom(red: Double, green: Double, blue: Double, opacity: Double = 1.0)
}

// MARK: - CosmicColor SwiftUI Conversion
extension CosmicColor {
    public var swiftUIColor: Color {
        switch self {
        case .tarotBackground:
            return Color(red: 0.03, green: 0.02, blue: 0.08)
        case .tarotGold:
            return Color(red: 0.855, green: 0.706, blue: 0.329)
        case .white:
            return Color.white
        case .orange:
            return Color(red: 1.0, green: 0.647, blue: 0.0)
        case .blue:
            return Color(red: 0.0, green: 0.478, blue: 1.0)
        case .purple:
            return Color(red: 0.627, green: 0.125, blue: 0.941)
        case .gray:
            return Color(red: 0.5, green: 0.5, blue: 0.5)
        case .magenta:
            return Color(red: 1.0, green: 0.0, blue: 1.0)
        case .indigo:
            return Color(red: 0.294, green: 0.0, blue: 0.51)
        case .red:
            return Color(red: 1.0, green: 0.0, blue: 0.0)
        case .green:
            return Color(red: 0.0, green: 0.502, blue: 0.0)
        case .custom(let r, let g, let b, let opacity):
            return Color(red: r, green: g, blue: b, opacity: opacity)
        }
    }
}

