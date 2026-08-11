import SwiftUI
import TarotCore

/// Premium staggered card grid for the Library with entrance animations,
/// grouped by arcana type and suit, and a search overlay.
struct LibraryGridView: View {
    let repository: any CardRepository
    @StateObject private var model: LibraryGridModel

    init(repository: any CardRepository, activeDeck: DeckType = .riderWaite, cardBackDesign: CardBackDesign = .classic) {
        self.repository = repository
        _model = StateObject(wrappedValue: LibraryGridModel(repository: repository, activeDeck: activeDeck, cardBackDesign: cardBackDesign))
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(alignment: .leading, spacing: 24) {
                        // Search bar
                        searchBar
                            .padding(.horizontal)
                            .padding(.top, 8)

                        if model.query.isEmpty {
                            arcanaSections
                        } else {
                            searchResults
                        }
                    }
                    .padding(.bottom, 30)
                }
                .searchable(text: $model.query, prompt: "Buscar carta, número o palo")
                .navigationTitle("Biblioteca")
            }
        }
    }

    // MARK: - Search Bar
    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.tarotAccent)
            TextField("Buscar carta, número o palo", text: $model.query)
                .textFieldStyle(.plain)
                .foregroundStyle(.primary)
            if !model.query.isEmpty {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        model.query = ""
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.tarotPanel.opacity(0.90))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.tarotAccent.opacity(0.25), lineWidth: 1)
        )
    }

    // MARK: - Sections by Arcana
    private var arcanaSections: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Major Arcana
            let majors = repository.cards(in: .majorArcana)
            if !majors.isEmpty {
                gridSection(title: "Arcanos Mayores", subtitle: "\(majors.count) cartas", cards: majors)
            }

            // Minor Arcana by suit
            ForEach(CardSuit.allCases, id: \.self) { suit in
                let minors = repository.cards(in: .minorArcana(suit: suit))
                if !minors.isEmpty {
                    gridSection(title: suit.displayName, subtitle: "\(minors.count) cartas", cards: minors)
                }
            }
        }
    }

    private func gridSection(title: String, subtitle: String, cards: [Card]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(.system(size: 18, weight: .bold, design: .serif))
                    .foregroundStyle(.primary)
                Spacer()
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 12)], spacing: 14) {
                ForEach(cards) { card in
                    NavigationLink {
                        CardDetailView(card: card, orientation: .upright, repository: repository, activeDeck: model.activeDeck, cardBackDesign: model.cardBackDesign)
                    } label: {
                        LibraryCardCell(card: card, activeDeck: model.activeDeck, cardBackDesign: model.cardBackDesign)
                    }
                    .buttonStyle(.plain)
                    .simultaneousGesture(TapGesture().onEnded {
                        TarotAudioService.shared.playCardSelect()
                    })
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Search Results
    private var searchResults: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(model.results.count) resultados")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            if model.results.isEmpty {
                VStack(spacing: 14) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 44))
                        .foregroundStyle(.secondary)
                    Text("Sin resultados para “\(model.query)”")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 50)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 12)], spacing: 14) {
                    ForEach(model.results) { card in
                        NavigationLink {
                            CardDetailView(card: card, orientation: .upright, repository: repository, activeDeck: model.activeDeck, cardBackDesign: model.cardBackDesign)
                        } label: {
                            LibraryCardCell(card: card, activeDeck: model.activeDeck, cardBackDesign: model.cardBackDesign)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Library Card Cell
private struct LibraryCardCell: View {
    let card: Card
    let activeDeck: DeckType
    let cardBackDesign: CardBackDesign
    @State private var isPressed = false

    var body: some View {
        VStack(spacing: 8) {
            CardFace(
                name: card.name,
                imageName: card.imageName,
                textureName: card.textureImageName,
                reversed: false,
                useTexture: true,
                size: CGSize(width: 96, height: 144),
                activeDeck: activeDeck,
                backDesign: cardBackDesign
            )
            .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 5)
            .scaleEffect(isPressed ? 0.94 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)

            Text(card.name)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.tarotPanel.opacity(0.85))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(card.arcanaType == .major ? Color.tarotAccent.opacity(0.4) : Color.tarotBorder, lineWidth: 1)
        )
        .onLongPressGesture(minimumDuration: 0.05, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(card.name), \(card.arcanaType == .major ? "Arcano Mayor" : "Arcano Menor")"
        )
    }
}

// MARK: - Library Grid Model
@MainActor
final class LibraryGridModel: ObservableObject {
    @Published var query: String = ""
    @Published var activeDeck: DeckType
    @Published var cardBackDesign: CardBackDesign

    private let repository: any CardRepository

    init(repository: any CardRepository, activeDeck: DeckType = .riderWaite, cardBackDesign: CardBackDesign = .classic) {
        self.repository = repository
        self.activeDeck = activeDeck
        self.cardBackDesign = cardBackDesign
    }

    var results: [Card] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        return repository.search(query: trimmed)
    }
}
