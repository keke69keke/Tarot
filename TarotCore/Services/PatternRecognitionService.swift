import Foundation
import TarotCore

/// Analyzes the user's reading history to identify recurring themes and dominant energies.
public protocol PatternRecognitionServiceProtocol {
    /// Calculates the frequency of cards drawn over a specific time window.
    func calculateCardFrequencies(since date: Date) -> [Card: Int]

    /// Identifies the most dominant cards (top N) in the user's history.
    func dominantCards(limit: Int, since date: Date?) -> [Card]

    /// Analyzes recent readings to find recurring themes or "clusters" of meanings.
    func identifyRecurringThemes(limit: Int) async throws -> [String]
}

public final class PatternRecognitionService: PatternRecognitionServiceProtocol {
    private let journalRepository: JournalRepository
    private let aiService: any OmniIntelligenceProtocol

    public init(journalRepository: JournalRepository, aiService: any OmniIntelligenceProtocol) {
        self.journalRepository = journalRepository
        self.aiService = aiService
    }

    public func calculateCardFrequencies(since date: Date) -> [Card: Int] {
        let entries = journalRepository.fetchAll().filter { $0.savedAt >= date }
        var frequencies: [Card: Int] = [:]

        for entry in entries {
            for drawn in entry.spread.drawnCards {
                frequencies[drawn.card, default: 0] += 1
            }
        }

        return frequencies
    }

    public func dominantCards(limit: Int = 3, since date: Date? = nil) -> [Card] {
        let targetDate = date ?? Date().addingTimeInterval(-30 * 24 * 60 * 60) // Default 30 days
        let frequencies = calculateCardFrequencies(since: targetDate)

        return frequencies
            .sorted { $0.value > $1.value }
            .prefix(limit)
            .map { $0.key }
    }

    public func identifyRecurringThemes(limit: Int = 5) async throws -> [String] {
        let entries = journalRepository.fetchAll().prefix(20)
        guard !entries.isEmpty else { return [] }

        let summaries = entries.map { entry in
            let cards = entry.spread.drawnCards.map { $0.card.name }.joined(separator: ", ")
            return "Reading on \(entry.savedAt.formatted()): \(cards). Notes: \(entry.notes)"
        }.joined(separator: "\n\n")

        let prompt = """
        Analiza las siguientes lecturas recientes del usuario y detecta los temas recurrentes, patrones energéticos o conflictos constantes.

        Lecturas:
        \(summaries)

        Instrucciones:
        1. Identifica los 3-5 temas más fuertes (ej: "Tensión en el trabajo", "Búsqueda de claridad espiritual", "Ciclo de renovación").
        2. Para cada tema, explica brevemente por qué lo consideras un patrón basándote en las cartas repetidas.
        3. Responde en español, con un tono empático y analítico.
        4. Devuelve la respuesta como una lista de temas separada por saltos de línea.

        Resultado:
        """

        // We use the existing AI service to analyze the patterns
        let analysis = try await aiService.synthesize(prompt: prompt)
        return analysis.components(separatedBy: "\n").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
    }
}
