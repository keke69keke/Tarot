import SwiftUI
import TarotCore
import TarotData

struct CardTextureOverlayView: View {
    let cardSize: CGSize
    let textureStyle: DeckTextureStyle

var body: some View {
        ZStack {
            switch textureStyle {
            case .agedParchment:   agedParchmentLayer
            case .sacredGeometry:  sacredGeometryLayer
            case .softPastel:      softPastelLayer
            case .medievalEmbroidery: medievalEmbroideryLayer
            case .watercolor:      watercolorLayer
            case .grunge:          grungeLayer
            case .starfield:       starfieldLayer
            case .leafVeins:       leafVeinsLayer
            }
            // Universal edge vignette (use overlay to remain visible over card art)
            RadialGradient(
                colors: [.clear, Color.black.opacity(0.12)],
                center: .center,
                startRadius: cardSize.width * 0.40,
                endRadius: cardSize.width * 0.80
            )
            .blendMode(.overlay)
        }
        .allowsHitTesting(false)
    }

    // MARK: - Rider-Waite: Aged Parchment
    private var agedParchmentLayer: some View {
        ZStack {
            Canvas { context, size in
                let step: CGFloat = 3.5
                var path = Path()
                for x in stride(from: 0, to: size.width, by: step) {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x + size.height * 0.4, y: size.height))
                }
                context.stroke(path, with: .color(Color(red: 0.55, green: 0.38, blue: 0.15).opacity(0.10)), lineWidth: 0.5)
            }
            LinearGradient(
                colors: [Color(red: 0.97, green: 0.92, blue: 0.80).opacity(0.22),
                         Color(red: 0.88, green: 0.76, blue: 0.55).opacity(0.32)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .blendMode(.overlay)
            // Gold vein lines
            Canvas { context, size in
                var vein = Path()
                vein.move(to: CGPoint(x: size.width * 0.2, y: 0))
                vein.addCurve(to: CGPoint(x: size.width * 0.8, y: size.height),
                              control1: CGPoint(x: size.width * 0.6, y: size.height * 0.3),
                              control2: CGPoint(x: size.width * 0.3, y: size.height * 0.7))
                context.stroke(vein, with: .color(Color(red: 0.85, green: 0.72, blue: 0.38).opacity(0.18)), lineWidth: 0.8)
            }
        }
    }

    // MARK: - Thoth: Sacred Geometry
    private var sacredGeometryLayer: some View {
        ZStack {
            Canvas { context, size in
                let cx = size.width / 2, cy = size.height / 2
                let radii: [CGFloat] = [size.width * 0.18, size.width * 0.35, size.width * 0.50]
for r in radii {
                    let circ = Path(ellipseIn: CGRect(x: cx - r, y: cy - r, width: r*2, height: r*2))
                    context.stroke(circ, with: .color(Color(red: 0.60, green: 0.45, blue: 0.92).opacity(0.24)), lineWidth: 0.75)
                }
                // Hexagram lines
                let pts6: [CGPoint] = (0..<6).map { i in
                    let a = Double(i) * .pi / 3 - .pi / 2
                    return CGPoint(x: cx + cos(a) * size.width * 0.44, y: cy + sin(a) * size.width * 0.44)
                }
                var star = Path()
                for i in 0..<6 {
                    star.move(to: pts6[i])
                    star.addLine(to: pts6[(i+3) % 6])
                }
                context.stroke(star, with: .color(Color(red: 0.72, green: 0.58, blue: 0.95).opacity(0.22)), lineWidth: 0.75)
            }
            LinearGradient(
                colors: [Color(red: 0.2, green: 0.05, blue: 0.35).opacity(0.18),
                         Color(red: 0.45, green: 0.15, blue: 0.80).opacity(0.12)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .blendMode(.screen)
        }
    }

// MARK: - Hello Kitty: Soft Pastel
    private var softPastelLayer: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 1.0, green: 0.88, blue: 0.95).opacity(0.26),
                         Color(red: 0.88, green: 0.92, blue: 1.0).opacity(0.22)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .blendMode(.screen)
            // Cute sparkle accents
            Canvas { context, size in
                let sparkles: [(CGFloat, CGFloat)] = [
                    (0.12, 0.18), (0.82, 0.22), (0.30, 0.82), (0.70, 0.78), (0.50, 0.45)
                ]
                for s in sparkles {
                    let dot = Path(ellipseIn: CGRect(x: s.0 * size.width - 1.5,
                                                    y: s.1 * size.height - 1.5,
                                                    width: 3, height: 3))
                    context.fill(dot, with: .color(Color.white.opacity(0.60)))
                }
            }
        }
    }

    // MARK: - Marseille: Medieval Embroidery
    private var medievalEmbroideryLayer: some View {
        ZStack {
            Canvas { context, size in
                let step: CGFloat = 14
                var grid = Path()
                for x in stride(from: 0, to: size.width, by: step) {
                    grid.move(to: CGPoint(x: x, y: 0))
                    grid.addLine(to: CGPoint(x: x, y: size.height))
                }
                for y in stride(from: 0, to: size.height, by: step) {
                    grid.move(to: CGPoint(x: 0, y: y))
                    grid.addLine(to: CGPoint(x: size.width, y: y))
                }
context.stroke(grid, with: .color(Color(red: 0.65, green: 0.15, blue: 0.15).opacity(0.14)), lineWidth: 0.5)
                // Diagonal overlay
                var diag = Path()
                for x in stride(from: -size.height, to: size.width + size.height, by: step * 2) {
                    diag.move(to: CGPoint(x: x, y: 0))
                    diag.addLine(to: CGPoint(x: x + size.height, y: size.height))
                }
                context.stroke(diag, with: .color(Color(red: 0.15, green: 0.25, blue: 0.65).opacity(0.12)), lineWidth: 0.5)
            }
            LinearGradient(
                colors: [Color(red: 0.95, green: 0.88, blue: 0.72).opacity(0.18),
                         Color(red: 0.82, green: 0.68, blue: 0.42).opacity(0.24)],
                startPoint: .top, endPoint: .bottom
            )
            .blendMode(.overlay)
        }
    }

    // MARK: - Osho: Watercolor
private var watercolorLayer: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 1.0, green: 0.5, blue: 0.2).opacity(0.16),
                         Color(red: 0.2, green: 0.7, blue: 1.0).opacity(0.16),
                         Color(red: 0.8, green: 0.2, blue: 0.9).opacity(0.12)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .blendMode(.screen)
            Canvas { context, size in
                // Soft circular blobs
                let blobs: [(x: CGFloat, y: CGFloat, r: CGFloat, op: CGFloat)] = [
                    (0.2, 0.25, 0.25, 0.14), (0.7, 0.4, 0.30, 0.12), (0.45, 0.70, 0.28, 0.16)
                ]
                for b in blobs {
                    let blob = Path(ellipseIn: CGRect(x: (b.x - b.r/2) * size.width,
                                                     y: (b.y - b.r/2) * size.height,
                                                     width: b.r * size.width,
                                                     height: b.r * size.height))
                    context.fill(blob, with: .color(Color(red: 0.5, green: 0.8, blue: 1.0).opacity(b.op)))
                }
            }
        }
    }

    // MARK: - Dark Side: Grunge
private var grungeLayer: some View {
        ZStack {
            LinearGradient(
                colors: [Color.black.opacity(0.30), Color(red: 0.1, green: 0.0, blue: 0.05).opacity(0.40)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .blendMode(.multiply)
            Canvas { context, size in
                // Rough scratches
                var scratches = Path()
                let scratchCoords: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [
                    (0.1, 0.05, 0.35, 0.28), (0.6, 0.1, 0.80, 0.40),
                    (0.2, 0.6, 0.55, 0.90), (0.7, 0.5, 0.95, 0.75),
                    (0.05, 0.45, 0.30, 0.55), (0.65, 0.7, 0.85, 0.85)
                ]
                for s in scratchCoords {
                    scratches.move(to: CGPoint(x: s.0 * size.width, y: s.1 * size.height))
                    scratches.addLine(to: CGPoint(x: s.2 * size.width, y: s.3 * size.height))
                }
                context.stroke(scratches, with: .color(Color.white.opacity(0.14)), lineWidth: 0.8)
            }
        }
    }

    // MARK: - Celestial: Starfield
    private var starfieldLayer: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.04, green: 0.05, blue: 0.18).opacity(0.34),
                         Color(red: 0.10, green: 0.18, blue: 0.40).opacity(0.26)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .blendMode(.screen)
            Canvas { context, size in
                // Star dots
                let stars: [(CGFloat, CGFloat, CGFloat)] = [
                    (0.05, 0.10, 1.2), (0.20, 0.30, 1.0), (0.35, 0.08, 0.9), (0.50, 0.22, 1.3),
                    (0.65, 0.12, 1.0), (0.80, 0.35, 1.2), (0.90, 0.05, 0.8),
                    (0.15, 0.55, 1.1), (0.40, 0.65, 0.9), (0.60, 0.75, 1.0),
                    (0.78, 0.60, 1.2), (0.25, 0.85, 0.8), (0.55, 0.90, 1.1), (0.88, 0.82, 1.0),
                    (0.72, 0.92, 0.9), (0.10, 0.78, 1.0), (0.45, 0.45, 0.8), (0.92, 0.48, 1.1)
                ]
                for s in stars {
                    let dot = Path(ellipseIn: CGRect(x: s.0 * size.width - s.2/2,
                                                    y: s.1 * size.height - s.2/2,
                                                    width: s.2, height: s.2))
                    context.fill(dot, with: .color(Color.white.opacity(0.85)))
                }
            }
        }
    }

    // MARK: - Botanical: Leaf Veins
    private var leafVeinsLayer: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.15, green: 0.40, blue: 0.20).opacity(0.20),
                         Color(red: 0.25, green: 0.55, blue: 0.25).opacity(0.16)],
                startPoint: .top, endPoint: .bottom
            )
            .blendMode(.screen)
            Canvas { context, size in
                // Central midrib
                var vein = Path()
                vein.move(to: CGPoint(x: size.width * 0.5, y: 0))
                vein.addLine(to: CGPoint(x: size.width * 0.5, y: size.height))
                context.stroke(vein, with: .color(Color(red: 0.2, green: 0.55, blue: 0.2).opacity(0.22)), lineWidth: 0.8)
                // Side veins
                let veinCount = 7
                for i in 0...veinCount {
                    let y = size.height * CGFloat(i) / CGFloat(veinCount)
                    var sv = Path()
                    sv.move(to: CGPoint(x: size.width * 0.5, y: y))
                    sv.addLine(to: CGPoint(x: size.width * 0.12, y: y - size.height * 0.06))
                    sv.move(to: CGPoint(x: size.width * 0.5, y: y))
                    sv.addLine(to: CGPoint(x: size.width * 0.88, y: y - size.height * 0.06))
                    context.stroke(sv, with: .color(Color(red: 0.2, green: 0.55, blue: 0.2).opacity(0.18)), lineWidth: 0.6)
                }
            }
        }
    }
}

/// Ornate Card Back View
