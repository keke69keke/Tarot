import SwiftUI
import TarotCore
import TarotData
import TarotDI

enum JournalViewMode {
    case list, map
}

struct JournalView: View { 
    @ObservedObject var model: TarotViewModel
    @State private var viewMode: JournalViewMode = .list

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Luxury Mode Selector
                HStack {
                    Spacer()
                    HStack(spacing: 0) {
                        modeButton(title: "Diario", mode: .list)
                        modeButton(title: "Mapa", mode: .map)
                    }
                    .padding(4)
                    .background(Capsule().fill(Color.white.opacity(0.05)))
                    .overlay(Capsule().stroke(Color.white.opacity(0.08), lineWidth: 0.5))
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)

                ZStack {
                    if viewMode == .list {
                        listContent
                            .transition(.asymmetric(insertion: .move(edge: .leading).combined(with: .opacity), removal: .opacity))
                    } else {
                        mapContent
                            .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .opacity))
                    }
                }
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: viewMode)
            }
            .navigationTitle(TarotStrings.journalTitle.localized)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.clear, for: .navigationBar)
            #endif
            .tarotNightBackground()
        }
    }


    private var listContent: some View {
        Group {
            if model.entries.isEmpty {
                emptyListView
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 20) {
                        LuxuryPageHeader(
                            eyebrow: "Diario",
                            title: TarotStrings.journalTitle.localized
                        )

                        ForEach(model.entries) { entry in
                            NavigationLink {
                                JournalDetail(
                                    entry: entry,
                                    repository: model.container.cards,
                                    activeDeck: model.settings.activeDeck,
                                    cardBackDesign: model.settings.cardBackDesign,
                                    reflectionService: model.container.reflection,
                                    onSaveResponse: { response in
                                        var updatedEntry = entry
                                        updatedEntry.reflectionResponse = response
                                        try? model.container.journal.save(entry: updatedEntry)
                                        model.reloadEntries()
                                    }
                                )
                            } label: {
                                editorialEntryCard(entry: entry)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                }
            }
        }
    }

    private func editorialEntryCard(entry: JournalEntry) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                EyebrowLabel(text: entry.spread.type?.label.uppercased() ?? "TIRADA")
                Spacer()
                Text(entry.savedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 10, weight: .regular, design: .serif))
                    .foregroundStyle(Color.tarotIvory.opacity(0.35))
            }

            GoldDivider(opacity: 0.15)

            HStack(spacing: -8) {
                ForEach(entry.spread.drawnCards.prefix(5)) { drawn in
                    CardFace(
                        name: drawn.card.name,
                        imageName: drawn.card.imageName,
                        textureName: drawn.card.textureImageName,
                        reversed: drawn.orientation == .reversed,
                        back: false,
                        useTexture: true,
                        size: CGSize(width: 32, height: 48),
                        activeDeck: model.settings.activeDeck,
                        backDesign: model.settings.cardBackDesign
                    )
                    .shadow(color: Color.black.opacity(0.3), radius: 3, x: 0, y: 2)
                }
                if entry.spread.drawnCards.count > 5 {
                    Text("+\(entry.spread.drawnCards.count - 5)")
                        .font(.system(size: 11, weight: .semibold, design: .serif))
                        .foregroundStyle(Color.tarotGold.opacity(0.6))
                        .padding(.leading, 12)
                }
            }

            Text(entry.spread.drawnCards.map { $0.card.name }.joined(separator: "  ·  "))
                .font(.system(size: 13, weight: .regular, design: .serif))
                .foregroundStyle(Color.tarotIvory.opacity(0.75))
                .lineLimit(2)
                .tracking(0.1)
                .truncationMode(.tail)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: LuxuryRadius.md, style: .continuous)
                .fill(Color.white.opacity(0.03))
                .background(
                    RoundedRectangle(cornerRadius: LuxuryRadius.md, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .opacity(0.4)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: LuxuryRadius.md, style: .continuous)
                        .stroke(
                            LinearGradient(colors: [.tarotGold.opacity(0.2), .clear, .tarotGold.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: 0.8
                        )
                )
        )
        .shadow(color: Color.black.opacity(0.2), radius: 12, x: 0, y: 6)
    }

    private var mapContent: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 20) {
                DestinyGraphView()
                GrowthPathView()
            }
            .padding()
        }
    }

    private func modeButton(title: String, mode: JournalViewMode) -> some View {
        Button {
            withAnimation(LuxuryAnimation.softSpring) { viewMode = mode }
        } label: {
            Text(title)
                .font(.system(size: 12, weight: .medium, design: .serif))
                .tracking(0.5)
                .foregroundStyle(viewMode == mode ? Color.tarotGold : Color.tarotIvory.opacity(0.4))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Group {
                        if viewMode == mode {
                            Capsule().fill(Color.tarotGold.opacity(0.15))
                        } else {
                            Color.clear
                        }
                    }
                )
                .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }

    private var emptyListView: some View {
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
    }
}
