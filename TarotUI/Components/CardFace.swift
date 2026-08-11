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
} else if let imageName, let platformImage = platformImage(named: imageName) {
                // Card Front Image: Edge-to-edge display matching reference card designs.
                // If the source image is significantly wider/shorter than the tall card
                // frame (e.g. Hello Kitty artwork is near-square), scale to FIT so the
                // full artwork is visible instead of cropped. Standard tall card art uses
                // scaledToFill for edge-to-edge coverage.
                let cornerRadius: CGFloat = max(10, cardSize.width * 0.08)
                let imageH = platformImage.size.height
                let imageW = platformImage.size.width
                let imageAspect = imageH > 0 ? imageW / imageH : 1.0
                let frameAspect = cardSize.height > 0 ? cardSize.width / cardSize.height : 0.66
                // Hello Kitty artwork is already pre-cropped to the card ratio (150:220 ≈ 0.682),
                // so we always scale to FILL to avoid blank bands. For other decks, only use
                // .fit when the source is clearly wider than the card frame.
                let useFit: Bool = {
                    if activeDeck == .helloKitty { return false }
                    return imageAspect > frameAspect + 0.03
                }()

                #if canImport(UIKit)
                Image(uiImage: platformImage)
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
                #elseif canImport(AppKit)
                Image(nsImage: platformImage)
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
#endif
            } else {
                // Fallback card illustration when image is not present
                CardFallbackIllustration(name: name, size: cardSize, textureStyle: activeDeck.textureStyle)
            }

            // Visible Tactile Deck-Specific Texture Overlay
            if useTexture {
                CardTextureOverlayView(
                    cardSize: cardSize,
                    textureStyle: activeDeck.textureStyle
                )
            }

            // Outer Metallic Gold Foil Frame & Bevel Border
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color(red: 0.92, green: 0.80, blue: 0.45),
                            Color(red: 0.65, green: 0.48, blue: 0.18),
                            Color(red: 0.98, green: 0.88, blue: 0.55),
                            Color(red: 0.70, green: 0.52, blue: 0.20)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: max(1.5, cardSize.width * 0.015)
                )

            // Inner Gold Inset Hairline Frame
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .stroke(Color(red: 0.85, green: 0.72, blue: 0.38).opacity(0.50), lineWidth: 1)
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

    private func platformImage(named name: String) -> PlatformImage? {
        let cleanName = (name as NSString).deletingPathExtension
        let candidates = ["\(activeDeck.rawValue)_\(cleanName)", cleanName]

        for candidate in candidates {
            if let resourceURL = Bundle.tarotContent.url(forResource: candidate, withExtension: "png") {
                #if canImport(UIKit)
                if let img = UIImage(contentsOfFile: resourceURL.path) { return img }
                #elseif canImport(AppKit)
                if let img = NSImage(contentsOf: resourceURL) { return img }
                #endif
            }

            if let resourceURL = Bundle.tarotContent.url(forResource: candidate, withExtension: nil) {
                #if canImport(UIKit)
                if let img = UIImage(contentsOfFile: resourceURL.path) { return img }
                #elseif canImport(AppKit)
                if let img = NSImage(contentsOf: resourceURL) { return img }
                #endif
            }

            #if canImport(UIKit)
            if let img = UIImage(named: candidate, in: .tarotContent, compatibleWith: nil) { return img }
            #elseif canImport(AppKit)
            if let img = Bundle.tarotContent.image(forResource: candidate) { return img }
            #endif
        }

        return nil
    }
}

/// Procedural per-deck texture overlay — generates unique visual skin for each deck style.
