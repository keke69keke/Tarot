import Foundation

/// A service responsible for taking a complete Spread and its drawn cards to synthesize a cohesive narrative.
public final class SpreadSynthesizer {
    private let cardRepository: CardRepository
    
    public init(cardRepository: CardRepository) {
        self.cardRepository = cardRepository
    }
    
    /// Generates a comprehensive narrative summary from a spread and its drawn cards.
    /// - Parameters:
    ///   - spread: The spread configuration (positions, name).
    ///   - drawnCards: The cards drawn for this spread in their positions.
    /// - Returns: A detailed string summarizing the reading's meaning, structured by position where possible.
    public func synthesize(for spread: Spread, drawnCards: [DrawnCard]) -> String {
        guard !drawnCards.isEmpty else {
            return "Esta tirada aún no contiene cartas interpretadas."
        }

        // Build the interpretation text per drawn card, then match positions
        // by normalized display name so the narrative reliably pairs each
        // position (from the spread's standard set) with the drawn card.
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

        // Overall synthesis based on the combined energy of all drawn cards.
        narrativeParts.append("\n— Síntesis General —")
        narrativeParts.append("🔮 **El Mensaje Central**: \(defaultSummary)")

        return narrativeParts.joined(separator: "\n\n")
    }
}
