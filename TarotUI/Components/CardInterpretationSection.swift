import SwiftUI
import TarotCore
import TarotData

struct CardInterpretationSection: View {
    let title: String
    let orientation: CardOrientation
    let interpretation: Interpretation
    let orderedAspectKeys: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: orientation == .upright ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                .font(.headline)
                .foregroundStyle(orientation == .upright ? Color(red: 0.20, green: 0.46, blue: 0.28) : Color.tarotBurgundy)

            Text(interpretation.summary)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)

            if !interpretation.keywords.isEmpty {
                Text(interpretation.keywords.joined(separator: " · "))
                    .font(.caption)
                    .foregroundStyle(Color.tarotIvory.opacity(0.58))
            }

            if !interpretation.aspects.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Aspectos").font(.subheadline).bold()
                    ForEach(aspectKeys(in: interpretation), id: \.self) { aspect in
                        if let value = interpretation.aspects[aspect] {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(aspect).bold()
                                Text(value).font(.subheadline).foregroundStyle(Color.tarotIvory.opacity(0.58))
                            }
                        }
                    }
                }
            }

            if !interpretation.contextual.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Contexto por posición").font(.subheadline).bold()
                    ForEach(interpretation.contextual.keys.sorted(by: { $0.displayName < $1.displayName }), id: \.self) { key in
                        if let value = interpretation.contextual[key] {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(key.displayName).bold()
                                Text(value).font(.body).foregroundStyle(Color.tarotIvory.opacity(0.58))
                            }
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.tarotPanel.opacity(0.80))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.tarotBorder, lineWidth: 1)
        )
    }

    private func aspectKeys(in interpretation: Interpretation) -> [String] {
        let knownKeys = orderedAspectKeys.filter { interpretation.aspects.keys.contains($0) }
        let extraKeys = interpretation.aspects.keys.sorted().filter { !knownKeys.contains($0) }
        return knownKeys + extraKeys
    }
}

