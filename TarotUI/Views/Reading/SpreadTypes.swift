import Foundation

/// Enum representing different Tarot spread configurations.
public enum SpreadType: CaseIterable, Identifiable {
    case celticCross
    case threeCard
    case oneCard
    case free // Free card count
    case oneCardWithSignificator
    case twoCard
    case threeCardWithSignificator
    case fourCard
    case fiveCard
    case sevenCard
    case nineCard

    // MARK: - Properties
    var id: Self { self }
    var symbol: String {
        switch self {
        case .celticCross: return "☮"
        case .threeCard: return "3"
        case .oneCard: return "1"
        case .free: return "🎲"
        case .oneCardWithSignificator: return "1+"
        case .twoCard: return "2"
        case .threeCardWithSignificator: return "3+"
        case .fourCard: return "4"
        case .fiveCard: return "5"
        case .sevenCard: return "7"
        case .nineCard: return "9"
        }
    }

    var label: String {
        switch self {
        case .celticCross: return "Celtic Cross"
        case .threeCard: return "Three-Card Spread"
        case .oneCard: return "Single Card"
        case .free: return "Free Cards"
        case .oneCardWithSignificator: return "Single Card + Significator"
        case .twoCard: return "Two-Card Spread"
        case .threeCardWithSignificator: return "Three-Card Spread + Significator"
        case .fourCard: return "Four-Card Spread"
        case .fiveCard: return "Five-Card Spread"
        case .sevenCard: return "Seven-Card Spread"
        case .nineCard: return "Nine-Card Spread"
        }
    }

    var positions: Int {
        switch self {
        case .celticCross: return 10
        case .threeCard: return 3
        case .oneCard: return 1
        case .free: return 0 // Free cards are dynamic
        case .oneCardWithSignificator: return 2
        case .twoCard: return 2
        case .threeCardWithSignificator: return 4
        case .fourCard: return 4
        case .fiveCard: return 5
        case .sevenCard: return 7
        case .nineCard: return 9
        }
    }

    var esotericDescription: String {
        switch self {
        case .celticCross: return "The classic spread for deep dives into past, present, and future."
        case .threeCard: return "A simple spread for quick insights."
        case .oneCard: return "A single card for guidance."
        case .free: return "Custom number of cards for your spread."
        case .oneCardWithSignificator: return "A single card plus a significator for deeper context."
        case .twoCard: return "Two cards for contrasting perspectives."
        case .threeCardWithSignificator: return "Three cards plus a significator for layered insights."
        case .fourCard: return "Four cards for balanced analysis."
        case .fiveCard: return "Five cards for comprehensive readings."
        case .sevenCard: return "Seven cards for a fuller picture."
        case .nineCard: return "Nine cards for a complete narrative."
        }
    }
}
