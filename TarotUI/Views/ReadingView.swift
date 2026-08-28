import SwiftUI
import TarotCore
import TarotData
import TarotDI

struct ReadingView: View {
    @ObservedObject var model: TarotViewModel
    @State private var notes = ""
    @State private var revealedIndices: Set<Int> = []
    @State private var selectedDrawnCard: DrawnCard? = nil
    @State private var replacementIndex: Int? = nil
    @State private var cardPickerQuery = ""
    @State private var isShowingReplacementPicker = false
    @State private var replacementPickerQuery = ""
    @State private var chosenFirstCardSlot: Int? = nil
    @FocusState private var notesFocused: Bool
    @FocusState private var cardPickerFocused: Bool
    @FocusState private var replacementPickerFocused: Bool

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    spreadSelector
                    spreadInfo
                    if model.selectedSpread == .free {
                        freeCardSection
                    }
                    firstCardsSection
                    intentionBanner
                    significatorSection
                    readingResultsSection()
                }
                .padding(.vertical)
            }
        }
        .navigationTitle(model.spread?.type?.label ?? "Tirada")
        .sheet(isPresented: $isShowingReplacementPicker) {
            replacementPickerSheet
        }
        .alert(TarotStrings.errorTitle.localized, isPresented: Binding(get: { model.errorMessage != nil }, set: { if !$0 { model.errorMessage = nil } })) {
            Button(TarotStrings.ok.localized, role: .cancel) {}
        } message: {
            Text(model.errorMessage ?? "")
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                if let spread = model.spread, !spread.drawnCards.isEmpty {
                    Button(TarotStrings.revealAll.localized) {
                        revealAll()
                    }
                }
            }
        }
    }

    // MARK: - Subviews (extraídos para evitar type-check timeout)

    private var spreadSelector: some View {
        VStack(alignment: .leading, spacing: 10) {
            EyebrowLabel(text: TarotStrings.selectSpread.localized)
                .padding(.horizontal, 4)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 9) {
                    ForEach(SpreadType.allCases, id: \.self) { type in
                        spreadButton(for: type)
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
            }
        }
    }

    private func spreadButton(for type: SpreadType) -> some View {
        let isSelected = model.selectedSpread == type
        return Button {
            #if os(iOS)
            UISelectionFeedbackGenerator().selectionChanged()
            #endif
            withAnimation(LuxuryAnimation.softSpring) {
                model.selectedSpread = type
                revealedIndices.removeAll()
            }
        } label: {
            HStack(spacing: 7) {
                Text(type.symbol)
                    .font(.system(size: 11, weight: .light, design: .serif))
                    .foregroundStyle(isSelected ? Color.tarotGold : Color.tarotIvory.opacity(0.72))
                Text(type.label)
                    .font(.system(size: 12.5, weight: .medium, design: .serif))
                    .tracking(0.12)
                    .lineLimit(1)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(
                Capsule()
                    .fill(isSelected ? Color.tarotGold.opacity(0.14) : Color.white.opacity(0.05))
                    .background(Capsule().fill(.ultraThinMaterial).opacity(isSelected ? 0.55 : 0.32))
            )
            .overlay(Capsule().stroke(isSelected ? Color.tarotGold.opacity(0.42) : Color.white.opacity(0.08), lineWidth: isSelected ? 0.9 : 0.6))
            .foregroundStyle(isSelected ? Color.tarotGold : Color.tarotIvory.opacity(0.82))
            .shadow(color: isSelected ? Color.tarotGold.opacity(0.14) : .clear, radius: 10, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(type.label)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        .accessibilityHint(isSelected ? "Seleccionada" : "Toca para seleccionar tirada")
    }

    private var spreadInfo: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\(model.selectedSpread.label)  ·  \(spreadCardCount()) cartas")
                .font(.system(size: 12, weight: .semibold, design: .serif))
                .tracking(0.4)
                .foregroundStyle(Color.tarotIvory.opacity(0.92))
            if !model.selectedSpread.esotericDescription.isEmpty {
                Text(model.selectedSpread.esotericDescription)
                    .font(.system(size: 12, weight: .regular, design: .serif))
                    .foregroundStyle(Color.tarotIvory.opacity(0.6))
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 4)
    }

    private var freeCardSection: some View {
        HStack(spacing: 12) {
            Image(systemName: "dice").font(.system(size: 13, weight: .light)).foregroundStyle(Color.tarotGold.opacity(0.9))
            Text(TarotStrings.numberOfCards.localized)
                .font(.system(size: 13, weight: .medium, design: .serif))
                .tracking(0.1)
                .foregroundStyle(Color.tarotIvory.opacity(0.84))
            Spacer()
            Stepper("", value: $model.freeCardCount, in: 1...12).labelsHidden().tint(Color.tarotGold)
            Text("\(model.freeCardCount)")
                .font(.system(size: 18, weight: .bold, design: .serif))
                .foregroundStyle(Color.tarotGold)
                .frame(width: 30)
        }
        .padding(.horizontal, 14).padding(.vertical, 12)
        .luxuryGlass(cornerRadius: LuxuryRadius.md)
        .padding(.horizontal, 4)
    }

    private var firstCardsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 7) {
                Image(systemName: "hand.tap").font(.system(size: 12, weight: .light)).foregroundStyle(Color.tarotGold.opacity(0.9))
                Text(TarotStrings.chooseFirstTwo.localized)
                    .font(.system(size: 13, weight: .semibold, design: .serif))
                    .tracking(0.12)
                    .foregroundStyle(Color.tarotIvory.opacity(0.92))
            }
            Text(TarotStrings.chooseFirstTwoDesc.localized)
                .font(.system(size: 11, weight: .regular, design: .serif))
                .foregroundStyle(Color.tarotIvory.opacity(0.52))
                .lineSpacing(2)

            HStack(spacing: 12) {
                Spacer()
                FirstCardSlot(index: 1, card: model.firstCardChoice, activeDeck: model.settings.activeDeck, backDesign: model.settings.cardBackDesign) { chosenFirstCardSlot = 0 }
                FirstCardSlot(index: 2, card: model.secondCardChoice, activeDeck: model.settings.activeDeck, backDesign: model.settings.cardBackDesign) { chosenFirstCardSlot = 1 }
                Spacer()
            }
            .frame(maxWidth: .infinity)

            if chosenFirstCardSlot != nil {
                firstCardPicker
            }

            if model.firstCardChoice != nil || model.secondCardChoice != nil {
                Button {
                    withAnimation(LuxuryAnimation.softSpring) { model.clearChosenFirstCards() }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "xmark.circle").font(.system(size: 11, weight: .light))
                        Text(TarotStrings.removeChosen.localized)
                            .font(.system(size: 11, weight: .medium, design: .serif))
                            .tracking(0.2)
                    }.foregroundStyle(Color.tarotGold.opacity(0.9))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .luxuryGlass()
        .padding(.horizontal, 4)
    }

    @ViewBuilder
    private var intentionBanner: some View {
        if !model.readingIntention.isEmpty {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "sparkle").font(.system(size: 10, weight: .thin)).foregroundStyle(Color.tarotGold.opacity(0.9)).padding(.top, 3)
                Text(model.readingIntention)
                    .font(.system(size: 13, weight: .regular, design: .serif))
                    .foregroundStyle(Color.tarotIvory.opacity(0.72))
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
            }
            .padding(.horizontal, 14).padding(.vertical, 11)
            .luxuryGlass(cornerRadius: LuxuryRadius.sm)
            .padding(.horizontal, 4)
        }
    }

    @ViewBuilder
    private var significatorSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle(isOn: $model.useSignificator.animation(LuxuryAnimation.softSpring)) {
                HStack(spacing: 7) {
                    Image(systemName: "person.crop.circle").font(.system(size: 12, weight: .light)).foregroundStyle(Color.tarotGold.opacity(0.85))
                    Text(TarotStrings.significatorTitle.localized)
                        .font(.system(size: 13, weight: .medium, design: .serif))
                        .tracking(0.1)
                        .foregroundStyle(Color.tarotIvory.opacity(0.88))
                }
            }
            .tint(Color.tarotGold)
            .padding(.horizontal, 4)

            if model.useSignificator {
                significatorButton
            }
        }
    }

    private var significatorButton: some View {
        Button { withAnimation(LuxuryAnimation.softSpring) { model.drawRandomSignificator() } } label: {
            HStack(spacing: 10) {
                Circle().fill(Color.tarotGold.opacity(0.14)).frame(width: 28, height: 28).overlay(
                    Image(systemName: "sparkles").font(.system(size: 11, weight: .light)).foregroundStyle(Color.tarotGold)
                )
                VStack(alignment: .leading, spacing: 2) {
                    if let sig = model.significatorCard {
                        Text(sig.name)
                            .font(.system(size: 13, weight: .semibold, design: .serif))
                            .foregroundStyle(Color.tarotIvory)
                            .lineLimit(1)
                        Text(TarotStrings.significatorSubtitle.localized).font(.system(size: 10, weight: .regular, design: .serif)).tracking(0.8).foregroundStyle(Color.tarotIvory.opacity(0.42))
                    } else {
                        Text(TarotStrings.noSignificatorSelected.localized)
                            .font(.system(size: 12, weight: .regular, design: .serif))
                            .foregroundStyle(Color.tarotIvory.opacity(0.56))
                            .lineLimit(1)
                    }
                }
                Spacer()
                Text(TarotStrings.chooseRandomly.localized.uppercased())
                    .font(.system(size: 10, weight: .bold, design: .serif))
                    .tracking(0.8)
                    .foregroundStyle(Color.tarotGold)
            }
            .padding(.horizontal, 12).padding(.vertical, 10)
            .luxuryGlass(cornerRadius: LuxuryRadius.sm)
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Reading results

    @ViewBuilder
    private func readingResultsSection() -> some View {
        if let spread = model.spread, !spread.drawnCards.isEmpty {
            revealedSpreadContent(spread: spread)
        } else {
            emptySpreadContent
        }
    }

    private func revealedSpreadContent(spread: Spread) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SpreadDiagramView(
                spread: spread,
                repository: model.container.cards,
                revealedIndices: revealedIndices,
                activeDeck: model.settings.activeDeck,
                cardBackDesign: model.settings.cardBackDesign,
                onSelectCard: { drawn in selectedDrawnCard = drawn },
                onReplaceCard: { index, _ in
                    replacementIndex = index
                    isShowingReplacementPicker = true
                },
                onRevealCard: { index in
                    withAnimation(LuxuryAnimation.softSpring) { _ = revealedIndices.insert(index) }
                }
            )
            .padding(.horizontal, 4)

            revealedHorizontalCards(spread: spread)
            notesSection
            HStack(spacing: 12) {
                Spacer()
                saveButton
                reshuffleButton
                Spacer()
            }
            .frame(minHeight: 44)
            Text(TarotStrings.holdToReplace.localized)
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)
        }
    }

    private func revealedHorizontalCards(spread: Spread) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Array(spread.drawnCards.enumerated()), id: \.offset) { index, drawn in
                    revealedCardCell(index: index, drawn: drawn)
                }
            }
            .padding(.horizontal, 4)
        }
    }

    private func revealedCardCell(index: Int, drawn: DrawnCard) -> some View {
        let isRevealed = revealedIndices.contains(index)
        return CardFace(
            name: drawn.card.name,
            imageName: drawn.card.imageName,
            textureName: drawn.card.textureImageName,
            reversed: drawn.orientation == .reversed,
            back: !isRevealed,
            useTexture: true,
            size: CGSize(width: 110, height: 160),
            activeDeck: model.settings.activeDeck,
            backDesign: model.settings.cardBackDesign
        )
        .rotation3DEffect(.degrees(isRevealed ? 0 : 180), axis: (x: 0, y: 1, z: 0))
        .shadow(color: Color.tarotShadow.opacity(isRevealed ? 1 : 0.3), radius: 10, x: 0, y: 6)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.tarotBorder, lineWidth: 1)
        )
        .scaleEffect(isRevealed ? 1.0 : 0.95)
        .overlay(alignment: .topLeading) {
            OrderNumberBadge(number: index + 1)
                .padding(4)
        }
        .onTapGesture {
            if !isRevealed {
                _ = withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    revealedIndices.insert(index)
                }
            }
        }
        .onLongPressGesture {
            selectedDrawnCard = drawn
            replacementIndex = index
            isShowingReplacementPicker = true
        }
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            EyebrowLabel(text: TarotStrings.readingNotesTitle.localized)
            TextEditor(text: $notes)
                .font(.system(size: 13, weight: .regular, design: .serif))
                .lineSpacing(3)
                .scrollContentBackground(.hidden)
                .padding(10)
                .frame(minHeight: 84)
                .luxuryGlass(cornerRadius: LuxuryRadius.sm)
                .focused($notesFocused)
        }
        .padding(.horizontal, 4)
    }

    private var saveButton: some View {
        Button {
            if notesFocused { notesFocused = false }
            withAnimation(LuxuryAnimation.softSpring) { model.saveSpread(notes: notes); notes = "" }
            TarotAudioService.shared.triggerHaptic(.success)
        } label: {
            Text(TarotStrings.saveReading.localized.uppercased())
                .font(.system(size: 12.5, weight: .semibold, design: .serif))
                .tracking(1.0)
                .foregroundStyle(Color(red: 0.09, green: 0.06, blue: 0.02))
                .padding(.horizontal, 24)
                .padding(.vertical, 13)
                .background(Capsule().fill(Color.tarotGoldGradient))
                .overlay(Capsule().stroke(Color.white.opacity(0.32), lineWidth: 0.7).blendMode(.softLight))
                .shadow(color: Color.black.opacity(0.32), radius: 16, x: 0, y: 8)
                .shadow(color: Color.tarotGold.opacity(0.18), radius: 16, x: 0, y: 0)
        }
        .buttonStyle(.plain)
    }

    private var reshuffleButton: some View {
        Button {
            withAnimation(LuxuryAnimation.softSpring) { model.reshuffleCurrentSpread(); revealedIndices.removeAll() }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "arrow.triangle.2.circlepath").font(.system(size: 11, weight: .light))
                Text(TarotStrings.reshuffle.localized)
                    .font(.system(size: 12, weight: .medium, design: .serif))
                    .tracking(0.2)
            }
            .foregroundStyle(Color.tarotGold.opacity(0.95))
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(Capsule().fill(Color.white.opacity(0.05)).background(Capsule().fill(.ultraThinMaterial).opacity(0.42)))
            .overlay(Capsule().stroke(Color.white.opacity(0.09), lineWidth: 0.75))
        }
        .buttonStyle(.plain)
    }

    private var emptySpreadContent: some View {
        VStack(spacing: 18) {
            Button { withAnimation(LuxuryAnimation.softSpring) { model.draw() } } label: {
                HStack(spacing: 10) {
                    Image(systemName: "sparkles").font(.system(size: 12, weight: .light))
                    Text(TarotStrings.shuffleAndReveal.localized.uppercased())
                        .font(.system(size: 13, weight: .semibold, design: .serif))
                        .tracking(1.0)
                }
                .foregroundStyle(Color(red: 0.09, green: 0.06, blue: 0.02))
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background(Capsule().fill(Color.tarotGoldGradient))
                .overlay(Capsule().stroke(Color.white.opacity(0.34), lineWidth: 0.75).blendMode(.softLight))
                .shadow(color: Color.black.opacity(0.34), radius: 18, x: 0, y: 10)
                .shadow(color: Color.tarotGold.opacity(0.18), radius: 20, x: 0, y: 0)
            }
            .buttonStyle(.plain)
            .disabled(model.isShuffling)
            .opacity(model.isShuffling ? 0.72 : 1)

            if model.isShuffling {
                VStack(spacing: 10) {
                    ProgressView().tint(Color.tarotGold)
                    Text(TarotStrings.shuffling.localized)
                        .font(.system(size: 11, weight: .medium, design: .serif))
                        .tracking(0.8)
                        .foregroundStyle(Color.tarotIvory.opacity(0.52))
                }
            }
        }
        .padding(.vertical, 28)
    }

    private func revealAll() {
        guard let spread = model.spread else { return }
        TarotAudioService.shared.triggerHaptic(.medium)
        withAnimation(.easeInOut(duration: 0.6)) {
            revealedIndices = Set(0..<spread.drawnCards.count)
        }
    }

    private func spreadCardCount() -> Int {
        model.selectedSpread == .free ? model.freeCardCount : model.selectedSpread.positions.count
    }

    private var firstCardPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            TextField(TarotStrings.searchCard.localized, text: $cardPickerQuery)
                .textFieldStyle(.roundedBorder)
                .focused($cardPickerFocused)
            ScrollView(.vertical, showsIndicators: true) {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 62), spacing: 8)], spacing: 8) {
                    ForEach(cardsForPicker()) { card in
                        Button {
                            chooseFirstCard(card)
                        } label: {
                            CardFace(
                                name: card.name,
                                imageName: card.imageName,
                                textureName: card.textureImageName,
                                reversed: false,
                                useTexture: true,
                                size: CGSize(width: 58, height: 84),
                                activeDeck: model.settings.activeDeck,
                                backDesign: model.settings.cardBackDesign
                            )
                            .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 3)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .frame(maxHeight: 240)
        }
        .padding(10)
        .background(Color.tarotPanel.opacity(0.9))
        .cornerRadius(14)
    }

    private var replacementPickerSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 10) {
                Text(TarotStrings.chooseReplacement.localized)
                    .font(.system(size: 13, weight: .semibold, design: .serif))
                    .foregroundStyle(Color.tarotIvory)
                    .padding(.horizontal, 4)
                TextField(TarotStrings.searchCard.localized, text: $replacementPickerQuery)
                    .textFieldStyle(.roundedBorder)
                    .focused($replacementPickerFocused)
                ScrollView(.vertical, showsIndicators: true) {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 62), spacing: 8)], spacing: 8) {
                        ForEach(replacementCards()) { card in
                            Button {
                                chooseReplacementCard(card)
                            } label: {
                                CardFace(
                                    name: card.name,
                                    imageName: card.imageName,
                                    textureName: card.textureImageName,
                                    reversed: false,
                                    useTexture: true,
                                    size: CGSize(width: 58, height: 84),
                                    activeDeck: model.settings.activeDeck,
                                    backDesign: model.settings.cardBackDesign
                                )
                                .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 3)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 4)
                }
                .frame(maxHeight: 240)
            }
            .padding(.vertical)
            .navigationTitle(TarotStrings.replaceCard.localized)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(TarotStrings.cancel.localized) {
                        isShowingReplacementPicker = false
                        replacementPickerQuery = ""
                        replacementPickerFocused = false
                        replacementIndex = nil
                    }
                }
            }
        }
    }

    private func cardsForPicker() -> [Card] {
        let query = cardPickerQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        let all = model.container.cards.allCards()
        return query.isEmpty ? all : model.container.cards.search(query: query)
    }

    private func chooseFirstCard(_ card: Card) {
        // Resign keyboard antes de remover el picker para evitar warning "keyboard was not even present"
        if cardPickerFocused { cardPickerFocused = false }
        // Pequeño delay para que el teclado se oculte antes de quitar la vista
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            if chosenFirstCardSlot == 0 {
                if model.secondCardChoice?.id == card.id {
                    model.secondCardChoice = nil
                }
                model.firstCardChoice = card
            } else if chosenFirstCardSlot == 1 {
                if model.firstCardChoice?.id == card.id {
                    model.firstCardChoice = nil
                }
                model.secondCardChoice = card
            }
            chosenFirstCardSlot = nil
            cardPickerQuery = ""
        }
    }

    private func replacementCards() -> [Card] {
        let query = replacementPickerQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        let all = model.container.cards.allCards()
        return query.isEmpty ? all : model.container.cards.search(query: query)
    }

    private func chooseReplacementCard(_ card: Card) {
        if replacementPickerFocused { replacementPickerFocused = false }
        // Delay dismiss para dejar que el teclado se oculte primero
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            model.replaceCard(at: replacementIndex ?? 0, with: card)
            isShowingReplacementPicker = false
            replacementPickerQuery = ""
            replacementIndex = nil
        }
    }
}

// MARK: - First card slot — minimal joya (ahora con imagen real + haptics)
private struct FirstCardSlot: View {
    let index: Int
    let card: Card?
    var activeDeck: DeckType = .riderWaite
    var backDesign: CardBackDesign = .classic
    let onTap: () -> Void

    var body: some View {
        Button {
            #if os(iOS)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            #endif
            onTap()
        } label: {
            VStack(spacing: 7) {
                ZStack(alignment: .topLeading) {
                    if let c = card {
                        CardFace(
                            name: c.name,
                            imageName: c.imageName,
                            textureName: c.textureImageName,
                            reversed: false,
                            useTexture: true,
                            size: CGSize(width: 86, height: 126),
                            activeDeck: activeDeck,
                            backDesign: backDesign
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 13, style: .continuous)
                                .stroke(Color.tarotGold.opacity(0.28), lineWidth: 0.85)
                        )
                        .shadow(color: Color.black.opacity(0.22), radius: 10, x: 0, y: 6)
                    } else {
                        RoundedRectangle(cornerRadius: 13, style: .continuous)
                            .fill(Color.white.opacity(0.05))
                            .background(RoundedRectangle(cornerRadius: 13, style: .continuous).fill(.ultraThinMaterial).opacity(0.38))
                            .frame(width: 86, height: 126)
                            .overlay(RoundedRectangle(cornerRadius: 13, style: .continuous).stroke(Color.white.opacity(0.08), lineWidth: 0.85))
                            .shadow(color: Color.black.opacity(0.22), radius: 10, x: 0, y: 6)
                            .overlay {
                                VStack(spacing: 6) {
                                    Image(systemName: "plus").font(.system(size: 12, weight: .thin)).foregroundStyle(Color.tarotIvory.opacity(0.42))
                                    Text(TarotStrings.addCard.localized)
                                        .font(.system(size: 9, weight: .bold, design: .serif)).tracking(1.0).foregroundStyle(Color.tarotIvory.opacity(0.36))
                                }
                            }
                    }
                    // badge
                    ZStack {
                        Circle().fill(Color.tarotGoldGradient).frame(width: 18, height: 18).shadow(color: Color.black.opacity(0.32), radius: 3, x: 0, y: 1)
                        Text("\(index)").font(.system(size: 9, weight: .bold, design: .serif)).foregroundStyle(Color.white)
                    }
                    .padding(5)
                }
                Text(card?.name ?? TarotStrings.choose.localized)
                    .font(.system(size: 10.5, weight: .medium, design: .serif))
                    .tracking(0.1)
                    .foregroundStyle(card == nil ? Color.tarotIvory.opacity(0.48) : Color.tarotIvory.opacity(0.92))
                    .lineLimit(1)
                    .frame(width: 86)
            }
        }
        .buttonStyle(.plain)
    }
}
