import SwiftUI
import TarotCore
import TarotDI

/// Visualizador de la evolución espiritual: rastrea la densidad de arcanos y la energía de los palos a lo largo del tiempo.
struct GrowthPathView: View {
    @EnvironmentObject var container: AppContainer
    @State private var data: [GrowthPoint] = []
    @State private var selectedPoint: GrowthPoint?

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundStyle(Color.tarotGold)
                Text("Senda de Crecimiento")
                    .font(.system(size: 20, weight: .bold, design: .serif))
                    .foregroundStyle(Color.tarotIvory)
            }
            .padding(.bottom, 8)

            if data.isEmpty {
                emptyState
            } else {
                ZStack(alignment: .bottomLeading) {
                    // Subtle time axis
                    HStack {
                        ForEach(0..<5) { i in
                            VStack(alignment: .leading, spacing: 4) {
                                Rectangle().fill(Color.white.opacity(0.1)).frame(width: 1, height: 10)
                                Text(axisLabel(for: i))
                                    .font(.system(size: 9, design: .serif))
                                    .foregroundStyle(Color.tarotIvory.opacity(0.3))
                            }
                            Spacer()
                        }
                    }
                    .padding(.bottom, 20)
                    .padding(.horizontal, 10)

                    growthChart
                }
                .frame(height: 220)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(
                            LinearGradient(colors: [.tarotGold.opacity(0.4), .clear, .tarotGold.opacity(0.4)], startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: 1
                        )
                )
        )
        .onAppear(perform: calculateGrowth)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Text("Aún no hay datos suficientes")
                .font(.system(size: 15, design: .serif))
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.tarotIvory.opacity(0.5))
            Text("Realiza más lecturas para trazar tu mapa de evolución.")
                .font(.system(size: 13, design: .serif))
                .foregroundStyle(Color.tarotIvory.opacity(0.3))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }

    private var growthChart: some View {
        GeometryReader { geo in
            ZStack {
                Canvas { ctx, size in
                    let suits: [CardSuit] = [.wands, .cups, .swords, .pentacles]
                    let colors: [CardSuit: Color] = [
                        .wands: .orange,
                        .cups: .blue,
                        .swords: .white,
                        .pentacles: .green
                    ]

                    for suit in suits {
                        let points = data.filter { ($0.suits[suit] ?? 0) > 0 }
                        guard points.count > 1 else { continue }

                        var path = Path()
                        let cgPoints: [CGPoint] = points.enumerated().map { (i, point) in
                            CGPoint(
                                x: CGFloat(i) / CGFloat(points.count - 1) * size.width,
                                y: size.height - CGFloat(point.suits[suit] ?? 0) * 40
                            )
                        }

                        path.move(to: cgPoints[0])
                        for i in 0..<cgPoints.count - 1 {
                            let p1 = cgPoints[i]
                            let p2 = cgPoints[i+1]
                            let cp1 = CGPoint(x: (p1.x + p2.x) / 2, y: p1.y)
                            let cp2 = CGPoint(x: (p1.x + p2.x) / 2, y: p2.y)
                            path.addCurve(to: p2, control1: cp1, control2: cp2)
                        }

                        let suitColor = colors[suit] ?? .gray
                        ctx.stroke(path, with: .color(suitColor.opacity(0.2)), lineWidth: 8)
                        ctx.stroke(path, with: .color(suitColor), lineWidth: 1.5)
                    }

                    // The Golden Thread: Overall spiritual weight (Major Arcana density)
                    let weightPoints = data.enumerated().map { (i, point) in
                        CGPoint(
                            x: CGFloat(i) / CGFloat(data.count - 1) * size.width,
                            y: size.height - CGFloat(point.spiritualWeight) * 40
                        )
                    }

                    if weightPoints.count > 1 {
                        var goldPath = Path()
                        goldPath.move(to: weightPoints[0])
                        for i in 0..<weightPoints.count - 1 {
                            let p1 = weightPoints[i]
                            let p2 = weightPoints[i+1]
                            let cp1 = CGPoint(x: (p1.x + p2.x) / 2, y: p1.y)
                            let cp2 = CGPoint(x: (p1.x + p2.x) / 2, y: p2.y)
                            goldPath.addCurve(to: p2, control1: cp1, control2: cp2)
                        }
                        ctx.stroke(goldPath, with: .color(Color.tarotGold.opacity(0.6)), lineWidth: 3)
                        ctx.stroke(goldPath, with: .color(Color.tarotGold), lineWidth: 1)
                    }
                }
                .blendMode(.screen)

                // Interactive data points
                ForEach(data.indices, id: \.self) { i in
                    Circle()
                        .fill(Color.tarotGold)
                        .frame(width: 4, height: 4)
                        .position(
                            x: CGFloat(i) / CGFloat(data.count - 1) * geo.size.width,
                            y: geo.size.height - CGFloat(data[i].spiritualWeight) * 40
                        )
                        .onTapGesture {
                            TarotAudioService.shared.triggerHaptic(.light)
                            selectedPoint = data[i]
                        }
                }
            }
        }
    }

    private func axisLabel(for index: Int) -> String {
        guard !data.isEmpty else { return "" }
        let step = data.count / 4
        let idx = index * step
        guard idx < data.count else { return "" }
        return data[idx].date.formatted(.dateTime.month(.abbreviated).day())
    }

    private func calculateGrowth() {
        let entries = container.journal.fetchAll().sorted { $0.savedAt < $1.savedAt }
        var currentPoints: [GrowthPoint] = []

        for entry in entries {
            var counts: [CardSuit: Int] = [:]
            var majorCount = 0
            for drawn in entry.spread.drawnCards {
                if let suit = drawn.card.suit {
                    counts[suit, default: 0] += 1
                }
                if drawn.card.arcanaType == .major {
                    majorCount += 1
                }
            }
            currentPoints.append(GrowthPoint(date: entry.savedAt, suits: counts, spiritualWeight: majorCount))
        }

        self.data = currentPoints
    }
}

private struct GrowthPoint {
    let date: Date
    let suits: [CardSuit: Int]
    let spiritualWeight: Int
}
