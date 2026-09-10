import SwiftUI
import TarotCore
import TarotData

/// Preparation UI shown before cards are shuffled and revealed.
/// Lets the user pick a spread type, set a card count (for free spreads),
/// optionally select a significator card, choose two "first cards", set a
/// reading intention, then trigger the draw.
struct ReadingPreparationView: View {
    @ObservedObject var model: TarotViewModel
    @Binding var chosenFirstCardSlot: Int?
    @Binding var cardPickerQuery: String
    @Binding var isShowingReplacementPicker: Bool
    @Binding var replacementPickerQuery: String
    @Binding var replacementIndex: Int?

    @State private var showingFirstCardPicker = false
    @State private var showingSignificatorPicker = false
    @State private var significatorSearch = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            // MARK: - Title
            VStack(alignment: .leading, spacing: 6) {
                Text(TarotStrings.selectSpread.localized)
                    .font(.system(size: 28, weight: .bold, design: .serif))
                    .foregroundStyle(Color.tarotIvory)
                Text(TarotStrings.ritualDescription.localized)
                    .font(.system(size: 13, weight: .light, design: .serif))
                    .foregroundStyle(Color.tarotIvory.opacity(0.55))
                    .lineSpacing(3)
            }

            // MARK: - Spread selector
            spreadSelector

            // MARK: - Free card count
            if model.selectedSpread == .free {
                freeCardCountPicker
            }

            // MARK: - Significator
            significatorSection

            // MARK: - Intention
            intentionField

            // MARK: - First cards
            firstCardsSection

            // MARK: - Shuffle button
            shuffleButton
        }
        .padding(.vertical, 8)
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
    }

    // MARK: - Views

    private var spreadSelector: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Tipo de tirada")
                .font(.system(size: 10, weight: .bold, design: .serif))
                .tracking(1.4)
                .foregroundStyle(Color.tarotGold.opacity(0.7))
                .textCase(.uppercase)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(SpreadType.allCases, id: \.id) { spreadType in
                        SpreadChip(
                            spreadType: spreadType,
                            isSelected: model.selectedSpread == spreadType
                        ) {
                            withAnimation(LuxuryAnimation.softSpring) {
                                model.selectedSpread = spreadType
                            }
                        }
                    }
                }
                .padding(.horizontal, 2)
            }
        }
    }

    @ViewBuilder
    private var freeCardCountPicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(TarotStrings.numberOfCards.localized)
                .font(.system(size: 10, weight: .bold, design: .serif))
                .tracking(1.4)
                .foregroundStyle(Color.tarotGold.opacity(0.7))
                .textCase(.uppercase)

            HStack {
                Text("\(model.freeCardCount) cartas")
                    .font(.system(size: 14, weight: .medium, design: .serif))
                    .foregroundStyle(Color.tarotIvory)
                Spacer()
                Stepper(value: $model.freeCardCount, in: 1...10) {
                    Text("Ajustar")
                        .font(.system(size: 12, design: .serif))
                        .foregroundStyle(Color.tarotIvory.opacity(0.8))
                }
                #if os(iOS)
                #if os(iOS)
                                .labelsHidden()
                                #endif
                #endif
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .luxuryGlass(cornerRadius: 16)
    }

    private var significatorSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle(isOn: $model.useSignificator) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 12, weight: .light))
                        .foregroundStyle(Color.tarotGold)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(TarotStrings.significatorTitle.localized)
                            .font(.system(size: 13, weight: .medium, design: .serif))
                            .foregroundStyle(Color.tarotIvory)
                        Text(TarotStrings.significatorSubtitle.localized)
                            .font(.system(size: 11, weight: .light, design: .serif))
                            .foregroundStyle(Color.tarotIvory.opacity(0.55))
                    }
                }
            }
            .toggleStyle(.switch)
            .tint(Color.tarotGold)

            if model.useSignificator {
                if let card = model.significatorCard {
                    significatorCardView(card: card)
                } else {
                    significatorPlaceholder
                }
            }
        }
    }

    @ViewBuilder
    private func significatorCardView(card: Card) -> some View {
        HStack {
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
            VStack(alignment: .leading, spacing: 4) {
                Text(card.name)
                    .font(.system(size: 12, weight: .medium, design: .serif))
                    .foregroundStyle(Color.tarotIvory)
                Text(TarotStrings.significatorSubtitle.localized)
                    .font(.system(size: 10, weight: .light, design: .serif))
                    .foregroundStyle(Color.tarotIvory.opacity(0.45))
            }
            Spacer()
            Button(TarotStrings.chooseRandomly.localized) {
                withAnimation(LuxuryAnimation.softSpring) {
                    model.drawRandomSignificator()
                }
            }
            .font(.system(size: 11, weight: .medium, design: .serif))
            .foregroundStyle(Color.tarotGold)
        }
        .padding(.horizontal, 4)
    }

    private var significatorPlaceholder: some View {
        HStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.white.opacity(0.04))
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .opacity(0.25)
                )
                .frame(width: 64, height: 92)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.white.opacity(0.1), lineWidth: 0.8)
                )
                .overlay {
                    Image(systemName: "sparkles")
                        .font(.system(size: 18, weight: .thin))
                        .foregroundStyle(Color.tarotIvory.opacity(0.3))
                }
            VStack(alignment: .leading, spacing: 4) {
                Text(TarotStrings.noSignificatorSelected.localized)
                    .font(.system(size: 12, design: .serif))
                    .foregroundStyle(Color.tarotIvory.opacity(0.45))
                Text("o toca para elegir")
                    .font(.system(size: 10, design: .serif))
                    .foregroundStyle(Color.tarotIvory.opacity(0.25))
            }
            Spacer()
            Button {
                significatorSearch = ""
                showingSignificatorPicker = true
            } label: {
                Image(systemName: "dice.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.tarotGold)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            significatorSearch = ""
            showingSignificatorPicker = true
        }
        .padding(.horizontal, 4)
    }

    private var intentionField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Intención de la lectura")
                .font(.system(size: 10, weight: .bold, design: .serif))
                .tracking(1.4)
                .foregroundStyle(Color.tarotGold.opacity(0.7))
                .textCase(.uppercase)

            TextField(TarotStrings.notesPlaceholder.localized, text: $model.readingIntention, axis: .vertical)
                .font(.system(size: 13, design: .serif))
                .foregroundStyle(Color.tarotIvory)
                .padding(14)
                .luxuryGlass(cornerRadius: 14)
                .submitLabel(.done)
                .submitLabel(.done)
        }
    }

    private var firstCardsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(TarotStrings.chooseFirstTwo.localized)
                .font(.system(size: 10, weight: .bold, design: .serif))
                .tracking(1.4)
                .foregroundStyle(Color.tarotGold.opacity(0.7))
                .textCase(.uppercase)
            Text(TarotStrings.chooseFirstTwoDesc.localized)
                .font(.system(size: 11, weight: .light, design: .serif))
                .foregroundStyle(Color.tarotIvory.opacity(0.45))
                .lineSpacing(2)

            HStack(spacing: 16) {
                firstCardSlot(index: 0, card: model.firstCardChoice)
                firstCardSlot(index: 1, card: model.secondCardChoice)
            }
        }
    }

    private func firstCardSlot(index: Int, card: Card?) -> some View {
        VStack(spacing: 6) {
            Text("Carta \(index + 1)")
                .font(.system(size: 9, weight: .bold, design: .serif))
                .tracking(0.8)
                .foregroundStyle(Color.tarotGold.opacity(0.6))
                .textCase(.uppercase)

            if let c = card {
                CardFace(
                    name: c.name,
                    imageName: c.imageName,
                    textureName: c.textureImageName,
                    reversed: false,
                    useTexture: true,
                    size: CGSize(width: 72, height: 104),
                    activeDeck: model.settings.activeDeck,
                    backDesign: model.settings.cardBackDesign
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.tarotGold.opacity(0.4), lineWidth: 1)
                )
                .onTapGesture {
                    cardPickerQuery = ""
                    chosenFirstCardSlot = index
                    showingFirstCardPicker = true
                }
            } else {
                Button {
                    cardPickerQuery = ""
                    chosenFirstCardSlot = index
                    showingFirstCardPicker = true
                } label: {
                    Color.clear
                                .frame(width: 72, height: 104)
                                .luxuryGlass(cornerRadius: 12)
                        .overlay {
                            VStack(spacing: 4) {
                                Image(systemName: "plus")
                                    .font(.system(size: 12, weight: .thin))
                                    .foregroundStyle(Color.tarotIvory.opacity(0.3))
                                Text(TarotStrings.addCard.localized)
                                    .font(.system(size: 8, weight: .bold, design: .serif))
                                    .tracking(0.8)
                                    .foregroundStyle(Color.tarotIvory.opacity(0.3))
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var shuffleButton: some View {
        Button {
            withAnimation(LuxuryAnimation.softSpring) {
                model.draw()
            }
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
            .foregroundStyle(Color.tarotIvory)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.tarotGoldGradient)
                    .opacity(model.isShuffling ? 0.6 : 1)
            )
            .disabled(model.isShuffling)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - SpreadChip

private struct SpreadChip: View {
    let spreadType: SpreadType
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                ZStack {
                    if isSelected {
                        Circle()
                            .fill(Color.tarotGoldGradient)
                    } else {
                        Circle()
                            .fill(Color.tarotPanel)
                    }
                    Circle()
                        .stroke(isSelected ? Color.tarotGold : Color.white.opacity(0.15), lineWidth: isSelected ? 1.5 : 0.75)
                    Text(spreadType.symbol)
                        .font(.system(size: isSelected ? 22 : 18, weight: isSelected ? .bold : .light, design: .monospaced))
                        .foregroundStyle(isSelected ? Color.tarotBackground : Color.tarotIvory.opacity(0.45))
                    if isSelected {
                        Circle()
                            .stroke(Color.tarotGold.opacity(0.3), lineWidth: 10)
                    }
                }
                .frame(width: 52, height: 52)

                Text(spreadType.label)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .regular, design: .serif))
                    .foregroundStyle(isSelected ? Color.tarotGold : Color.tarotIvory.opacity(0.55))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(width: 70)
            }
        }
        .buttonStyle(.plain)
        .frame(width: 80)
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
            .background(StarfieldBackgroundView(starCount: 80))
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
            .background(StarfieldBackgroundView(starCount: 80))
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
