import SwiftUI
import TarotCore

/// Tutorial de primer arranque: un paseo guiado por cada sección de la app.
/// Aparece una sola vez (persistido en UserDefaults) y puede repetirse desde Ajustes.
struct SectionsTutorialView: View {
    let onComplete: () -> Void

    @State private var step = 0
    @State private var appear = false

    private struct TutorialStep {
        let eyebrow: String
        let title: String
        let description: String
        let icon: String
        let tips: [String]
    }

    private let steps: [TutorialStep] = [
        TutorialStep(
            eyebrow: "Bienvenida",
            title: "Un paseo por ARCANA",
            description: "Trece secciones, un solo ritual. Te muestro qué vive en cada rincón para que empieces con ventaja.",
            icon: "sparkles",
            tips: ["Todo tu progreso se guarda solo", "Puedes repetir este tutorial desde Ajustes"]
        ),
        TutorialStep(
            eyebrow: "Lectura",
            title: "Tirada",
            description: "El corazón de la app. Elige una tirada (hay 22), define tu intención y deja que el mazo hable.",
            icon: "diamond",
            tips: ["Toca «Todas» para ver el catálogo completo", "Puedes fijar las 2 primeras cartas o una significadora"]
        ),
        TutorialStep(
            eyebrow: "Lectura",
            title: "Preguntar & Hoy",
            description: "«Preguntar» responde una duda concreta con astrología en vivo. «Hoy» revela tu carta del día y su mensaje.",
            icon: "sunrise",
            tips: ["La carta del día es la misma durante todo el día", "Agita el iPhone para barajar (Tirada)"]
        ),
        TutorialStep(
            eyebrow: "Lectura",
            title: "Arcana IA",
            description: "Conversa con la IA arcana: sube tu tirada, pide una síntesis o pregunta el significado de cualquier carta.",
            icon: "wand.and.stars",
            tips: ["Configura tu clave de OpenAI en Ajustes"]
        ),
        TutorialStep(
            eyebrow: "Estudio",
            title: "Biblioteca",
            description: "Las 78 cartas en Galería o formato Libro: significados al derecho e invertida, amor, salud, carrera y símbolos.",
            icon: "rectangle.stack",
            tips: ["Cambia de mazo en Ajustes: Rider-Waite, Marsella, etc."]
        ),
        TutorialStep(
            eyebrow: "Estudio",
            title: "Aprender & Referencia",
            description: "Una sola entrada con dos solapas: «Aprender» es tu curso con lecciones y sonido, y «Referencia» guarda libros PDF, la guía ilustrada y el Atlas de Símbolos.",
            icon: "lightbulb",
            tips: ["Cambia de solapa arriba", "Importa tus propios PDF en Referencia", "Marca páginas y retoma donde dejaste"]
        ),
        TutorialStep(
            eyebrow: "Estudio",
            title: "Fases lunares",
            description: "Dónde está la luna hoy, qué ritual le corresponde y el ciclo completo con las ocho fases.",
            icon: "moon.stars",
            tips: ["Toca cualquier fase para leer su ritual"]
        ),
        TutorialStep(
            eyebrow: "Estudio",
            title: "Horóscopo, Biorritmo & Hoja Natal",
            description: "Tu mapa cósmico: horóscopo diario, ritmos físicos/emo­cionales/intelectuales y tu carta natal dibujada.",
            icon: "moon.stars",
            tips: ["Completa fecha, hora y lugar de nacimiento en Ajustes"]
        ),
        TutorialStep(
            eyebrow: "Personal",
            title: "Diario & Almas",
            description: "Guarda cada lectura en tu diario para ver patrones con el tiempo, y vincula almas queridas para leer su conexión.",
            icon: "text.book.closed",
            tips: ["El diario enriquece las lecturas: más entradas, más patrones"]
        ),
        TutorialStep(
            eyebrow: "Listo",
            title: "Tu ritual comienza",
            description: "Eso es todo. Empieza con una tirada de tres cartas y deja que la intuición haga el resto.",
            icon: "star.circle",
            tips: ["Baraja con intención", "Vuelve cada día: la carta diaria te espera"]
        )
    ]

    var body: some View {
        ZStack {
            Color.tarotBackground.ignoresSafeArea()
            Color.tarotBackgroundGradient.ignoresSafeArea()
            LuxuryVignette()

            VStack(spacing: 0) {
                // Progreso
                HStack(spacing: 6) {
                    ForEach(0..<steps.count, id: \.self) { i in
                        Capsule()
                            .fill(i <= step ? AnyShapeStyle(Color.tarotGoldGradient) : AnyShapeStyle(Color.white.opacity(0.10)))
                            .frame(width: i == step ? 26 : 10, height: 3)
                    }
                }
                .padding(.top, 46)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 26) {
                        // Emblema
                        ZStack {
                            Circle()
                                .fill(Color.tarotGold.opacity(0.10))
                                .frame(width: 130, height: 130)
                                .blur(radius: 18)
                            Circle()
                                .strokeBorder(Color.tarotGold.opacity(0.25), lineWidth: 0.8)
                                .frame(width: 108, height: 108)
                            Image(systemName: steps[step].icon)
                                .font(.system(size: 40, weight: .thin))
                                .foregroundStyle(Color.tarotGold)
                        }
                        .padding(.top, 34)
                        .scaleEffect(appear ? 1 : 0.94)
                        .opacity(appear ? 1 : 0)

                        VStack(spacing: 10) {
                            Text(steps[step].eyebrow.uppercased())
                                .font(.system(size: 10, weight: .bold, design: .serif))
                                .tracking(2.6)
                                .foregroundStyle(Color.tarotGold.opacity(0.85))
                            Text(steps[step].title)
                                .font(.system(size: 30, weight: .bold, design: .serif))
                                .foregroundStyle(Color.tarotIvory)
                                .multilineTextAlignment(.center)
                            Text(steps[step].description)
                                .font(.system(size: 14.5, weight: .light, design: .serif))
                                .foregroundStyle(Color.tarotIvory.opacity(0.65))
                                .lineSpacing(4)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.horizontal, 24)
                        }
                        .opacity(appear ? 1 : 0)
                        .offset(y: appear ? 0 : 10)

                        // Tips
                        VStack(alignment: .leading, spacing: 9) {
                            ForEach(steps[step].tips, id: \.self) { tip in
                                HStack(alignment: .top, spacing: 9) {
                                    Image(systemName: "diamond.fill")
                                        .font(.system(size: 6))
                                        .foregroundStyle(Color.tarotGold.opacity(0.8))
                                        .padding(.top, 5)
                                    Text(tip)
                                        .font(.system(size: 12.5, weight: .medium, design: .serif))
                                        .foregroundStyle(Color.tarotIvory.opacity(0.72))
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                        .padding(16)
                        .frame(maxWidth: 460)
                        .background(
                            RoundedRectangle(cornerRadius: LuxuryRadius.md, style: .continuous)
                                .fill(Color.white.opacity(0.045))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: LuxuryRadius.md, style: .continuous)
                                .stroke(Color.tarotGold.opacity(0.18), lineWidth: 0.75)
                        )
                        .padding(.horizontal, 24)
                    }
                    .padding(.bottom, 20)
                }

                // Navegación
                HStack(spacing: 14) {
                    if step > 0 {
                        Button {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                                step -= 1
                                reappear()
                            }
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Color.tarotIvory.opacity(0.7))
                                .frame(width: 48, height: 48)
                                .background(Circle().fill(Color.white.opacity(0.06)))
                                .overlay(Circle().stroke(Color.tarotGold.opacity(0.25), lineWidth: 0.8))
                        }
                        .buttonStyle(.plain)
                    }

                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                            if step < steps.count - 1 {
                                step += 1
                                reappear()
                            } else {
                                onComplete()
                            }
                        }
                    } label: {
                        HStack(spacing: 9) {
                            Text(step == steps.count - 1 ? "Comenzar" : "Continuar")
                                .font(.system(size: 14, weight: .semibold, design: .serif))
                                .tracking(1.0)
                            Image(systemName: "arrow.right")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundStyle(Color.tarotIvory)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.tarotGoldGradient))
                        .shadow(color: Color.tarotGoldDeep.opacity(0.45), radius: 14, x: 0, y: 8)
                    }
                    .buttonStyle(LuxuryPrimaryButtonStyle())
                }
                .padding(.horizontal, LuxurySpacing.lg)
                .padding(.bottom, 34)
            }
        }
        .onAppear { reappear() }
        .onTapGesture { HapticManager.shared.triggerSelection() }
    }

    private func reappear() {
        appear = false
        withAnimation(.easeOut(duration: 0.45).delay(0.05)) { appear = true }
    }
}
