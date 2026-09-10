 import SwiftUI

struct CardStackView: View {
    var cards: [Card]

    @State private var cardOffset: CGFloat = 0

    var body: some View {
        ZStack(alignment: .leading) {
            // Background gradient effect
            LinearGradient(
                colors: [.blue.opacity(0.1), .white],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Animated card stack with smooth transitions
            VStack(spacing: 2) {
                ForEach(cards, id: \.name) { card in
                    CardView(card: card)
                    // .transition(.blurCubic) // optional transition (commented out if undefined)
                }
            }
        }
    }
}

struct CardView: View {
    let card: Card

    var body: some View {
        VStack(spacing: 10) {
            Text(card.name)
                .font(.title3)
                .bold()

            if !card.uprightMeaning.summary.isEmpty {
                Text(card.uprightMeaning.summary)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}
