import SwiftUI
import TarotCore

/// Lectura en profundidad de la carta: claves arquetípicas (numerología,
/// elemento, simbolismo) y su mensaje en tres planos (amor, trabajo, espíritu).
/// Todo derivado de forma determinista desde los datos del mazo.
struct CardDeepDiveView: View {
    let card: Card
    let orientation: CardOrientation

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "text.book.closed")
                    .foregroundStyle(Color.tarotGold)
                Text("Lectura en Profundidad")
                    .font(.system(size: 16, weight: .bold, design: .serif))
                    .foregroundStyle(Color.tarotIvory)
                Spacer()
                Text(orientation == .upright ? "Al derecho" : "Invertida")
                    .font(.system(size: 9, weight: .bold, design: .serif))
                    .tracking(0.8)
                    .foregroundStyle(Color.tarotGold)
            }
            .accessibilityAddTraits(.isHeader)

            VStack(alignment: .leading, spacing: 12) {
                row(icon: "number", title: "Numerología", text: card.numerologyMeaning)
                row(icon: "flame", title: "Elemento", text: card.elementMeaning)
                row(icon: "eye.trianglebadge.exclamationmark", title: "Simbolismo", text: card.symbolism)
            }

            Text("EN TRES PLANOS")
                .font(.system(size: 9, weight: .bold, design: .serif))
                .tracking(1.4)
                .foregroundStyle(Color.tarotGold.opacity(0.75))

            VStack(alignment: .leading, spacing: 12) {
                row(icon: "heart", title: "Amor", text: card.loveReading)
                row(icon: "briefcase", title: "Trabajo y abundancia", text: card.workReading)
                row(icon: "sparkles", title: "Camino espiritual", text: card.spiritualReading)
            }

            if orientation == .reversed {
                Text("Al estar invertida, lee estos planos como un espejo: la energía pide integrarse por dentro antes de manifestarse afuera.")
                    .font(.system(size: 11, weight: .regular, design: .serif))
                    .foregroundStyle(Color.tarotBurgundy.opacity(0.9))
                    .lineSpacing(2.5)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 2)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(LinearGradient(
                    colors: [Color.tarotGold.opacity(0.08), Color.tarotBurgundy.opacity(0.05)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.tarotGold.opacity(0.25), lineWidth: 1)
        )
    }

    private func row(icon: String, title: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.tarotGold.opacity(0.14))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.tarotGold)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.tarotIvory)
                Text(text)
                    .font(.caption)
                    .foregroundStyle(Color.tarotIvory.opacity(0.62))
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
    }
}
