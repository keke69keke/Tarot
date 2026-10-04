import SwiftUI
import TarotCore
import TarotData

struct SpreadNarrativeCard: View {
    let spread: Spread
    let synthesizer: any SpreadSynthesizerProtocol
    let intention: String
    @State private var expanded = false
    @State private var narrative: String?
    @State private var isLoading = false
    @State private var errorMessage: String?

    init(spread: Spread, synthesizer: any SpreadSynthesizerProtocol, intention: String = "") {
        self.spread = spread
        self.synthesizer = synthesizer
        self.intention = intention
    }

    private func loadNarrative() async {
        isLoading = true
        errorMessage = nil
        do {
            var base = try await synthesizer.synthesize(for: spread, drawnCards: spread.drawnCards)
            if !intention.isEmpty {
                base = "◈ **Intención**: \(intention)\n\n\(base)"
            }
            narrative = base
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .foregroundStyle(Color.tarotAccent)
                Text("Lectura Completa")
                    .font(.system(size: 16, weight: .bold, design: .serif))
                    .foregroundStyle(Color.tarotIvory)
                Spacer()
                Image(systemName: "book.closed")
                    .foregroundStyle(Color.tarotAccent.opacity(0.6))
            }

            if isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                        .tint(Color.tarotGold)
                    Spacer()
                }
                .padding(.vertical, 20)
            } else if let error = errorMessage {
                Text("No se pudo sintetizar la lectura: \(error)")
                    .font(.system(size: 14, design: .serif))
                    .foregroundStyle(Color.red.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else if let text = narrative {
                VStack(alignment: .leading, spacing: 12) {
                    Text(text)
                        .font(.system(size: 14, design: .serif))
                        .lineSpacing(6)
                        .foregroundStyle(Color.tarotIvory.opacity(0.58))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lineLimit(expanded ? nil : 6)
                        .fixedSize(horizontal: false, vertical: true)

                    if text.count > 200 {
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
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.tarotAccent.opacity(0.10), Color.tarotAccent.opacity(0.04)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.tarotAccent.opacity(0.30), lineWidth: 1)
        )
        .shadow(color: Color.tarotShadow.opacity(0.2), radius: 10, x: 0, y: 6)
        .task {
            await loadNarrative()
        }
    }
}

