import SwiftUI
import TarotCore
import TarotData

struct ReadingRevelationView: View {
    @ObservedObject var model: TarotViewModel
    @Binding var revealedIndices: Set<Int>
    @Binding var selectedDrawnCard: DrawnCard?
    @Binding var replacementIndex: Int?
    @Binding var isShowingReplacementPicker: Bool
    @Binding var notes: String
    @Binding var isRitualActive: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            ZStack {
                SoulAuraView(state: model.container.biometrics.soulState)
                    .opacity(0.6)
                    .blur(radius: 40)

                revealedSpreadContent
            }
            .padding(.vertical, 20)
        }
    }

    private var revealedSpreadContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            if let spread = model.spread, !spread.drawnCards.isEmpty {
                SpreadDiagramView(
                    spread: spread,
                    repository: model.container.cards,
                    revealedIndices: revealedIndices,
                    activeDeck: model.settings.activeDeck,
                    cardBackDesign: model.settings.cardBackDesign,
                    onSelectCard: { drawn in selectedDrawnCard = drawn },
                    onReplaceCard: { index, _ in
                        replacementIndex = index
                        isShowingReplacementPicker = true
                    },
                    onRevealCard: { index in
                        withAnimation(LuxuryAnimation.softSpring) { _ = revealedIndices.insert(index) }
                    }
                )
                .padding(.horizontal, 4)
            } else {
                emptySpreadContent
            }

            if model.currentSynthesis == nil {
                synthesisTriggerButton
            } else {
                synthesisPanel
            }

            notesSection

            HStack(spacing: 12) {
                Spacer()
                saveButton
                reshuffleButton
                Spacer()
            }
            .frame(minHeight: 44)

            Text(TarotStrings.holdToReplace.localized)
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)
        }
    }

    private var synthesisTriggerButton: some View {
        Button {
            HapticManager.shared.triggerMedium()
            Task { await model.revealSynthesis() }
        } label: {
            VStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.system(size: 24, weight: .light))
                    .foregroundStyle(Color.tarotGold)
                Text("Revelar Significado Sagrado")
                    .font(.system(size: 16, weight: .semibold, design: .serif))
                    .tracking(1.0)
                    .foregroundStyle(Color.tarotIvory)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.tarotGold.opacity(0.08))
                    .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(Color.tarotGold.opacity(0.3), lineWidth: 1))
            )
            .shadow(color: Color.tarotGold.opacity(0.1), radius: 20)
        }
        .buttonStyle(.plain)
        .disabled(model.isSynthesizing)
        .opacity(model.isSynthesizing ? 0.6 : 1)
    }

    private var synthesisPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.tarotGold)
                Text("Sintetizando el Destino")
                    .font(.system(size: 14, weight: .bold, design: .serif))
                    .foregroundStyle(Color.tarotGold)
            }
            .padding(.horizontal, 4)

            Text(model.currentSynthesis ?? "")
                .font(.system(size: 15, weight: .regular, design: .serif))
                .foregroundStyle(Color.tarotIvory.opacity(0.9))
                .lineSpacing(6)
                .multilineTextAlignment(.leading)
                .padding(20)
                .luxuryGlass(cornerRadius: LuxuryRadius.md)
                .padding(.horizontal, 4)
        }
        .transition(.asymmetric(insertion: .opacity.combined(with: .move(edge: .bottom)), removal: .opacity))
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            EyebrowLabel(text: TarotStrings.readingNotesTitle.localized)
            TextEditor(text: $notes)
                .font(.system(size: 13, weight: .regular, design: .serif))
                .lineSpacing(3)
                #if os(iOS)
                                .scrollContentBackground(.hidden)
                                #endif
                .padding(10)
                .frame(minHeight: 84)
                .luxuryGlass(cornerRadius: LuxuryRadius.sm)
        }
        .padding(.horizontal, 4)
    }

    private var saveButton: some View {
        Button {
            Task {
                await model.saveSpread(notes: notes)
                withAnimation(LuxuryAnimation.softSpring) {
                    notes = ""
                }
            }
            HapticManager.shared.triggerSuccess()
        } label: {
            Text(TarotStrings.saveReading.localized.uppercased())
                .font(.system(size: 12.5, weight: .semibold, design: .serif))
                .tracking(1.0)
                .foregroundStyle(Color(red: 0.09, green: 0.06, blue: 0.02))
                .padding(.horizontal, 24)
                .padding(.vertical, 13)
                .background(Capsule().fill(Color.tarotGoldGradient))
                .overlay(Capsule().stroke(Color.white.opacity(0.32), lineWidth: 0.7).blendMode(.softLight))
                .shadow(color: Color.black.opacity(0.32), radius: 16, x: 0, y: 8)
                .shadow(color: Color.tarotGold.opacity(0.18), radius: 16, x: 0, y: 0)
        }
        .buttonStyle(.plain)
    }

    private var reshuffleButton: some View {
        Button {
            withAnimation(LuxuryAnimation.softSpring) {
                model.reshuffleCurrentSpread()
                revealedIndices.removeAll()
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "arrow.triangle.2.circlepath").font(.system(size: 11, weight: .light))
                Text(TarotStrings.reshuffle.localized)
                    .font(.system(size: 12, weight: .medium, design: .serif))
                    .tracking(0.2)
            }
            .foregroundStyle(Color.tarotGold.opacity(0.95))
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(Capsule().fill(Color.white.opacity(0.05)).background(Capsule().fill(.ultraThinMaterial).opacity(0.42)))
            .overlay(Capsule().stroke(Color.white.opacity(0.09), lineWidth: 0.75))
        }
        .buttonStyle(.plain)
    }

    private var emptySpreadContent: some View {
        VStack(spacing: 18) {
            Button {
                isRitualActive = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "sparkles").font(.system(size: 12, weight: .light))
                    Text(TarotStrings.shuffleAndReveal.localized.uppercased())
                        .font(.system(size: 13, weight: .semibold, design: .serif))
                        .tracking(1.0)
                }
                .foregroundStyle(Color(red: 0.09, green: 0.06, blue: 0.02))
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background(Capsule().fill(Color.tarotGoldGradient))
                .overlay(Capsule().stroke(Color.white.opacity(0.34), lineWidth: 0.75).blendMode(.softLight))
                .shadow(color: Color.black.opacity(0.34), radius: 18, x: 0, y: 10)
                .shadow(color: Color.tarotGold.opacity(0.18), radius: 20, x: 0, y: 0)
            }
            .buttonStyle(.plain)
            .disabled(model.isShuffling)
            .opacity(model.isShuffling ? 0.72 : 1)

            if model.isShuffling {
                VStack(spacing: 10) {
                    ProgressView().tint(Color.tarotGold)
                    Text(TarotStrings.shuffling.localized)
                        .font(.system(size: 11, weight: .medium, design: .serif))
                        .tracking(0.8)
                        .foregroundStyle(Color.tarotIvory.opacity(0.52))
                }
            }
        }
        .padding(.vertical, 28)
    }
}
