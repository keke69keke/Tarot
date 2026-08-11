import SwiftUI
import TarotCore
import TarotData

struct CardBackView: View {
    let cardSize: CGSize
    let design: CardBackDesign

    var body: some View {
        ZStack {
            switch design {
            case .classic:
                classicBackDesign
            case .mystical:
                mysticalBackDesign
            case .celestial:
                celestialBackDesign
            case .floral:
                floralBackDesign
            case .alchemical:
                alchemicalBackDesign
            case .darkMoon:
                darkMoonBackDesign
            }
        }
    }

    // MARK: - Classic (Deep Indigo + Gold)
    private var classicBackDesign: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.07, green: 0.08, blue: 0.20), Color(red: 0.14, green: 0.10, blue: 0.30), Color(red: 0.05, green: 0.04, blue: 0.12)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            backLatticePattern(color: Color(red: 0.85, green: 0.72, blue: 0.38), step: 20)
            backCenterEmblem(icon: "sparkles", text: "ARCANA", accentR: 0.92, accentG: 0.80, accentB: 0.45)
        }
    }

    // MARK: - Mystical (Deep Purple + Violet)
    private var mysticalBackDesign: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.08, green: 0.03, blue: 0.18), Color(red: 0.18, green: 0.08, blue: 0.34), Color(red: 0.06, green: 0.04, blue: 0.14)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            backLatticePattern(color: Color(red: 0.72, green: 0.58, blue: 0.92), step: 18)
            backCenterEmblem(icon: "moon.stars.fill", text: "MYSTERIUM", accentR: 0.85, accentG: 0.70, accentB: 1.0)
        }
    }

    // MARK: - Celestial (Deep Space Blue)
    private var celestialBackDesign: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.02, green: 0.04, blue: 0.18), Color(red: 0.06, green: 0.12, blue: 0.38), Color(red: 0.01, green: 0.02, blue: 0.10)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            // Starfield
            Canvas { context, size in
                let stars: [(CGFloat, CGFloat, CGFloat)] = [
                    (0.12, 0.08, 1.8), (0.35, 0.15, 1.2), (0.65, 0.05, 1.5), (0.88, 0.18, 1.0),
                    (0.22, 0.45, 1.3), (0.50, 0.30, 2.0), (0.78, 0.42, 1.1), (0.08, 0.70, 1.4),
                    (0.40, 0.65, 1.6), (0.72, 0.58, 1.2), (0.55, 0.80, 1.8), (0.18, 0.88, 1.0),
                    (0.85, 0.75, 1.5), (0.95, 0.90, 1.0), (0.30, 0.92, 1.3), (0.62, 0.95, 1.1)
                ]
                for s in stars {
                    let dot = Path(ellipseIn: CGRect(x: s.0 * size.width - s.2/2, y: s.1 * size.height - s.2/2, width: s.2, height: s.2))
                    context.fill(dot, with: .color(Color.white.opacity(0.75)))
                }
            }
            backCenterEmblem(icon: "star.fill", text: "COSMOS", accentR: 0.40, accentG: 0.72, accentB: 1.0)
        }
    }

    // MARK: - Floral Art Nouveau (Emerald + Gold)
    private var floralBackDesign: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.04, green: 0.18, blue: 0.10), Color(red: 0.08, green: 0.28, blue: 0.14), Color(red: 0.02, green: 0.10, blue: 0.06)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            backLatticePattern(color: Color(red: 0.45, green: 0.78, blue: 0.42), step: 16)
            backCenterEmblem(icon: "leaf.fill", text: "NATURA", accentR: 0.55, accentG: 0.88, accentB: 0.45)
        }
    }

    // MARK: - Alchemical (Amber + Dark Brown)
    private var alchemicalBackDesign: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.16, green: 0.08, blue: 0.02), Color(red: 0.28, green: 0.14, blue: 0.04), Color(red: 0.10, green: 0.05, blue: 0.01)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            // Alchemical symbol grid
            Canvas { context, size in
                let step: CGFloat = 22
                var tria = Path()
                for x in stride(from: step, to: size.width - step, by: step * 2.5) {
                    for y in stride(from: step, to: size.height - step, by: step * 2.5) {
                        // Triangle up
                        tria.move(to: CGPoint(x: x, y: y + step * 0.6))
                        tria.addLine(to: CGPoint(x: x - step * 0.5, y: y - step * 0.3))
                        tria.addLine(to: CGPoint(x: x + step * 0.5, y: y - step * 0.3))
                        tria.closeSubpath()
                    }
                }
                context.stroke(tria, with: .color(Color(red: 0.95, green: 0.72, blue: 0.28).opacity(0.14)), lineWidth: 0.8)
            }
            backCenterEmblem(icon: "flame.fill", text: "PRIMA MATERIA", accentR: 0.95, accentG: 0.72, accentB: 0.28)
        }
    }

    // MARK: - Dark Moon (Charcoal + Silver)
    private var darkMoonBackDesign: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.06, green: 0.06, blue: 0.08), Color(red: 0.12, green: 0.10, blue: 0.14), Color(red: 0.04, green: 0.04, blue: 0.06)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            backLatticePattern(color: Color(red: 0.60, green: 0.60, blue: 0.70), step: 24)
            backCenterEmblem(icon: "moon.fill", text: "LUNA NIGRA", accentR: 0.65, accentG: 0.65, accentB: 0.80)
        }
    }

    // MARK: - Shared Helpers
    private func backLatticePattern(color: Color, step: CGFloat) -> some View {
        Canvas { context, size in
            var lattice = Path()
            for x in stride(from: -size.height, to: size.width + size.height, by: step) {
                lattice.move(to: CGPoint(x: x, y: 0))
                lattice.addLine(to: CGPoint(x: x + size.height, y: size.height))
                lattice.move(to: CGPoint(x: x, y: size.height))
                lattice.addLine(to: CGPoint(x: x + size.height, y: 0))
            }
            context.stroke(lattice, with: .color(color.opacity(0.13)), lineWidth: 0.75)
        }
    }

    private func backCenterEmblem(icon: String, text: String, accentR: Double, accentG: Double, accentB: Double) -> some View {
        let accent = Color(red: accentR, green: accentG, blue: accentB)
        return VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(LinearGradient(colors: [accent, accent.opacity(0.4)], startPoint: .top, endPoint: .bottom), lineWidth: 1.5)
                    .frame(width: max(32, cardSize.width * 0.38), height: max(32, cardSize.width * 0.38))
                Image(systemName: icon)
                    .font(.system(size: max(18, cardSize.width * 0.20), weight: .semibold))
                    .foregroundStyle(LinearGradient(colors: [accent, accent.opacity(0.65)], startPoint: .top, endPoint: .bottom))
            }
            Text(text)
                .font(.system(size: max(7, cardSize.width * 0.07), weight: .bold, design: .serif))
                .tracking(1.8)
                .foregroundStyle(accent.opacity(0.85))
        }
    }

}

/// Fallback Illustration when Card Image is not available
