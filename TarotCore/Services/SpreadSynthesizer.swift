import Foundation

/// A service responsible for taking a complete Spread and its drawn cards to synthesize a cohesive narrative.
public final class SpreadSynthesizer: SpreadSynthesizerProtocol {
    private let cardRepository: CardRepository
    private let synthesisEngine: NeuralSynthesisEngineProtocol
    private let lunarService: LunarServiceProtocol

    public init(cardRepository: CardRepository, synthesisEngine: NeuralSynthesisEngineProtocol, lunarService: LunarServiceProtocol) {
        self.cardRepository = cardRepository
        self.synthesisEngine = synthesisEngine
        self.lunarService = lunarService
    }
    
    public func synthesize(for spread: Spread, drawnCards: [DrawnCard]) async throws -> String {
        guard !drawnCards.isEmpty else {
            return "Esta tirada aún no contiene cartas interpretadas."
        }

        // Try neural synthesis first
        do {
            return try await synthesisEngine.synthesizeSummary(for: spread, moonPhase: lunarService.currentPhase())
        } catch {
            // Fallback to the deterministic synthesis
            return synthesizeDeterministic(for: spread, drawnCards: drawnCards)
        }
    }

    public func synthesizeNarrative(for spread: Spread, drawnCards: [DrawnCard]) async throws -> String {
        // For the full narrative, we use the detailed breakdown + the neural summary
        let base = synthesizeDeterministic(for: spread, drawnCards: drawnCards)

        do {
            let neural = try await synthesisEngine.synthesizeSummary(for: spread, moonPhase: lunarService.currentPhase())
            return base + "\n\n— Síntesis Neural —\n\n\(neural)"
        } catch {
            return base
        }
    }

    private func synthesizeDeterministic(for spread: Spread, drawnCards: [DrawnCard]) -> String {
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
}
