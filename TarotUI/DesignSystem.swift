import SwiftUI

// MARK: - 100k MXN Design System — Editorial Luxury
// Silencioso, caro, atemporal. Inspirado en joyería, papel de algodón y luz de vela.

// MARK: - Semantic Spacing
enum LuxurySpacing {
    static let xs: CGFloat = 6
    static let sm: CGFloat = 10
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 36
    static let xxl: CGFloat = 52
}

// MARK: - Radii
enum LuxuryRadius {
    static let sm: CGFloat = 12
    static let md: CGFloat = 18
    static let lg: CGFloat = 26
    static let pill: CGFloat = 999
    static let card: CGFloat = 18
}

// MARK: - Typography — Editorial Serif
extension Font {
    static var luxuryTitle: Font { .system(size: 32, weight: .bold, design: .serif) }
    static var luxuryTitle2: Font { .system(size: 26, weight: .bold, design: .serif) }
    static var luxuryHeadline: Font { .system(size: 15, weight: .semibold, design: .serif) }
    static var luxurySubheadline: Font { .system(size: 13, weight: .medium, design: .serif) }
    static var luxuryCaption: Font { .system(size: 11, weight: .medium, design: .serif) }
    static var luxuryEyebrow: Font { .system(size: 10, weight: .bold, design: .serif) }
}

// MARK: - Animations — Lentas, pesadas, caras
struct LuxuryAnimation {
    static let softSpring = Animation.spring(response: 0.55, dampingFraction: 0.82)
    static let slowSpring = Animation.spring(response: 0.72, dampingFraction: 0.85)
    static let breathe = Animation.easeInOut(duration: 3.2).repeatForever(autoreverses: true)
    static func reveal(delay: Double) -> Animation { .easeOut(duration: 0.55).delay(delay) }
    static let cardFlip = Animation.spring(response: 0.42, dampingFraction: 0.78)
}

// MARK: - View Modifiers — Glass + Oro
struct LuxuryGlass: ViewModifier {
    var cornerRadius: CGFloat = LuxuryRadius.lg
    var borderOpacity: Double = 0.13
    func body(content: Content) -> some View {
        content
            .background {
                ZStack {
                    // 1. Base Nativa: Material de vidrio ultra delgado
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)
                    
                    // 2. Capa de Reflejo Líquido: Degradado blanco suave para simular superficie pulida
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    .white.opacity(0.12),
                                    .white.opacity(0.03),
                                    .clear,
                                    .white.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .blendMode(.screen)
                    
                    // 3. Brillo Interno (Inner Glow): Simula la refracción en los bordes
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.2), .clear, .white.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                        .blur(radius: 1)
                }
                .overlay(
                    // 4. Borde de Oro Refinado: Línea ultra fina para definición
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.tarotGold.opacity(borderOpacity * 2),
                                    Color.tarotGold.opacity(borderOpacity * 0.5),
                                    Color.tarotGold.opacity(borderOpacity * 1.5)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.6
                        )
                )
            }
            .shadow(color: Color.black.opacity(0.25), radius: 20, x: 0, y: 12)
            .shadow(color: Color.tarotGold.opacity(0.05), radius: 15, x: 0, y: 0)
    }
}
struct LuxuryHairlinePanel: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.tarotPanel)
            .overlay(
                RoundedRectangle(cornerRadius: LuxuryRadius.lg, style: .continuous)
                    .stroke(Color.tarotBorder, lineWidth: 0.75)
            )
            .shadow(color: Color.tarotShadow.opacity(0.22), radius: 16, x: 0, y: 8)
    }
}
struct GoldFoilStroke: ViewModifier {
    var radius: CGFloat = 16
    var lineWidth: CGFloat = 1.1
    func body(content: Content) -> some View {
        content.overlay(
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .stroke(Color.tarotGoldGradient, lineWidth: lineWidth)
        )
    }
}
extension View {
    func luxuryGlass(cornerRadius: CGFloat = LuxuryRadius.lg) -> some View { modifier(LuxuryGlass(cornerRadius: cornerRadius)) }
    func luxuryHairline() -> some View { modifier(LuxuryHairlinePanel()) }
    func goldFoil(radius: CGFloat = 16, lineWidth: CGFloat = 1.0) -> some View { modifier(GoldFoilStroke(radius: radius, lineWidth: lineWidth)) }
    func luxuryShadow() -> some View { shadow(color: Color.black.opacity(0.4), radius: 20, x: 0, y: 10) }
}

// MARK: - Fondo nocturno compartido
/// Aplica la base nocturna solida (color + degradado) sin dibujar el cielo
/// estrellado.
///
/// Se usa como capa base tanto en la raiz como dentro de cada `sheet`: los
/// modales no heredan el fondo de la vista que los presenta, asi que sin esto
/// caian al negro del sistema y cortaban la atmosfera de la app.
struct TarotNightBase: ViewModifier {
    func body(content: Content) -> some View {
        content.background(
            ZStack {
                Color.tarotBackground
                Color.tarotBackgroundGradient
            }
            .ignoresSafeArea()
        )
    }
}

/// Fondo nocturno completo para vistas de nivel superior: la base solida mas el
/// cielo estrellado animado por encima.
///
/// Debe aplicarse **dentro** de cada `NavigationStack`, no fuera: el stack es una
/// capa opaca que tapa todo lo que quede por debajo, asi que un cielo pintado en
/// la raiz de la escena no se ve. Se comprobo midiendo capturas del simulador:
/// con el fondo dentro del stack la zona de contenido da violeta (~24,14,33) y
/// con el cielo solo en la raiz da negro puro (0,0,0).
///
/// Contrapartida asumida: cada pestana monta su propio `StarfieldBackgroundView`
/// y, por tanto, su propio `TimelineView` a 30 fps. Es el precio de que el fondo
/// se vea; en iOS la raiz no pinta fondo porque quedaria tapada igualmente.
struct TarotNightBackground: ViewModifier {
    func body(content: Content) -> some View {
        content.background(
            ZStack {
                Color.tarotBackground
                Color.tarotBackgroundGradient
                StarfieldBackgroundView()
            }
            .ignoresSafeArea()
        )
    }
}

extension View {
    /// Base nocturna solida, sin cielo animado. Para `sheet` y secciones.
    func tarotNightBase() -> some View { modifier(TarotNightBase()) }
    /// Fondo nocturno completo con cielo estrellado. Va **dentro** del
    /// `NavigationStack` de la vista (ver nota de `TarotNightBackground`).
    func tarotNightBackground() -> some View { modifier(TarotNightBackground()) }
    /// Fondo para el contenido de un `sheet`.
    ///
    /// Un modal no hereda el fondo de la vista que lo presenta: sin esto caia al
    /// negro del sistema. Combina el fondo del propio modal
    /// (`presentationBackground`, alli donde existe) con la base nocturna de su
    /// contenido, de modo que no queda ninguna franja negra ni al arrastrar ni
    /// en las esquinas redondeadas.
    func tarotSheetBackground() -> some View {
        modifier(TarotSheetBackground())
    }
}

/// Vease `View.tarotSheetBackground()`.
struct TarotSheetBackground: ViewModifier {
    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 16.4, macOS 13.3, *) {
            content
                .presentationBackground(Color.tarotBackground)
                .tarotNightBase()
        } else {
            content.tarotNightBase()
        }
    }
}

// MARK: - Liquid Glass real (iOS 26 / macOS 26) con fallback
/// Aplica el vidrio nativo del sistema cuando el SDK lo soporta y, si no,
/// cae al material luxury equivalente. Así las barras dejan de ser una
/// imitación y muestran la UI real de Liquid Glass.
struct LiquidGlassSurface: ViewModifier {
    var cornerRadius: CGFloat = LuxuryRadius.lg
    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            content.glassEffect(
                .regular,
                in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
        } else {
            content.luxuryGlass(cornerRadius: cornerRadius)
        }
    }
}

extension View {
    func liquidGlassSurface(cornerRadius: CGFloat = LuxuryRadius.lg) -> some View {
        modifier(LiquidGlassSurface(cornerRadius: cornerRadius))
    }
}

// MARK: - Legacy shim (compatibilidad con código existente)
extension Color {
    static let tarotBackgroundDeep = Color.tarotBackground
    static let tarotAccent = Color.tarotGold
    static let tarotCardBackground = Color.tarotPanel
    static let tarotCardBorder = Color.tarotBorder
    static let tarotTextPrimary = Color.tarotIvory
    static let tarotTextSecondary = Color.tarotIvory.opacity(0.58)
    static let tarotPurple = Color(red: 0.72, green: 0.55, blue: 0.95)
    static let cardBackground = Color.tarotPanel
    static let cardBorder = Color.tarotBorder
    static let textPrimary = Color.tarotIvory
    static let textSecondary = Color.tarotIvory.opacity(0.58)
    static let accent = Color.tarotGold
}
enum DesignDS {
    static let cardCornerRadius: CGFloat = LuxuryRadius.card
    static let cardPadding: CGFloat = LuxurySpacing.md
    static let iconSize: CGSize = CGSize(width: 44, height: 44)
    static let spacingSmall: CGFloat = LuxurySpacing.xs
    static let spacingMedium: CGFloat = LuxurySpacing.sm
    static let spacingLarge: CGFloat = LuxurySpacing.lg
}
struct TarotAnimation {
    static let spring = LuxuryAnimation.softSpring
    static let pulse = LuxuryAnimation.breathe
    static func stagger(delay: Double) -> Animation { LuxuryAnimation.reveal(delay: delay) }
    static let shuffle = LuxuryAnimation.slowSpring
}
struct DesignSystem {
    static let cardCornerRadius: CGFloat = LuxuryRadius.card
    static let cardPadding: CGFloat = LuxurySpacing.md
    static let iconSize: CGSize = CGSize(width: 44, height: 44)
    static let spacingSmall: CGFloat = LuxurySpacing.xs
    static let spacingMedium: CGFloat = LuxurySpacing.sm
    static let spacingLarge: CGFloat = LuxurySpacing.lg
}

// MARK: - Order Number Badge — Alta joyería, no plástico
struct OrderNumberBadge: View {
    let number: Int
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.tarotGoldGradient)
                .overlay(Circle().stroke(Color.white.opacity(0.35), lineWidth: 0.6))
            Text("\(number)")
                .font(.system(size: 10.5, weight: .bold, design: .serif))
                .foregroundStyle(Color(red: 0.09, green: 0.06, blue: 0.02))
                .tracking(0.2)
        }
        .frame(width: 21, height: 21)
        .shadow(color: Color.black.opacity(0.45), radius: 4, x: 0, y: 2)
        .shadow(color: Color.tarotGold.opacity(0.35), radius: 6, x: 0, y: 0)
    }
}

// MARK: - Eyebrow Label — usado en headers editoriales
struct EyebrowLabel: View {
    let text: String
    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 10, weight: .bold, design: .serif))
            .tracking(2.4)
            .foregroundStyle(Color.tarotGold.opacity(0.92))
    }
}

// MARK: - Gold Divider — 1px hairline editorial
struct GoldDivider: View {
    var opacity: Double = 0.18
    var body: some View {
        Rectangle()
            .fill(Color.tarotGold.opacity(opacity))
            .frame(height: 0.75)
    }
}
