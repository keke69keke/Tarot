import SwiftUI
import TarotCore
import TarotData

struct CardDetailText: View {
    let card: Card
    let orientation: CardOrientation
    let repository: any CardRepository

    var body: some View {
        let interpretation = repository.interpretation(for: card, position: nil, orientation: orientation)
        VStack(alignment: .leading, spacing: 12) {
            Label(orientation == .upright ? "Al derecho" : "Invertida", systemImage: orientation == .upright ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                .foregroundStyle(orientation == .upright ? Color(red: 0.20, green: 0.46, blue: 0.28) : Color.tarotBurgundy)
                .font(.headline)

            Text(interpretation.summary)

            if !interpretation.keywords.isEmpty {
                Text(interpretation.keywords.joined(separator: " · "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if !interpretation.aspects.isEmpty {
                Divider()
                Text("Consulta rápida").font(.subheadline).bold()
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(interpretation.aspects.keys).sorted(), id: \.self) { aspect in
                        if let value = interpretation.aspects[aspect] {
                            HStack(alignment: .top, spacing: 0) {
                                Text(aspect + ": ")
                                    .foregroundColor(.primary)
                                Text(value)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .font(.subheadline)
            }

            if orientation == .reversed {
                Text("Interpretación invertida mostrada arriba.").font(.caption).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
