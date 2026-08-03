import SwiftUI

struct CardStackView: View {
    var cards: [Card]
    
    @State privatevar cardOffset: CGFloat = 0
    
    var body: some View {
        ZStack(alignment: .leading) {
            // Background gradient effect
            LinearGradient(
                colors: [.blue.opacity(0.1), .white],
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Animated card stack with smooth transitions
            VStack(spacing: 2) {
                ForEach(cards, id: \.self.name) { card in
                    CardView(card: card)
                        .transition(.blurCubic)
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
