import SwiftUI
import TarotCore
import TarotData

struct DailyCardView: View {
    @ObservedObject var model: TarotViewModel
    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Carta del día")
                        .font(.title2.bold())
                        .foregroundStyle(.primary)
                    Text(model.dailyRevealed ? "Tu guía para el día está lista." : "Toca la carta para descubrir tu orientación e inspiración diaria.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(18)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color.tarotPanel.opacity(0.90))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.tarotBorder, lineWidth: 1)
                )

Button {
                    if !model.dailyRevealed {
                        TarotAudioService.shared.playGoldenChime()
                        model.revealDaily()
                    }
                } label: {
                    CardFace(
                        name: model.dailyCard.name,
                        imageName: model.dailyCard.imageName,
                        textureName: model.dailyCard.textureImageName,
                        reversed: false,
                        back: !model.dailyRevealed,
                        useTexture: true,
                        size: CGSize(width: 220, height: 330),
                        activeDeck: model.settings.activeDeck,
                        backDesign: model.settings.cardBackDesign
                    )
                    .rotation3DEffect(.degrees(model.dailyRevealed ? 0 : 180), axis: (x: 0, y: 1, z: 0))
                    .shadow(color: Color.tarotShadow.opacity(1), radius: 18, x: 0, y: 12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(Color.tarotBorder, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .accessibilityLabel(model.dailyRevealed ? model.dailyCard.name : "Carta del día boca abajo")
                .padding(.vertical, 4)

                Text(model.dailyRevealed ? "Carta revelada. Desplázate para ver la interpretación." : "Pulsa la carta para revelarla")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)

                if model.dailyRevealed {
                    CardDetailText(card: model.dailyCard, orientation: .upright, repository: model.container.cards)
                        .padding()
                        .background(Color.tarotPanel.opacity(0.90))
                        .cornerRadius(22)
                }

                Spacer(minLength: 0)
            }
            .padding()
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Carta del día")
        }
    }
}
