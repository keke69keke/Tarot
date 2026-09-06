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

        // Opening based on spread size and nature
        switch count {
        case 1:
            summary = "Una sola carta ha hablado: \(cardNames.first ?? "desconocida"). Su mensaje es directo y poderoso, resonando en el núcleo de tu pregunta con una claridad absoluta. "
        case 2...3:
            summary = "Esta tirada concisa de \(count) cartas revela un diálogo esencial entre energías. "
            if !majorArcana.isEmpty {
                summary += "La presencia de los Arcanos Mayores eleva la lectura a un plano trascendental, señalando influencias del destino. "
            }
        case 4...6:
            summary = "El despliegue de \(count) cartas teje una narrativa matizada y profunda. Cada posición ilumina un ángulo distinto de tu situación, creando un tapiz de significados entrelazados. "
        default:
            summary = "\(count) cartas se han alineado para revelar una historia compleja y exhaustiva. Esta lectura examina múltiples capas de tu realidad, desde las causas ocultas hasta los desenlaces más probables. "
        }

        // Synthesis of the "Energy" of the draw
        if majorArcana.count >= 3 {
            summary += "La densidad de Arcanos Mayores sugiere que te encuentras en un punto de inflexión vital, donde fuerzas kármicas están guiando tu camino. "
        } else if reversedCards.count > count / 2 {
            summary += "Predominan las energías invertidas, lo que indica un momento de introspección forzada o bloqueos internos que requieren atención consciente. "
        } else if reversedCards.isEmpty && !majorArcana.isEmpty {
            summary += "La armonía de las cartas en posición derecha, junto a la fuerza de los Arcanos, señala un flujo natural y alineado con tu propósito superior. "
        }

        // Highlight specific dominant forces
        if majorArcana.count == 1 {
            let majorName = majorArcana.first?.card.name ?? "Un Arcano Mayor"
            summary += "\(majorName) emerge como la fuerza dominante, actuando como el eje central de esta interpretación. "
        }

        // Position-based insights (refined)
        if cards.count >= 3 {
            let positions = cards.prefix(3).map { $0.position.displayName }
            summary += "Al analizar el flujo inicial, observamos que "
            summary += positions.enumerated().map { "\($0.element) se manifiesta a través de \(cardNames[$0.offset])" }.joined(separator: ", ")
            summary += ". "
        }

        // Closing guidance
        summary += "La interacción entre estas energías sugiere un momento de transición y revelación. Te invitamos a profundizar en cada posición y aspecto para descubrir cómo estos mensajes se entrelazan en tu realidad actual."

        return summary
    }
}
