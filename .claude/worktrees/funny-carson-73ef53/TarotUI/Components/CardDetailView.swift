import SwiftUI
import TarotCore
import TarotData

struct CardDetailView: View {
    let card: Card
    let repository: any CardRepository
    let activeDeck: DeckType
    let cardBackDesign: CardBackDesign
    @State private var orientation: CardOrientation

    private var currentInterpretation: Interpretation {
        repository.interpretation(for: card, position: nil, orientation: orientation)
    }

    private let orderedAspectKeys = ["Amor", "Economía", "Salud", "Carrera"]

    init(drawn: DrawnCard, repository: any CardRepository, activeDeck: DeckType = .riderWaite, cardBackDesign: CardBackDesign = .classic) {
        self.card = drawn.card
        self.repository = repository
        self.activeDeck = activeDeck
        self.cardBackDesign = cardBackDesign
        _orientation = State(initialValue: drawn.orientation)
    }

    init(card: Card, orientation: CardOrientation, repository: any CardRepository, activeDeck: DeckType = .riderWaite, cardBackDesign: CardBackDesign = .classic) {
        self.card = card
        self.repository = repository
        self.activeDeck = activeDeck
        self.cardBackDesign = cardBackDesign
        _orientation = State(initialValue: orientation)
    }

    var body: some View {
        ScrollView(Axis.Set.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {

                // Card image hero + orientation selector
                ZStack(alignment: .bottom) {
                    CardFace(name: card.name, imageName: card.imageName, textureName: card.textureImageName, reversed: orientation == .reversed, useTexture: true, size: CGSize(width: 260, height: 390), activeDeck: activeDeck, backDesign: cardBackDesign)
                        .frame(maxWidth: .infinity)
                        .shadow(color: .black.opacity(0.45), radius: 24, x: 0, y: 14)

                    // Orientation badge
                    HStack(spacing: 6) {
                        Image(systemName: orientation == .upright ? "arrow.up.circle" : "arrow.down.circle")
                            .foregroundStyle(orientation == .upright ? Color.tarotGold : Color.tarotBurgundy)
                        Text(orientation == .upright ? "Al derecho" : "Invertida")
                            .font(.caption.weight(.semibold))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(.ultraThinMaterial, in: Capsule())
                    .offset(y: 18)
                }
                .padding(.bottom, 24)

                // Card title & metadata
                VStack(alignment: .leading, spacing: 6) {
                    Text(card.name)
                        .font(.title.bold())
                    HStack(spacing: 10) {
                        if let number = card.number, !number.isEmpty {
                            Text(number)
                                .font(.subheadline)
                                .foregroundStyle(Color.tarotIvory.opacity(0.58))
                        }
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

                // Orientation toggle
                Picker("Orientación", selection: $orientation) {
                    Text("Al derecho").tag(CardOrientation.upright)
                    Text("Invertida").tag(CardOrientation.reversed)
                }
                .pickerStyle(.segmented)

// Quick aspects summary
                if !currentInterpretation.aspects.isEmpty {
                    CardAspectSummaryView(interpretation: currentInterpretation)
                }

                // Esoteric wisdom panel (unified card info)
                CardWisdomView(card: card)

                // Book content from OCR (Fiebig & Bürger)
                if let bookContent = card.bookContent, !bookContent.isEmpty {
                    BookContentBlock(text: bookContent)
                }

                // Full interpretation section
                CardInterpretationSection(
                    title: orientation == .upright ? "Al derecho" : "Invertida",
                    orientation: orientation,
                    interpretation: currentInterpretation,
                    orderedAspectKeys: orderedAspectKeys
                )

                // Link to Reference view for deeper study
                NavigationLink {
                    ReferenceCardView(card: card, orientation: orientation, repository: repository)
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.tarotGold.opacity(0.12))
                                .frame(width: 44, height: 44)
                            Image(systemName: "book")
                                .font(.title3)
                                .foregroundStyle(Color.tarotGold)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Explorar en el Libro Rider")
                                .font(.headline)
                                .foregroundStyle(Color.tarotIvory)
                            Text("Vista completa con símbolos, aspectos y contexto por posición")
                                .font(.caption)
                                .foregroundStyle(Color.tarotIvory.opacity(0.58))
                        }
                        Spacer()
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(LinearGradient(
                                colors: [Color.tarotGold.opacity(0.10), Color.tarotBurgundy.opacity(0.08)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.tarotGold.opacity(0.30), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
            .padding()
        }
        .navigationTitle(card.name)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    private func aspectKeys(in interpretation: Interpretation) -> [String] {
        let knownKeys = orderedAspectKeys.filter { interpretation.aspects.keys.contains($0) }
        let extraKeys = interpretation.aspects.keys.sorted().filter { !knownKeys.contains($0) }
        return knownKeys + extraKeys
    }
}

