import SwiftUI
import TarotCore
import TarotData

struct ReferenceCardView: View {
    let card: Card
    let orientation: CardOrientation
    let repository: any CardRepository
    let activeDeck: DeckType
    let cardBackDesign: CardBackDesign

    init(card: Card, orientation: CardOrientation, repository: any CardRepository, activeDeck: DeckType = .riderWaite, cardBackDesign: CardBackDesign = .classic) {
        self.card = card
        self.orientation = orientation
        self.repository = repository
        self.activeDeck = activeDeck
        self.cardBackDesign = cardBackDesign
    }

    private var currentInterpretation: Interpretation {
        repository.interpretation(for: card, position: nil, orientation: orientation)
    }

    var body: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 14) {
                    CardFace(
                        name: card.name,
                        imageName: card.imageName,
                        textureName: card.textureImageName,
                        reversed: orientation == .reversed,
                        useTexture: true,
                        size: CGSize(width: 280, height: 420),
                        activeDeck: activeDeck,
                        backDesign: cardBackDesign
                    )
                    .frame(maxWidth: .infinity, minHeight: 260)
                    .shadow(color: .black.opacity(0.45), radius: 24, x: 0, y: 14)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(card.name).font(.title).bold()
                        HStack(spacing: 10) {
                            Text(card.suit?.displayName ?? (card.arcanaType == .major ? "Arcano Mayor" : "Arcano Menor"))
                                .font(.subheadline)
                                .foregroundStyle(Color.tarotIvory.opacity(0.58))
                            Text(card.arcanaType == .major ? "Mayor" : "Menor")
                                .font(.caption2.weight(.semibold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(card.arcanaType == .major ? Color.tarotGold.opacity(0.18) : Color.tarotBurgundy.opacity(0.14)))
                                .foregroundStyle(card.arcanaType == .major ? Color.tarotGold : Color.tarotBurgundy)
                        }
                    }
                    .padding(.horizontal, 4)
                }
                .padding()
                .background(Color.tarotPanel.opacity(0.96))
                .cornerRadius(24)
                .shadow(color: Color.tarotShadow.opacity(0.35), radius: 15, x: 0, y: 8)

                // Book content from OCR (Fiebig & Bürger)
                if let bookContent = card.bookContent, !bookContent.isEmpty {
                    BookContentBlock(text: bookContent)
                }

                BookInfoGrid(card: card, interpretation: currentInterpretation)
                BookHighlightsView(interpretation: currentInterpretation)
                CardBookSection(title: orientation == .upright ? "Al derecho" : "Invertida", interpretation: currentInterpretation)

                // Esoteric detail panel with 8 collapsible sections
                EsotericReferencePanel(card: card, interpretation: currentInterpretation)

                if !currentInterpretation.keywords.isEmpty {
                    Divider()
                    Text("Palabras clave relevantes").font(.headline)
                    Text(currentInterpretation.keywords.joined(separator: " · "))
                        .font(.caption)
                        .foregroundStyle(Color.tarotIvory.opacity(0.58))
                }

                Spacer(minLength: 28)
            }
            .padding()
        }
        .navigationTitle(card.name)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

private struct BookInfoGrid: View {
    let card: Card
    let interpretation: Interpretation
    private let highlightedKeys = ["Amor", "Economía", "Salud", "Carrera"]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Palo", systemImage: "suit.club.fill")
                Spacer()
                Text(card.suit?.displayName ?? "Arcano Mayor")
                    .font(.caption)
                    .foregroundStyle(Color.tarotIvory.opacity(0.58))
            }
            HStack {
                Label("Número", systemImage: "number")
                Spacer()
                Text(card.number ?? "—")
                    .font(.caption)
                    .foregroundStyle(Color.tarotIvory.opacity(0.58))
            }
            HStack {
                Label("Origen", systemImage: "book.fill")
                Spacer()
                Text("Rider-Waite")
                    .font(.caption)
                    .foregroundStyle(Color.tarotIvory.opacity(0.58))
            }
            HStack {
                Label("Ilustración", systemImage: "photo.on.rectangle.angled")
                Spacer()
                Text("Original Rider-Waite")
                    .font(.caption)
                    .foregroundStyle(Color.tarotIvory.opacity(0.58))
            }

            // Encyclopedic Data
            if card.astrology != nil || card.kabbalah != nil || card.element != nil || card.yesNo != nil || card.chakras != nil {
                Divider()
                Text("Simbología y Correspondencias").font(.subheadline).bold()

                if let element = card.element {
                    HStack {
                        Text("Elemento:").bold().font(.caption)
                        Spacer()
                        Text(element).font(.caption).foregroundStyle(Color.tarotIvory.opacity(0.58))
                    }
                }

                if let astrology = card.astrology {
                    HStack {
                        Text("Astrología:").bold().font(.caption)
                        Spacer()
                        Text(astrology).font(.caption).foregroundStyle(Color.tarotIvory.opacity(0.58))
                    }
                }

                if let numerology = card.numerology {
                    HStack {
                        Text("Numerología:").bold().font(.caption)
                        Spacer()
                        Text(numerology).font(.caption).foregroundStyle(Color.tarotIvory.opacity(0.58))
                    }
                }

                if let kabbalah = card.kabbalah {
                    HStack(alignment: .top) {
                        Text("Cábala:").bold().font(.caption)
                        Spacer()
                        Text(kabbalah).font(.caption).foregroundStyle(Color.tarotIvory.opacity(0.58))
                            .multilineTextAlignment(.trailing)
                    }
                }

                if let lightShadow = card.lightShadow {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Luz y Sombra:").bold().font(.caption)
                        Text(lightShadow).font(.caption).foregroundStyle(Color.tarotIvory.opacity(0.58))
                    }
                }

                if let yesNo = card.yesNo {
                    HStack(alignment: .top) {
                        Text("Respuesta (Sí/No):").bold().font(.caption)
                        Spacer()
                        Text(yesNo).font(.caption).foregroundStyle(Color.tarotIvory.opacity(0.58))
                    }
                }

                if let chakras = card.chakras {
                    HStack(alignment: .top) {
                        Text("Chakras:").bold().font(.caption)
                        Spacer()
                        Text(chakras).font(.caption).foregroundStyle(Color.tarotIvory.opacity(0.58))
                    }
                }

                if let crystals = card.crystals {
                    HStack(alignment: .top) {
                        Text("Cristales:").bold().font(.caption)
                        Spacer()
                        Text(crystals).font(.caption).foregroundStyle(Color.tarotIvory.opacity(0.58))
                    }
                }

                if let mythology = card.mythology {
                    HStack(alignment: .top) {
                        Text("Mitología:").bold().font(.caption)
                        Spacer()
                        Text(mythology).font(.caption).foregroundStyle(Color.tarotIvory.opacity(0.58))
                    }
                }

                if let decan = card.zodiacalDecan {
                    HStack(alignment: .top) {
                        Text("Decanato:").bold().font(.caption)
                        Spacer()
                        Text(decan).font(.caption).foregroundStyle(Color.tarotIvory.opacity(0.58))
                    }
                }

                if let affirmation = card.affirmation {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Afirmación:").bold().font(.caption)
                        Text(affirmation).font(.caption).italic().foregroundStyle(Color.tarotIvory.opacity(0.58))
                    }
                }
            }

            if !interpretation.aspects.isEmpty {
                Divider()
                Text("Aspectos clave").font(.subheadline).bold()
                ForEach(highlightedKeys.filter { interpretation.aspects[$0] != nil }, id: \.self) { aspect in
                    if let value = interpretation.aspects[aspect] {
                        HStack(alignment: .top, spacing: 4) {
                            Text(aspect + ":").bold().font(.caption)
                            Text(value).font(.caption).foregroundStyle(Color.tarotIvory.opacity(0.58))
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.tarotPanel.opacity(0.90))
        .cornerRadius(16)
    }
}

private struct BookHighlightsView: View {
    let interpretation: Interpretation

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Consulta rápida").font(.headline)
            Text("Explora los elementos más importantes en Amor, Economía, Salud y Carrera sin perder de vista el mensaje completo del libro Rider.")
                .font(.subheadline)
                .foregroundStyle(Color.tarotIvory.opacity(0.58))
                .fixedSize(horizontal: false, vertical: true)

            if !interpretation.keywords.isEmpty {
                HStack(alignment: .top) {
                    Text("Palabras clave:").bold().font(.caption)
                    Text(interpretation.keywords.joined(separator: " · ")).font(.caption).foregroundStyle(Color.tarotIvory.opacity(0.58))
                }
            }

            if !interpretation.aspects.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(interpretation.aspects.keys).sorted(), id: \.self) { aspect in
                        if let value = interpretation.aspects[aspect] {
                            HStack(alignment: .top, spacing: 8) {
                                Text(aspect).bold().font(.caption)
                                Text(value).font(.caption).foregroundStyle(Color.tarotIvory.opacity(0.58))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.tarotPanel.opacity(0.88))
        .cornerRadius(16)
    }
}

private struct CardBookSection: View {
    let title: String
    let interpretation: Interpretation

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: title == "Al derecho" ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                .font(.headline)
                .foregroundStyle(title == "Al derecho" ? Color(red: 0.20, green: 0.46, blue: 0.28) : Color.tarotBurgundy)

            Text(interpretation.summary)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(6)

            if !interpretation.aspects.isEmpty {
                SectionHeader(title: "Aspectos")
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(interpretation.aspects.sorted(by: { $0.key < $1.key }), id: \.key) { aspect, value in
                        VStack(alignment: .leading, spacing: 5) {
                            Text(aspect).bold()
                            Text(value).font(.subheadline).foregroundStyle(Color.tarotIvory.opacity(0.58))
                        }
                        .padding(10)
                        .background(Color.tarotPanel.opacity(0.96))
                        .cornerRadius(14)
                        .shadow(color: Color.tarotShadow.opacity(0.18), radius: 6, x: 0, y: 3)
                    }
                }
            }

            if !interpretation.contextual.isEmpty {
                SectionHeader(title: "Detalles por posición")
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(interpretation.contextual.sorted(by: { $0.key.displayName < $1.key.displayName }), id: \.key) { position, value in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(position.displayName).bold()
                            Text(value).font(.body).foregroundStyle(Color.tarotIvory.opacity(0.58))
                        }
                        .padding(12)
                        .background(Color.tarotPanel.opacity(0.96))
                        .cornerRadius(14)
                        .shadow(color: Color.tarotShadow.opacity(0.18), radius: 6, x: 0, y: 3)
                    }
                }
            }
        }
        .padding()
        .background(Color.tarotPanel.opacity(0.12))
        .cornerRadius(24)
    }
}

private struct SectionHeader: View {
    let title: String

    var body: some View {
        HStack {
            Text(title).font(.subheadline).bold()
            Spacer()
        }
        .padding(.bottom, 4)
    }
}

private struct EsotericReferencePanel: View {
    let card: Card
    let interpretation: Interpretation

    @State private var expanded: [Bool] = Array(repeating: false, count: 8)

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Ficha Esotérica").font(.headline)
            VStack(spacing: 6) {
                disclosure(0, title: "Descripción clásica", content: card.bookContent ?? interpretation.summary)
                disclosure(1, title: "Letra Hebrea", content: card.kabbalah ?? "—")
                disclosure(2, title: "Sendero del Árbol de la Vida", content: card.numerology ?? card.kabbalah ?? "No disponible")
                disclosure(3, title: "Astrología", content: astrologyText())
                disclosure(4, title: "Principio Alquímico", content: card.element ?? card.numerology ?? "—")
                disclosure(5, title: "Chakra Asociado", content: card.chakras ?? "—")
                disclosure(6, title: "◈ Respuesta Sí / No / Tal vez", content: card.yesNo ?? "—")
                disclosure(7, title: "Meditación + Afirmación", content: meditationText())
            }
            .padding()
            .background(Color.tarotPanel.opacity(0.92))
            .cornerRadius(14)
        }
        .padding(.top)
    }

    private func disclosure(_ idx: Int, title: String, content: String) -> some View {
        DisclosureGroup(isExpanded: Binding(get: { expanded[idx] }, set: { expanded[idx] = $0 })) {
            Text(content)
                .font(.subheadline)
                .foregroundStyle(Color.tarotIvory.opacity(0.58))
                .padding(.top, 6)
                .fixedSize(horizontal: false, vertical: true)
        } label: {
            HStack {
                Text(title).bold().font(.subheadline)
                Spacer()
            }
        }
        .accentColor(Color.tarotGold)
        .padding(.vertical, 6)
    }

    private func astrologyText() -> String {
        var parts: [String] = []
        if let astro = card.astrology { parts.append("Signo: \(astro)") }
        if let decan = card.zodiacalDecan { parts.append("Decanato: \(decan)") }
        return parts.isEmpty ? "—" : parts.joined(separator: " · ")
    }

    private func meditationText() -> String {
        var s = ""
        if let a = card.affirmation { s += "Afirmación: " + a }
        else if let ls = card.lightShadow { s += ls }
        if s.isEmpty { s = "—" }
        return s
    }
}
