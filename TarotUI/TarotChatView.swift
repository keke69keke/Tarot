import SwiftUI
import TarotCore
import TarotContent
import TarotDI

// MARK: - Chat Models

public struct ChatMessage: Identifiable, Equatable {
    public let id: UUID
    public let role: Role
    public let content: String
    public let timestamp: Date

    public enum Role: Equatable {
        case user
        case assistant
        case system
    }

    public init(id: UUID = UUID(), role: Role, content: String, timestamp: Date = Date()) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
    }
}

// MARK: - AI Chat Service (multi-provider)

@MainActor
final class TarotAIChatService: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var lastEngineName: String = ArcanaIntelligenceRouter.preferredEngineName

    private var apiKey: String
    private var provider: AIProvider
    private var baseURL: String
    private var modelName: String
    private let repository: any CardRepository

    /// URL efectiva del endpoint (sin trailing slash).
    private var effectiveBaseURL: String {
        let raw = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolved = raw.isEmpty ? provider.defaultBaseURL : raw
        return resolved.hasSuffix("/") ? String(resolved.dropLast()) : resolved
    }

    /// Modelo efectivo enviado a la API.
    private var effectiveModel: String {
        let raw = modelName.trimmingCharacters(in: .whitespacesAndNewlines)
        return raw.isEmpty ? provider.defaultModel : raw
    }

    private let systemPrompt = """
    Eres "Arcana", una lectora de tarot experta con 30 años de experiencia en el Tarot Rider-Waite \
    y sus 78 cartas. No eres una simple IA, eres un puente entre lo consciente y el inconsciente. Respondes siempre en español.

    ## Filosofía de Interpretación
    - No te limites a definir la carta; conecta el arquetipo con la psique del consultante.
    - Integra la visión de Jung (Sombra, Anima/Animus, Sincronicidad) y la Cábala Hermética.
    - Si el consultante pregunta por una tirada, analiza la *sintaxis* de las cartas: cómo una modifica a la otra y qué elemento (Fuego, Agua, Aire, Tierra) domina la lectura.
    - Distingues siempre entre carta derecha e invertida, viendo la inversión no como "negativa", sino como energía bloqueada, internalizada o en proceso de transmutación.

    ## Cómo respondes
    - Tono: Cálido, misterioso y espiritual, pero con una claridad quirúrgica. Evita el lenguaje genérico de "el universo te dice"; prefiere "la energía de esta carta sugiere...".
    - Simbolismo Visual: Describe detalles específicos de la ilustración (colores, gestos, elementos) y conéctalos con la situación real del usuario.
    - Estructura: Párrafos cortos. Usa negritas (**Carta**) para los nombres. Emojis de luna/estrellas/cartas con moderación (máximo 2 por respuesta).
    - Cierre: Termina siempre con una pregunta oracular que obligue al usuario a mirar hacia adentro, no una fórmula repetitiva.
    - Longitud: Máximo 3 párrafos salvo que pidan un análisis exhaustivo.

    ## Límites
    - El tarot es una herramienta de reflexión y autoconocimiento, no predice el futuro fatalmente ni sustituye consejo médico, legal o financiero.
    - Si el usuario atraviesa una crisis grave, responde con empatía profunda y sugiere buscar apoyo profesional.
    - No inventas cartas ni datos; te ciñes al mazo Rider-Waite y la sabiduría esotérica tradicional.
    """

    init(apiKey: String, provider: AIProvider = .openAI, baseURL: String = "", modelName: String = "", repository: any CardRepository) {
        self.apiKey = apiKey
        self.provider = provider
        self.baseURL = baseURL
        self.modelName = modelName
        self.repository = repository
    }

    func updateAPIKey(_ key: String) { self.apiKey = key }

    /// Propaga cambios en caliente desde Ajustes sin recrear el servicio.
    func updateProvider(_ newProvider: AIProvider, baseURL: String, modelName: String, apiKey: String) {
        self.provider = newProvider
        self.baseURL = baseURL
        self.modelName = modelName
        self.apiKey = apiKey
        lastEngineName = newProvider.isLocal
            ? "\(newProvider.displayName)"
            : "\(newProvider.displayName) · \(effectiveModel)"
    }

    func send(userMessage: String) async {
        let trimmed = userMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isLoading else { return }
        messages.append(ChatMessage(role: .user, content: trimmed))
        isLoading = true
        errorMessage = nil

        do {
            let reply = try await callAI(userMessage: trimmed)
            messages.append(ChatMessage(role: .assistant, content: reply))
        } catch {
            errorMessage = (error as? ChatError)?.localizedDescription
                ?? "Error de conexión: \(error.localizedDescription)"
        }
        isLoading = false
    }

    func clearHistory() { messages.removeAll() }

    // MARK: - Router Apple → proveedor configurado → local

    private func callAI(userMessage: String) async throws -> String {
        // 1) Apple Intelligence on-device (solo para proveedor OpenAI sin URL custom)
        if provider == .openAI && baseURL.isEmpty && ArcanaIntelligenceRouter.appleAvailable {
            let history: [ArcanaChatTurn] = messages.dropLast().suffix(12).map {
                ArcanaChatTurn(role: $0.role == .user ? "user" : "assistant", content: $0.content)
            }
            if let appleReply = await ArcanaIntelligenceRouter.tryApple(
                systemPrompt: systemPrompt, history: history, userMessage: userMessage
            ) {
                lastEngineName = appleReply.engine
                return appleReply.text
            }
        }

        // 2) Proveedor local (Ollama / LM Studio): sin API key
        if provider.isLocal {
            return try await callOpenAICompatible(userMessage: userMessage)
        }

        // 3) Proveedor remoto: necesita API key
        guard !apiKey.isEmpty, apiKey != "sk-..." else {
            lastEngineName = "Local"
            return try await localTarotResponse(for: userMessage)
        }
        return try await callOpenAICompatible(userMessage: userMessage)
    }

    /// Endpoint `/v1/chat/completions` compatible con OpenAI.
    private func callOpenAICompatible(userMessage: String) async throws -> String {
        guard !effectiveBaseURL.isEmpty,
              let url = URL(string: "\(effectiveBaseURL)/v1/chat/completions") else {
            throw ChatError.serverError(0)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 60
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if !apiKey.isEmpty { request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization") }

        var history: [[String: String]] = [["role": "system", "content": systemPrompt]]
        if let name = UserDefaults.standard.string(forKey: "userName"), !name.isEmpty {
            history.append(["role": "system", "content": "El consultante se llama \(name)."])
        }
        for msg in messages.dropLast().suffix(12) {
            switch msg.role {
            case .user:      history.append(["role": "user",      "content": msg.content])
            case .assistant: history.append(["role": "assistant", "content": msg.content])
            default: break
            }
        }
        history.append(["role": "user", "content": userMessage])

        let body: [String: Any] = [
            "model": effectiveModel, "messages": history,
            "temperature": 0.85, "max_tokens": 600
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            if http.statusCode == 401 { throw ChatError.invalidAPIKey }
            if http.statusCode == 429 { throw ChatError.rateLimited }
            throw ChatError.serverError(http.statusCode)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let first = choices.first,
              let msg = first["message"] as? [String: Any],
              let content = msg["content"] as? String else {
            throw ChatError.parseError
        }
        lastEngineName = "\(provider.displayName) · \(effectiveModel)"
        return content
    }

    // MARK: - Motor local determinista (sin API)

    private func localTarotResponse(for query: String) async throws -> String {
        try await Task.sleep(nanoseconds: 900_000_000)
        let q = query.lowercased()
        let allCards = repository.allCards()

        if let card = allCards.first(where: { q.contains($0.name.lowercased()) }) {
            let interp = repository.interpretation(for: card, position: nil, orientation: .upright)
            return "✨ **\(card.name)** es una carta de gran profundidad. \(interp.summary)\n\n🌙 Palabras clave: \(interp.keywords.prefix(5).joined(separator: " · "))\n\nRecuerda que las cartas son espejos de tu alma interior. ¿Qué resuena más contigo en este momento?"
        }

        guard let randomCard = allCards.randomElement() else { throw ChatError.parseError }
        let interp = repository.interpretation(for: randomCard, position: nil, orientation: .upright)

        return [
            "🌟 Las cartas me muestran **\(randomCard.name)** para tu pregunta.\n\n\(interp.summary)\n\n¿Hay algo específico en tu vida sobre lo que quieras explorar con mayor profundidad?",
            "✨ El universo responde con **\(randomCard.name)**.\n\n\(interp.summary)\n\nEnergías presentes: \(interp.keywords.prefix(4).joined(separator: " · ")). ¿Cómo se relaciona esto con tu situación?",
            "🔮 Siento la energía de **\(randomCard.name)** rodeando tu pregunta.\n\n\(interp.summary)\n\nLas cartas siempre revelan lo que necesitamos ver, no siempre lo que queremos. ¿Qué te habla esta energía?"
        ].randomElement()!
    }
}

// MARK: - ChatError

enum ChatError: LocalizedError {
    case invalidAPIKey
    case rateLimited
    case serverError(Int)
    case parseError

    var errorDescription: String? {
        switch self {
        case .invalidAPIKey:      return "API Key inválida. Ve a Ajustes y verifica tu clave."
        case .rateLimited:        return "Demasiadas consultas. Espera un momento antes de continuar."
        case .serverError(let c): return "Error del servidor (\(c)). Intenta de nuevo."
        case .parseError:         return "Error al procesar la respuesta. Intenta de nuevo."
        }
    }
}

// MARK: - TarotChatView

public struct TarotChatView: View {
    @StateObject private var service: TarotAIChatService
    @State private var isShadowMode = false
    @State private var inputText = ""
    @State private var showClearAlert = false
    @FocusState private var inputFocused: Bool
    @Environment(\.colorScheme) private var colorScheme

    // Valores vigentes para detectar cambios en caliente desde Ajustes
    private let apiKey: String
    private let provider: AIProvider
    private let baseURL: String
    private let modelName: String

    // Spread actual para inyectar al contexto
    private let currentSpread: Spread?

    private let suggestions = [
        "¿Qué me dice El Loco?",
        "Necesito una lectura rápida",
        "¿Qué significa La Torre?",
        "Léeme para el amor",
        "¿Cómo interpreto cartas invertidas?",
        "Explícame el significado de La Luna"
    ]

    public init(apiKey: String, repository: any CardRepository,
                provider: AIProvider = .openAI, baseURL: String = "", modelName: String = "",
                currentSpread: Spread? = nil) {
        self.apiKey = apiKey
        self.provider = provider
        self.baseURL = baseURL
        self.modelName = modelName
        self.currentSpread = currentSpread
        _service = StateObject(wrappedValue: TarotAIChatService(
            apiKey: apiKey, provider: provider, baseURL: baseURL, modelName: modelName,
            repository: repository
        ))
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                Color.clear

                VStack(spacing: 0) {
                    messagesArea
                    if let spread = currentSpread, !spread.drawnCards.isEmpty {
                        spreadContextBar(spread: spread)
                    }
                    inputBar
                }
            }
            .navigationTitle("Arcana IA")
            .onChange(of: apiKey) { nueva in service.updateAPIKey(nueva) }
            .onChange(of: provider) { _ in
                service.updateProvider(provider, baseURL: baseURL, modelName: modelName, apiKey: apiKey)
            }
            .onChange(of: baseURL) { _ in
                service.updateProvider(provider, baseURL: baseURL, modelName: modelName, apiKey: apiKey)
            }
            .onChange(of: modelName) { _ in
                service.updateProvider(provider, baseURL: baseURL, modelName: modelName, apiKey: apiKey)
            }
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    colors: isShadowMode ? [Color.black, Color.purple] : [Color.tarotGold, Color.tarotGoldDeep],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                ))
                                .frame(width: 30, height: 30)
                            Image(systemName: isShadowMode ? "moon.stars.fill" : "sparkles")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.white)
                        }
                        .onTapGesture {
                            withAnimation(.spring()) {
                                isShadowMode.toggle()
                            }
                        }
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Arcana IA")
                                .font(.headline)
                                .foregroundStyle(Color.tarotIvory)
                            Text(service.isLoading ? "escribiendo..." : (isShadowMode ? "Sombra Activa · \(service.lastEngineName)" : "Lectora de Tarot · \(service.lastEngineName)"))
                                .font(.caption2)
                                .foregroundStyle(isShadowMode ? Color.purple : Color.tarotIvory.opacity(0.58))
                        }
                    }
                }
                #if os(iOS)
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showClearAlert = true } label: {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundStyle(Color.tarotIvory.opacity(0.58))
                    }
                    .disabled(service.messages.isEmpty)
                }
                #endif
            }
            .alert("Limpiar conversación", isPresented: $showClearAlert) {
                Button("Limpiar", role: .destructive) { service.clearHistory() }
                Button("Cancelar", role: .cancel) {}
            } message: {
                Text("¿Borrar todos los mensajes de esta sesión?")
            }
            .tarotNightBackground()
        }
    }

    // MARK: - Barra de contexto: tirada actual

    private func spreadContextBar(spread: Spread) -> some View {
        let cardNames = spread.drawnCards.map { "\($0.card.name)\($0.orientation == .reversed ? " (inv.)" : "")" }
        let preview = cardNames.prefix(3).joined(separator: " · ")
        let more = cardNames.count > 3 ? " +\(cardNames.count - 3)" : ""

        return Button {
            let ctx = "Tengo esta tirada: \(cardNames.joined(separator: ", ")). ¿Puedes interpretarla?"
            Task { await service.send(userMessage: ctx) }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "rectangle.stack")
                    .font(.system(size: 11, weight: .light))
                    .foregroundStyle(Color.tarotGold)
                Text("Tirada actual: \(preview)\(more)")
                    .font(.system(size: 11, design: .serif))
                    .foregroundStyle(Color.tarotIvory.opacity(0.75))
                    .lineLimit(1)
                Spacer(minLength: 0)
                Text("Interpretar →")
                    .font(.system(size: 10, weight: .semibold, design: .serif))
                    .foregroundStyle(Color.tarotGold)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color.tarotGold.opacity(0.08))
            .overlay(Rectangle().fill(Color.tarotGold.opacity(0.18)).frame(height: 0.5), alignment: .top)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Messages Area

    @ViewBuilder
    private var messagesArea: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    if service.messages.isEmpty { welcomeBanner }

                    ForEach(service.messages) { message in
                        if message.role != .system {
                            MessageBubble(message: message)
                                .id(message.id)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 4)
                        }
                    }

                    if service.isLoading {
                        TypingIndicator()
                            .padding(.horizontal, 14)
                            .padding(.top, 4)
                            .id("typing")
                    }

                    if let error = service.errorMessage {
                        ErrorBanner(message: error)
                            .padding(.horizontal, 14)
                            .padding(.top, 8)
                    }

                    Color.clear.frame(height: 12).id("bottom")
                }
                .padding(.top, 12)
            }
            #if os(iOS)
            .scrollDismissesKeyboard(.interactively)
            #endif
            .onChange(of: service.messages.count) { _ in
                withAnimation(.easeOut(duration: 0.3)) { proxy.scrollTo("bottom", anchor: .bottom) }
            }
            .onChange(of: service.isLoading) { loading in
                if loading { withAnimation(.easeOut(duration: 0.3)) { proxy.scrollTo("typing", anchor: .bottom) } }
            }
            .onChange(of: inputFocused) { focused in
                guard focused else { return }
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 280_000_000)
                    withAnimation(.easeOut(duration: 0.25)) { proxy.scrollTo("bottom", anchor: .bottom) }
                }
            }
        }
    }

    // MARK: - Welcome Banner

    private var welcomeBanner: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [Color.tarotGold.opacity(0.20), Color.tarotGoldDeep.opacity(0.15)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ))
                    .frame(width: 90, height: 90)
                Circle()
                    .stroke(Color.tarotGoldGradient, lineWidth: 1.5)
                    .frame(width: 90, height: 90)
                Image(systemName: "moon.stars")
                    .font(.system(size: 36, weight: .thin))
                    .foregroundStyle(Color.tarotGoldGradient)
            }
            .shadow(color: Color.tarotGold.opacity(0.40), radius: 20)

            VStack(spacing: 8) {
                Text("Arcana IA")
                    .font(.title2.bold())
                    .foregroundStyle(Color.tarotIvory)
                Text("Tu guía de tarot con inteligencia artificial.\nHaz preguntas sobre cartas, tiradas o pide una lectura.")
                    .font(.subheadline)
                    .foregroundStyle(Color.tarotIvory.opacity(0.58))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Suggestion chips
            VStack(alignment: .leading, spacing: 8) {
                Text("Prueba preguntando:")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.tarotIvory.opacity(0.58))
                    .padding(.leading, 4)

                FlowLayout(spacing: 8) {
                    ForEach(suggestions, id: \.self) { suggestion in
                        Button {
                            Task { await service.send(userMessage: suggestion) }
                        } label: {
                            Text(suggestion)
                                .font(.caption)
                                .foregroundStyle(Color.tarotGold)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(
                                    Capsule()
                                        .fill(Color.tarotGold.opacity(0.10))
                                        .overlay(Capsule().stroke(Color.tarotGold.opacity(0.30), lineWidth: 1))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.tarotPanel.opacity(0.70))
                    .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Color.tarotBorder, lineWidth: 1))
            )
        }
        .padding(24)
        .padding(.top, 12)
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        HStack(spacing: 10) {
            ZStack(alignment: .topLeading) {
                if inputText.isEmpty {
                    Text("Pregunta a Arcana...")
                        .font(.body)
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 11)
                        .allowsHitTesting(false)
                }
                TextEditor(text: $inputText)
                    .font(.body)
                    .foregroundStyle(Color.tarotIvory)
                    .frame(minHeight: 38, maxHeight: 120)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .focused($inputFocused)
            }
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color.white.opacity(0.06))
                    .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(.ultraThinMaterial).opacity(0.35))
                    .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(Color.tarotGold.opacity(inputText.isEmpty ? 0.14 : 0.32), lineWidth: 0.9))
            )

            Button { sendMessage() } label: {
                ZStack {
                    if inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || service.isLoading {
                        Circle().fill(Color.secondary.opacity(0.20)).frame(width: 40, height: 40)
                    } else {
                        Circle()
                            .fill(LinearGradient(colors: [Color.tarotGold, Color.tarotGoldDeep], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 40, height: 40)
                    }
                    Image(systemName: service.isLoading ? "ellipsis" : "arrow.up")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
            .buttonStyle(.plain)
            .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || service.isLoading)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .overlay(Rectangle().fill(Color.tarotBorder.opacity(0.5)).frame(height: 0.5), alignment: .top)
        #if os(iOS)
        .onTapGesture { inputFocused = true }
        #endif
    }

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !service.isLoading else { return }
        inputText = ""
        inputFocused = true

        var finalMessage = text
        if isShadowMode {
            finalMessage = "[MODO SOMBRA] \(text)"
        }

        Task { await service.send(userMessage: finalMessage) }
    }
}

// MARK: - Message Bubble

private struct MessageBubble: View {
    let message: ChatMessage
    private var isUser: Bool { message.role == .user }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isUser { Spacer(minLength: 50) }

            if !isUser {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [Color.tarotGold, Color.tarotGoldDeep], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 28, height: 28)
                    Image(systemName: "sparkles").font(.system(size: 12, weight: .bold)).foregroundStyle(.white)
                }
            }

            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                Text(LocalizedStringKey(message.content))
                    .font(.body)
                    .foregroundStyle(isUser ? Color.white : Color.primary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(bubbleBackground)
                    .shadow(color: .black.opacity(0.10), radius: 4, x: 0, y: 2)

                Text(message.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 4)
            }

            if !isUser { Spacer(minLength: 50) }
        }
    }

    @ViewBuilder
    private var bubbleBackground: some View {
        if isUser {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(LinearGradient(colors: [Color.tarotGold, Color.tarotGoldDeep], startPoint: .topLeading, endPoint: .bottomTrailing))
                .shadow(color: Color.tarotGold.opacity(0.18), radius: 8, x: 0, y: 4)
        } else {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(.ultraThinMaterial).opacity(0.38))
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color.tarotGold.opacity(0.14), lineWidth: 0.8))
                .shadow(color: Color.black.opacity(0.18), radius: 8, x: 0, y: 4)
        }
    }
}

// MARK: - Typing Indicator

private struct TypingIndicator: View {
    @State private var phase: Int = 0

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [Color.tarotGold, Color.tarotGoldDeep], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 28, height: 28)
                Image(systemName: "sparkles").font(.system(size: 12, weight: .bold)).foregroundStyle(.white)
            }

            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(Color.tarotGold)
                        .frame(width: 7, height: 7)
                        .scaleEffect(phase == i ? 1.3 : 0.8)
                        .opacity(phase == i ? 1.0 : 0.4)
                        .animation(.easeInOut(duration: 0.4).repeatForever().delay(Double(i) * 0.15), value: phase)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.tarotPanel.opacity(0.95))
                    .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color.tarotBorder.opacity(0.5), lineWidth: 1))
            )

            Spacer(minLength: 50)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.4).repeatForever()) { phase = 1 }
        }
    }
}

// MARK: - Error Banner

private struct ErrorBanner: View {
    let message: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Color.tarotBurgundy)
                .font(.caption)
            Text(message)
                .font(.caption)
                .foregroundStyle(Color.tarotBurgundy)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.tarotBurgundy.opacity(0.08))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.tarotBurgundy.opacity(0.25), lineWidth: 1))
        )
    }
}

// MARK: - FlowLayout (wrapping chip layout)

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        FlowResult(in: proposal.replacingUnspecifiedDimensions().width, subviews: subviews, spacing: spacing).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, frame) in result.frames.enumerated() {
            subviews[index].place(at: CGPoint(x: frame.minX + bounds.minX, y: frame.minY + bounds.minY), proposal: ProposedViewSize(frame.size))
        }
    }

    private struct FlowResult {
        var frames: [CGRect] = []
        var size: CGSize = .zero

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0; var y: CGFloat = 0; var rowHeight: CGFloat = 0
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                if x + size.width > maxWidth, x > 0 { y += rowHeight + spacing; x = 0; rowHeight = 0 }
                frames.append(CGRect(origin: CGPoint(x: x, y: y), size: size))
                x += size.width + spacing
                rowHeight = max(rowHeight, size.height)
            }
            self.size = CGSize(width: maxWidth, height: y + rowHeight)
        }
    }
}
