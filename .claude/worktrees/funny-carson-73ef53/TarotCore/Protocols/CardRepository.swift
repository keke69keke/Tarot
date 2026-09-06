import Foundation

/// Read-only access to the card catalogue loaded from the bundle JSON.
public protocol CardRepository {
    func allCards() -> [Card]
    func cards(in group: CardGroup) -> [Card]
    func search(query: String) -> [Card]
    func interpretation(
        for card: Card,
        position: SpreadPosition?,
        orientation: CardOrientation
    ) -> Interpretation
    func drawCards(for spread: Spread) async throws -> [DrawnCard]
}
