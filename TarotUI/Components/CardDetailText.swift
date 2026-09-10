import SwiftUI
import TarotColors
import TarotCore
import TarotData

struct CardDetailText: View {
    let card: Card
    let orientation: CardOrientation
    let repository: any CardRepository

    var body: some View {
        let interpretation = repository.interpretation(
            for: card,
            position: nil,
            orientation: orientation
        )

        VStack(alignment: .leading, spacing: 12) {
            // Orientation indicator
            Label(orientation == .upright ? "Al derecho" : "Invertida",
                  systemImage: orientation == .upright ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
            .foregroundStyle(orientation == .upright ? Color.tarotAspectSalud : Color.tarotBurgundy)
            .font(.headline)

            // Summary text
            Text(interpretation.summary)
            .foregroundStyle(Color.tarotIvory)

            // Keywords
            if !interpretation.keywords.isEmpty {
                Text(interpretation.keywords.joined(separator: " · "))
                .font(.caption)
                .foregroundStyle(Color.tarotIvory.opacity(0.58))
            }

            // Aspects
            if !interpretation.aspects.isEmpty {
                Divider()
                    .background(Color.tarotBorder)
                Text("Consulta rápida").font(.subheadline).bold()
                    .foregroundStyle(Color.tarotIvory)

                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(interpretation.aspects.keys).sorted(), id: \.self) { aspect in
                        if let value = interpretation.aspects[aspect] {
                            HStack(alignment: .top, spacing: 0) {
                                Text(aspect + ": ")
                                    .foregroundColor(Color.tarotIvory)
                                Text(value)
                                    .foregroundColor(Color.tarotIvory.opacity(0.58))
                            }
                        }
                    }
                }
                .font(.subheadline)
            }

            // Reversed note
            if orientation == .reversed {
                Text("Interpretación invertida mostrada arriba.")
                .font(.caption)
                .foregroundStyle(Color.tarotIvory.opacity(0.58))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
