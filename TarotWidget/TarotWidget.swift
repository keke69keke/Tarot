import WidgetKit
import SwiftUI
import TarotCore
import TarotContent
import TarotData

// MARK: - Timeline Provider

/// App Group shared between the app and the widget.
let appGroupID = "group.com.gvstii.tarotapp"

/// Uses the same deterministic algorithm as the app's daily card service,
/// so the widget always shows the same card as the in-app "Carta del día".
struct DailyCardProvider: TimelineProvider {

    func placeholder(in context: Context) -> DailyCardEntry {
        DailyCardEntry(date: Date(), card: sampleCard())
    }

    func getSnapshot(in context: Context, completion: @escaping (DailyCardEntry) -> Void) {
        completion(DailyCardEntry(date: Date(), card: currentDailyCard()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DailyCardEntry>) -> Void) {
        let entry = DailyCardEntry(date: Date(), card: currentDailyCard())
        // Refresh at next midnight so the card changes each day.
        let nextMidnight = Calendar.current.nextDate(
            after: Date(),
            matching: DateComponents(hour: 0, minute: 0, second: 0),
            matchingPolicy: .nextTime
        ) ?? Date().addingTimeInterval(86_400)
        let timeline = Timeline(entries: [entry], policy: .after(nextMidnight))
        completion(timeline)
    }

    // MARK: - Helpers

    private func loadCards() -> [Card] {
        let repo = try? BundleCardRepository(bundle: .tarotContent)
        return repo?.allCards() ?? []
    }

    private func currentDailyCard() -> Card {
        let cards = loadCards()
        guard !cards.isEmpty else { return sampleCard() }
        let calendar = Calendar.current
        let year = calendar.component(.year, from: Date())
        let day = calendar.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let seed = year * 366 + day
        return cards[abs(seed) % cards.count]
    }

    private func sampleCard() -> Card {
        let cards = loadCards()
        return cards.first ?? Card(
            id: 0,
            name: "El Loco",
            number: nil,
            suit: nil,
            arcanaType: .major,
            imageName: "card_00_the_fool",
            uprightMeaning: Interpretation(cards: [], summary: "", keywords: [], contextual: [:], aspects: [:]),
            reversedMeaning: Interpretation(cards: [], summary: "", keywords: [], contextual: [:], aspects: [:])
        )
    }
}

// MARK: - Entry

struct DailyCardEntry: TimelineEntry {
    let date: Date
    let card: Card
}

// MARK: - Widget View

struct TarotDailyCardWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: DailyCardEntry

    var body: some View {
        ZStack {
            // Esoteric purple background
            LinearGradient(
                colors: [
                    Color(red: 0.10, green: 0.04, blue: 0.22),
                    Color(red: 0.16, green: 0.08, blue: 0.30)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Ambient glow
            Circle()
                .fill(Color(red: 0.72, green: 0.55, blue: 0.95).opacity(0.18))
                .frame(width: 120, height: 120)
                .blur(radius: 40)
                .offset(x: 60, y: -40)

            switch family {
            case .systemSmall:
                smallLayout
            case .systemMedium:
                mediumLayout
            default:
                smallLayout
            }
        }
        .widgetURL(URL(string: "tarot://daily"))
    }

    // MARK: - Small Layout
    private var smallLayout: some View {
        VStack(spacing: 8) {
            Text("TU CARTA DE HOY")
                .font(.system(size: 9, weight: .bold, design: .serif))
                .tracking(2)
                .foregroundStyle(Color(red: 0.85, green: 0.72, blue: 0.38))

            cardArt(name: entry.card.name, imageName: entry.card.imageName)
                .frame(width: 64, height: 96)

            Text(entry.card.name)
                .font(.system(size: 13, weight: .semibold, design: .serif))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.8)
        }
        .padding(8)
    }

    // MARK: - Medium Layout
    private var mediumLayout: some View {
        HStack(spacing: 16) {
            cardArt(name: entry.card.name, imageName: entry.card.imageName)
                .frame(width: 84, height: 126)

            VStack(alignment: .leading, spacing: 8) {
                Text("TU CARTA DE HOY")
                    .font(.system(size: 10, weight: .bold, design: .serif))
                    .tracking(2)
                    .foregroundStyle(Color(red: 0.85, green: 0.72, blue: 0.38))

                Text(entry.card.name)
                    .font(.system(size: 18, weight: .bold, design: .serif))
                    .foregroundStyle(.white)

                Text(entry.card.uprightMeaning.summary)
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.85))
                    .lineLimit(3)

                if !entry.card.uprightMeaning.keywords.isEmpty {
                    Text(entry.card.uprightMeaning.keywords.prefix(3).joined(separator: " · "))
                        .font(.system(size: 9))
                        .foregroundStyle(Color(red: 0.85, green: 0.72, blue: 0.38))
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(16)
    }

    // MARK: - Card Art
    @ViewBuilder
    private func cardArt(name: String, imageName: String) -> some View {
        let clean = (imageName as NSString).deletingPathExtension
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(red: 0.20, green: 0.10, blue: 0.30))
            if let url = Bundle.tarotContent.url(forResource: clean, withExtension: "png"),
               let img = UIImage(contentsOfFile: url.path) {
                Image(uiImage: img)
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            } else {
                VStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 16))
                        .foregroundStyle(Color(red: 0.78, green: 0.62, blue: 0.98))
                    Text(name)
                        .font(.system(size: 8, weight: .medium, design: .serif))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 4)
                }
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color(red: 0.85, green: 0.72, blue: 0.38).opacity(0.60), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.4), radius: 6, x: 0, y: 4)
    }
}

// MARK: - Widget

struct TarotDailyCardWidget: Widget {
    let kind: String = "TarotDailyCard"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DailyCardProvider()) { entry in
            TarotDailyCardWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    Color(red: 0.10, green: 0.04, blue: 0.22)
                }
        }
        .configurationDisplayName("Carta del día")
        .description("Tu carta de tarot diaria, siempre visible en tu pantalla de inicio.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
