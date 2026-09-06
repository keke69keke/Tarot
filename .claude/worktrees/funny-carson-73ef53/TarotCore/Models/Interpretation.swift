import Foundation

/// Represents possible positions within a tarot spread.
public enum SpreadPositionType: String, Codable {
    case daily = "Daily"
    case past = "Past"
    case present = "Present"
    case future = "Future"
    case advice = "Advice"
    case outcome = "Outcome"
    case challenge = "Challenge"
    case strength = "Strength"
    case shadow = "Shadow"
    case environment = "Environment"
    case unknown = "Unknown"
}

/// Textual meaning of a card, optionally specialised per spread position.
public struct Interpretation: Codable {

    /// General summary text. Must be between 100 and 400 words.
    public let summary: String

    /// The specific cards drawn for this interpretation (the source of truth).
    public let cards: [DrawnCard]

    /// At least 3 keywords that capture the essence of the interpretation.
    public let keywords: [String]

    /// Position-specific override texts. When a position is absent the general
    /// `summary` is used as fallback (Requirement 7.5).
    public let contextual: [SpreadPositionType: String]

    /// Structured aspects commonly consulted by users (e.g., Amor, Economía, Salud, Carrera).
    public let aspects: [String: String]

    public init(
        cards: [DrawnCard], // Changed to accept cards directly for synergy support
        summary: String? = nil, // Made optional, allowing dynamic generation if needed
        keywords: [String],
        contextual: [SpreadPositionType: String] = [:],
        aspects: [String: String] = [:]
    ) {
        self.cards = cards
        // If summary is not provided, we can generate a default one based on the spread/cards
        self.summary = summary ?? Interpretation.generateDefaultSummary(from: cards)
        self.keywords = keywords
        self.contextual = contextual
        self.aspects = aspects
    }

    /// Backwards-compatible initializer used by older modules that constructed
    /// an Interpretation without providing the originating DrawnCard list.
    public init(summary: String, keywords: [String], contextual: [SpreadPositionType: String] = [:]) {
        self.init(cards: [], summary: summary, keywords: keywords, contextual: contextual, aspects: [:])
    }

    /// Generates a high-level summary string based on the drawn cards and their positions.
    /// This is used when an explicit summary isn't provided during initialization.
    static func generateDefaultSummary(from cards: [DrawnCard]) -> String {
        guard !cards.isEmpty else {
            return "No se han revelado cartas en esta lectura."
        }

        let count = cards.count
        let cardNames = cards.map { $0.card.name }
        let majorArcana = cards.filter { $0.card.arcanaType == .major }
        let reversedCards = cards.filter { $0.isReversed }

        var summary = ""

        // Opening based on spread size
        switch count {
        case 1:
            summary = "Una sola carta ha hablado: \(cardNames.first ?? "desconocida"). Su mensaje es directo y poderoso, resonando en el núcleo de tu pregunta. "
        case 2...3:
            summary = "Esta tirada concise de \(count) cartas que dialogan entre sí. "
            if !majorArcana.isEmpty {
                summary += "La presencia de los Arcanos Mayores eleva la lectura a un plano profundamente significativo. "
            }
        case 4...6:
            summary = "El despliegue de \(count) cartas teje una narrativa matizada. Cada posición ilumina un aspecto distinto de tu situación, creando un tapiz de significados entrelazados. "
        default:
            summary = "\(count) cartas se han alineado para revelar una historia compleja. Esta lectura extensa examina múltiples capas de tu realidad, desde las causas ocultas hasta los desenlaces probables. "
        }

        // Highlight major arcana if present
        if !majorArcana.isEmpty {
            let majorNames = majorArcana.map { $0.card.name }
            if majorNames.count == 1 {
                summary += "\(majorNames.first ?? "Un Arcano Mayor") emerge como fuerza dominante, señalando una lección kármica o momento de profunda transformación. "
            } else {
                summary += "Los Arcanos Mayores \(majorNames.joined(separator: " y ")) convergen, indicando que estás atravesando un ciclo de crecimiento espiritual de gran magnitud. "
            }
        }

        // Mention reversed cards
        if !reversedCards.isEmpty {
            let reversedNames = reversedCards.map { $0.card.name }
            summary += "Las cartas invertidas (\(reversedNames.joined(separator: ", "))) sugieren energías bloqueadas o internas que requieren tu atención consciente. "
        }

        // Position-based insights
        if cards.count >= 3 {
            let positions = cards.prefix(3).map { $0.position.displayName }
            summary += "En las posiciones clave observamos: "
            summary += positions.enumerated().map { "\($0.element) revela \(cardNames[$0.offset])" }.joined(separator: ", ")
            summary += ". "
        }

        // Closing guidance
        summary += "La interacción entre estas cartas sugiere un momento de transición y revelation. Profundiza en cada posición y aspecto para descubrir cómo estas energías se entrelazan en tu situación particular."

        return summary
    }
}
