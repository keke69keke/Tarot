import SwiftUI
import TarotCore
import TarotData
import TarotDI

struct JournalView: View {
    @ObservedObject var model: TarotViewModel
    var body: some View {
        NavigationStack {
            Group {
                if model.entries.isEmpty {
                    VStack(spacing: 18) {
                        ZStack {
                            Circle()
                                .fill(Color.tarotGold.opacity(0.07))
                                .frame(width: 110, height: 110)
                                .blur(radius: 18)
                            Circle()
                                .stroke(Color.tarotGold.opacity(0.14), lineWidth: 0.85)
                                .frame(width: 110, height: 110)
                            Image(systemName: "text.book.closed")
                                .font(.system(size: 34, weight: .thin))
                                .foregroundStyle(Color.tarotGold.opacity(0.85))
                        }
                        .shadow(color: Color.black.opacity(0.18), radius: 16, x: 0, y: 8)

                        VStack(spacing: 8) {
                            Text(TarotStrings.emptyJournalTitle.localized)
                                .font(.system(size: 18, weight: .semibold, design: .serif))
                                .tracking(-0.2)
                                .foregroundStyle(Color.tarotIvory)
                                .multilineTextAlignment(.center)
                            Text(TarotStrings.emptyJournalMessage.localized)
                                .font(.system(size: 13, weight: .regular, design: .serif))
                                .foregroundStyle(Color.tarotIvory.opacity(0.56))
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                                .padding(.horizontal, 28)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                } else {
                    List {
                        ForEach(model.entries) { entry in
                            NavigationLink {
                                JournalDetail(entry: entry, repository: model.container.cards, activeDeck: model.settings.activeDeck, cardBackDesign: model.settings.cardBackDesign)
                            } label: {
                                VStack(alignment: .leading, spacing: 7) {
                                    HStack(spacing: 8) {
                                        EyebrowLabel(text: entry.spread.type?.label.uppercased() ?? "TIRADA")
                                        Spacer()
                                        Text(entry.savedAt.formatted(date: .abbreviated, time: .shortened))
                                            .font(.system(size: 11, weight: .regular, design: .serif))
                                            .foregroundStyle(Color.tarotIvory.opacity(0.42))
                                    }
                                    GoldDivider(opacity: 0.10)
                                    // Miniaturas de las cartas de la tirada
                                    HStack(spacing: -8) {
                                        ForEach(entry.spread.drawnCards.prefix(5)) { drawn in
                                            CardFace(
                                                name: drawn.card.name,
                                                imageName: drawn.card.imageName,
                                                textureName: drawn.card.textureImageName,
                                                reversed: drawn.orientation == .reversed,
                                                back: false,
                                                useTexture: true,
                                                size: CGSize(width: 30, height: 45),
                                                activeDeck: model.settings.activeDeck,
                                                backDesign: model.settings.cardBackDesign
                                            )
                                            .shadow(color: Color.black.opacity(0.35), radius: 4, x: 0, y: 2)
                                        }
                                        if entry.spread.drawnCards.count > 5 {
                                            Text("+\(entry.spread.drawnCards.count - 5)")
                                                .font(.system(size: 10, weight: .semibold, design: .serif))
                                                .foregroundStyle(Color.tarotIvory.opacity(0.45))
                                                .padding(.leading, 12)
                                        }
                                    }
                                    Text(entry.spread.drawnCards.map { $0.card.name }.joined(separator: "  ·  "))
                                        .lineLimit(1)
                                        .font(.system(size: 12, weight: .regular, design: .serif))
                                        .foregroundStyle(Color.tarotIvory.opacity(0.72))
                                        .tracking(0.1)
                                        .truncationMode(.tail)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .onDelete { offsets in
                            TarotAudioService.shared.triggerHaptic(.medium)
                            offsets.map { model.entries[$0] }.forEach(model.delete)
                        }
                        .listRowBackground(
                            RoundedRectangle(cornerRadius: LuxuryRadius.md, style: .continuous)
                                .fill(Color.white.opacity(0.045))
                                .background(RoundedRectangle(cornerRadius: LuxuryRadius.md, style: .continuous).fill(.ultraThinMaterial).opacity(0.38))
                                .overlay(RoundedRectangle(cornerRadius: LuxuryRadius.md, style: .continuous).stroke(Color.white.opacity(0.07), lineWidth: 0.7))
                        )
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                }
            }
            .navigationTitle(TarotStrings.journalTitle.localized)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.tarotBackground, for: .navigationBar)
            #endif
        }
    }
}
