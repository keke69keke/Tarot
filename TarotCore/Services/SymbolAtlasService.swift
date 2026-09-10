import Foundation

/// A bridge between esoteric universal symbols and the user's personal tarot history.
public protocol SymbolAtlasServiceProtocol {
    /// Retrieves the list of all tracked universal symbols.
    func getAllSymbols() -> [UniversalSymbol]

    /// Finds all journal entries where a specific symbol appeared (via associated cards).
    func findReadings(for symbol: UniversalSymbol) -> [JournalEntry]

    /// Returns the "Universal Meaning" of a symbol.
    func meaning(for symbol: UniversalSymbol) -> String
}

public struct UniversalSymbol: Identifiable, Hashable {
    public let id: String
    public let name: String
    public let associatedCardIds: Set<Int>
}

public final class SymbolAtlasService: SymbolAtlasServiceProtocol {
    private let journalRepository: JournalRepository
    private let cardRepository: any CardRepository

    public init(journalRepository: JournalRepository, cardRepository: any CardRepository) {
        self.journalRepository = journalRepository
        self.cardRepository = cardRepository
    }

    public func getAllSymbols() -> [UniversalSymbol] {
        return [
            UniversalSymbol(id: "sun", name: "El Sol", associatedCardIds: [19]),
            UniversalSymbol(id: "moon", name: "La Luna", associatedCardIds: [18]),
            UniversalSymbol(id: "star", name: "La Estrella", associatedCardIds: [17]),
            UniversalSymbol(id: "tower", name: "La Torre", associatedCardIds: [16]),
            UniversalSymbol(id: "death", name: "La Muerte", associatedCardIds: [13]),
            UniversalSymbol(id: "wheel", name: "La Rueda", associatedCardIds: [10]),
            UniversalSymbol(id: "cups", name: "Copas (Emociones)", associatedCardIds: Set((22...35).map { $0 })), // Minor cups
            UniversalSymbol(id: "swords", name: "Espadas (Intelecto)", associatedCardIds: Set((36...49).map { $0 })), // Minor swords
            UniversalSymbol(id: "wands", name: "Bastos (Energía)", associatedCardIds: Set((50...63).map { $0 })), // Minor wands
            UniversalSymbol(id: "pentacles", name: "Oros (Materia)", associatedCardIds: Set((64...77).map { $0 })), // Minor pentacles
        ]
    }

    public func findReadings(for symbol: UniversalSymbol) -> [JournalEntry] {
        let entries = journalRepository.fetchAll()
        return entries.filter { entry in
            let cardIds = Set(entry.spread.drawnCards.map { $0.card.id })
            return !cardIds.isDisjoint(with: symbol.associatedCardIds)
        }
    }

    public func meaning(for symbol: UniversalSymbol) -> String {
        switch symbol.id {
        case "sun": return "La culminación de la luz; el momento en que el alma se reconoce en el espejo del cosmos y la verdad deja de ser un secreto."
        case "moon": return "El susurro de lo invisible; el camino plateado que atraviesa el bosque de los sueños y el mapa del inconsciente."
        case "star": return "Un faro de esperanza en la noche más profunda; la promesa de que la sanación es posible y que el cielo siempre nos guía."
        case "tower": return "El relámpago que despoja lo superfluo; el colapso necesario de las falsas certezas para construir sobre la roca de la verdad."
        case "death": return "La danza eterna de la transmutación; el silencio donde muere la forma para que el espíritu pueda finalmente despertar."
        case "wheel": return "El giro inevitable del destino; el recordatorio de que somos parte de un ciclo sagrado donde cada final es un nuevo origen."
        case "cups": return "El océano del sentimiento; la marea que fluye entre el amor, la empatía y los abismos sagrados del corazón."
        case "swords": return "El filo del intelecto; la espada que corta la ilusión para revelar la verdad desnuda, aunque la herida sea necesaria."
        case "wands": return "La chispa primordial de la voluntad; el fuego que impulsa la creación y la pasión que convierte la idea en acto."
        case "pentacles": return "El ancla de la materia; la sabiduría de lo tangible, la estabilidad de la tierra y la manifestación del espíritu en la forma."
        default: return "Un eco del macrocosmos resonando en tu propia historia; un símbolo que une tu camino con la arquitectura del universo."
        }
    }
}
