import SwiftUI
import TarotCore
import TarotData
import TarotDI

struct DailyCardView: View {
    @ObservedObject var model: TarotViewModel
    @State private var halo: CGFloat = 1.0

    /// Texto compartible de la Carta del Día (R11).
    private var dailyShareText: String {
        "◈ \(TarotStrings.dailyCardTitle.localized): \(model.dailyCard.name)"
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 32) {
                // Header editorial
                VStack(alignment: .leading, spacing: 12) {
                    EyebrowLabel(text: "RITUAL  ·  HOY")
                    Text("Carta del día")
                        .font(.system(size: 32, weight: .bold, design: .serif))
                        .tracking(-0.8)
                        .foregroundStyle(Color.tarotIvory)
                    Text("Una sola carta. Luz suficiente para el día.")
                        .font(.system(size: 14, weight: .regular, design: .serif))
                        .foregroundStyle(Color.tarotIvory.opacity(0.56))
                        .lineSpacing(5)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 4)
                .padding(.top, 12)

                // Escenario joya
                ZStack {
                    Ellipse()
                        .fill(Color.tarotGold.opacity(model.dailyRevealed ? 0.12 : 0.06))
                        .frame(width: 380, height: 380)
                        .blur(radius: 40)
                        .scaleEffect(halo)
                        .offset(y: 10)

                    CardFace(
                        name: model.dailyCard.name,
                        imageName: model.dailyCard.imageName,
                        textureName: model.dailyCard.textureImageName,
                        reversed: false,
                        back: !model.dailyRevealed,
                        useTexture: true,
                        size: CGSize(width: 224, height: 336),
                        activeDeck: model.settings.activeDeck,
                        backDesign: model.settings.cardBackDesign
                    )
                    .rotation3DEffect(.degrees(model.dailyRevealed ? 0 : 180), axis: (x: 0, y: 1, z: 0))
                    .shadow(color: Color.black.opacity(0.5), radius: 30, x: 0, y: 16)
                    .shadow(color: Color.tarotGold.opacity(model.dailyRevealed ? 0.22 : 0.08), radius: 24, x: 0, y: 0)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.tarotGold.opacity(model.dailyRevealed ? 0.25 : 0.15), lineWidth: 1)
                    )
                    .scaleEffect(model.dailyRevealed ? 1.0 : 0.98)

                    if !model.dailyRevealed {
                        Button {
                            withAnimation(LuxuryAnimation.softSpring) { model.revealDaily() }
                            TarotAudioService.shared.triggerHaptic(.medium)
                        } label: {
                            VStack(spacing: 10) {
                                Image(systemName: "eye")
                                    .font(.system(size: 18, weight: .thin))
                                    .foregroundStyle(Color.tarotIvory.opacity(0.95))
                                Text("REVELAR")
                                    .font(.system(size: 11, weight: .semibold, design: .serif))
                                    .tracking(1.8)
                                    .foregroundStyle(Color.tarotIvory.opacity(0.75))
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(
                                Capsule()
                                    .fill(Color.black.opacity(0.4))
                                    .background(Capsule().fill(.ultraThinMaterial).opacity(0.5))
                            )
                            .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 0.8))
                            .shadow(color: Color.black.opacity(0.4), radius: 15, x: 0, y: 10)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(height: 400)
                .onAppear { withAnimation(LuxuryAnimation.breathe) { halo = 1.06 } }

                VStack(spacing: 16) {
                    Text(model.dailyRevealed ? "Sincronía del día" : "Toca para revelar")
                        .font(.system(size: 12, weight: .medium, design: .serif))
                        .tracking(0.8)
                        .foregroundStyle(Color.tarotIvory.opacity(0.44))
                        .frame(maxWidth: .infinity)

                    if model.dailyRevealed {
                        VStack(alignment: .leading, spacing: 16) {
                            GoldDivider(opacity: 0.2)
                            CardDetailText(card: model.dailyCard, orientation: .upright, repository: model.container.cards)
                        }
                        .padding(20)
                        .luxuryGlass()
                        .transition(.asymmetric(insertion: .opacity.combined(with: .move(edge: .bottom)), removal: .opacity))

                        ShareLink(item: dailyShareText) {
                            HStack(spacing: 8) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 12, weight: .light))
                                Text("Compartir")
                                    .font(.system(size: 11, weight: .medium, design: .serif))
                                    .tracking(0.8)
                            }
                            .foregroundStyle(Color.tarotIvory.opacity(0.8))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Capsule().fill(Color.white.opacity(0.05)))
                            .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 0.7))
                        }
                        .buttonStyle(.plain)
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
        }
        .navigationTitle(TarotStrings.dailyCardTitle.localized)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}
