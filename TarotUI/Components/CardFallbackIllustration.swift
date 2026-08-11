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

extension Color {
    // Esoteric deep purple base (dark violet-navy)
    static var tarotBackground: Color {
        #if canImport(UIKit)
        return Color(UIColor.systemBackground)
        #elseif canImport(AppKit)
        return Color(nsColor: .windowBackgroundColor)
        #else
        return Color(red: 0.05, green: 0.02, blue: 0.12)
        #endif
    }

    // Violet translucent panel
    static var tarotPanel: Color {
        #if canImport(UIKit)
        return Color(UIColor.secondarySystemBackground)
        #elseif canImport(AppKit)
        return Color(nsColor: .textBackgroundColor)
        #else
        return Color(red: 0.22, green: 0.10, blue: 0.34).opacity(0.16)
        #endif
    }

    // Card base background for image containers (deep plum)
    static var tarotCardBase: Color {
        #if canImport(UIKit)
        return Color(UIColor.tertiarySystemBackground)
        #elseif canImport(AppKit)
        return Color(nsColor: .textBackgroundColor)
        #else
        return Color(red: 0.20, green: 0.10, blue: 0.30)
        #endif
    }

    // Violet/lavender translucent border
    static var tarotBorder: Color {
        Color(red: 0.72, green: 0.55, blue: 0.95).opacity(0.28)
    }

    // Deep violet shadow
    static var tarotShadow: Color {
        Color(red: 0.12, green: 0.02, blue: 0.28).opacity(0.30)
    }

    // Lavender-gold accent (kept name for compatibility)
    static var tarotGold: Color {
        Color(red: 0.78, green: 0.62, blue: 0.98)
    }

    // Deep violet-magenta
    static var tarotBurgundy: Color {
        Color(red: 0.42, green: 0.12, blue: 0.42)
    }
}

extension Appearance {
    var colorScheme: ColorScheme? {
        switch self {
        case .automatic: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

// SpreadType.label is defined in Spread.swift (all 18 cases, including Phase 4)

extension CardSuit {
    var displayName: String {
        switch self {
        case .wands: return "Bastos"
        case .cups: return "Copas"
        case .swords: return "Espadas"
        case .pentacles: return "Oros"
        }
    }
}
