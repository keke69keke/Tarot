import SwiftUI
import TarotCore
import TarotData

struct CardAspectSummaryView: View {
    let interpretation: Interpretation
    private let highlightKeys = ["Amor", "Economía", "Salud", "Carrera"]
    private let aspectIcons = ["Amor": "heart.fill", "Economía": "banknote.fill", "Salud": "cross.fill", "Carrera": "briefcase.fill"]
    private let aspectColors: [String: Color] = [
        "Amor": Color(red: 0.72, green: 0.18, blue: 0.18),
        "Economía": Color(red: 0.78, green: 0.58, blue: 0.18),
        "Salud": Color(red: 0.20, green: 0.46, blue: 0.28),
        "Carrera": Color(red: 0.18, green: 0.28, blue: 0.52)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Aspectos clave")
                .font(.headline)
                .foregroundStyle(Color.tarotIvory)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(highlightKeys.filter { interpretation.aspects[$0] != nil }, id: \.self) { aspect in
                    if let value = interpretation.aspects[aspect] {
                        let color = aspectColors[aspect] ?? Color.tarotGold
                        let icon = aspectIcons[aspect] ?? "sparkle"
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 6) {
                                Image(systemName: icon)
                                    .font(.caption)
                                    .foregroundStyle(color)
                                Text(aspect)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(color)
                            }
                            Text(value)
                                .font(.caption)
                                .foregroundStyle(Color.tarotIvory.opacity(0.58))
                                .lineLimit(3)
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(color.opacity(0.07))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(color.opacity(0.20), lineWidth: 1)
                        )
                    }
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.tarotPanel.opacity(0.80))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.tarotGold.opacity(0.15), lineWidth: 1)
        )
    }
}

/// Esoteric wisdom panel that unifies all the card's hidden correspondences
/// (mythology, astrology, kabbalah, numerology, element, affirmation, crystals,
/// chakras, yes/no answer, zodiac decan, light/shadow) into one visual guide.
