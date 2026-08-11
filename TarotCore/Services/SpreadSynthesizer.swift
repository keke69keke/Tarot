import Foundation

/// A service responsible for taking a complete Spread and its drawn cards to synthesize a cohesive narrative.
public final class SpreadSynthesizer: SpreadSynthesizerProtocol {
    private let cardRepository: CardRepository
    
    public init(cardRepository: CardRepository) {
        self.cardRepository = cardRepository
    }
    
    public func synthesize(for spread: Spread, drawnCards: [DrawnCard]) -> String {
        guard !drawnCards.isEmpty else {
            return "Esta tirada aún no contiene cartas interpretadas."
        }

        var cardByName: [String: String] = [:]
        for card in drawnCards {
            let text = card.positionalInterpretation
                ?? cardRepository.interpretation(
                    for: card.card,
                    position: card.position,
                    orientation: card.orientation
                ).summary
            let key = card.position.displayName
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if !key.isEmpty {
                if cardByName[key] == nil || cardByName[key]?.isEmpty == true {
                    cardByName[key] = text
                }
            }
        }

        let defaultSummary: String = {
            let parts = drawnCards.map { dc in
                let orient = (dc.orientation == .reversed) ? "invertida" : "al derecho"
                return "\(dc.card.name) (\(orient))"
            }
            return "Tirada centrada en: " + parts.joined(separator: ", ") + "."
        }()

        var narrativeParts: [String] = []
        narrativeParts.append("— Desglose por Posición —")

        let orderedPositions: [SpreadPosition] = spread.allPositions
        for position in orderedPositions {
            let key = position.displayName
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if let text = cardByName[key], !text.isEmpty {
                narrativeParts.append("✨ **\(position.displayName)**: \(text)")
            } else {
                narrativeParts.append("❓ **\(position.displayName)**: \(defaultSummary)")
            }
        }

        narrativeParts.append("\n— Síntesis General —")
        narrativeParts.append("🔮 **El Mensaje Central**: \(defaultSummary)")

        return narrativeParts.joined(separator: "\n\n")
    }

    public func synthesizeNarrative(for spread: Spread, drawnCards: [DrawnCard]) -> String {
        synthesize(for: spread, drawnCards: drawnCards)
    }
}
