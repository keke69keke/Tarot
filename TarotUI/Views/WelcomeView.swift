import SwiftUI

struct WelcomeView: View {
    let colorScheme: ColorScheme
    let userName: String
    let onDismiss: () -> Void

    @State private var starOpacity: Double = 0
    @State private var titleOffset: CGFloat = 30
    @State private var titleOpacity: Double = 0
    @State private var subtitleOpacity: Double = 0
    @State private var buttonOpacity: Double = 0
    @State private var rotationAngle: Double = 0
    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        ZStack {
// Deep mystical background (esoteric purple)
            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.02, blue: 0.18),
                    Color(red: 0.12, green: 0.04, blue: 0.26),
                    Color(red: 0.05, green: 0.02, blue: 0.14)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Ambient glow orbs — esoteric purple palette
            Circle()
                .fill(Color(red: 0.42, green: 0.12, blue: 0.42).opacity(0.30)) // deep violet
                .frame(width: 420, height: 420)
                .blur(radius: 90)
                .offset(x: -80, y: -220)

            Circle()
                .fill(Color(red: 0.72, green: 0.55, blue: 0.95).opacity(0.24)) // lavender
                .frame(width: 300, height: 300)
                .blur(radius: 70)
                .offset(x: 120, y: 240)

            Circle()
                .fill(Color(red: 0.20, green: 0.08, blue: 0.40).opacity(0.42)) // deep purple
                .frame(width: 180, height: 180)
                .blur(radius: 40)
                .offset(x: -40, y: 60)

            // Rotating star mandala
            ZStack {
                ForEach(0..<8, id: \.self) { i in
                    Image(systemName: "sparkle")
                        .font(.system(size: 12, weight: .thin))
                        .foregroundStyle(Color(red: 0.78, green: 0.62, blue: 0.98).opacity(0.5))
                        .offset(y: -110)
                        .rotationEffect(.degrees(Double(i) * 45))
                }
                ForEach(0..<16, id: \.self) { i in
                    Circle()
                        .fill(Color(red: 0.72, green: 0.55, blue: 0.95).opacity(0.18))
                        .frame(width: 3, height: 3)
                        .offset(y: -155)
                        .rotationEffect(.degrees(Double(i) * 22.5))
                }
            }
            .rotationEffect(.degrees(rotationAngle))
            .opacity(starOpacity)

            VStack(spacing: 0) {
                Spacer()

                // Central tarot card icon with pulse
                ZStack {
                    // Outer glow ring
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.90, green: 0.78, blue: 1.0),
                                    Color(red: 0.55, green: 0.35, blue: 0.80),
                                    Color(red: 0.90, green: 0.78, blue: 1.0)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                        .frame(width: 100, height: 100)
                        .opacity(starOpacity * 0.6)
                        .scaleEffect(pulseScale)

// Inner background
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(red: 0.30, green: 0.15, blue: 0.55),
                                    Color(red: 0.12, green: 0.05, blue: 0.28)
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 48
                            )
                        )
                        .frame(width: 96, height: 96)

                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 38))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.90, green: 0.78, blue: 1.0),
                                    Color(red: 0.72, green: 0.55, blue: 0.95)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
                .shadow(color: Color(red: 0.42, green: 0.20, blue: 0.60).opacity(0.70), radius: 30, x: 0, y: 0)
                .opacity(starOpacity)

                Spacer().frame(height: 40)

                // Greeting text
                VStack(spacing: 14) {
                    Text(userName.isEmpty ? "Bienvenida" : "Hola, \(userName)")
                        .font(.system(size: 44, weight: .bold, design: .serif))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.90, green: 0.78, blue: 1.0),
                                    Color(red: 0.78, green: 0.62, blue: 0.98),
                                    Color(red: 0.55, green: 0.35, blue: 0.80)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: Color(red: 0.55, green: 0.35, blue: 0.80).opacity(0.45), radius: 16, x: 0, y: 4)
                        .offset(y: titleOffset)
                        .opacity(titleOpacity)

                    Text("Las cartas te esperan")
                        .font(.system(size: 17, weight: .regular, design: .serif))
                        .tracking(2)
                        .foregroundStyle(Color(red: 0.90, green: 0.78, blue: 1.0).opacity(0.80))
                        .opacity(subtitleOpacity)

                    HStack(spacing: 6) {
                        ForEach(0..<5, id: \.self) { _ in
                            Image(systemName: "sparkle")
                                .font(.caption2)
                                .foregroundStyle(Color(red: 0.78, green: 0.62, blue: 0.98).opacity(0.50))
                        }
                    }
                    .opacity(subtitleOpacity)
                }

                Spacer().frame(height: 64)

                // Enter button
                Button(action: onDismiss) {
                    HStack(spacing: 10) {
                        Image(systemName: "sparkles")
                        Text("Iniciar lectura")
                            .fontWeight(.semibold)
                    }
                    .font(.body)
                    .foregroundStyle(.black.opacity(0.85))
                    .padding(.horizontal, 36)
                    .padding(.vertical, 16)
.background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.78, green: 0.62, blue: 0.98),
                                        Color(red: 0.42, green: 0.20, blue: 0.60)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .shadow(color: Color(red: 0.42, green: 0.20, blue: 0.60).opacity(0.55), radius: 18, x: 0, y: 8)
                    .scaleEffect(pulseScale)
                }
                .opacity(buttonOpacity)

                Spacer().frame(height: 20)

                Text("Tarot Rider-Waite")
                    .font(.caption2)
                    .tracking(3)
                    .foregroundStyle(Color.white.opacity(0.20))
                    .opacity(buttonOpacity)

                Spacer()
            }
        }
        .onAppear {
            // Staggered entrance animations
            withAnimation(.easeOut(duration: 1.4).delay(0.1)) {
                starOpacity = 1
            }
            withAnimation(.easeOut(duration: 0.9).delay(0.4)) {
                titleOffset = 0
                titleOpacity = 1
            }
            withAnimation(.easeOut(duration: 0.8).delay(0.85)) {
                subtitleOpacity = 1
            }
            withAnimation(.easeOut(duration: 0.7).delay(1.2)) {
                buttonOpacity = 1
            }
            // Continuous gentle rotation
            withAnimation(.linear(duration: 30).repeatForever(autoreverses: false)) {
                rotationAngle = 360
            }
            // Pulse breathing
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true).delay(1.0)) {
                pulseScale = 1.06
            }
        }
    }
}
