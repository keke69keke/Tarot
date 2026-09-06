import SwiftUI
import TarotCore
import TarotData

struct JournalDetail: View {
    let entry: JournalEntry
    let repository: any CardRepository
    let activeDeck: DeckType
    let cardBackDesign: CardBackDesign
    let reflectionService: ReflectionServiceProtocol
    var onSaveResponse: ((String) -> Void)?

    @State private var reflectionResponse = ""
    @State private var mirrorResponse: String? = nil
    @State private var isReflecting = false

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                // Header info
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "calendar")
                            .font(.caption)
                            .foregroundStyle(Color.tarotGold)
                        Text(entry.savedAt.formatted(date: .long, time: .shortened))
                            .font(.system(size: 13, design: .serif))
                            .foregroundStyle(Color.tarotIvory.opacity(0.58))
                    }
                    Text(entry.spread.type?.label ?? "Tirada")
                        .font(.system(size: 22, weight: .bold, design: .serif))
                        .foregroundStyle(Color.tarotIvory)
                    Text("\(entry.spread.drawnCards.count) cartas")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.tarotGold)
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color.tarotPanel.opacity(0.92))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.tarotGold.opacity(0.30), lineWidth: 1)
                )

                // Cards in the spread
                VStack(alignment: .leading, spacing: 12) {
                    Label("Cartas de la tirada", systemImage: "rectangle.stack")
                        .font(.system(size: 14, weight: .bold, design: .serif))
                        .foregroundStyle(Color.tarotGold)

                    ForEach(entry.spread.drawnCards, id: \.card.id) { drawn in
                        NavigationLink {
                            CardDetailView(drawn: drawn, repository: repository)
                        } label: {
                            HStack(spacing: 14) {
                                CardFace(
                                    name: drawn.card.name,
                                    imageName: drawn.card.imageName,
                                    textureName: drawn.card.textureImageName,
                                    reversed: drawn.orientation == .reversed,
                                    useTexture: true,
                                    size: CGSize(width: 52, height: 78),
                                    activeDeck: activeDeck,
                                    backDesign: cardBackDesign
                                )
                                .shadow(color: .black.opacity(0.20), radius: 6, x: 0, y: 3)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(drawn.position.displayName)
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(Color.tarotGold)
                                    Text(drawn.card.name)
                                        .font(.system(size: 15, weight: .semibold, design: .serif))
                                        .foregroundStyle(Color.tarotIvory)
                                    if drawn.orientation == .reversed {
                                        Label("Invertida", systemImage: "arrow.down.circle")
                                            .font(.caption2)
                                            .foregroundStyle(Color.tarotBurgundy)
                                    }
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(Color.tarotPanel.opacity(0.88))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(Color.tarotBorder, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }

                // Soul Dialogue (Reflection)
                if let prompt = entry.reflectionPrompt {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(Color.tarotGold)
                            Text("Diálogo del Alma")
                                .font(.system(size: 14, weight: .bold, design: .serif))
                                .foregroundStyle(Color.tarotGold)
                        }

                        Text(prompt)
                            .font(.system(size: 15, design: .serif))
                            .foregroundStyle(Color.tarotIvory)
                            .lineSpacing(4)
                            .italic()

                        TextField("Escribe tu reflexión...", text: $reflectionResponse)
                            .font(.system(size: 14, design: .serif))
                            .foregroundStyle(Color.tarotIvory)
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.white.opacity(0.05)))
                            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.tarotGold.opacity(0.2), lineWidth: 0.75))
                            .onSubmit {
                                Task {
                                    onSaveResponse?(reflectionResponse)
                                    await reflect()
                                }
                            }

                        if let mirror = mirrorResponse {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "mirror")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(Color.tarotGold)
                                    Text("Reflejo del Alma")
                                        .font(.system(size: 14, weight: .bold, design: .serif))
                                        .foregroundStyle(Color.tarotGold)
                                }
                                Text(mirror)
                                    .font(.system(size: 15, design: .serif))
                                    .foregroundStyle(Color.tarotIvory)
                                    .lineSpacing(6)
                                    .italic()
                            }
                            .padding(20)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 22, style: .continuous)
                                    .fill(Color.tarotPanel.opacity(0.6))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 22, style: .continuous)
                                    .stroke(Color.tarotGold.opacity(0.15), lineWidth: 1)
                            )
                            .transition(.asymmetric(insertion: .move(edge: .bottom).combined(with: .opacity), removal: .opacity))
                        } else if isReflecting {
                            ProgressView()
                                .tint(Color.tarotGold)
                                .padding()
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(Color.tarotPanel.opacity(0.88))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(Color.tarotGold.opacity(0.2), lineWidth: 1)
                    )
                }

                // Notes (if any)
                if !entry.notes.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Notas del diario", systemImage: "pencil.line")
                            .font(.system(size: 14, weight: .bold, design: .serif))
                            .foregroundStyle(Color.tarotGold)

                        Text(entry.notes)
                            .font(.system(size: 15, design: .serif))
                            .foregroundStyle(Color.tarotIvory)
                            .lineSpacing(6)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(Color.tarotPanel.opacity(0.88))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(Color.tarotBorder, lineWidth: 1)
                    )
                }

                Spacer(minLength: 24)
            }
            .padding(20)
        }
        .navigationTitle(entry.spread.type?.label ?? "Tirada")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    private func reflect() async {
        guard !reflectionResponse.isEmpty else { return }
        isReflecting = true
        do {
            mirrorResponse = try await reflectionService.reflect(on: reflectionResponse, context: entry)
        } catch {
            mirrorResponse = "El espejo está nublado en este momento. Intenta reflexionar nuevamente."
        }
        isReflecting = false
    }
}
/// Summative card that synthesizes the full spread into a coherent narrative.
