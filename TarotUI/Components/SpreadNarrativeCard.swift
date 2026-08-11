import SwiftUI
import TarotCore
import TarotData

struct SpreadNarrativeCard: View {
    let spread: Spread
    let repository: any CardRepository
    let intention: String
    @State private var expanded = false

    init(spread: Spread, repository: any CardRepository, intention: String = "") {
        self.spread = spread
        self.repository = repository
        self.intention = intention
    }

    private var narrative: String {
        let synthesizer = SpreadSynthesizer(cardRepository: repository)
        var base = synthesizer.synthesize(for: spread, drawnCards: spread.drawnCards)
        if !intention.isEmpty {
            base = "🎯 **Intención**: \(intention)\n\n\(base)"
        }
        return base
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .foregroundStyle(Color.tarotAccent)
                Text("Lectura Completa")
                    .font(.system(size: 16, weight: .bold, design: .serif))
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: "book.closed.fill")
                    .foregroundStyle(Color.tarotAccent.opacity(0.6))
            }

            Text(narrative)
                .font(.system(size: 14, design: .serif))
                .lineSpacing(6)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(expanded ? nil : 6)
                .fixedSize(horizontal: false, vertical: true)

            if narrative.count > 200 {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        expanded.toggle()
                    }
                } label: {
                    HStack(spacing: 5) {
                        Text(expanded ? "Mostrar menos" : "Leer lectura completa")
                            .font(.caption.weight(.semibold))
                        Image(systemName: expanded ? "chevron.up" : "chevron.down")
                            .font(.caption2)
                    }
                    .foregroundStyle(Color.tarotAccent)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.tarotAccent.opacity(0.10), Color.tarotBurgundy.opacity(0.10)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(LinearGradient(colors: [Color.tarotAccent.opacity(0.4), Color.tarotBurgundy.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
        )
        .shadow(color: Color.tarotShadow.opacity(0.2), radius: 10, x: 0, y: 6)
    }
}

