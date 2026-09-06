import SwiftUI
import TarotCore
import TarotDI

/// Fondo editorial dinámico que reacciona al estado cósmico y la energía de la lectura.
struct AmbientBackgroundView: View {
    @EnvironmentObject var engine: CosmicBackgroundEngine
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            // Luz cenital dinámica basada en el color del motor cósmico
            RadialGradient(colors: [engine.accentColor, .clear], center: .top, startRadius: 0, endRadius: 680)
                .ignoresSafeArea()
                .blendMode(.softLight)
            // Segundo respiro inferior
            RadialGradient(colors: [Color.white.opacity(0.03), .clear], center: .bottom, startRadius: 0, endRadius: 560)
                .ignoresSafeArea()
                .blendMode(.softLight)
            // Viñeta editorial
            RadialGradient(colors: [.clear, Color.black.opacity(0.28)], center: .center, startRadius: 420, endRadius: 900)
                .ignoresSafeArea()

            if scenePhase == .active {
                twinklingStars(speed: engine.particleSpeed)
                driftingDust(speed: engine.particleSpeed)
            } else {
                starField(time: 0, speed: 1.0)
            }
        }
        .background(engine.primaryColor.ignoresSafeArea())
        .animation(.easeInOut(duration: 2.0), value: engine.primaryColor)
        .animation(.easeInOut(duration: 2.0), value: engine.accentColor)
        .animation(.easeInOut(duration: 2.0), value: engine.particleSpeed)
        .allowsHitTesting(false)
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }

    private func twinklingStars(speed: Double) -> some View {
        TimelineView(.animation(minimumInterval: 1.0 / 24.0)) { t in
            starField(time: t.date.timeIntervalSinceReferenceDate, speed: speed)
        }
        .blendMode(.screen)
        .opacity(0.9)
    }

    private func driftingDust(speed: Double) -> some View {
        TimelineView(.animation(minimumInterval: 1.0 / 20.0)) { t in
            dustField(time: t.date.timeIntervalSinceReferenceDate, speed: speed)
        }
        .blendMode(.screen)
    }

    private func starField(time: TimeInterval, speed: Double) -> some View {
        Canvas { ctx, size in
            for s in LuxuryStars.all {
                let tw = 0.42 + 0.58 * sin(time * 0.55 * speed + s.phase)
                let x = s.x * size.width
                let y = s.y * size.height
                let r = s.r * (0.85 + 0.22 * tw)
                let op = 0.07 + 0.10 * tw
                ctx.fill(Path(ellipseIn: CGRect(x: x - r/2, y: y - r/2, width: r, height: r)), with: .color(Color.white.opacity(op)))
            }
        }
    }

    private func dustField(time: TimeInterval, speed: Double) -> some View {
        Canvas { ctx, size in
            for p in LuxuryDust.all {
                let travel = (time * p.speed * speed + p.phase).truncatingRemainder(dividingBy: 1.0)
                let y = size.height * (p.startY - travel * 0.42)
                let x = size.width * p.x + sin(time * 0.22 * speed + p.phase * 3.1) * size.width * 0.008
                let a: Double = travel < 0.22 ? travel/0.22 : max(0, 1 - (travel-0.22)/0.78)
                ctx.fill(Path(ellipseIn: CGRect(x: x - 0.65, y: y - 0.65, width: 1.3, height: 1.3)), with: .color(Color.tarotGold.opacity(0.14 * a)))
            }
        }
    }
}

private enum LuxuryStars {
    static let all: [(x: CGFloat, y: CGFloat, r: CGFloat, phase: Double)] = [
        (0.14, 0.08, 1.1, 0.0), (0.38, 0.07, 0.9, 1.1), (0.62, 0.09, 1.0, 2.0), (0.86, 0.07, 0.9, 0.6),
        (0.22, 0.22, 0.85, 1.7), (0.51, 0.18, 0.9, 2.8), (0.74, 0.22, 0.85, 0.4),
        (0.09, 0.36, 0.9, 2.2), (0.33, 0.40, 0.95, 0.9), (0.58, 0.38, 0.85, 3.0), (0.82, 0.42, 0.9, 1.3),
        (0.18, 0.58, 0.85, 0.8), (0.44, 0.62, 0.9, 2.4), (0.67, 0.59, 0.85, 1.0), (0.91, 0.62, 0.9, 2.1),
        (0.12, 0.78, 0.9, 1.4), (0.36, 0.82, 0.85, 0.5), (0.62, 0.84, 0.95, 2.6), (0.88, 0.80, 0.85, 0.7),
        (0.26, 0.94, 0.85, 1.9), (0.53, 0.92, 0.9, 2.2), (0.78, 0.94, 0.85, 0.3),
    ]
}
private enum LuxuryDust {
    static let all: [(x: CGFloat, startY: CGFloat, speed: Double, phase: Double)] = [
        (0.18, 0.96, 0.018, 0.1), (0.42, 0.92, 0.016, 0.9), (0.66, 0.98, 0.019, 1.7), (0.84, 0.94, 0.015, 2.3), (0.29, 0.78, 0.017, 2.9), (0.58, 0.76, 0.016, 3.4),
    ]
}
