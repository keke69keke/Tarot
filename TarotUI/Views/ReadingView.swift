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
            .background(StarfieldBackgroundView(starCount: 90))
            .navigationTitle(model.spread?.type?.label ?? "Tirada")
            .toolbar {
                // Back to preparation: lets the user choose a different spread type
                if ritualPhase == .revelation {
                    #if os(iOS)
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
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
                        } label: {
                            Label("Cambiar tirada", systemImage: "chevron.left.circle")
                                .font(.system(size: 12, weight: .medium, design: .serif))
                                .foregroundStyle(Color.tarotIvory)
                        }
                    }
                    #else
                    // macOS: ToolbarItem with navigationBarLeading not available
                    #endif
                }

                ToolbarItem(placement: .automatic) {
                    if let spread = model.spread, !spread.drawnCards.isEmpty {
                        Button(TarotStrings.revealAll.localized) {
                            revealAll()
                        }
                    }
                }
            }
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
        .alert(TarotStrings.errorTitle.localized, isPresented: Binding(get: { model.errorMessage != nil }, set: { if !$0 { model.errorMessage = nil } })) {
            Button(TarotStrings.ok.localized, role: .cancel) {}
        } message: {
            Text(model.errorMessage ?? "")
        }
        .onAppear {
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
        .onChange(of: model.isShuffling) { shuffling in
            if !shuffling, model.spread != nil, ritualPhase == .preparation {
                withAnimation(LuxuryAnimation.softSpring) {
                    ritualPhase = .revelation
                }
            }
        }
    }

    private func revealAll() {
        guard let spread = model.spread else { return }
        HapticManager.shared.triggerMedium()
        withAnimation(.easeInOut(duration: 0.6)) {
            revealedIndices = Set(0..<spread.drawnCards.count)
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
                    .textFieldStyle(.roundedBorder)
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
