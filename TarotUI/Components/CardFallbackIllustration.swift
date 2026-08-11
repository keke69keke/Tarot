import SwiftUI
import TarotCore
import TarotData

struct CardFallbackIllustration: View {
    let name: String
    let size: CGSize
    var textureStyle: DeckTextureStyle = .agedParchment

    var body: some View {
        ZStack {
            // Deck-specific textured background
            LinearGradient(
                colors: [Color(red: 0.15, green: 0.12, blue: 0.28), Color(red: 0.08, green: 0.06, blue: 0.16)],
                startPoint: .top,
                endPoint: .bottom
            )

            // Apply the deck's signature texture overlay
            CardTextureOverlayView(cardSize: size, textureStyle: textureStyle)

            // Subtle radial glow in the center
            RadialGradient(
                colors: [.clear, Color(red: 0.78, green: 0.62, blue: 0.98).opacity(0.28)],
                center: .center,
                startRadius: 0,
                endRadius: size.width * 0.55
            )

            VStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.system(size: max(24, size.width * 0.22)))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 0.90, green: 0.78, blue: 1.0), Color(red: 0.72, green: 0.55, blue: 0.95)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                Text(name)
                    .font(.system(size: max(11, size.width * 0.09), weight: .medium, design: .serif))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: 1)
            }

            // Inner gold hairline frame to match real cards
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .stroke(Color(red: 0.85, green: 0.72, blue: 0.38).opacity(0.45), lineWidth: 1)
                .padding(4)
        }
    }
}
