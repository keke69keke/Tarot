import SwiftUI
import TarotCore
import TarotData
import TarotDI

@MainActor final class TarotViewModel: ObservableObject {
    @Published var selectedSpread: SpreadType = .threeCard {
        didSet {
            if oldValue != selectedSpread {
                // La tirada mostrada corresponde al tipo anterior — invalidarla hasta nuevo Barajar
                spread = nil
            }
        }
    }
    @Published var spread: Spread?
    @Published var isShuffling = false
    @Published var entries: [JournalEntry] = []
    @Published var searchQuery = ""
    @Published var settings: UserSettings
    @Published var dailyCard: Card
    @Published var dailyRevealed: Bool
    @Published var errorMessage: String?
    @Published var readingIntention: String = ""
    @Published var useSignificator: Bool = false
    @Published var significatorCard: Card?
    /// Number of cards used by the "Tirada Libre" spread.
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
    /// Cards the user chooses to be the first ones that come out of the deck
    /// (slot 0 and slot 1 of the spread).
    @Published var firstCardChoice: Card? = nil
    @Published var secondCardChoice: Card? = nil

    let container: any AppContainerProtocol
    private let drawUseCase: DrawCardsUseCaseProtocol

    init(container: any AppContainerProtocol) {
        self.container = container
        settings = container.settings.load()
        dailyCard = container.daily.dailyCard(for: .now)
        dailyRevealed = container.daily.isRevealed(for: .now)
        drawUseCase = DrawCardsUseCase(cardRepository: container.cards, synthesizer: container.spreadSynthesizer)
        reloadEntries()
    }

    var visibleCards: [Card] { searchQuery.isEmpty ? container.cards.allCards() : container.cards.search(query: searchQuery) }

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

                // Place the user-chosen "first cards" at the front (order of appearance).
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

    /// Positions used for the current spread, honouring the free count when selected.
    func positionsForSelectedSpread() -> [SpreadPosition] {
        if selectedSpread == .free {
            return (1...freeCardCount).map { i in
                SpreadPosition(name: "Carta \(i)", displayName: "Carta \(i)",
                               description: "Posición libre \(i) de tu tirada.")
            }
        }
        return selectedSpread.positions
    }

    /// Moves the user-chosen first cards to the head of the spread (slots 0 and 1),
    /// respetando el significador si está presente.
    private func applyChosenFirstCards(to drawn: [DrawnCard], positions: [SpreadPosition]) -> [DrawnCard] {
        let chosen = [firstCardChoice, secondCardChoice].compactMap { $0 }
        guard !chosen.isEmpty else { return drawn }

        // Detecta si el mazo ya contiene significador en índice 0
        let hasSigAtFront: Bool = {
            guard useSignificator, let sig = significatorCard, !drawn.isEmpty else { return false }
            return drawn.first?.card.id == sig.id
        }()
        let offset = hasSigAtFront ? 1 : 0

        var placed = drawn.filter { dc in !chosen.contains { $0.id == dc.card.id } }
        for (slot, card) in chosen.enumerated() {
            let targetIndex = offset + slot
            let pos = positions.indices.contains(slot)
                ? positions[slot]
                : SpreadPosition(name: "Carta \(slot + 1)", displayName: "Carta \(slot + 1)")
            // Si hay significador, mantenlo al frente y coloca elegidas justo después
            placed.insert(DrawnCard(card: card, position: pos, orientation: .upright), at: min(targetIndex, placed.count))
        }
        return placed
    }

    /// Clear both chosen first-card slots.
    func clearChosenFirstCards() {
        firstCardChoice = nil
        secondCardChoice = nil
    }

    func saveSpread(notes: String = "") {
        guard let spread else { return }
        var fullNotes = notes
        if !readingIntention.isEmpty {
            fullNotes = "🎯 Intención: \(readingIntention)" + (notes.isEmpty ? "" : "\n\n\(notes)")
        }
        do { try container.journal.save(entry: JournalEntry(spread: spread, notes: fullNotes)); reloadEntries() }
        catch { errorMessage = error.localizedDescription }
    }

    func reloadEntries() { entries = container.journal.fetchAll() }
    func delete(_ entry: JournalEntry) { do { try container.journal.delete(id: entry.id); reloadEntries() } catch { errorMessage = error.localizedDescription } }
    func revealDaily() { container.daily.markRevealed(for: .now); withAnimation { dailyRevealed = true } }

    func replaceCard(at index: Int, with card: Card) {
        guard var spread = spread, spread.drawnCards.indices.contains(index) else { return }
        let currentOrientation = spread.drawnCards[index].orientation
        spread.drawnCards[index] = DrawnCard(card: card, position: spread.drawnCards[index].position, orientation: currentOrientation)
        self.spread = spread
    }

    func reshuffleCurrentSpread() {
        guard let currentSpread = spread else { return }
        isShuffling = true
        Task { @MainActor in
            do {
                let positions = currentSpread.standardPositions.isEmpty
                    ? positionsForSelectedSpread()
                    : currentSpread.standardPositions
                var drawn = try await drawUseCase.execute(for: currentSpread).drawnCards

                // Preserva significador si la tirada actual lo tenía o si el toggle sigue activo
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

    func persistSettings() { container.settings.save(settings) }
}
