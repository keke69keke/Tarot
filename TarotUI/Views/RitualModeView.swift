import SwiftUI

/// A high-end, immersive pre-draw sequence that prepares the user's energy before a reading.
public struct RitualModeView: View {
    @Binding var isActive: Bool
    var onComplete: () -> Void

    @State private var focusAmount: CGFloat = 0.0
    @State private var isPulsing = false

    public var body: some View {
        ZStack {
            // Deep background
            Color.tarotBackground.ignoresSafeArea()

            // Ambient breathing glow
            Circle()
                .fill(RadialGradient(
                    gradient: Gradient(colors: [Color.tarotGold.opacity(0.15), .clear]),
                    center: .center,
                    startRadius: 50,
                    endRadius: 300
                ))
                .frame(width: 600, height: 600)
                .scaleEffect(isPulsing ? 1.2 : 0.8)
                .opacity(isPulsing ? 0.6 : 0.3)
                .animation(.easeInOut(duration: 3.2).repeatForever(autoreverses: true), value: isPulsing)

            VStack(spacing: 40) {
                Spacer()

                // Central ritual focus point
                ZStack {
                    Circle()
                        .stroke(Color.tarotGold.opacity(0.2), lineWidth: 1)
                        .frame(width: 200, height: 200)

                    Circle()
                        .stroke(Color.tarotGoldGradient, lineWidth: 2)
                        .frame(width: 180, height: 180)
                        .scaleEffect(1.0 + (focusAmount * 0.2))
                        .opacity(0.3 + (focusAmount * 0.7))
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: focusAmount)

                    Image(systemName: "sparkles")
                        .font(.system(size: 40, weight: .thin))
                        .foregroundStyle(Color.tarotGold)
                        .scaleEffect(1.0 + (focusAmount * 0.1))
                }
                .frame(width: 200, height: 200)

                VStack(spacing: 20) {
                    Text("Sintoniza tu energía")
                        .font(.system(size: 22, weight: .medium, design: .serif))
                        .tracking(1.2)
                        .foregroundStyle(Color.tarotIvory)

                    Text("Mantén presionado para cargar la lectura")
                        .font(.system(size: 14, weight: .regular, design: .serif))
                        .foregroundStyle(Color.tarotIvory.opacity(0.5))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }

                // Focus Button
                Button {
                    // Interaction handled by LongPressGesture in parent or via a custom gesture
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.tarotGold.opacity(0.1))
                            .frame(width: 80, height: 80)
                            .overlay(Circle().stroke(Color.tarotGold.opacity(0.4), lineWidth: 1))

                        Image(systemName: "hand.tap.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(Color.tarotGold)
                    }
                }
                .buttonStyle(.plain)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            // Simulate charging
                            if focusAmount < 1.0 {
                                focusAmount += 0.02
                                HapticManager.shared.triggerSelection()
                            }
                        }
                        .onEnded { _ in
                            if focusAmount >= 0.9 {
                                HapticManager.shared.triggerHeavy()
                                onComplete()
                            } else {
                                withAnimation(.spring()) {
                                    focusAmount = 0
                                }
                            }
                        }
                )

                Spacer()
            }
            .padding()
        }
        .onAppear {
            isPulsing = true
        }
    }
}
