import SwiftUI
import TarotCore
import TarotData


@MainActor final class TarotViewModel: ObservableObject {
    @Published var selectedSpread: SpreadType = .threeCard
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
    let container: AppContainer
    private let drawUseCase: DrawCardsUseCaseProtocol

    init(container: AppContainer) {
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
                let spread = Spread(type: selectedSpread, drawnCards: [], createdAt: Date())
                let result = try await drawUseCase.execute(for: spread)
                var drawn = result.drawnCards

                if useSignificator, let sig = significatorCard {
                    let sigPosition = SpreadPosition(name: "Significador", displayName: "Tu Carta", description: "La carta que te representa en esta lectura")
                    let sigDrawn = DrawnCard(card: sig, position: sigPosition, orientation: .upright)
                    drawn.removeAll { $0.card.id == sig.id }
                    drawn.insert(sigDrawn, at: 0)
                }

                self.spread = Spread(type: selectedSpread, drawnCards: drawn, createdAt: Date())
            } catch {
                self.errorMessage = error.localizedDescription
            }
            self.isShuffling = false
        }
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
                let result = try await drawUseCase.execute(for: currentSpread)
                self.spread = Spread(type: currentSpread.type ?? selectedSpread, drawnCards: result.drawnCards, createdAt: currentSpread.createdAt ?? Date())
            } catch {
                self.errorMessage = error.localizedDescription
            }
            self.isShuffling = false
        }
    }

    func persistSettings() { container.settings.save(settings) }
}
