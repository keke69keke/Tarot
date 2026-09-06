import SwiftUI
import TarotCore
import TarotData

struct CardFace: View {
    let name: String
    let imageName: String?
    let textureName: String?
    let reversed: Bool
    var back = false
    var useTexture = true
    var size: CGSize? = nil
    var activeDeck: DeckType = .riderWaite
    var backDesign: CardBackDesign = .classic

    private var cardSize: CGSize { size ?? CGSize(width: 150, height: 220) }

    var body: some View {
        ZStack {
            // Card base background
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.tarotCardBase)

            if back {
                // Ornate Tarot Card Back
                CardBackView(cardSize: cardSize, design: backDesign)
            } else if let platformImage = resolvedPlatformImage {
                // Card Front Image: Edge-to-edge display matching reference card designs.
                let cornerRadius: CGFloat = max(10, cardSize.width * 0.08)
                let imageH = platformImage.size.height
                let imageW = platformImage.size.width
                let imageAspect = imageH > 0 ? imageW / imageH : 1.0
                let frameAspect = cardSize.height > 0 ? cardSize.width / cardSize.height : 0.66
                let useFit: Bool = {
                    // HK cards have ratio ~0.682 matching the frame — use fit to avoid crops
                    if activeDeck == .helloKitty { return false }
                    return imageAspect > frameAspect + 0.03
                }()

                Image(platformImage: platformImage)
                    .resizable()
                    .renderingMode(.original)
                    .interpolation(.high)
                    .aspectRatio(contentMode: useFit ? .fit : .fill)
                    .frame(width: cardSize.width, height: cardSize.height)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(Color.black.opacity(0.60), lineWidth: max(1.5, cardSize.width * 0.015))
                    )
            } else {
                // Fallback card illustration when image is not present
                CardFallbackIllustration(name: name, size: cardSize, textureStyle: activeDeck.textureStyle)
            }

            // Texture sutil — 0.08 para mazos con arte dedicado (evita glitch/pixelado)
            if useTexture {
                CardTextureOverlayView(
                    cardSize: cardSize,
                    textureStyle: activeDeck.textureStyle
                )
                .opacity(activeDeck.hasDedicatedArtwork ? 0.08 : 0.28)
            }

            // Outer Lavender Foil Frame & Bevel Border
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.tarotGoldGradient, lineWidth: max(1.5, cardSize.width * 0.015))

            // Inner Foil Inset Hairline Frame
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .stroke(Color.tarotGold.opacity(0.50), lineWidth: 1)
                .padding(4)
        }
        .frame(width: cardSize.width, height: cardSize.height)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.35), radius: 10, x: 0, y: 6)
        .rotationEffect(reversed ? .degrees(180) : .zero)
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(back ? "Carta boca abajo" : name)
    }

    /// Resolves the correct image for the active deck (e.g. helloKitty prefix) with fallback to base Rider-Waite.
    private var resolvedPlatformImage: PlatformImage? {
        guard let imageName else { return nil }
        // Try deck-prefixed variant first (Hello Kitty has dedicated assets)
        if let prefix = activeDeck.assetPrefix {
            let prefixed = "\(prefix)_\(imageName)"
            if let img = PlatformImageLoader.image(named: prefixed) { return img }
        }
        // Fallback to base Rider-Waite image (exists for all 78 cards)
        if let img = PlatformImageLoader.image(named: imageName) { return img }
        return nil
    }
}

extension Image {
    init(platformImage: PlatformImage) {
        #if canImport(UIKit)
        self.init(uiImage: platformImage)
        #elseif canImport(AppKit)
        self.init(nsImage: platformImage)
        #else
        self.init(platformImage)
        #endif
    }
}
