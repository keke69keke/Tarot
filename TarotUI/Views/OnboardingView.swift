import SwiftUI
import TarotCore
import TarotDI

/// Vista de iniciación espiritual: transforma el primer arranque en un ritual guiado.
struct OnboardingView: View {
    @EnvironmentObject var model: TarotViewModel
    @State private var step = 0
    @State private var userIntention = ""
    @State private var userName = ""
    @State private var isCompleting = false

    private let steps = [
        OnboardingStep(
            title: "El Llamado",
            description: "Has llegado al espejo del alma. Este no es un simple juego de azar, sino un puente hacia tu inconsciente.",
            image: "moon.stars.fill"
        ),
        OnboardingStep(
            title: "Tu Identidad",
            description: "¿Cómo desea el universo llamarte en este camino?",
            image: "person.crop.circle",
            isInput: true
        ),
        OnboardingStep(
            title: "Tu Intención",
            description: "Define el ancla de tu camino. ¿Buscas claridad, sanación, evolución o simplemente escuchar la verdad?",
            image: "sparkles",
            isInput: true
        ),
        OnboardingStep(
            title: "El Vínculo",
            description: "A partir de ahora, cada carta, cada fase lunar y cada planeta resonarán con tu intención. El ritual ha comenzado.",
            image: "wand.and.stars"
        )
    ]

    var body: some View {
        ZStack {
            // Background Atmosférico
            Color.tarotBackground.ignoresSafeArea()
            Color.tarotBackgroundGradient.ignoresSafeArea()
            AmbientBackgroundView().opacity(0.6)

            VStack(spacing: 40) {
                // Barra de progreso minimalista
                HStack(spacing: 8) {
                    ForEach(0..<steps.count, id: \.self) { i in
                        Capsule()
                            .fill(i <= step ? Color.tarotGold : Color.white.opacity(0.1))
                            .frame(width: i == step ? 30 : 12, height: 3)
                            .animation(.spring(), value: step)
                    }
                }
                .padding(.top, 60)
                .padding(.horizontal, 40)

                // Contenido del paso
                VStack(spacing: 32) {
                    ZStack {
                        Circle()
                            .fill(Color.tarotGold.opacity(0.1))
                            .frame(width: 120, height: 120)
                            .blur(radius: 20)

                        Image(systemName: steps[step].image)
                            .font(.system(size: 48, weight: .thin))
                            .foregroundStyle(Color.tarotGold)
                            .scaleEffect(isCompleting ? 1.2 : 1.0)
                            .animation(.easeInOut(duration: 0.8), value: isCompleting)
                    }
                    .frame(height: 150)

                    VStack(spacing: 16) {
                        Text(steps[step].title)
                            .font(.system(size: 32, weight: .bold, design: .serif))
                            .foregroundStyle(Color.tarotIvory)
                            .tracking(-0.5)

                        Text(steps[step].description)
                            .font(.system(size: 17, weight: .regular, design: .serif))
                            .foregroundStyle(Color.tarotIvory.opacity(0.65))
                            .multilineTextAlignment(.center)
                            .lineSpacing(6)
                            .padding(.horizontal, 30)
                    }
                }
                .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
                .id(step)

                if steps[step].isInput {
                    inputField
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                Spacer()

                // Botón de navegación
                Button {
                    nextStep()
                } label: {
                    HStack(spacing: 12) {
                        Text(step == steps.count - 1 ? "Iniciar Ritual" : "Continuar")
                            .font(.system(size: 16, weight: .semibold, design: .serif))
                            .tracking(1.0)

                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .light))
                    }
                    .foregroundStyle(Color(red: 0.09, green: 0.06, blue: 0.02))
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(Capsule().fill(Color.tarotGoldGradient))
                    .overlay(Capsule().stroke(Color.white.opacity(0.3), lineWidth: 0.7))
                    .shadow(color: Color.black.opacity(0.3), radius: 15, x: 0, y: 8)
                }
                .buttonStyle(.plain)
                .padding(.bottom, 60)
            }
            .padding(.horizontal, 24)
        }
    }

    @ViewBuilder
    private var inputField: some View {
        TextField(
            step == 1 ? "Tu nombre..." : "Tu intención...",
            text: step == 1 ? $userName : $userIntention
        )
        .font(.system(size: 18, design: .serif))
        .foregroundStyle(Color.tarotIvory)
        .multilineTextAlignment(.center)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.05))
                .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(.ultraThinMaterial).opacity(0.4))
                .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Color.tarotGold.opacity(0.2), lineWidth: 1))
        )
        .padding(.horizontal, 20)
        .transition(.opacity)
    }

    private func nextStep() {
        if step == 1 && userName.isEmpty { return }
        if step == 2 && userIntention.isEmpty { return }

        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            if step < steps.count - 1 {
                step += 1
            } else {
                completeOnboarding()
            }
        }
    }

    private func completeOnboarding() {
        isCompleting = true
        withAnimation(.easeInOut(duration: 1.2)) {
            model.settings.userName = userName
            model.settings.natalPlace = userIntention // Use as a starting point for intention
            model.persistSettings()
            // Mark as seen welcome
            UserDefaults.standard.set(true, forKey: "hasSeenWelcome")
        }
    }
}

struct OnboardingStep {
    let title: String
    let description: String
    let image: String
    var isInput: Bool = false
}
