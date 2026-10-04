import SwiftUI
import TarotCore

/// Ficha informativa de una tirada: cuántas cartas, su tradición, cómo leerla
/// y para qué sirve. Se muestra en el selector y en el catálogo completo.
struct SpreadInfoCard: View {
    let spreadType: SpreadType
    var compact: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 10 : 14) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(spreadType.symbol)
                    .font(.system(size: compact ? 16 : 20, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.tarotGold)
                Text(spreadType.label)
                    .font(.system(size: compact ? 13 : 16, weight: .bold, design: .serif))
                    .foregroundStyle(Color.tarotIvory)
                Spacer(minLength: 0)
                Text("\(spreadType.positions.count) cartas")
                    .font(.system(size: 10, weight: .bold, design: .serif))
                    .tracking(0.6)
                    .foregroundStyle(Color.tarotGold)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Capsule().fill(Color.tarotGold.opacity(0.14)))
                    .overlay(Capsule().stroke(Color.tarotGold.opacity(0.25), lineWidth: 0.6))
            }
            .accessibilityAddTraits(.isHeader)

            block(icon: "book.closed", title: "Tradición", text: spreadType.story)
            block(icon: "eye", title: "Cómo leerla", text: spreadType.howToRead)
            block(icon: "target", title: "Ideal para", text: spreadType.bestFor)

            if !compact {
                Text(spreadType.esotericDescription)
                    .font(.system(size: 10, weight: .regular, design: .serif))
                    .foregroundStyle(Color.tarotIvory.opacity(0.45))
                    .padding(.top, 2)
            }
        }
        .padding(compact ? 14 : 18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .luxuryGlass(cornerRadius: compact ? 16 : 20)
    }

    private func block(icon: String, title: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .light))
                .foregroundStyle(Color.tarotGold.opacity(0.9))
                .frame(width: 16, height: 16)
                .padding(.top, 1)
            VStack(alignment: .leading, spacing: 3) {
                Text(title.uppercased())
                    .font(.system(size: 9, weight: .bold, design: .serif))
                    .tracking(1.2)
                    .foregroundStyle(Color.tarotGold.opacity(0.75))
                Text(text)
                    .font(.system(size: compact ? 11.5 : 12.5, weight: .regular, design: .serif))
                    .foregroundStyle(Color.tarotIvory.opacity(0.78))
                    .lineSpacing(2.5)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
    }
}
