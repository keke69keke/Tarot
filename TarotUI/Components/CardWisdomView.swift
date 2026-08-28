import SwiftUI
import TarotCore
import TarotData

struct CardWisdomView: View {
    let card: Card

    private struct WisdomItem: Identifiable {
        let id = UUID()
        let icon: String
        let title: String
        let value: String
        let color: Color
    }

    private var items: [WisdomItem] {
        var result: [WisdomItem] = []

        // Paleta monocroma lavanda — ritmo por opacidad, no por tono
        if let m = card.mythology, !m.isEmpty {
            result.append(WisdomItem(icon: "figure.mind.and.body", title: "Mitología", value: m, color: Color.tarotGold.opacity(0.95)))
        }
        if let a = card.astrology, !a.isEmpty {
            result.append(WisdomItem(icon: "star", title: "Astrología", value: a, color: Color.tarotGold.opacity(0.80)))
        }
        if let d = card.zodiacalDecan, !d.isEmpty {
            result.append(WisdomItem(icon: "moon.stars", title: "Decanato", value: d, color: Color.tarotGold.opacity(0.90)))
        }
        if let k = card.kabbalah, !k.isEmpty {
            result.append(WisdomItem(icon: "tree", title: "Cábala", value: k, color: Color.tarotGold.opacity(0.75)))
        }
        if let n = card.numerology, !n.isEmpty {
            result.append(WisdomItem(icon: "number", title: "Numerología", value: n, color: Color.tarotGold.opacity(0.85)))
        }
        if let e = card.element, !e.isEmpty {
            result.append(WisdomItem(icon: "flame", title: "Elemento", value: e, color: Color.tarotGold.opacity(0.90)))
        }
        if let c = card.chakras, !c.isEmpty {
            result.append(WisdomItem(icon: "circle.hexagongrid", title: "Chakras", value: c, color: Color.tarotGold.opacity(0.80)))
        }
        if let cr = card.crystals, !cr.isEmpty {
            result.append(WisdomItem(icon: "sparkles", title: "Cristales", value: cr, color: Color.tarotGold.opacity(0.85)))
        }
        if let ls = card.lightShadow, !ls.isEmpty {
            result.append(WisdomItem(icon: "sun.max", title: "Luz y Sombra", value: ls, color: Color.tarotGold.opacity(0.90)))
        }
        if let yn = card.yesNo, !yn.isEmpty {
            result.append(WisdomItem(icon: "checkmark.circle", title: "Respuesta Sí/No", value: yn, color: Color.tarotGold.opacity(0.85)))
        }
        if let af = card.affirmation, !af.isEmpty {
            result.append(WisdomItem(icon: "hands.sparkles", title: "Afirmación", value: "“\(af)”", color: Color.tarotGold.opacity(0.95)))
        }
        return result
    }

var body: some View {
        let visibleItems = items
        if visibleItems.isEmpty {
            EmptyView()
        } else {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "wand.and.stars")
                    .foregroundStyle(Color.tarotGold)
                Text("Sabiduría de la Carta")
                    .font(.system(size: 16, weight: .bold, design: .serif))
                    .foregroundStyle(Color.tarotIvory)
                Spacer()
            }
            .accessibilityAddTraits(.isHeader)

            ForEach(visibleItems) { item in
                HStack(alignment: .top, spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(item.color.opacity(0.14))
                            .frame(width: 40, height: 40)
                        Image(systemName: item.icon)
                            .font(.system(size: 16))
                            .foregroundStyle(item.color)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.title)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(Color.tarotIvory)
                        Text(item.value)
                            .font(.caption)
                            .foregroundStyle(Color.tarotIvory.opacity(0.58))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(item.color.opacity(0.06))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(item.color.opacity(0.18), lineWidth: 1)
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.tarotGold.opacity(0.08), Color.tarotGold.opacity(0.03)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.tarotGold.opacity(0.25), lineWidth: 1)
        )
        }
    }
}

