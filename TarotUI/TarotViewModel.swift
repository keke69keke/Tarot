import SwiftUI
import TarotCore
import TarotData
import TarotDI
import Combine

@MainActor final class TarotViewModel: ObservableObject {
    /// Tabs obligatorios reexportados para la UI (Settings).
    static let mandatoryTabs: [AppTab] = AppTab.mandatoryTabs

    @Published var selectedSpread: SpreadType = .threeCard {
        didSet {
            if oldValue != selectedSpread {
                spread = nil
            }
        }
    }
    @Published var spread: Spread?
    @Published var isShuffling = false
    @Published var currentSynthesis: String?
    @Published var isSynthesizing = false
    @Published var entries: [JournalEntry] = []
    @Published var searchQuery = ""
    @Published var dailyCard: Card
    @Published var dailyRevealed: Bool
    @Published var errorMessage: String?
    @Published var readingIntention: String = ""
    @Published var useSignificator: Bool = false
    @Published var significatorCard: Card?
    @Published var isDreamReading: Bool = false
    @Published var dreamThemes: String = ""
    @Published var settings: UserSettings
    
    @Published var freeCardCount: Int = 5 {
        didSet {
            if oldValue != freeCardCount, selectedSpread == .free {
                freeCardDebounce?.cancel()
                freeCardDebounce = Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 300_000_000)
                    guard !Task.isCancelled else { return }
                    spread = nil
                }
            }
        }
    }
    private var freeCardDebounce: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()
    private var calmStartedAt: Date?
    
    @Published var firstCardChoice: Card? = nil
    @Published var secondCardChoice: Card? = nil

    let container: any AppContainerProtocol
    private let drawUseCase: DrawCardsUseCaseProtocol

    init(container: any AppContainerProtocol) {
        self.container = container
        self.settings = container.settings.load()
        self.dailyCard = container.daily.dailyCard(for: .now)
        self.dailyRevealed = container.daily.isRevealed(for: .now)
        self.drawUseCase = DrawCardsUseCase(cardRepository: container.cards, synthesizer: container.spreadSynthesizer)
        reloadEntries()
        setupBiometricSync()
    }

    var visibleCards: [Card] { searchQuery.isEmpty ? container.cards.allCards() : container.cards.search(query: searchQuery) }

    func persistSettings() {
        container.settings.save(settings)
    }

    func drawRandomSignificator() {
        significatorCard = container.cards.allCards().randomElement()
    }

    func draw() {
        isShuffling = true
        Task { @MainActor in
            do {
                let positions = positionsForSelectedSpread()
                var drawn = try await drawUseCase.execute(for: Spread(standardPositions: positions)).drawnCards

                if useSignificator, let sig = significatorCard {
                    let sigPosition = SpreadPosition(name: "Significador", displayName: "Tu Carta", description: "La carta que te representa en esta lectura")
                    let sigDrawn = DrawnCard(card: sig, position: sigPosition, orientation: .upright)
                    drawn.removeAll { $0.card.id == sig.id }
                    drawn.insert(sigDrawn, at: 0)
                }

                drawn = applyChosenFirstCards(to: drawn, positions: positions)

                var finalSpread = Spread(standardPositions: positions)
                finalSpread.drawnCards = drawn
                finalSpread.type = selectedSpread
                finalSpread.createdAt = Date()
                self.spread = finalSpread
            } catch {
                self.errorMessage = error.localizedDescription
            }
            self.isShuffling = false
        }
    }

    func positionsForSelectedSpread() -> [SpreadPosition] {
        if selectedSpread == .free {
            return (1...freeCardCount).map { i in
                SpreadPosition(name: "Carta \(i)", displayName: "Carta \(i)",
                               description: "Posición libre \(i) de tu tirada.")
            }
        }
        return selectedSpread.positions
    }

    /// Reconstruye la tirada tras el reparto garantizando:
    /// 1) el significador ocupa la posición 0 cuando está activo,
    /// 2) las cartas elegidas (first/second) caen en sus slots reales,
    /// 3) cada DrawnCard i mapea EXACTAMENTE a positions[i] y el conteo
    ///    final coincide con el de posiciones (p. ej. 12 casas, 10 sefirot).
    /// Antes se insertaban cartas a mitad de lista y se descartaba el resto,
    /// dejando tiradas sin todas sus posiciones ("algunas tiradas no funcionan").
    private func applyChosenFirstCards(to drawn: [DrawnCard], positions: [SpreadPosition]) -> [DrawnCard] {
        let chosen = [firstCardChoice, secondCardChoice].compactMap { $0 }
        let hasSigAtFront: Bool = {
            guard useSignificator, let sig = significatorCard, !drawn.isEmpty else { return false }
            return drawn.first?.card.id == sig.id
        }()
        let chosenIDs = Set(chosen.map { $0.id })

        // 1) El significador ya viene al frente desde draw(); si no, colócalo.
        var pool = drawn
        if useSignificator, let sig = significatorCard, !pool.isEmpty {
            if let idx = pool.firstIndex(where: { $0.card.id == sig.id }), idx != 0 {
                let entry = pool.remove(at: idx)
                pool.insert(entry, at: 0)
            }
        }

        // 2) Fuera las cartas elegidas: se recolocan en sus slots explícitos.
        pool.removeAll { chosenIDs.contains($0.card.id) }

        // 3) Ensamblado determinista: slot 0 = significador (si aplica),
        //    slots siguientes = elecciones del usuario, resto del mazo.
        var queue = pool
        var result: [DrawnCard] = []
        for (slot, position) in positions.enumerated() {
            if slot == 0, useSignificator, let sig = significatorCard {
                result.append(DrawnCard(card: sig, position: position, orientation: .upright))
                continue
            }
            let slotIndex = slot - (hasSigAtFront ? 1 : 0)
            if slotIndex >= 0, slotIndex < chosen.count {
                result.append(DrawnCard(card: chosen[slotIndex], position: position, orientation: .upright))
            } else if !queue.isEmpty {
                result.append(queue.removeFirst())
            } else {
                break
            }
        }
        return result
    }

    func clearChosenFirstCards() {
        firstCardChoice = nil
        secondCardChoice = nil
    }

    func saveSpread(notes: String = "") async {
        guard let spread else { return }
        var fullNotes = notes
        if !readingIntention.isEmpty {
            fullNotes = "◈ Intención: \(readingIntention)" + (notes.isEmpty ? "" : "\n\n\(notes)")
        }

        do {
            let moonPhase = container.lunar.currentPhase()
            let prompts = try await container.reflection.generatePrompts(for: spread, moonPhase: moonPhase)
            let prompt = prompts.first ?? ""

            let entry = JournalEntry(
                spread: spread,
                savedAt: .now,
                moonPhase: moonPhase,
                reflectionPrompt: prompt,
                reflectionResponse: nil,
                isDreamReading: isDreamReading,
                dreamThemes: dreamThemes.isEmpty ? nil : dreamThemes,
                notes: fullNotes,
                isSyncedToCloud: false
            )

            try container.journal.save(entry: entry)
            reloadEntries()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func revealSynthesis() async {
        guard let spread = spread else { return }
        isSynthesizing = true
        do {
            let moonPhase = container.lunar.currentPhase()
            currentSynthesis = try await container.omniIntelligence.synthesizeSummary(for: spread, moonPhase: moonPhase)
        } catch {
            errorMessage = error.localizedDescription
        }
        isSynthesizing = false
    }

    func reloadEntries() { entries = container.journal.fetchAll() }
    func delete(_ entry: JournalEntry) { do { try container.journal.delete(id: entry.id); reloadEntries() } catch { errorMessage = error.localizedDescription } }
    func revealDaily() { container.daily.markRevealed(for: .now); withAnimation { dailyRevealed = true } }

    func checkProactiveInsights() async {
        await container.proactiveGuidance.analyzeForShadowLoops()
        if let suggestion = container.environmentOracle.getEnvironmentalSuggestion() {
            print("Proactive Insight: \(suggestion)")
        }
    }

    func replaceCard(at index: Int, with card: Card) {
        guard var spread = spread, spread.drawnCards.indices.contains(index) else { return }
        let currentOrientation = spread.drawnCards[index].orientation
        spread.drawnCards[index] = DrawnCard(card: card, position: spread.drawnCards[index].position, orientation: currentOrientation)
        self.spread = spread
    }

    func reshuffleCurrentSpread() {
        guard let currentSpread = spread else { return }
        isShuffling = true
        currentSynthesis = nil
        Task { @MainActor in
            do {
                let positions = currentSpread.standardPositions.isEmpty
                    ? positionsForSelectedSpread()
                    : currentSpread.standardPositions
                var drawn = try await drawUseCase.execute(for: currentSpread).drawnCards

                if useSignificator, let sig = significatorCard {
                    let hasSig = currentSpread.drawnCards.first?.card.id == sig.id
                    if hasSig || currentSpread.drawnCards.contains(where: { $0.card.id == sig.id }) || useSignificator {
                        let sigPosition = currentSpread.drawnCards.first { $0.card.id == sig.id }?.position
                            ?? SpreadPosition(name: "Significador", displayName: "Tu Carta", description: "La carta que te representa en esta lectura")
                        let sigDrawn = DrawnCard(card: sig, position: sigPosition, orientation: .upright)
                        drawn.removeAll { $0.card.id == sig.id }
                        drawn.insert(sigDrawn, at: 0)
                    }
                }

                drawn = applyChosenFirstCards(to: drawn, positions: positions)

                var finalSpread = Spread(standardPositions: positions)
                finalSpread.drawnCards = drawn
                finalSpread.type = currentSpread.type ?? selectedSpread
                finalSpread.createdAt = currentSpread.createdAt ?? Date()
                self.spread = finalSpread
            } catch {
                self.errorMessage = error.localizedDescription
            }
            self.isShuffling = false
        }
    }

    private func setupBiometricSync() {
        container.biometrics.$currentHeartRate
            .combineLatest(container.biometrics.$soulState)
            .sink { [weak self] heartRate, state in
                guard let self = self else { return }
                self.container.cosmicBackground.updateForBiometrics(heartRate: heartRate, state: state)
                if let omni = self.container.omniIntelligence as? OmniIntelligenceService {
                    omni.currentSoulState = state
                }
                let dominantPlanet = self.container.planetary.currentDominantPlanet().planet
                TarotAudioService.shared.updateAmbience(dominantPlanet: dominantPlanet, heartRate: heartRate)

                if state == .calm {
                    if self.calmStartedAt == nil {
                        self.calmStartedAt = Date()
                    } else if let start = self.calmStartedAt, Date().timeIntervalSince(start) > 30 {
                        if !self.container.cosmicBackground.isZenMode {
                            self.container.cosmicBackground.setZenMode(true)
                            TarotAudioService.shared.playZenChime()
                        }
                    }
                } else {
                    if self.container.cosmicBackground.isZenMode {
                        self.container.cosmicBackground.setZenMode(false)
                    }
                    self.calmStartedAt = nil
                }
            }
            .store(in: &cancellables)
    }
}
