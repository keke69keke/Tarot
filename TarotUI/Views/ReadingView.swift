import SwiftUI
import Combine
import TarotCore
import TarotData
import TarotDI

struct ReadingView: View {
    @ObservedObject var model: TarotViewModel
    @State private var notes = ""
    @State private var revealedIndices: Set<Int> = []
    @State private var isRitualActive = false
    @State private var selectedDrawnCard: DrawnCard? = nil
    @State private var replacementIndex: Int? = nil
    @State private var cardPickerQuery = ""
    @State private var isShowingReplacementPicker = false
    @State private var replacementPickerQuery = ""
    @State private var chosenFirstCardSlot: Int? = nil
    @State private var ritualPhase: RitualPhase = .preparation
    @FocusState private var notesFocused: Bool
    @FocusState private var cardPickerFocused: Bool
    @FocusState private var replacementPickerFocused: Bool
    @State private var cancellables = Set<AnyCancellable>()

    enum RitualPhase {
        case preparation, revelation
    }

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                phaseContent
            }
            .navigationTitle(model.spread?.type?.label ?? "Tirada")
            .toolbar { toolbarContent }
            .tarotNightBackground()
        }
        #if os(iOS)
        .fullScreenCover(isPresented: $isRitualActive) {
            RitualModeView(isActive: $isRitualActive) {
                isRitualActive = false
                withAnimation(LuxuryAnimation.softSpring) {
                    model.draw()
                }
            }
        }
        #endif
        .sheet(isPresented: $isShowingReplacementPicker) {
            replacementPickerSheet
        }
        .sheet(item: $selectedDrawnCard) { drawn in
            drawnCardDetailSheet(for: drawn)
        }
        .alert(TarotStrings.errorTitle.localized, isPresented: errorAlertBinding) {
            Button(TarotStrings.ok.localized, role: .cancel) {}
        } message: {
            Text(model.errorMessage ?? "")
        }
        .onAppear(perform: startSomaticListening)
        .onChange(of: model.isShuffling) { shuffling in
            advanceToRevelationIfReady(isShuffling: shuffling)
        }
    }

    // MARK: - Subviews (extraído del body para aligerar el type-check)

    @ViewBuilder
    private var phaseContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            if ritualPhase == .preparation {
                ReadingPreparationView(
                    model: model,
                    chosenFirstCardSlot: $chosenFirstCardSlot,
                    cardPickerQuery: $cardPickerQuery,
                    isShowingReplacementPicker: $isShowingReplacementPicker,
                    replacementPickerQuery: $replacementPickerQuery,
                    replacementIndex: $replacementIndex
                )
                .transition(.asymmetric(insertion: .opacity.combined(with: .move(edge: .leading)), removal: .opacity))
            } else {
                ReadingRevelationView(
                    model: model,
                    revealedIndices: $revealedIndices,
                    selectedDrawnCard: $selectedDrawnCard,
                    replacementIndex: $replacementIndex,
                    isShowingReplacementPicker: $isShowingReplacementPicker,
                    notes: $notes,
                    isRitualActive: $isRitualActive
                )
                .transition(.asymmetric(insertion: .opacity.combined(with: .move(edge: .trailing)), removal: .opacity))
            }
        }
        .padding(.vertical)
        .padding(.horizontal)
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        #if os(iOS)
        if ritualPhase == .revelation {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: backToPreparation) {
                    Label("Cambiar tirada", systemImage: "chevron.left.circle")
                        .font(.system(size: 12, weight: .medium, design: .serif))
                        .foregroundStyle(Color.tarotIvory)
                }
            }
        }
        #endif

        ToolbarItem(placement: .automatic) {
            if let spread = model.spread, !spread.drawnCards.isEmpty {
                Button(TarotStrings.revealAll.localized) {
                    revealAll()
                }
            }
        }
    }

    private var errorAlertBinding: Binding<Bool> {
        Binding(
            get: { model.errorMessage != nil },
            set: { if !$0 { model.errorMessage = nil } }
        )
    }

    /// Vuelve a preparación para elegir otra tirada.
    private func backToPreparation() {
        HapticManager.shared.triggerLight()
        withAnimation(LuxuryAnimation.softSpring) {
            revealedIndices.removeAll()
            notes = ""
            model.currentSynthesis = nil
            model.spread = nil
            model.clearChosenFirstCards()
            model.significatorCard = nil
            model.selectedSpread = .threeCard
            ritualPhase = .preparation
        }
    }

    /// Al terminar el reparto, pasa a la fase de revelación.
    private func advanceToRevelationIfReady(isShuffling: Bool) {
        guard !isShuffling, model.spread != nil, ritualPhase == .preparation else { return }
        withAnimation(LuxuryAnimation.softSpring) {
            ritualPhase = .revelation
        }
    }

    /// Escucha el agitado del dispositivo para repartir.
    private func startSomaticListening() {
        model.container.somatic.startAccelerometerUpdates()
        model.container.somatic.$isShaking
            .sink { isShaking in
                if isShaking {
                    HapticManager.shared.triggerMedium()
                    withAnimation(LuxuryAnimation.softSpring) {
                        model.draw()
                    }
                }
            }
            .store(in: &cancellables)
    }

    private func revealAll() {
        guard let spread = model.spread else { return }
        HapticManager.shared.triggerMedium()
        withAnimation(.easeInOut(duration: 0.6)) {
            revealedIndices = Set(0..<spread.drawnCards.count)
        }
    }

    // MARK: - Detalle de carta revelada (hoja de significado)

    /// Hoja con el significado completo de una carta ya revelada:
    /// cabecera editorial con la posición en la tirada + `CardDetailView`
    /// (héroe, orientación, keywords, aspectos y acceso al Libro Rider).
    private func drawnCardDetailSheet(for drawn: DrawnCard) -> some View {
        NavigationStack {
            VStack(spacing: 0) {
                DrawnCardDetailHeader(drawn: drawn)

                GoldDivider(opacity: 0.22)

                CardDetailView(
                    drawn: drawn,
                    repository: model.container.cards,
                    activeDeck: model.settings.activeDeck,
                    cardBackDesign: model.settings.cardBackDesign
                )
            }
            .background(Color.tarotBackground.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        HapticManager.shared.triggerLight()
                        selectedDrawnCard = nil
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 11, weight: .bold, design: .serif))
                            .foregroundStyle(Color.tarotIvory.opacity(0.72))
                            .padding(7)
                            .background(Circle().fill(Color.white.opacity(0.07)))
                            .overlay(Circle().stroke(Color.tarotGold.opacity(0.28), lineWidth: 0.75))
                    }
                    .accessibilityLabel("Cerrar")
                }
            }
        }
    }

    private var replacementPickerSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 10) {
                Text(TarotStrings.chooseReplacement.localized)
                    .font(.system(size: 13, weight: .semibold, design: .serif))
                    .foregroundStyle(Color.tarotIvory)
                    .padding(.horizontal, 4)
                TextField(TarotStrings.searchCard.localized, text: $replacementPickerQuery)
                    // `.roundedBorder` es el estilo por defecto de iOS: pinta el
                    // campo con el gris del sistema y se ve como una banda opaca
                    // sobre el fondo nocturno. Aqui se dibuja a mano, translucido.
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.white.opacity(0.06))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(Color.tarotGold.opacity(0.22), lineWidth: 0.8)
                            )
                    )
                    .focused($replacementPickerFocused)
                ScrollView(.vertical, showsIndicators: true) {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 62), spacing: 8)], spacing: 8) {
                        ForEach(replacementCards(), id: \.id) { card in
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
            // Sin fondo propio el modal caia al gris del sistema: la vista que
            // lo presenta no se lo presta. Verificado midiendo la captura: gris
            // (28,28,30) sin esto, violeta de la app con esto.
            .tarotSheetBackground()
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

// MARK: - Cabecera de posición — overline editorial + nombre de posición
private struct DrawnCardDetailHeader: View {
    let drawn: DrawnCard
    @State private var appeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            EyebrowLabel(text: "Posición en la tirada")

            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(drawn.position.displayName)
                    .font(.system(size: 21, weight: .bold, design: .serif))
                    .tracking(-0.3)
                    .foregroundStyle(Color.tarotIvory)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Spacer()

                Image(systemName: "sparkle")
                    .font(.system(size: 11, weight: .light))
                    .foregroundStyle(Color.tarotGold.opacity(0.75))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 12)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
        .onAppear {
            withAnimation(LuxuryAnimation.softSpring) { appeared = true }
        }
        .accessibilityElement(children: .combine)
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
            HapticManager.shared.triggerLight()
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
