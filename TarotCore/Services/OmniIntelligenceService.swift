import Foundation
import SwiftUI
import TarotCore

/// A unified intelligence engine that handles chat, synthesis, and spiritual reflection.
/// It merges the roles of the AI Chat, Synthesis Engine, and Reflection Service into one "Soul" for the app.
public protocol OmniIntelligenceProtocol: ObservableObject, NeuralSynthesisEngineProtocol {
    var messages: [ChatMessage] { get }
    var isLoading: Bool { get }
    var errorMessage: String? { get }

    func send(userMessage: String) async
    func clearHistory()
    func synthesize(prompt: String) async throws -> String
}

public final class OmniIntelligenceService: OmniIntelligenceProtocol {
    @Published public var messages: [ChatMessage] = []
    @Published public var isLoading = false
    @Published public var errorMessage: String?

    private var apiKey: String
    private let repository: any CardRepository
    private let planetaryService: PlanetaryServiceProtocol
    public var patterns: PatternRecognitionServiceProtocol?
    public var currentSoulState: SoulState = .unknown

    private func getCurrentSystemPrompt() async -> String {
        var themes: [String] = []
        if let patterns = patterns {
            do {
                themes = try await patterns.identifyRecurringThemes(limit: 5)
            } catch {
                // Fail silently for system prompt augmentation
            }
        }
        return getDynamicSystemPrompt(patterns: themes)
    }

    private func getDynamicSystemPrompt(patterns: [String] = []) -> String {
        let basePrompt = """
        Eres una lectora de tarot sabia, empática y perspicaz llamada "Arcana". \
        Tu especialidad es el Tarot Rider-Waite y sus 78 cartas. \
        Respondes siempre en español con un tono cálido, misterioso y espiritual. \
        Cuando el usuario pregunta sobre una carta específica, describes su simbolismo, \
        arquetipos y cómo puede aplicarse a su situación. \
        Cuando el usuario pide una lectura, haces preguntas clarificadoras antes de proceder. \
        Siempre recuerdas que el tarot es una herramienta de reflexión y autoconocimiento, \
        no predicción del futuro. Usas emojis de luna, estrellas y cartas ocasionalmente. \
        Mantienes las respuestas concisas (máximo 3 párrafos) a menos que se pida detalle. \
        No tienes acceso a internet ni a información externa; solo tu conocimiento del tarot.
        """

        let influence = planetaryService.currentDominantPlanet()
        let celestialContext = """

        Contexto Astral Actual: La energía dominante es \(influence.planet.rawValue), \
        aportando un estado de ánimo \(influence.mood) y una energía de \(influence.energy). \
        Ajusta tu tono y perspectiva para reflejar esta influencia cósmica en tus respuestas.
        """

        var soulContext = ""
        if !patterns.isEmpty {
            soulContext = """

            Patrones del Alma Detectados: He notado que en las lecturas recientes del consultante \
            aparecen temas recurrentes: \(patterns.joined(separator: ", ")). \
            Utiliza este conocimiento para profundizar en la lectura, reconociendo estos patrones \
            como parte de su proceso de evolución espiritual.
            """
        }

        if currentSoulState != .unknown {
            let biometricMood = currentSoulState == .stressed ? "en un estado de alta tensión y estrés" :
                                (currentSoulState == .calm ? "en un estado de profunda paz y apertura" : "en un estado energético y enfocado")
            soulContext += """

            Estado Biométrico Actual: El consultante se encuentra \(biometricMood). \
            Ajusta tu tono para ser \(currentSoulState == .stressed ? "más aterrizador, calmante y protector" : "más expansivo y místico"), \
            validando su estado físico mientras guías su camino espiritual.
            """
        }

        return basePrompt + celestialContext + soulContext
    }

    public init(apiKey: String, repository: any CardRepository, planetaryService: PlanetaryServiceProtocol) {
        self.apiKey = apiKey
        self.repository = repository
        self.planetaryService = planetaryService
    }

    public func updateAPIKey(_ key: String) {
        self.apiKey = key
    }

    // MARK: - Chat Logic
    public func send(userMessage: String) async {
        let userMsg = ChatMessage(role: .user, content: userMessage)
        messages.append(userMsg)
        isLoading = true
        errorMessage = nil

        do {
            let reply = try await callOpenAI(userMessage: userMessage)
            messages.append(ChatMessage(role: .assistant, content: reply))
        } catch {
            if let chatError = error as? ChatError {
                errorMessage = chatError.localizedDescription
            } else {
                errorMessage = "Error de conexión: \(error.localizedDescription)"
            }
        }
        isLoading = false
    }

    public func clearHistory() {
        messages.removeAll()
    }

    // MARK: - Synthesis Logic
    public func synthesize(prompt: String) async throws -> String {
        return try await callOpenAI(userMessage: prompt, isSynthesis: true)
    }

    public func synthesizeSummary(for spread: Spread, moonPhase: String) async throws -> String {
        return try await synthesizeSummaryWithContext(for: spread, moonPhase: moonPhase, isDream: false, dreamThemes: nil)
    }

    public func synthesizeSynastrySummary(for spread: Spread, partnerName: String, moonPhase: String) async throws -> String {
        let cardsDescription = spread.drawnCards.map { drawn in
            "\(drawn.card.name) in position \(drawn.position.displayName)"
        }.joined(separator: ", ")

        let prompt = """
        Actúa como Arcana, la sabia lectora de tarot. Estás realizando una lectura de Sinastría (Sincronía de Almas) entre el consultante y \(partnerName).

        Cartas de la Sincronía: \(cardsDescription)
        Fase Lunar: \(moonPhase)

        Instrucciones:
        1. Analiza cómo las energías de estas cartas crean un puente entre las dos almas.
        2. No te centres en el individuo, sino en la RESONANCIA entre ambos.
        3. Explora los puntos de convergencia espiritual y los desafíos de crecimiento mutuo.
        4. Mantén un tono místico, lujoso y profundamente empático.
        5. Longitud: entre 150 y 300 palabras.
        6. Idioma: Español.

        Resultado:
        """
        return try await synthesize(prompt: prompt)
    }

    public func synthesizeDreamSummary(for spread: Spread, moonPhase: String, themes: String?) async throws -> String {
        return try await synthesizeSummaryWithContext(for: spread, moonPhase: moonPhase, isDream: true, dreamThemes: themes)
    }

    private func synthesizeSummaryWithContext(for spread: Spread, moonPhase: String, isDream: Bool, dreamThemes: String?) async throws -> String {
        let cardsDescription = spread.drawnCards.map { drawn in
            "\(drawn.card.name) in position \(drawn.position.displayName) (\(drawn.orientation == .upright ? "upright" : "reversed"))"
        }.joined(separator: ", ")

        let prompt = """
        Actúa como Arcana, la sabia lectora de tarot. Sintetiza una lectura coherente y poética basada en los siguientes datos:

        Cartas: \(cardsDescription)
        Fase Lunar: \(moonPhase)
        \(isDream ? "Naturaleza de la lectura: Onírica (Sueño). Temas del sueño: \(dreamThemes ?? "No especificados")" : "")

        Instrucciones:
        1. No listes las cartas una por una. Crea una narrativa fluida.
        2. Conecta los significados de las cartas entre sí, buscando hilos conductores.
        3. Integra la influencia de la fase lunar (\(moonPhase)) en el tono y la conclusión.
        \(isDream ? "4. Al ser una lectura onírica, integra los símbolos del sueño con los arquetipos del tarot. Explora el lenguaje del inconsciente y los mensajes ocultos en la arquitectura del sueño." : "4. Mantén un tono místico, empático y lujoso.")
        5. Longitud: entre 100 y 300 palabras.
        6. Idioma: Español.

        Resultado:
        """
        return try await synthesize(prompt: prompt)
    }

    // MARK: - Private API Logic
    private func callOpenAI(userMessage: String, isSynthesis: Bool = false) async throws -> String {
        guard !apiKey.isEmpty, apiKey != "sk-..." else {
            return try await localTarotResponse(for: userMessage)
        }

        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var history: [[String: String]] = [
            ["role": "system", "content": await getCurrentSystemPrompt()]
        ]
        if !isSynthesis {
            for msg in messages.dropLast() {
                switch msg.role {
                case .user: history.append(["role": "user", "content": msg.content])
                case .assistant: history.append(["role": "assistant", "content": msg.content])
                default: break
                }
            }
        }
        history.append(["role": "user", "content": userMessage])

        let body: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": history,
            "temperature": 0.85,
            "max_tokens": 600
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            if httpResponse.statusCode == 401 {
                throw ChatError.invalidAPIKey
            } else if httpResponse.statusCode == 429 {
                throw ChatError.rateLimited
            }
            throw ChatError.serverError(httpResponse.statusCode)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let first = choices.first,
              let message = first["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw ChatError.parseError
        }
        return content
    }

    private func localTarotResponse(for query: String) async throws -> String {
        try await Task.sleep(nanoseconds: 900_000_000)

        let q = query.lowercased()
        let allCards = repository.allCards()

        if let card = allCards.first(where: { q.contains($0.name.lowercased()) }) {
            let interp = repository.interpretation(for: card, position: nil, orientation: .upright)
            return """
            ✨ **\(card.name)** es una carta de gran profundidad. \
            \(interp.summary)

            🌙 Palabras clave: \(interp.keywords.prefix(5).joined(separator: " · "))

            Recuerda que las cartas son espejos de tu alma interior. ¿Qué resuena más contigo en este momento?
            """
        }

        let randomCard = allCards.randomElement()!
        let interp = repository.interpretation(for: randomCard, position: nil, orientation: .upright)

        let responses = [
            """
            🌟 Las cartas me muestran **\(randomCard.name)** para tu pregunta.

            \(interp.summary)

            ¿Hay algo específico en tu vida sobre lo que quieras explorar con mayor profundidad?
            """,
            """
            ✨ El universo responde con **\(randomCard.name)**.

            \(interp.summary)

            Energías presentes: \(interp.keywords.prefix(4).joined(separator: " · ")). ¿Cómo se relaciona esto con tu situación?
            """,
            """
            🔮 Siento la energía de **\(randomCard.name)** rodeando tu pregunta.

            \(interp.summary)

            Las cartas siempre revelan lo que necesitamos ver, no siempre lo que queremos. ¿Qué te habla esta energía?
            """
        ]

        return responses.randomElement()!
    }
}
