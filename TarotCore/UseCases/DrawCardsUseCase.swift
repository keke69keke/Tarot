// MARK: - Protocols

public protocol DrawCardsUseCaseProtocol {
    func execute(for spread: Spread) async throws -> ReadingResult
}

public protocol SpreadSynthesizerProtocol {
    func synthesize(for spread: Spread, drawnCards: [DrawnCard]) async throws -> String
    func synthesizeNarrative(for spread: Spread, drawnCards: [DrawnCard]) async throws -> String
}

// MARK: - Types
public struct ReadingResult: Codable {
    public let drawnCards: [DrawnCard]
    public let synthesisSummary: String
    public let narrativeSummary: String?
    public let spread: Spread

    public init(
        drawnCards: [DrawnCard],
        synthesisSummary: String,
        narrativeSummary: String? = nil,
        spread: Spread
    ) {
        self.drawnCards = drawnCards
        self.synthesisSummary = synthesisSummary
        self.narrativeSummary = narrativeSummary
        self.spread = spread
    }
}

// MARK: - Implementation
public final class DrawCardsUseCase: DrawCardsUseCaseProtocol {
    private let cardRepository: CardRepository  // ✅ Use CardRepository, not CardRepositoryProtocol
    private let synthesizer: SpreadSynthesizerProtocol

    public init(cardRepository: CardRepository, synthesizer: SpreadSynthesizerProtocol) {
        self.cardRepository = cardRepository
        self.synthesizer = synthesizer
    }

    public func execute(for spread: Spread) async throws -> ReadingResult {
        let drawnCards = try await cardRepository.drawCards(for: spread)

        var enrichedCards: [DrawnCard] = []
        for var card in drawnCards {
            let interpretation = cardRepository.interpretation(
                for: card.card,
                position: card.position,
                orientation: card.orientation
            )
            card.positionalInterpretation = interpretation.summary
            enrichedCards.append(card)
        }

        let synthesisSummary = try await synthesizer.synthesize(for: spread, drawnCards: enrichedCards)
        let narrativeSummary = try await synthesizer.synthesizeNarrative(for: spread, drawnCards: enrichedCards)

        return ReadingResult(
            drawnCards: enrichedCards,
            synthesisSummary: synthesisSummary,
            narrativeSummary: narrativeSummary,
            spread: spread
        )
    }
}
