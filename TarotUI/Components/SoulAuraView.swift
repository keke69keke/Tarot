import SwiftUI
import TarotCore

/// A luxury background aura that pulses and shifts color based on the user's biometric soul state.
struct SoulAuraView: View {
    let state: SoulState

    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            let pulse = 0.7 + 0.3 * sin(time * 0.5)
            let rotation = time * 0.2

            ZStack {
                Circle()
                    .fill(auraColor)
                    .frame(width: 300 * pulse, height: 300 * pulse)
                    .blur(radius: 60)
                    .opacity(0.4)
                    .rotationEffect(.degrees(rotation))

                Circle()
                    .fill(auraColor.opacity(0.6))
                    .frame(width: 150 * pulse, height: 150 * pulse)
                    .blur(radius: 30)
                    .rotationEffect(.degrees(-rotation * 1.5))
            }
        }
    }

    private var auraColor: Color {
        switch state {
        case .calm: return Color.blue.opacity(0.5)
        case .elevated: return Color.tarotGold.opacity(0.5)
        case .stressed: return Color.red.opacity(0.4)
        case .unknown: return Color.white.opacity(0.2)
        }
    }
}
