import Foundation

/// Service for analyzing dreams and bridging them with Tarot wisdom.
public protocol DreamOracleProtocol: ObservableObject {
    func analyzeDream(text: String) async throws -> DreamAnalysis
}

public struct DreamAnalysis {
    public let summary: String
    public let identifiedSymbols: [String]
    public let emotionalTone: String
    public let recommendedSpread: SpreadType?
    public let reasoning: String
}

public final class DreamOracleService: DreamOracleProtocol {
    private let intelligence: any OmniIntelligenceProtocol
    private let repository: DreamRepositoryProtocol

    public init(intelligence: any OmniIntelligenceProtocol, repository: DreamRepositoryProtocol) {
        self.intelligence = intelligence
        self.repository = repository
    }

    public func analyzeDream(text: String) async throws -> DreamAnalysis {
        let prompt = """
        Actúa como el Oráculo Onírico, un maestro en la interpretación de sueños y arquetipos del tarot.
        Analiza el siguiente sueño y extrae su esencia espiritual:

        SUEÑO:
        \"\(text)\"

        Instrucciones:
        1. Identifica los símbolos clave y अर्quetipos presentes.
        2. Determina el tono emocional predominante.
        3. Recomienda una tirada de tarot específica (ej: Tres Cartas, Cruz Celta, Tirada Libre) que ayude al consultante a resolver la tensión del sueño.
        4. Explica brevemente por qué recomiendas esa tirada.

        Formato de respuesta (JSON estrictamente):
        {
          \"summary\": \"Resumen poético del sueño\",
          \"symbols\": [\"Símbolo 1\", \"Símbolo 2\"],
          \"tone\": \"Tono emocional\",
          \"recommendedSpread\": \"nombre_del_spread\",
          \"reasoning\": \"Razón de la recomendación\"
        }
        """

        let response = try await intelligence.synthesize(prompt: prompt)
        return parseAnalysis(response)
    }

    private func parseAnalysis(_ response: String) -> DreamAnalysis {
        // Simple JSON parsing logic
        guard let data = response.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return DreamAnalysis(
                summary: "El oráculo está en silencio, pero los símbolos permanecen.",
                identifiedSymbols: [],
                emotionalTone: "Misterioso",
                recommendedSpread: .threeCard,
                reasoning: "Una lectura base para comenzar a descifrar el mensaje."
            )
        }

        let spreadRaw = json["recommendedSpread"] as? String ?? ""
        let spread = SpreadType.allCases.first { $0.rawValue == spreadRaw } ?? .threeCard

        return DreamAnalysis(
            summary: json["summary"] as? String ?? "Sin resumen",
            identifiedSymbols: json["symbols"] as? [String] ?? [],
            emotionalTone: json["tone"] as? String ?? "Neutral",
            recommendedSpread: spread,
            reasoning: json["reasoning"] as? String ?? ""
        )
    }
}
