import Foundation

public protocol ReflectionServiceProtocol {
    /// Generates provocative, Socratic-style questions for a specific reading to invite deep introspection.
    func generatePrompts(for spread: Spread, moonPhase: String) async throws -> [String]

    /// Provides a "mirror" response to the user's reflection, acting as a spiritual guide.
    func reflect(on response: String, context: JournalEntry) async throws -> String
}

public final class ReflectionService: ReflectionServiceProtocol {
    private let intelligence: any OmniIntelligenceProtocol

    public init(intelligence: any OmniIntelligenceProtocol) {
        self.intelligence = intelligence
    }

    public func generatePrompts(for spread: Spread, moonPhase: String) async throws -> [String] {
        let cardsDescription = spread.drawnCards.map { "\($0.card.name) (\($0.position.displayName))" }.joined(separator: ", ")

        let prompt = """
        Actúa como un mentor espiritual y experto en tarot. Basándote en la siguiente tirada, genera 2 preguntas provocativas y profundas que inviten al usuario a una introspección honesta.

        Lectura: \(cardsDescription)
        Fase Lunar: \(moonPhase)

        Instrucciones:
        1. Las preguntas no deben ser predictivas, sino reflexivas (estilo Socrático).
        2. Enfócate en la sombra, el crecimiento personal y la responsabilidad del consultante.
        3. Evita clichés; busca la tensión emocional entre las cartas.
        4. Formato: Devuelve solo las preguntas, una por línea, sin numeración.
        5. Idioma: Español.

        Resultado:
        """
        let response = try await intelligence.synthesize(prompt: prompt)
        return response.components(separatedBy: "\n").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
    }

    public func reflect(on response: String, context: JournalEntry) async throws -> String {
        let cardsDescription = context.spread.drawnCards.map { "\($0.card.name) (\($0.position.displayName))" }.joined(separator: ", ")

        let prompt = """
        Actúa como el Espejo del Alma, un guía espiritual que no da respuestas, sino que devuelve la verdad al consultante.

        Contexto de la Lectura:
        - Cartas: \(cardsDescription)
        - Fase Lunar: \(context.moonPhase)
        - Intención/Notas: \(context.notes)

        Respuesta del Usuario a la introspección:
        "\(response)"

        Instrucciones para el Espejo:
        1. No valides ni juzgues la respuesta. No digas "está bien" o "es correcto".
        2. Refleja la emoción subyacente. Usa frases como "Siento que en tus palabras hay un eco de..." o "El espejo muestra una tensión entre...".
        3. Conecta la respuesta del usuario con un arquetipo de las cartas presentes en la lectura.
        4. Termina con una única pregunta final que empuje al usuario un paso más allá en su autodescubrimiento.
        5. Tono: Lujoso, minimalista, profundo y ligeramente misterioso.
        6. Idioma: Español.

        Resultado:
        """
        return try await intelligence.synthesize(prompt: prompt)
    }
}
