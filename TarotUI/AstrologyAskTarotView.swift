import SwiftUI
import TarotCore
import TarotContent
import TarotDI

// MARK: - Zodiac Signs

public enum ZodiacSign: String, CaseIterable, Identifiable {
    case aries = "Aries"
    case taurus = "Tauro"
    case gemini = "Géminis"
    case cancer = "Cáncer"
    case leo = "Leo"
    case virgo = "Virgo"
    case libra = "Libra"
    case scorpio = "Escorpio"
    case sagittarius = "Sagitario"
    case capricorn = "Capricornio"
    case aquarius = "Acuario"
    case pisces = "Piscis"

    public var id: String { rawValue }

    public var symbol: String {
        switch self {
        case .aries: return "♈︎"
        case .taurus: return "♉︎"
        case .gemini: return "♊︎"
        case .cancer: return "♋︎"
        case .leo: return "♌︎"
        case .virgo: return "♍︎"
        case .libra: return "♎︎"
        case .scorpio: return "♏︎"
        case .sagittarius: return "♐︎"
        case .capricorn: return "♑︎"
        case .aquarius: return "♒︎"
        case .pisces: return "♓︎"
        }
    }

    public var element: String {
        switch self {
        case .aries, .leo, .sagittarius: return "Fuego"
        case .taurus, .virgo, .capricorn: return "Tierra"
        case .gemini, .libra, .aquarius: return "Aire"
        case .cancer, .scorpio, .pisces: return "Agua"
        }
    }

    public var dates: String {
        switch self {
        case .aries: return "21 Mar - 19 Abr"
        case .taurus: return "20 Abr - 20 May"
        case .gemini: return "21 May - 20 Jun"
        case .cancer: return "21 Jun - 22 Jul"
        case .leo: return "23 Jul - 22 Ago"
        case .virgo: return "23 Ago - 22 Sep"
        case .libra: return "23 Sep - 22 Oct"
        case .scorpio: return "23 Oct - 21 Nov"
        case .sagittarius: return "22 Nov - 21 Dic"
        case .capricorn: return "22 Dic - 19 Ene"
        case .aquarius: return "20 Ene - 18 Feb"
        case .pisces: return "19 Feb - 20 Mar"
        }
    }

    public var dailyHoroscope: String {
        switch self {
        case .aries:
            return "Hoy la energía del Fuego impulsa tu intuición. Es un excelente momento para iniciar proyectos con liderazgo. El Tarot te invita a actuar con valentía sin descuidar los detalles."
        case .taurus:
            return "La estabilidad de la Tierra te brinda paciencia. El universo sugiere consolidar tus finanzas y buscar paz en tus relaciones. Una carta de Oros rige tu jornada."
        case .gemini:
            return "Tu mente brilla con creatividad y comunicación fluida. Las cartas sugieren tomar decisiones importantes con claridad y honestidad interior."
        case .cancer:
            return "Momento de reconectar con tu mundo emocional y tu familia. Las cartas de Copas indican bendiciones afectivas e intuición elevada hoy."
        case .leo:
            return "Tu magnetismo personal está al máximo. Confía en tu fuerza y brilla sin temor. La rueda del destino gira a tu favor en temas de proyectos."
        case .virgo:
            return "Día ideal para organizar tu espacio y tus pensamientos. El orden te traerá serenidad. El Tarot promete respuestas claras a lo que dudas."
        case .libra:
            return "La armonía y el equilibrio guían tu día. Es un momento propicio para solucionar desacuerdos y rodearte de arte y belleza."
        case .scorpio:
            return "Transformación profunda e intuición aguda. Revelaciones importantes en temas personales. Confía en tu poder de regeneración."
        case .sagittarius:
            return "Expansión, optimismo y deseos de explorar nuevos horizontes. La energía del Tarot favorece viajes, estudios y decisiones valientes."
        case .capricorn:
            return "Tu disciplina da frutos sólidos. Mantén tu enfoque en tus metas a largo plazo. La perseverancia te coronará con éxito."
        case .aquarius:
            return "Ideas innovadoras y visión de futuro. Un encuentro o reflexión inesperada te abrirá nuevas perspectivas en tu camino."
        case .pisces:
            return "Sensibilidad y conexión espiritual amplificadas. Escucha tus sueños e corazonadas hoy; traen mensajes valiosos de guía."
        }
    }
}

// MARK: - Daily (date-based) horoscope

extension ZodiacSign {
    /// Deterministic daily horoscope that changes with the date (updates every day).
    func dailyHoroscopeText(for date: Date) -> String {
        let cal = Calendar.current
        let dayOfYear = cal.ordinality(of: .day, in: .year, for: date) ?? 0
        let seed = abs(dayOfYear + (cal.component(.year, from: date) * 37)) % 5

        let fortunes = [
            "Hoy brilla una energía propicia para avanzar con seguridad.",
            "El universo alinea la suerte a tu favor: actúa con confianza.",
            "Un día de claridad te pide tomar decisiones importantes.",
            "Cuida tu paz interior; los frutos llegan con serenidad.",
            "Una oportunidad inesperada llama a tu puerta hoy."
        ]
        let lucky = [3, 7, 11, 13, 21, 33]
        let numbers = [lucky[seed], lucky[(seed + 1) % 6], lucky[(seed + 2) % 6]]
        let cards = ["El Sol", "La Estrella", "La Rueda de la Fortuna", "El Mundo", "La Luna"]
        let card = cards[seed]

        return dailyHoroscope
            + "\n\n"
            + fortunes[seed]
            + "\n◈ Carta guía: \(card)"
            + "\n✦ Números de la suerte: \(numbers.map(String.init).joined(separator: " · "))"
    }

    func dateString(for date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "es_ES")
        f.dateFormat = "EEEE d 'de' MMMM"
        return f.string(from: date).capitalized(with: f.locale)
    }
}


// MARK: - Ask Tarot View (Pregunta al Tarot)

public struct AskTarotView: View {
    let repository: any CardRepository
    @State private var question: String = ""
    @State private var selectedTopic: String = "General"
    @State private var drawnCard: Card? = nil
    @State private var isRevealed: Bool = false
    @State private var isShuffling: Bool = false
    @State private var cardShuffleAngle: Double = 0

    private let topics = ["General", "Amor", "Trabajo", "Dinero", "Decisión Sí/No"]

    public init(repository: any CardRepository) {
        self.repository = repository
    }

    public var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    headerCard
                    topicSelector
                    questionInput
                    drawButton
                    if isShuffling {
                        shufflingView
                    }
                    if let card = drawnCard {
                        answerView(for: card)
                    }
                }
                .padding(20)
            }
            .background(StarfieldBackgroundView(starCount: 90))
             .navigationTitle("Pregunta al Tarot")
             #if os(iOS)
             .navigationBarTitleDisplayMode(.inline)
             #endif
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .foregroundStyle(Color.tarotGold)
                Text("CONSULTA AL ORÁCULO")
                    .font(.system(size: 11, weight: .bold, design: .serif))
                    .tracking(2.4)
                    .foregroundStyle(Color.tarotGold)
            }
            Text("Pregunta al Tarot")
                .font(.system(size: 28, weight: .bold, design: .serif))
                .tracking(-0.4)
                .foregroundStyle(Color.tarotIvory)

            Text("Escribe cualquier pregunta personal o inquietud y consulta las cartas para recibir una respuesta orientadora personalizada.")
                .font(.system(size: 14, design: .serif))
                .foregroundStyle(Color.tarotIvory.opacity(0.68))
                .lineSpacing(5)
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .luxuryGlass(cornerRadius: 26)
    }

    private var topicSelector: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Tema de tu consulta")
                .font(.system(size: 13, weight: .semibold, design: .serif))
                .tracking(0.2)
                .foregroundStyle(Color.tarotGold)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(topics, id: \.self) { t in
                        topicChip(t)
                    }
                }
            }
        }
    }

    private func topicChip(_ topic: String) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTopic = topic
            }
        } label: {
            Text(topic)
                .font(.system(size: 13, weight: .semibold, design: .serif))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(selectedTopic == topic
                            ? AnyShapeStyle(Color.tarotGold.opacity(0.22))
                            : AnyShapeStyle(Color.tarotPanel.opacity(0.9))
                        )
                )
                .overlay(
                    Capsule().stroke(selectedTopic == topic ? Color.tarotGold.opacity(0.55) : Color.tarotGold.opacity(0.25), lineWidth: 0.75)
                )
                .foregroundStyle(selectedTopic == topic ? Color.tarotGold : Color.tarotIvory)
                .shadow(color: selectedTopic == topic ? Color.tarotGold.opacity(0.35) : Color.clear, radius: 8)
        }
        .buttonStyle(.plain)
    }

    private var questionInput: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Tu Pregunta")
                .font(.system(size: 15, weight: .bold, design: .serif))
                .tracking(0.1)
                .foregroundStyle(Color.tarotIvory)

            TextField("Ej: ¿Cómo debo actuar en mi trabajo esta semana?", text: $question)
                .font(.system(size: 15, design: .serif))
                .foregroundStyle(Color.tarotIvory)
                .padding(16)
                .background(Color.tarotPanel.opacity(0.95))
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.tarotGold.opacity(0.35), lineWidth: 0.75)
                )
        }
    }

    private var drawButton: some View {
        Button {
            guard !question.trimmingCharacters(in: .whitespaces).isEmpty else { return }
            TarotAudioService.shared.triggerHaptic(.medium)
            isShuffling = true
            drawnCard = nil
            isRevealed = false

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                let all = repository.allCards()
                drawnCard = all.randomElement()
                isShuffling = false
                TarotAudioService.shared.playGoldenChime()
                withAnimation(.spring(response: 0.55, dampingFraction: 0.6)) {
                    isRevealed = true
                }
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: isShuffling ? "sparkles" : "hand.tap")
                Text(isShuffling ? "Consultando al Oráculo…" : "Consultar Tarot")
                    .font(.system(size: 16, weight: .bold, design: .serif))
                    .tracking(0.2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.white.opacity(0.07))
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .opacity(0.5)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.tarotGold.opacity(0.35), lineWidth: 0.75)
            )
            .foregroundStyle(Color.tarotGold)
            .shadow(color: Color.tarotGold.opacity(0.25), radius: 12)
            .opacity(question.isEmpty || isShuffling ? 0.45 : 1.0)
        }
        .disabled(question.isEmpty || isShuffling)
    }

    private var shufflingView: some View {
        VStack(spacing: 16) {
            ZStack {
                ForEach(0..<3, id: \.self) { i in
                    CardFace(name: "Carta", imageName: nil, textureName: nil, reversed: false, back: true, size: CGSize(width: 110, height: 165))
                        .rotationEffect(.degrees(Double(i) * 24 + cardShuffleAngle))
                        .offset(x: CGFloat(i - 1) * 26, y: 6)
                }
            }
            .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: cardShuffleAngle)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                    cardShuffleAngle = 12
                }
            }
            Text("Barajando las cartas...")
                .font(.system(size: 14, weight: .medium, design: .serif))
                .foregroundStyle(Color.tarotGold.opacity(0.88))
        }
        .transition(.opacity)
    }

    private func answerView(for card: Card) -> some View {
        VStack(spacing: 20) {
            answerHeader
            ZStack {
                Circle()
                    .fill(Color.tarotGold.opacity(0.18))
                    .frame(width: 160, height: 160)
                    .blur(radius: 16)

                CardFace(name: card.name, imageName: card.imageName, textureName: card.textureImageName, reversed: false, useTexture: true, size: CGSize(width: 150, height: 225))
                    .shadow(color: Color.tarotGold.opacity(0.5), radius: 18, x: 0, y: 8)
            }

            Text(card.name)
                .font(.system(size: 22, weight: .bold, design: .serif))
                .foregroundStyle(Color.tarotIvory)

            answerSummary(for: card)
        }
        .padding(22)
        .luxuryGlass(cornerRadius: 26)
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }

    private var answerHeader: some View {
        HStack(spacing: 6) {
            Image(systemName: "star")
                .font(.caption2)
                .foregroundStyle(Color.tarotGold)
            Text("RESPUESTA DEL TAROT")
                .font(.system(size: 12, weight: .bold, design: .serif))
                .tracking(2.4)
                .foregroundStyle(Color.tarotGold)
            Image(systemName: "star")
                .font(.caption2)
                .foregroundStyle(Color.tarotGold)
        }
    }

    private func answerSummary(for card: Card) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "quote.opening")
                    .font(.caption)
                    .foregroundStyle(Color.tarotGold)
                Text(question)
                    .font(.system(size: 14, weight: .medium, design: .serif).italic())
                    .foregroundStyle(Color.tarotGold)
            }

            Divider().overlay(Color.tarotGold.opacity(0.3))

            Text(repository.interpretation(for: card, position: nil, orientation: .upright).summary)
                .font(.system(size: 15, design: .serif))
                .lineSpacing(7)
                .foregroundStyle(Color.tarotIvory.opacity(0.92))

            if selectedTopic == "Decisión Sí/No" {
                HStack(spacing: 8) {
                    Text("Veredicto:")
                        .font(.system(size: 14, weight: .bold, design: .serif))
                        .foregroundStyle(Color.tarotIvory)
                    Text(card.arcanaType == .major ? "✦ SÍ (Muy Favorable)" : "◇ Depende de tu voluntad")
                        .font(.system(size: 14, weight: .semibold, design: .serif))
                        .foregroundStyle(Color.tarotGold)
                }
                .padding(.top, 4)
            }
        }
        .padding(20)
        .background(Color.tarotPanel.opacity(0.92))
        .cornerRadius(22)
    }
}

// MARK: - Horoscopes View (Horóscopo Diario por Signo)

public struct HoroscopeView: View {
    @EnvironmentObject var container: AppContainer
    @State private var selectedSign: ZodiacSign = .aries
    @State private var today: Date = Date()
    let repository: any CardRepository

    public init(repository: any CardRepository) {
        self.repository = repository
    }

    // MARK: - Background Layer (morado lujo)
    private var backgroundLayer: some View {
        StarfieldBackgroundView(starCount: 90)
    }

    public var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {

                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .foregroundStyle(Color.tarotGold)
                         Text("ZODÍACO & TAROT")
                            .font(.system(size: 11, weight: .bold, design: .serif))
                            .tracking(2.4)
                            .foregroundStyle(Color.tarotGold)
                        }
                        Text("Horóscopo Astrológico")
                            .font(.system(size: 28, weight: .bold, design: .serif))
                            .tracking(-0.4)
                            .foregroundStyle(Color.tarotIvory)

                        Text("Selecciona tu signo para consultar tu lectura astral y la energía de las cartas que rigen tu jornada.")
                            .font(.system(size: 14, design: .serif))
                            .foregroundStyle(Color.tarotIvory.opacity(0.68))
                            .lineSpacing(5)
                    }
                    .padding(22)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .luxuryGlass(cornerRadius: 26)

                    // Zodiac Grid Selector
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                             ForEach(ZodiacSign.allCases) { sign in
                                 Button {
                                     withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                         selectedSign = sign
                                     }
                                 } label: {
                                     VStack(spacing: 6) {
                                         Text(sign.symbol)
                                             .font(.system(size: 32))
                                         Text(sign.rawValue)
                                             .font(.system(size: 12, weight: .semibold, design: .serif))
                                             .foregroundStyle(Color.tarotIvory)
                                     }
                                     .padding(.horizontal, 16)
                                     .padding(.vertical, 12)
                                     .background(
                                         RoundedRectangle(cornerRadius: 20, style: .continuous)
                                             .fill(selectedSign == sign
                                                 ? Color.tarotGold.opacity(0.24)
                                                 : Color.tarotPanel.opacity(0.90)
                                             )
                                     )
                                     .overlay(
                                         RoundedRectangle(cornerRadius: 20, style: .continuous)
                                             .stroke(selectedSign == sign ? Color.tarotGold : Color.tarotGold.opacity(0.15), lineWidth: selectedSign == sign ? 1.2 : 0.75)
                                     )
                                     .foregroundStyle(selectedSign == sign ? Color.tarotGold : Color.tarotIvory)
                                     .shadow(color: selectedSign == sign ? Color.tarotGold.opacity(0.3) : Color.clear, radius: 8)
                                 }
                                 .buttonStyle(.plain)
                             }
                        }
                        .padding(.horizontal, 4)
                    }

                    // Sign Detail Card
                    VStack(alignment: .leading, spacing: 16) {
                         HStack {
                            HStack(spacing: 10) {
                                Text(selectedSign.symbol)
                                    .font(.system(size: 36))
                                    .foregroundStyle(Color.tarotGold)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(selectedSign.rawValue)
                                        .font(.system(size: 24, weight: .bold, design: .serif))
                                        .foregroundStyle(Color.tarotIvory)
                                    Text(selectedSign.dates)
                                        .font(.system(size: 12, design: .serif))
                                        .foregroundStyle(Color.tarotIvory.opacity(0.56))
                                }
                            }
                            Spacer()
                            Text("Elemento: \(selectedSign.element)")
                                .font(.system(size: 12, weight: .bold, design: .serif))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Capsule().fill(Color.tarotGold.opacity(0.2)))
                                .foregroundStyle(Color.tarotGold)
                        }

                            Rectangle()
                                .fill(LinearGradient(colors: [Color.tarotGold.opacity(0.05), Color.tarotGold.opacity(0.4), Color.tarotGold.opacity(0.05)], startPoint: .leading, endPoint: .trailing))
                                .frame(height: 0.75)

                            Text("Lectura de Hoy · \(selectedSign.dateString(for: today))")
                                .font(.system(size: 15, weight: .bold, design: .serif))
                                .tracking(0.1)
                                .foregroundStyle(Color.tarotGold)

                            Text(selectedSign.dailyHoroscopeText(for: today))
                                .font(.system(size: 15, design: .serif))
                                .lineSpacing(8)
                                .foregroundStyle(Color.tarotIvory.opacity(0.92))
                    }
                    .padding(24)
                    .luxuryGlass(cornerRadius: 26)
                }
                .padding(20)
            }
            .background(backgroundLayer)
             .navigationTitle("Horóscopo")
             #if os(iOS)
             .navigationBarTitleDisplayMode(.inline)
             #endif
             .toolbar {
                 ToolbarItem(placement: .automatic) {
                     Button {
                         withAnimation { today = Date() }
                     } label: {
                         Label("Actualizar", systemImage: "arrow.clockwise")
                     }
                     .help("Actualizar lectura de hoy")
                 }
             }
        }
    }
}
