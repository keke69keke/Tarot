import SwiftUI

// MARK: - Colors (Esoteric Tarot Palette)
extension Color {
    // Deep mystical background
    static let tarotBackgroundDeep = Color(red: 0.05, green: 0.02, blue: 0.14)

    // Lavender-gold accent (primary)
    static let tarotAccent = Color(red: 0.85, green: 0.72, blue: 0.38)

    // Violet panel
    static let tarotCardBackground = Color.white.opacity(0.1)
    static let tarotCardBorder = Color.purple.opacity(0.2)
    static let tarotTextPrimary = Color.white
    static let tarotTextSecondary = Color.white.opacity(0.6)
    static let tarotPurple = Color.purple
    static let tarotBurgundyDeep = Color(red: 0.42, green: 0.12, blue: 0.42)

    // Backward-compatible aliases (used across the app)
    static let cardBackground = Color.white.opacity(0.1)
    static let cardBorder = Color.purple.opacity(0.2)
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.6)
    static let accent = Color.purple
}

// MARK: - Spacing & Layout
enum DesignDS {
    static let cardCornerRadius: CGFloat = 14
    static let cardPadding: CGFloat = 14
    static let iconSize: CGSize = CGSize(width: 44, height: 44)
    static let spacingSmall: CGFloat = 8
    static let spacingMedium: CGFloat = 14
    static let spacingLarge: CGFloat = 20
}

// MARK: - Animation Presets
struct TarotAnimation {
    /// Standard smooth spring for card interactions.
    static let spring = Animation.spring(response: 0.45, dampingFraction: 0.75)

    /// Gentle breathing/pulse for hero elements.
    static let pulse = Animation.easeInOut(duration: 2.2).repeatForever(autoreverses: true)

    /// Staggered reveal for card grids.
    static func stagger(delay: Double) -> Animation {
        .easeOut(duration: 0.45).delay(delay)
    }

    /// Shuffle animation.
    static let shuffle = Animation.interactiveSpring(response: 0.5, dampingFraction: 0.7)
}

// MARK: - Design System (legacy struct kept for compatibility)
struct DesignSystem {
    static let cardCornerRadius: CGFloat = 14
    static let cardPadding: CGFloat = 14
    static let iconSize: CGSize = CGSize(width: 44, height: 44)
    static let spacingSmall: CGFloat = 8
    static let spacingMedium: CGFloat = 14
    static let spacingLarge: CGFloat = 20
}
