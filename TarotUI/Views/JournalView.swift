import SwiftUI
import TarotCore
import TarotData

struct JournalView: View {
    @ObservedObject var model: TarotViewModel
    var body: some View {
        NavigationStack {
            Group {
                if model.entries.isEmpty {
                    VStack(spacing: 22) {
                        ZStack {
                            Circle()
                                .fill(Color.tarotGold.opacity(0.10))
                                .frame(width: 110, height: 110)
                            Image(systemName: "book.closed.fill")
                                .font(.system(size: 52))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color.tarotGold, Color.tarotBurgundy],
                                        startPoint: .topLeading, endPoint: .bottomTrailing
                                    )
                                )
                        }
                        .shadow(color: Color.tarotGold.opacity(0.25), radius: 18, x: 0, y: 8)

                        Text("Aún no hay lecturas guardadas")
                            .font(.title3.bold())
                            .foregroundStyle(.primary)
                        Text("Guarda tus tiradas aquí y vuelve a consultarlas cuando quieras.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                } else {
                    List {
                        ForEach(model.entries) { entry in
                            NavigationLink {
                                JournalDetail(entry: entry, repository: model.container.cards, activeDeck: model.settings.activeDeck, cardBackDesign: model.settings.cardBackDesign)
                            } label: {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(entry.spread.type?.label ?? "Tirada")
                                        .font(.headline)
                                    Text(entry.savedAt.formatted(date: .abbreviated, time: .shortened))
                                        .foregroundStyle(.secondary)
                                    Text(entry.spread.drawnCards.map { $0.card.name }.joined(separator: " · "))
                                        .lineLimit(1)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(14)
                                .background(Color.tarotPanel.opacity(0.88))
                                .cornerRadius(18)
                            }
                        }
                        .onDelete { offsets in offsets.map { model.entries[$0] }.forEach(model.delete) }
                        .listRowBackground(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(Color.tarotPanel.opacity(0.88))
                                .shadow(color: Color.tarotShadow.opacity(0.15), radius: 8, x: 0, y: 4)
                                .padding(.vertical, 4)
                        )
                        .listRowSeparator(.hidden)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                }
            }
            .navigationTitle("Diario")
        }
    }
}
