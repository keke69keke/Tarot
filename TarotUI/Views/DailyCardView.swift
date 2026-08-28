import SwiftUI
import TarotCore
import TarotData
import TarotDI

struct DailyCardView: View {
    @ObservedObject var model: TarotViewModel
    @State private var halo: CGFloat = 1.0

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: LuxurySpacing.lg) {
                // Header editorial — pequeño, no grita
                VStack(alignment: .leading, spacing: 8) {
                    EyebrowLabel(text: "RITUAL  ·  HOY")
                    Text("Carta del día")
                        .font(.system(size: 28, weight: .bold, design: .serif))
                        .tracking(-0.5)
                        .foregroundStyle(Color.tarotIvory)
                    Text("Una sola carta. Luz suficiente para el día.")
                        .font(.system(size: 13, weight: .regular, design: .serif))
                        .foregroundStyle(Color.tarotIvory.opacity(0.56))
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 4)
                .padding(.top, 6)

                // Escenario joya — foco cenital, halo mínimo
                ZStack {
                    // velo de luz
                    Ellipse()
                        .fill(Color.tarotGold.opacity(model.dailyRevealed ? 0.09 : 0.05))
                        .frame(width: 360, height: 360)
                        .blur(radius: 36)
                        .scaleEffect(halo)
                        .offset(y: 10)

                    // Card con marco joya
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
                    .shadow(color: Color.black.opacity(0.45), radius: 24, x: 0, y: 14)
                    .shadow(color: Color.tarotGold.opacity(model.dailyRevealed ? 0.18 : 0.07), radius: 22, x: 0, y: 0)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.tarotGold.opacity(model.dailyRevealed ? 0.22 : 0.14), lineWidth: 0.9)
                    )
                    .scaleEffect(model.dailyRevealed ? 1.0 : 0.985)

                    // Tap organico — no botón plástico
                    if !model.dailyRevealed {
                        Button { withAnimation(LuxuryAnimation.softSpring) { model.revealDaily() } } label: {
                            VStack(spacing: 8) {
                                Image(systemName: "eye")
                                    .font(.system(size: 16, weight: .thin))
                                    .foregroundStyle(Color.tarotIvory.opacity(0.92))
                                Text("REVELAR")
                                    .font(.system(size: 10, weight: .semibold, design: .serif))
                                    .tracking(1.6)
                                    .foregroundStyle(Color.tarotIvory.opacity(0.72))
                            }
                            .padding(.horizontal, 18)
                            .padding(.vertical, 14)
                            .background(
                                Capsule()
                                    .fill(Color.black.opacity(0.38))
                                    .background(Capsule().fill(.ultraThinMaterial).opacity(0.45))
                            )
                            .overlay(Capsule().stroke(Color.white.opacity(0.14), lineWidth: 0.75))
                            .shadow(color: Color.black.opacity(0.35), radius: 12, x: 0, y: 8)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(TarotStrings.tapToReveal.localized)
                        .accessibilityHint("Revela la carta del día")
                        .accessibilityAddTraits(.isButton)
                    } else {
                        EmptyView()
                            .accessibilityHidden(true)
                    }
                }
                .frame(height: 386)
                .padding(.vertical, 4)
                .onAppear { withAnimation(LuxuryAnimation.breathe) { halo = 1.06 } }

                Text(model.dailyRevealed ? "Carta revelada" : "Toca para revelar")
                    .font(.system(size: 11, weight: .medium, design: .serif))
                    .tracking(0.6)
                    .foregroundStyle(Color.tarotIvory.opacity(0.44))
                    .frame(maxWidth: .infinity)

                if model.dailyRevealed {
                    VStack(alignment: .leading, spacing: 12) {
                        GoldDivider(opacity: 0.14)
                        CardDetailText(card: model.dailyCard, orientation: .upright, repository: model.container.cards)
                    }
                    .padding(18)
                    .luxuryGlass()
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                Spacer(minLength: 12)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .navigationTitle(TarotStrings.dailyCardTitle.localized)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}
