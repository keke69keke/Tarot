import SwiftUI

struct WelcomeView: View {
    let colorScheme: ColorScheme
    let userName: String
    let onStart: () -> Void
    @State private var appear = false
    @State private var halo: CGFloat = 0.9

    var body: some View {
        ZStack {
            Color.tarotBackground.ignoresSafeArea()
            Color.tarotBackgroundGradient.ignoresSafeArea()

            // Sutil velo viñeta editorial — no brillos infantiles
            RadialGradient(colors: [Color.white.opacity(0.04), .clear], center: .top, startRadius: 0, endRadius: 720)
                .ignoresSafeArea()
                .blendMode(.softLight)

            // Halo morado muy suave — tarot nocturno
            Circle()
                .fill(Color.tarotGold.opacity(0.10))
                .frame(width: 560, height: 560)
                .blur(radius: 64)
                .scaleEffect(halo)
                .opacity(appear ? 1 : 0)

            VStack(spacing: 0) {
                Spacer(minLength: 40)

                // Emblema tarot — carta minimal morada
                ZStack {
                    Circle()
                        .stroke(Color.tarotGold.opacity(0.13), lineWidth: 0.85)
                        .frame(width: 132, height: 132)
                    Circle()
                        .stroke(Color.tarotGold.opacity(0.07), lineWidth: 0.75)
                        .frame(width: 108, height: 108)
                    TarotCardEmblem(size: 52)
                        .shadow(color: Color.tarotGold.opacity(0.18), radius: 14, x: 0, y: 6)
                }
                .scaleEffect(appear ? 1 : 0.92)
                .opacity(appear ? 1 : 0)

                Spacer().frame(height: 34)

                VStack(spacing: 14) {
                    // Eyebrow editorial
                    EyebrowLabel(text: "ARCANA  ·  78 CARTAS  ·  RIDER-WAITE")
                        .opacity(appear ? 1 : 0)
                        .offset(y: appear ? 0 : 6)

                    if !userName.isEmpty {
                        Text("Hola, \(userName)")
                            .font(.system(size: 16, weight: .regular, design: .serif))
                            .foregroundStyle(Color.tarotIvory.opacity(0.62))
                            .tracking(0.2)
                            .transition(.opacity)
                    }

                    Text("Las cartas te esperan")
                        .font(.system(size: 34, weight: .bold, design: .serif))
                        .tracking(-0.6)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color.tarotIvory)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .shadow(color: Color.black.opacity(0.28), radius: 10, x: 0, y: 6)

                    Text("Ritual diario, mazo completo y lecturas\ncon la profundidad del tarot.")
                        .font(.system(size: 15, weight: .regular, design: .serif))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color.tarotIvory.opacity(0.58))
                        .lineSpacing(5)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 28)
                }
                .opacity(appear ? 1 : 0)
                .offset(y: appear ? 0 : 8)

                Spacer().frame(height: 36)

                // CTA — tarot morado, no plástico
                Button { withAnimation(LuxuryAnimation.softSpring) { onStart() } } label: {
                    HStack(spacing: 10) {
                        Text(TarotStrings.startReading.localized.uppercased())
                            .font(.system(size: 13, weight: .semibold, design: .serif))
                            .tracking(1.2)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 11, weight: .semibold))
                            .opacity(0.85)
                    }
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(
                        Capsule()
                            .fill(Color.tarotGoldGradient)
                            .overlay(
                                Capsule()
                                    .stroke(Color.white.opacity(0.28), lineWidth: 0.75)
                                    .blendMode(.softLight)
                            )
                    )
                    .shadow(color: Color.black.opacity(0.38), radius: 16, x: 0, y: 10)
                    .shadow(color: Color.tarotGold.opacity(0.32), radius: 18, x: 0, y: 0)
                }
                .buttonStyle(.plain)
                .scaleEffect(appear ? 1 : 0.96)
                .opacity(appear ? 1 : 0)

                Spacer(minLength: 24)

                // Footer discreto — marca, no ruido
                Text("Hecho para durar. Sin prisas.")
                    .font(.system(size: 10, weight: .medium, design: .serif))
                    .tracking(1.0)
                    .foregroundStyle(Color.tarotIvory.opacity(0.28))
                    .padding(.bottom, 18)
            }
            .padding(.horizontal, 24)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.9)) { appear = true }
            withAnimation(LuxuryAnimation.breathe) { halo = 1.04 }
        }
    }
}

// MARK: - Tarot card emblem — carta minimal morada (mismo lenguaje que el icono)
private struct TarotCardEmblem: View {
    var size: CGFloat = 52
    var body: some View {
        ZStack {
            // Carta base — rounded rect morado
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color(red: 0.11, green: 0.08, blue: 0.19))
                .frame(width: size*0.66, height: size)
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(Color.tarotGold, lineWidth: 1.25)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 4.5, style: .continuous)
                        .stroke(Color.tarotGold.opacity(0.22), lineWidth: 0.85)
                        .padding(6)
                )
            // Estrella central tarot — 5 puntas hairline
            Canvas { ctx, sz in
                let c = CGPoint(x: sz.width/2, y: sz.height/2)
                let outer: CGFloat = size*0.22
                let inner: CGFloat = size*0.09
                var pts: [CGPoint] = []
                for i in 0..<10 {
                    let a = Double(-90 + i*36) * Double.pi/180
                    let r = i%2==0 ? outer : inner
                    pts.append(CGPoint(x: c.x + CGFloat(cos(a))*r, y: c.y + CGFloat(sin(a))*r))
                }
                var p = Path()
                p.move(to: pts[0])
                for pt in pts.dropFirst() { p.addLine(to: pt) }
                p.closeSubpath()
                ctx.stroke(p, with: .color(Color.tarotGold), lineWidth: 1.15)
                // círculo central
                let cr: CGFloat = size*0.065
                ctx.stroke(Path(ellipseIn: CGRect(x: c.x-cr, y: c.y-cr, width: cr*2, height: cr*2)), with: .color(Color.tarotGold.opacity(0.52)), lineWidth: 0.9)
            }
            .frame(width: size, height: size)
            // sparkles esquinas — muy sutiles
            ForEach([CGPoint(x: -size*0.18, y: -size*0.32), CGPoint(x: size*0.20, y: -size*0.26)], id: \.x) { off in
                Image(systemName: "sparkle")
                    .font(.system(size: 5, weight: .thin))
                    .foregroundStyle(Color.tarotGoldHighlight.opacity(0.72))
                    .offset(x: off.x, y: off.y)
            }
        }
        .frame(width: size, height: size)
    }
}
