import SwiftUI
import TarotCore
import TarotData

/// Preparation UI shown before cards are revealed.
/// Curated featured spreads + full categorized picker, significator, intention
/// and first-card choice — all wrapped in the shared luxury page container.
struct ReadingPreparationView: View {
    @ObservedObject var model: TarotViewModel
    @Binding var chosenFirstCardSlot: Int?
    @Binding var cardPickerQuery: String
    @Binding var isShowingReplacementPicker: Bool
    @Binding var replacementPickerQuery: String
    @Binding var replacementIndex: Int?

    @State private var showingFirstCardPicker = false
    @State private var showingSignificatorPicker = false
    @State private var showingAllSpreads = false
    @State private var significatorSearch = ""

    /// En macOS la ventana es ancha: 4 columnas fijas equilibran las 8 tiradas destacadas (2×4).
    private static var spreadColumns: [GridItem] {
        #if os(macOS)
        return Array(repeating: GridItem(.flexible(maximum: 140)), count: 4)
        #else
        return [GridItem(.adaptive(minimum: 88, maximum: 120), spacing: 14)]
        #endif
    }

    /// Curated subset shown directly on the canvas.
    private let featuredSpreads: [SpreadType] = [
        .dailyCard, .threeCard, .celticCross, .fiveCard,
        .horseshoe, .relationship, .decision, .free
    ]

    var body: some View {
        // Mismo patron que Referencia y Lazos del alma: la pagina tiene que poder desplazarse.
        // Sin esto, en una ventana baja (macOS) el boton de barajar y las cartas iniciales
        // quedaban cortados por el borde sin forma de alcanzarlos.
        ScrollView(.vertical, showsIndicators: false) {
        LuxuryPage(maxWidth: 780) {
            VStack(alignment: .leading, spacing: 21) {
                hero

                spreadSelector

                if model.selectedSpread == .free {
                    freeCardCountPicker
                }

                significatorSection

                intentionField

                firstCardsSection

                shuffleButton
            }
            .padding(.vertical, 8)
        }
        }
        .sheet(isPresented: $showingFirstCardPicker) {
            FirstCardPickerSheet(
                model: model,
                searchQuery: $cardPickerQuery,
                selectedSlot: $chosenFirstCardSlot
            ) { card, slot in
                if slot == 0 {
                    model.firstCardChoice = card
                } else {
                    model.secondCardChoice = card
                }
            }
        }
        .sheet(isPresented: $showingSignificatorPicker) {
            SignificatorPickerSheet(
                model: model,
                searchQuery: $significatorSearch
            ) { card in
                model.significatorCard = card
            }
        }
        .sheet(isPresented: $showingAllSpreads) {
            AllSpreadsSheet(model: model)
        }
    }

    // MARK: - Hero

    private var hero: some View {
        LuxuryPageHeader(
            eyebrow: "Ritual de lectura",
            title: TarotStrings.selectSpread.localized,
            subtitle: TarotStrings.ritualDescription.localized
        )
    }

    // MARK: - Spread selector (featured grid + full catalog)

    private var spreadSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                EyebrowLabel(text: "Tipo de tirada")
                Spacer()
                Button {
                    showingAllSpreads = true
                } label: {
                    HStack(spacing: 5) {
                        Text("Todas")
                        Text("\(SpreadType.allCases.count)")
                            .font(.system(size: 9.5, weight: .bold, design: .serif))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1.5)
                            .background(Capsule().fill(Color.tarotGold.opacity(0.18)))
                    }
                }
                .font(.system(size: 10.5, weight: .semibold, design: .serif))
                .tracking(0.8)
                .foregroundStyle(Color.tarotGold.opacity(0.95))
                .buttonStyle(.plain)
            }

            LazyVGrid(
                columns: Self.spreadColumns,
                spacing: 18
            ) {
                ForEach(featuredSpreads, id: \.id) { spreadType in
                    SpreadChip(
                        spreadType: spreadType,
                        isSelected: model.selectedSpread == spreadType
                    ) {
                        withAnimation(LuxuryAnimation.softSpring) {
                            model.selectedSpread = spreadType
                        }
                        HapticManager.shared.triggerSelection()
                    }
                }
            }

            // Ficha de la tirada elegida: tradición, cómo leerla y para qué sirve.
            SpreadInfoCard(spreadType: model.selectedSpread, compact: true)
                .id(model.selectedSpread)
                .transition(.opacity)
        }
    }

    // MARK: - Free card count

    @ViewBuilder
    private var freeCardCountPicker: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(TarotStrings.numberOfCards.localized.uppercased())
                    .font(.system(size: 9, weight: .bold, design: .serif))
                    .tracking(1.4)
                    .foregroundStyle(Color.tarotGold.opacity(0.7))
                Text("\(model.freeCardCount) cartas")
                    .font(.system(size: 15, weight: .medium, design: .serif))
                    .foregroundStyle(Color.tarotIvory)
            }
            Spacer()
            Stepper(value: $model.freeCardCount, in: 1...10) {
                Text("Ajustar")
                    .font(.system(size: 12, design: .serif))
                    .foregroundStyle(Color.tarotIvory.opacity(0.8))
            }
            .labelsHidden()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .luxuryGlass(cornerRadius: 16)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    // MARK: - Significator

    private var significatorSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle(isOn: $model.useSignificator) {
                HStack(spacing: 10) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 13, weight: .light))
                        .foregroundStyle(Color.tarotGold)
                        .frame(width: 22)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(TarotStrings.significatorTitle.localized)
                            .font(.system(size: 13.5, weight: .medium, design: .serif))
                            .foregroundStyle(Color.tarotIvory)
                        Text(TarotStrings.significatorSubtitle.localized)
                            .font(.system(size: 11, weight: .light, design: .serif))
                            .foregroundStyle(Color.tarotIvory.opacity(0.55))
                    }
                }
            }
            .toggleStyle(LuxuryToggleStyle())

            if model.useSignificator {
                if let card = model.significatorCard {
                    significatorCardView(card: card)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                } else {
                    significatorPlaceholder
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .animation(LuxuryAnimation.softSpring, value: model.useSignificator)
    }

    @ViewBuilder
    private func significatorCardView(card: Card) -> some View {
        HStack(spacing: 14) {
            CardFace(
                name: card.name,
                imageName: card.imageName,
                textureName: card.textureImageName,
                reversed: false,
                useTexture: true,
                size: CGSize(width: 64, height: 92),
                activeDeck: model.settings.activeDeck,
                backDesign: model.settings.cardBackDesign
            )
            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)

            VStack(alignment: .leading, spacing: 4) {
                LuxuryTag(text: "Significadora")
                Text(card.name)
                    .font(.system(size: 14, weight: .medium, design: .serif))
                    .foregroundStyle(Color.tarotIvory)
                Text(TarotStrings.significatorSubtitle.localized)
                    .font(.system(size: 10.5, weight: .light, design: .serif))
                    .foregroundStyle(Color.tarotIvory.opacity(0.45))
            }
            Spacer()
            Button {
                withAnimation(LuxuryAnimation.softSpring) {
                    model.drawRandomSignificator()
                }
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "dice.fill")
                        .font(.system(size: 16, weight: .medium))
                    Text("Al azar")
                        .font(.system(size: 9, weight: .semibold, design: .serif))
                        .tracking(0.6)
                }
                .foregroundStyle(Color.tarotGold)
                .frame(width: 62, height: 52)
                .background(
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .fill(Color.white.opacity(0.05))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .stroke(Color.tarotGold.opacity(0.25), lineWidth: 0.7)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: LuxuryRadius.md, style: .continuous)
                .fill(Color.white.opacity(0.035))
        )
    }

    private var significatorPlaceholder: some View {
        Button {
            significatorSearch = ""
            showingSignificatorPicker = true
        } label: {
            HStack(spacing: 14) {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.white.opacity(0.04))
                    .frame(width: 64, height: 92)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(style: StrokeStyle(lineWidth: 0.9, dash: [4, 3]))
                            .foregroundStyle(Color.tarotGold.opacity(0.35))
                    )
                    .overlay {
                        Image(systemName: "sparkles")
                            .font(.system(size: 17, weight: .thin))
                            .foregroundStyle(Color.tarotIvory.opacity(0.35))
                    }

                VStack(alignment: .leading, spacing: 4) {
                    Text(TarotStrings.noSignificatorSelected.localized)
                        .font(.system(size: 12.5, weight: .medium, design: .serif))
                        .foregroundStyle(Color.tarotIvory.opacity(0.7))
                    Text("o toca para elegir")
                        .font(.system(size: 10.5, design: .serif))
                        .foregroundStyle(Color.tarotIvory.opacity(0.35))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.tarotIvory.opacity(0.3))
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: LuxuryRadius.md, style: .continuous)
                    .fill(Color.white.opacity(0.035))
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Intention

    private var intentionField: some View {
        VStack(alignment: .leading, spacing: 8) {
            EyebrowLabel(text: "Intención de la lectura")

            TextField(TarotStrings.notesPlaceholder.localized, text: $model.readingIntention, axis: .vertical)
                .font(.system(size: 13.5, design: .serif))
                .foregroundStyle(Color.tarotIvory)
                .lineLimit(2...4)
                .padding(14)
                .luxuryGlass(cornerRadius: 14)
                .submitLabel(.done)
        }
    }

    // MARK: - First cards

    private var firstCardsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            EyebrowLabel(text: "Cartas iniciales")
            Text(TarotStrings.chooseFirstTwoDesc.localized)
                .font(.system(size: 11, weight: .light, design: .serif))
                .foregroundStyle(Color.tarotIvory.opacity(0.45))
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 18) {
                firstCardSlot(index: 0, card: model.firstCardChoice)
                LuxuryVLine()
                firstCardSlot(index: 1, card: model.secondCardChoice)
            }
        }
    }

    private func firstCardSlot(index: Int, card: Card?) -> some View {
        VStack(spacing: 8) {
            Text("Carta \(index + 1)")
                .font(.system(size: 9, weight: .bold, design: .serif))
                .tracking(1.0)
                .foregroundStyle(Color.tarotGold.opacity(0.65))
                .textCase(.uppercase)

            Button {
                HapticManager.shared.triggerLight()
                cardPickerQuery = ""
                chosenFirstCardSlot = index
                showingFirstCardPicker = true
            } label: {
                ZStack(alignment: .topLeading) {
                    if let c = card {
                        CardFace(
                            name: c.name,
                            imageName: c.imageName,
                            textureName: c.textureImageName,
                            reversed: false,
                            useTexture: true,
                            size: CGSize(width: 84, height: 122),
                            activeDeck: model.settings.activeDeck,
                            backDesign: model.settings.cardBackDesign
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 13, style: .continuous)
                                .stroke(Color.tarotGold.opacity(0.4), lineWidth: 0.9)
                        )
                        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 6)
                    } else {
                        RoundedRectangle(cornerRadius: 13, style: .continuous)
                            .fill(Color.white.opacity(0.035))
                            .frame(width: 84, height: 122)
                            .overlay(
                                RoundedRectangle(cornerRadius: 13, style: .continuous)
                                    .strokeBorder(style: StrokeStyle(lineWidth: 0.9, dash: [5, 4]))
                                    .foregroundStyle(Color.tarotGold.opacity(0.3))
                            )
                            .overlay {
                                VStack(spacing: 6) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 15, weight: .thin))
                                        .foregroundStyle(Color.tarotGold.opacity(0.55))
                                    Text(TarotStrings.addCard.localized)
                                        .font(.system(size: 8.5, weight: .bold, design: .serif))
                                        .tracking(1.2)
                                        .foregroundStyle(Color.tarotIvory.opacity(0.35))
                                }
                            }
                    }

                    // Badge numerado
                    ZStack {
                        Circle().fill(Color.tarotGoldGradient).frame(width: 18, height: 18)
                        Text("\(index + 1)")
                            .font(.system(size: 9, weight: .bold, design: .serif))
                            .foregroundStyle(Color.tarotBackground)
                    }
                    .shadow(color: .black.opacity(0.35), radius: 3, x: 0, y: 1)
                    .padding(6)
                }
                .frame(width: 84, height: 122)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Text(card?.name ?? TarotStrings.choose.localized)
                .font(.system(size: 10.5, weight: .medium, design: .serif))
                .foregroundStyle(card == nil ? Color.tarotIvory.opacity(0.42) : Color.tarotIvory.opacity(0.9))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
                .frame(width: 90)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Shuffle CTA

    private var shuffleButton: some View {
        Button {
            withAnimation(LuxuryAnimation.softSpring) {
                model.draw()
            }
            HapticManager.shared.triggerMedium()
        } label: {
            HStack(spacing: 10) {
                if model.isShuffling {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(Color.tarotIvory)
                } else {
                    Image(systemName: "star.fill")
                        .font(.system(size: 14, weight: .medium))
                }
                Text(model.isShuffling
                       ? TarotStrings.shuffling.localized
                       : TarotStrings.shuffleAndReveal.localized)
                    .font(.system(size: 16, weight: .medium, design: .serif))
                    .tracking(0.8)
            }
            .disabled(model.isShuffling)
        }
        .buttonStyle(LuxuryPrimaryButtonStyle(isEnabled: !model.isShuffling))
        .padding(.top, 6)
    }
}

// MARK: - Spread Chip

private struct SpreadChip: View {
    let spreadType: SpreadType
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 9) {
                ZStack {
                    Circle()
                        .fill(isSelected ? AnyShapeStyle(Color.tarotGoldGradient) : AnyShapeStyle(Color.white.opacity(0.05)))
                    Circle()
                        .strokeBorder(
                            isSelected ? Color.tarotGoldHighlight.opacity(0.75) : Color.tarotGold.opacity(0.18),
                            lineWidth: isSelected ? 1.2 : 0.75
                        )
                    Text(spreadType.symbol)
                        .font(.system(size: isSelected ? 21 : 18, weight: isSelected ? .bold : .light, design: .monospaced))
                        .foregroundStyle(isSelected ? Color.tarotBackground : Color.tarotIvory.opacity(0.55))
                }
                .frame(width: 52, height: 52)
                .shadow(
                    color: isSelected ? Color.tarotGoldDeep.opacity(0.55) : .black.opacity(0.2),
                    radius: isSelected ? 12 : 6, x: 0, y: isSelected ? 4 : 3
                )

                Text(spreadType.label)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .regular, design: .serif))
                    .foregroundStyle(isSelected ? Color.tarotGold : Color.tarotIvory.opacity(0.72))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.34, dampingFraction: 0.75), value: isSelected)
    }
}

// MARK: - All Spreads Sheet (catálogo completo por categorías)

private struct AllSpreadsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var model: TarotViewModel

    private var categories: [(String, [SpreadType])] {
        [
            ("Esenciales", [.dailyCard, .threeCard, .fiveCard, .celticCross, .horseshoe, .relationship, .twelveMonth, .decision, .pathOfLife, .free]),
            ("Sagradas", [.chakraSpread, .hexagram, .treeOfLife, .starDavid, .soulMirror, .alchemyPath, .temperance]),
            ("Astrológicas y lunares", [.astrological, .moonCycle]),
            ("Prácticas", [.pyramid, .yesNo, .lineage])
        ]
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    ForEach(categories, id: \.0) { title, spreads in
                        VStack(alignment: .leading, spacing: 12) {
                            EyebrowLabel(text: title)
                            LazyVGrid(
                                columns: [GridItem(.adaptive(minimum: 96, maximum: 130), spacing: 12)],
                                spacing: 16
                            ) {
                                ForEach(spreads, id: \.id) { spread in
                                    SpreadChip(
                                        spreadType: spread,
                                        isSelected: model.selectedSpread == spread
                                    ) {
                                        withAnimation(LuxuryAnimation.softSpring) {
                                            model.selectedSpread = spread
                                        }
                                        HapticManager.shared.triggerSelection()
                                        dismiss()
                                    }
                                }
                            }
                        }
                    }

                    // Detalle de la tirada seleccionada (se actualiza al tocar una chip).
                    SpreadInfoCard(spreadType: model.selectedSpread)
                        .id(model.selectedSpread)
                        .transition(.opacity)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 18)
            }
            .navigationTitle("Todas las tiradas")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Listo") { dismiss() }
                }
            }
            .tarotNightBackground()
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Card Picker Sheet (shared by first-card and significator selection)

private struct FirstCardPickerSheet: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var model: TarotViewModel
    @Binding var searchQuery: String
    @Binding var selectedSlot: Int?
    let onSelect: (Card, Int) -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 64), spacing: 10)], spacing: 10) {
                    ForEach(filteredCards(), id: \.id) { card in
                        CardPickerCell(card: card, activeDeck: model.settings.activeDeck, backDesign: model.settings.cardBackDesign) {
                            onSelect(card, selectedSlot ?? 0)
                            dismiss()
                        }
                    }
                }
                .padding()
            }
            .tarotNightBase()
            .searchable(text: $searchQuery, prompt: TarotStrings.searchCard.localized)
            .navigationTitle(TarotStrings.choose.localized)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(TarotStrings.cancel.localized) { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func filteredCards() -> [Card] {
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        let all = model.container.cards.allCards()
        return query.isEmpty ? all : model.container.cards.search(query: query)
    }
}

private struct SignificatorPickerSheet: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var model: TarotViewModel
    @Binding var searchQuery: String
    let onSelect: (Card) -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 64), spacing: 10)], spacing: 10) {
                    ForEach(filteredCards(), id: \.id) { card in
                        CardPickerCell(card: card, activeDeck: model.settings.activeDeck, backDesign: model.settings.cardBackDesign) {
                            onSelect(card)
                            dismiss()
                        }
                    }
                }
                .padding()
            }
            .tarotNightBase()
            .searchable(text: $searchQuery, prompt: TarotStrings.searchCard.localized)
            .navigationTitle(TarotStrings.significatorTitle.localized)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(TarotStrings.cancel.localized) { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func filteredCards() -> [Card] {
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        let all = model.container.cards.allCards()
        return query.isEmpty ? all : model.container.cards.search(query: query)
    }
}

private struct CardPickerCell: View {
    let card: Card
    let activeDeck: DeckType
    let backDesign: CardBackDesign
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            CardFace(
                name: card.name,
                imageName: card.imageName,
                textureName: card.textureImageName,
                reversed: false,
                useTexture: true,
                size: CGSize(width: 60, height: 86),
                activeDeck: activeDeck,
                backDesign: backDesign
            )
        }
        .buttonStyle(.plain)
    }
}
