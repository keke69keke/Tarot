import SwiftUI
import TarotCore
import TarotData

struct LibraryView: View {
    @ObservedObject var model: TarotViewModel
    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(model.visibleCards) { card in
                        NavigationLink {
                            CardDetailView(card: card, orientation: .upright, repository: model.container.cards, activeDeck: model.settings.activeDeck, cardBackDesign: model.settings.cardBackDesign)
                        } label: {
                            HStack(spacing: 14) {
                                CardFace(name: card.name, imageName: card.imageName, textureName: card.textureImageName, reversed: false, useTexture: true, size: CGSize(width: 60, height: 90), activeDeck: model.settings.activeDeck)
                                    .shadow(color: .black.opacity(0.20), radius: 6, x: 0, y: 3)
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(card.name)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    Text(card.suit?.displayName ?? "Arcano Mayor")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    HStack(spacing: 6) {
                                        Text(card.arcanaType == .major ? "Mayor" : "Menor")
                                            .font(.caption2.weight(.semibold))
                                            .padding(.horizontal, 7)
                                            .padding(.vertical, 3)
                                            .background(Capsule().fill(card.arcanaType == .major ? Color.tarotGold.opacity(0.18) : Color.tarotBurgundy.opacity(0.14)))
                                            .foregroundStyle(card.arcanaType == .major ? Color.tarotGold : Color.tarotBurgundy)
                                        if let number = card.number, !number.isEmpty {
                                            Text(number)
                                                .font(.caption2)
                                                .foregroundStyle(.tertiary)
                                        }
                                    }
                                }
                                Spacer()
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 4)
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    }
                }
            }
            .searchable(text: $model.searchQuery, prompt: "Buscar carta, número o palo")
            .listStyle(.plain)
            .listRowSeparator(.hidden)
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .navigationTitle("Biblioteca")
        }
    }
}
