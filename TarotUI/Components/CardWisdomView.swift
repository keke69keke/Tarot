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

        if let m = card.mythology, !m.isEmpty {
            result.append(WisdomItem(icon: "figure.mind.and.body", title: "Mitología", value: m, color: Color(red: 0.72, green: 0.55, blue: 0.95)))
        }
        if let a = card.astrology, !a.isEmpty {
            result.append(WisdomItem(icon: "star.fill", title: "Astrología", value: a, color: Color(red: 0.90, green: 0.72, blue: 0.30)))
        }
        if let d = card.zodiacalDecan, !d.isEmpty {
            result.append(WisdomItem(icon: "moon.stars.fill", title: "Decanato", value: d, color: Color(red: 0.40, green: 0.72, blue: 1.0)))
        }
        if let k = card.kabbalah, !k.isEmpty {
            result.append(WisdomItem(icon: "tree.fill", title: "Cábala", value: k, color: Color(red: 0.42, green: 0.72, blue: 0.42)))
        }
        if let n = card.numerology, !n.isEmpty {
            result.append(WisdomItem(icon: "number", title: "Numerología", value: n, color: Color(red: 0.78, green: 0.55, blue: 0.30)))
        }
        if let e = card.element, !e.isEmpty {
            result.append(WisdomItem(icon: "flame.fill", title: "Elemento", value: e, color: Color(red: 0.85, green: 0.45, blue: 0.25)))
        }
        if let c = card.chakras, !c.isEmpty {
            result.append(WisdomItem(icon: "circle.hexagongrid.fill", title: "Chakras", value: c, color: Color(red: 0.72, green: 0.30, blue: 0.72)))
        }
        if let cr = card.crystals, !cr.isEmpty {
            result.append(WisdomItem(icon: "sparkles", title: "Cristales", value: cr, color: Color(red: 0.45, green: 0.65, blue: 0.90)))
        }
        if let ls = card.lightShadow, !ls.isEmpty {
            result.append(WisdomItem(icon: "sun.max.fill", title: "Luz y Sombra", value: ls, color: Color(red: 0.85, green: 0.75, blue: 0.35)))
        }
        if let yn = card.yesNo, !yn.isEmpty {
            result.append(WisdomItem(icon: "checkmark.circle.fill", title: "Respuesta Sí/No", value: yn, color: Color(red: 0.30, green: 0.62, blue: 0.42)))
        }
        if let af = card.affirmation, !af.isEmpty {
            result.append(WisdomItem(icon: "hands.sparkles.fill", title: "Afirmación", value: "“\(af)”", color: Color(red: 0.78, green: 0.55, blue: 0.95)))
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
                    .foregroundStyle(.primary)
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
                            .foregroundStyle(.primary)
                        Text(item.value)
                            .font(.caption)
                            .foregroundStyle(.secondary)
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
                        colors: [Color.tarotGold.opacity(0.08), Color.tarotBurgundy.opacity(0.08)],
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

