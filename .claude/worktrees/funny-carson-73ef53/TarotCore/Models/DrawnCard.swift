import Foundation

public struct DrawnCard: Codable, Identifiable {
    public let card: Card
    public let position: SpreadPosition
    public let orientation: CardOrientation
    public var isReversed: Bool { orientation == .reversed }
    public var positionalInterpretation: String?

    // CodingKeys to handle optional properties
    private enum CodingKeys: String, CodingKey {
        case card
        case position
        case orientation
        case positionalInterpretation
    }

    // MARK: - Initializers (Keep existing ones)

    public init(card: Card, position: SpreadPosition, orientation: CardOrientation) {
        self.card = card
        self.position = position
        self.orientation = orientation
        self.positionalInterpretation = nil
    }

    public init(card: Card, isReversed: Bool, position: SpreadPosition) {
        let orientation: CardOrientation = isReversed ? .reversed : .upright
        self.init(card: card, position: position, orientation: orientation)
    }

    public init(card: Card, position: SpreadPosition) {
        self.init(card: card, position: position, orientation: .upright)
    }

    // MARK: - Codable Conformance (Manual implementation for robustness)

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.card = try container.decode(Card.self, forKey: .card)
        self.position = try container.decode(SpreadPosition.self, forKey: .position)
        self.orientation = try container.decode(CardOrientation.self, forKey: .orientation)
        self.positionalInterpretation = try container.decodeIfPresent(String.self, forKey: .positionalInterpretation)
    }

public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(card, forKey: .card)
        try container.encode(position, forKey: .position)
        try container.encode(orientation, forKey: .orientation)
        try container.encodeIfPresent(positionalInterpretation, forKey: .positionalInterpretation)
    }

    // MARK: - Computed Properties (Keep existing ones)

    public var id: String { "\(card.id)-\(position.id)" }
}
