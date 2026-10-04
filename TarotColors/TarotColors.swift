import SwiftUI

/// Centralized color palette for the Tarot project.
/// Based on the "100k MXN Luxury Palette" — Editorial, nocturnal, and mystical.
public struct TarotColors {
    // MARK: - Primary Palette
    public static let ivory = Color(red: 0.95, green: 0.95, blue: 0.90)
    public static let gold = Color(red: 0.843, green: 0.651, blue: 0.247) // Ámbar Tarot (Ash Thorp cálido, sin azul frío)
    public static let goldHighlight = Color(red: 0.941, green: 0.808, blue: 0.478)
    public static let goldDeep = Color(red: 0.541, green: 0.392, blue: 0.125)
    public static let burgundy = Color(red: 0.28, green: 0.08, blue: 0.14)
    public static let burgundyDeep = Color(red: 0.18, green: 0.04, blue: 0.08)

    // MARK: - Aspect Colors
    public static let aspectAmor = Color(red: 0.72, green: 0.18, blue: 0.18)
    public static let aspectEconomia = Color(red: 0.78, green: 0.58, blue: 0.18)
    public static let aspectSalud = Color(red: 0.20, green: 0.46, blue: 0.28)
    public static let aspectCarrera = Color(red: 0.18, green: 0.28, blue: 0.52)

    // MARK: - Backgrounds & Panels
    public static let background = Color(red: 0.06, green: 0.04, blue: 0.13)
    public static let backgroundElevated = Color(red: 0.09, green: 0.06, blue: 0.18)
    public static let panel = Color.white.opacity(0.055)
    public static let panelStrong = Color.white.opacity(0.08)
    public static let cardBase = Color(red: 0.11, green: 0.08, blue: 0.19)

    // MARK: - Accents & Borders
    public static let border = Color(red: 0.843, green: 0.651, blue: 0.247).opacity(0.13)
    public static let borderStrong = Color(red: 0.843, green: 0.651, blue: 0.247).opacity(0.20)
    public static let shadow = Color.black.opacity(0.45)
    public static let shadowSoft = Color.black.opacity(0.28)

    // MARK: - Gradients
    public static var goldGradient: LinearGradient {
        LinearGradient(
            colors: [goldHighlight, gold, goldDeep],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    public static var goldHorizontal: LinearGradient {
        LinearGradient(
            colors: [goldDeep, gold, goldHighlight, gold, goldDeep],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    public static var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [backgroundElevated, Color(red: 0.05, green: 0.03, blue: 0.11)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

public extension Color {
    static let tarotIvory = TarotColors.ivory
    static let tarotGold = TarotColors.gold
    static let tarotGoldHighlight = TarotColors.goldHighlight
    static let tarotGoldDeep = TarotColors.goldDeep
    static let tarotBurgundy = TarotColors.burgundy
    static let tarotBurgundyDeep = TarotColors.burgundyDeep
    static let tarotAspectAmor = TarotColors.aspectAmor
    static let tarotAspectEconomia = TarotColors.aspectEconomia
    static let tarotAspectSalud = TarotColors.aspectSalud
    static let tarotAspectCarrera = TarotColors.aspectCarrera
    static let tarotBackground = TarotColors.background
    static let tarotBackgroundElevated = TarotColors.backgroundElevated
    static let tarotPanel = TarotColors.panel
    static let tarotPanelStrong = TarotColors.panelStrong
    static let tarotCardBase = TarotColors.cardBase
    static let tarotBorder = TarotColors.border
    static let tarotBorderStrong = TarotColors.borderStrong
    static let tarotShadow = TarotColors.shadow
    static let tarotShadowSoft = TarotColors.shadowSoft
}

public extension ShapeStyle where Self == LinearGradient {
    static var tarotGoldGradient: LinearGradient { TarotColors.goldGradient }
    static var tarotGoldHorizontal: LinearGradient { TarotColors.goldHorizontal }
    static var tarotBackgroundGradient: LinearGradient { TarotColors.backgroundGradient }
}
