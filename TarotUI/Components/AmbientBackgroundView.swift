import SwiftUI

// MARK: - Star
/// A single star in the animated field.
private struct Star: Identifiable {
    let id = UUID()
    var x: CGFloat      // 0...1 relative
    var y: CGFloat      // 0...1 relative
    var size: CGFloat
    var baseOpacity: Double
    var twinkleDuration: Double
    var twinkleDelay: Double
    var driftSpeed: Double
}

/// Dynamic starfield background: twinkling stars with a slow diagonal drift,
/// layered in two depths over the tarot gradient. Rendered with Canvas for
/// minimal overhead, animated via a single TimelineView.
struct StarfieldBackgroundView: View {
    var starCount: Int = 90
    var showsNebula: Bool = true

    @State private var stars: [Star] = []
    @State private var size: CGSize = .zero

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            Canvas { context, canvasSize in
                let t = timeline.date.timeIntervalSinceReferenceDate

                // Nebula: soft violet/indigo blobs for depth
                if showsNebula {
                    let nebulaColors: [(CGPoint, Color)] = [
                        (CGPoint(x: canvasSize.width * 0.2, y: canvasSize.height * 0.25), Color(red: 0.35, green: 0.22, blue: 0.65, opacity: 0.16)),
                        (CGPoint(x: canvasSize.width * 0.8, y: canvasSize.height * 0.6), Color(red: 0.15, green: 0.10, blue: 0.40, opacity: 0.20)),
                        (CGPoint(x: canvasSize.width * 0.5, y: canvasSize.height * 0.9), Color(red: 0.45, green: 0.28, blue: 0.55, opacity: 0.12))
                    ]
                    for (center, color) in nebulaColors {
                        let rect = CGRect(x: center.x - canvasSize.width * 0.55,
                                          y: center.y - canvasSize.width * 0.55,
                                          width: canvasSize.width * 1.1,
                                          height: canvasSize.width * 1.1)
                        let gradient = Gradient(colors: [color, .clear])
                        context.fill(
                            Path(ellipseIn: rect),
                            with: .radialGradient(gradient, center: center, startRadius: 0, endRadius: canvasSize.width * 0.55)
                        )
                    }
                }

                for star in stars {
                    // Slow diagonal drift, wrapping around
                    let drift = (t * star.driftSpeed).truncatingRemainder(dividingBy: 1.0)
                    var x = star.x + drift
                    var y = star.y + drift * 0.35
                    x = x.truncatingRemainder(dividingBy: 1.0)
                    if x < 0 { x += 1.0 }
                    y = y.truncatingRemainder(dividingBy: 1.0)
                    if y < 0 { y += 1.0 }

                    // Twinkle
                    let phase = (t + star.twinkleDelay) / star.twinkleDuration
                    let twinkle = 0.5 + 0.5 * sin(phase * 2 * .pi)
                    let opacity = star.baseOpacity * (0.45 + 0.55 * twinkle)

                    let px = x * canvasSize.width
                    let py = y * canvasSize.height
                    let r = star.size

                    // Glow halo for larger stars
                    if star.size > 1.6 {
                        let haloRect = CGRect(x: px - r * 3, y: py - r * 3, width: r * 6, height: r * 6)
                        context.fill(
                            Path(ellipseIn: haloRect),
                            with: .radialGradient(
                                Gradient(colors: [Color.white.opacity(opacity * 0.35), .clear]),
                                center: CGPoint(x: px, y: py),
                                startRadius: 0,
                                endRadius: r * 3
                            )
                        )
                    }

                    context.fill(
                        Path(ellipseIn: CGRect(x: px - r, y: py - r, width: r * 2, height: r * 2)),
                        with: .color(Color.white.opacity(opacity))
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(
            ZStack {
                Color.tarotBackground.ignoresSafeArea()
                Color.tarotBackgroundGradient.ignoresSafeArea()
            }
        )
        .ignoresSafeArea()
        .onAppear(perform: generateStars)
        .onChange(of: starCount) { _ in generateStars() }
    }

    private func generateStars() {
        stars = (0..<starCount).map { _ in
            Star(
                x: .random(in: 0...1),
                y: .random(in: 0...1),
                size: .random(in: 0.6...2.6),
                baseOpacity: .random(in: 0.35...0.95),
                twinkleDuration: .random(in: 1.8...5.5),
                twinkleDelay: .random(in: 0...6),
                driftSpeed: .random(in: 0.002...0.008)
            )
        }
    }
}


/// A background view with dynamic color based on cosmic data
struct AmbientBackgroundView: View {
    // MARK: - Properties
    let cosmicColor: Color = .clear
    let isNightMode: Bool = false

    // MARK: - View Logic
    var body: some View {
        Rectangle()
            .fill(cosmicColor)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea()
            .animation(.easeInOut, value: isNightMode)
    }
}
