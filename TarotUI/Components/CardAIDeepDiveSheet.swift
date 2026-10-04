import SwiftUI
import TarotCore
import TarotData

/// Vista modal para profundizar en cualquier carta usando Arcana IA.
/// Permite generar análisis arquetípicos, cabalísticos, astrológicos y psicológicos al instante.
public struct CardAIDeepDiveSheet: View {
    let card: Card
    let orientation: CardOrientation
    let repository: any CardRepository
    @Environment(\.dismiss) private var dismiss
    @StateObject private var service: TarotAIChatService
    @State private var inputText = ""
    @FocusState private var inputFocused: Bool

    public init(card: Card, orientation: CardOrientation, repository: any CardRepository) {
        self.card = card
        self.orientation = orientation
        self.repository = repository

        let settings = UserDefaultsSettingsRepository().load()
        let apiKey = settings.aiApiKey.isEmpty ? settings.openAIKey : settings.aiApiKey
        _service = StateObject(wrappedValue: TarotAIChatService(
            apiKey: apiKey,
            provider: settings.aiProvider,
            baseURL: settings.aiBaseURL,
            modelName: settings.aiModelName,
            repository: repository
        ))
    }

    private var initialAnalysisPrompt: String {
        """
        Por favor realiza un análisis profundo e iluminador de la carta **\(card.name)** (\(orientation == .upright ? "al derecho" : "invertida")).
        Incluye:
        1. El misterio central y simbolismo visual clave.
        2. La dimensión psicológica y arquetípica en la vida del consultante.
        3. Su lección de sombra y camino de integración.
        Sé poética, precisa y reveladora.
        """
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 0) {
                    // Header de la carta
                    cardHeader
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.03))
                        .overlay(Rectangle().fill(Color.tarotGold.opacity(0.18)).frame(height: 0.5), alignment: .bottom)

                    // Área de conversación
                    ScrollViewReader { proxy in
                        ScrollView(.vertical, showsIndicators: false) {
                            LazyVStack(spacing: 14) {
                                if service.messages.isEmpty {
                                    promptSuggestionsView
                                } else {
                                    ForEach(service.messages) { msg in
                                        if msg.role != .system {
                                            messageBubble(msg)
                                                .id(msg.id)
                                        }
                                    }
                                }

                                if service.isLoading {
                                    HStack(spacing: 8) {
                                        ProgressView()
                                            .tint(Color.tarotGold)
                                        Text("Arcana está profundizando en los arcanos...")
                                            .font(.caption)
                                            .foregroundStyle(Color.tarotIvory.opacity(0.65))
                                    }
                                    .padding(12)
                                    .id("loading")
                                }

                                if let error = service.errorMessage {
                                    Text(error)
                                        .font(.caption)
                                        .foregroundStyle(Color.tarotBurgundy)
                                        .padding(10)
                                        .background(Capsule().fill(Color.tarotBurgundy.opacity(0.15)))
                                }

                                Color.clear.frame(height: 12).id("bottom")
                            }
                            .padding(16)
                        }
                        .onChange(of: service.messages.count) { _ in
                            withAnimation { proxy.scrollTo("bottom", anchor: .bottom) }
                        }
                    }

                    // Input bar
                    inputBar
                }
            }
            .tarotNightBackground()
            .navigationTitle("Profundizar con Arcana IA")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }
                        .foregroundStyle(Color.tarotIvory.opacity(0.7))
                }
            }
            .onAppear {
                if service.messages.isEmpty {
                    Task {
                        await service.send(userMessage: initialAnalysisPrompt)
                    }
                }
            }
        }
    }

    private var cardHeader: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [Color.tarotGold, Color.tarotGoldDeep], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 40, height: 40)
                Image(systemName: "sparkles")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(card.name)
                    .font(.system(size: 16, weight: .bold, design: .serif))
                    .foregroundStyle(Color.tarotIvory)
                HStack(spacing: 6) {
                    Text(orientation == .upright ? "Al derecho" : "Invertida")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(orientation == .upright ? Color.tarotGold : Color.tarotBurgundy)
                    if let ast = card.astrology, !ast.isEmpty {
                        Text("· \(ast)")
                            .font(.caption2)
                            .foregroundStyle(Color.tarotIvory.opacity(0.5))
                    }
                }
            }
            Spacer()
        }
    }

    private var promptSuggestionsView: some View {
        VStack(spacing: 10) {
            Text("Iniciando conexión arcana...")
                .font(.subheadline)
                .foregroundStyle(Color.tarotIvory.opacity(0.7))
        }
        .padding(.vertical, 40)
    }

    private func messageBubble(_ msg: ChatMessage) -> some View {
        HStack(alignment: .top, spacing: 8) {
            if msg.role == .assistant {
                Image(systemName: "sparkles")
                    .font(.caption)
                    .foregroundStyle(Color.tarotGold)
                    .padding(.top, 4)
            } else {
                Spacer(minLength: 40)
            }

            VStack(alignment: msg.role == .user ? .trailing : .leading, spacing: 4) {
                Text(LocalizedStringKey(msg.content))
                    .font(.system(size: 14, design: .serif))
                    .lineSpacing(4)
                    .foregroundStyle(msg.role == .user ? Color.white : Color.tarotIvory)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(msg.role == .user
                                  ? Color.tarotGold.opacity(0.25)
                                  : Color.white.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(msg.role == .user ? Color.tarotGold.opacity(0.5) : Color.tarotGold.opacity(0.12), lineWidth: 0.8)
                            )
                    )
            }

            if msg.role == .user {
                Image(systemName: "person.circle.fill")
                    .font(.caption)
                    .foregroundStyle(Color.tarotIvory.opacity(0.6))
                    .padding(.top, 4)
            } else {
                Spacer(minLength: 40)
            }
        }
    }

    private var inputBar: some View {
        HStack(spacing: 8) {
            TextField("Pregúntale a la IA sobre \(card.name)...", text: $inputText)
                .font(.system(size: 13, design: .serif))
                .foregroundStyle(Color.tarotIvory)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: 20).fill(Color.white.opacity(0.06)))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.tarotGold.opacity(0.25), lineWidth: 0.8))
                .focused($inputFocused)
                .onSubmit { submitMessage() }

            Button {
                submitMessage()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(inputText.trimmingCharacters(in: .whitespaces).isEmpty ? Color.tarotIvory.opacity(0.3) : Color.tarotGold)
            }
            .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty || service.isLoading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }

    private func submitMessage() {
        let t = inputText.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty, !service.isLoading else { return }
        inputText = ""
        Task {
            await service.send(userMessage: t)
        }
    }
}
