import SwiftUI
import TarotCore
import TarotDI

/// Mapa visual de destino: conecta lecturas a través de símbolos y cartas recurrentes.
struct DestinyGraphView: View {
    @EnvironmentObject var container: AppContainer
    @State private var nodes: [DestinyReadingNode] = []
    @State private var edges: [Edge] = []
    @State private var selectedNode: DestinyReadingNode?
    @State private var hoverNode: DestinyReadingNode?

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack {
                Image(systemName: "network")
                    .foregroundStyle(Color.tarotGold)
                Text("Mapa del Destino")
                    .font(.system(size: 20, weight: .bold, design: .serif))
                    .foregroundStyle(Color.tarotIvory)
            }
            .padding(.bottom, 8)

            if nodes.isEmpty {
                emptyState
            } else {
                ZStack {
                    // Mystical background nebula
                    RadialGradient(colors: [Color.tarotGold.opacity(0.05), .clear], center: .center, startRadius: 0, endRadius: 300)
                        .ignoresSafeArea()

                    Canvas { ctx, size in
                        // Draw Edges with thematic coloring and glowing pulses
                        for edge in edges {
                            let start = nodes[edge.from].position
                            let end = nodes[edge.to].position

                            var path = Path()
                            path.move(to: start)
                            path.addLine(to: end)

                            let color = edge.isMajor ? Color.tarotGold : Color.white.opacity(0.2)
                            let width = edge.isMajor ? 2.0 : 0.8

                            // Deep outer glow for Major connections
                            if edge.isMajor {
                                ctx.stroke(path, with: .color(color.opacity(0.1)), lineWidth: width * 6)
                            }
                            ctx.stroke(path, with: .color(color.opacity(0.3)), lineWidth: width * 2)
                            ctx.stroke(path, with: .color(color), lineWidth: width)
                        }
                    }
                    .blendMode(.screen)

                    // Interaction layer for nodes
                    ForEach(nodes.indices, id: \.self) { i in
                        DestinyNodeView(node: nodes[i], isSelected: selectedNode?.id == nodes[i].id)
                            .position(nodes[i].position)
                            .onTapGesture {
                                TarotAudioService.shared.triggerHaptic(.medium)
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                    selectedNode = nodes[i]
                                }
                            }
                    }
                }
                .frame(height: 350)
                .background(
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .fill(Color.black.opacity(0.6))
                        .background(
                            RoundedRectangle(cornerRadius: 32, style: .continuous)
                                .fill(Color.tarotGold.opacity(0.03))
                                .blur(radius: 20)
                        )
                )
                .cornerRadius(32)
                .overlay(
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .stroke(
                            LinearGradient(colors: [.tarotGold.opacity(0.3), .clear, .tarotGold.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: 1.5
                        )
                )
            }

            // Soul Milestones Row
            HStack(spacing: 16) {
                ForEach(container.pathProgress.getAllPaths().filter {
                    container.pathProgress.getProgress(for: $0.id)?.isCompleted == true
                }) { path in
                    VStack(spacing: 4) {
                        Image(systemName: path.rewardBadge)
                            .font(.system(size: 20))
                            .foregroundStyle(Color.tarotGold)
                        Text(path.title)
                            .font(.system(size: 10, weight: .medium, design: .serif))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(Color.tarotIvory.opacity(0.6))
                    }
                    .padding(10)
                    .background(Capsule().fill(Color.tarotGold.opacity(0.1)))
                    .overlay(Capsule().stroke(Color.tarotGold.opacity(0.3), lineWidth: 0.5))
                }
            }
            .padding(.horizontal, 4)
            .frame(maxWidth: .infinity, alignment: .center)
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
        .onAppear(perform: buildGraph)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Text("El mapa está vacío")
                .font(.system(size: 15, design: .serif))
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.tarotIvory.opacity(0.5))
            Text("Tus lecturas crearán constelaciones a medida que los símbolos se repitan.")
                .font(.system(size: 13, design: .serif))
                .foregroundStyle(Color.tarotIvory.opacity(0.3))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }

    private func buildGraph() {
        let entries = container.journal.fetchAll().sorted { $0.savedAt < $1.savedAt }
        guard !entries.isEmpty else { return }

        // Generate nodes with a balanced organic constellation layout
        var newNodes: [DestinyReadingNode] = []
        let center = CGPoint(x: 150, y: 150)

        for (i, entry) in entries.enumerated() {
            let angle = (CGFloat(i) / CGFloat(entries.count)) * .pi * 2
            // Radius evolves slightly over time to show progression
            let progressionFactor = CGFloat(i) / CGFloat(entries.count)
            let baseRadius = 70 + (progressionFactor * 60)

            let seed = CGFloat(entry.id.uuidString.hashValue % 100) / 100.0
            let offsetX = cos(seed * .pi * 2) * 30
            let offsetY = sin(seed * .pi * 2) * 30

            let pos = CGPoint(
                x: center.x + cos(angle) * baseRadius + offsetX,
                y: center.y + sin(angle) * baseRadius + offsetY
            )
            newNodes.append(DestinyReadingNode(id: entry.id, entry: entry, position: pos))
        }

        // Generate edges based on shared cards, marking Major Arcana connections
        var newEdges: [Edge] = []
        for i in 0..<newNodes.count {
            for j in i+1..<newNodes.count {
                let cardsI = Set(newNodes[i].entry.spread.drawnCards.map { $0.card })
                let cardsJ = Set(newNodes[j].entry.spread.drawnCards.map { $0.card })
                let common = cardsI.intersection(cardsJ)

                if !common.isEmpty {
                    // An edge is "Major" if at least one shared card is a Major Arcana
                    let isMajor = common.contains { $0.arcanaType == .major }
                    newEdges.append(Edge(from: i, to: j, isMajor: isMajor))
                }
            }
        }

        self.nodes = newNodes
        self.edges = newEdges
    }
}

private struct DestinyNodeView: View {
    let node: DestinyReadingNode
    let isSelected: Bool

    var body: some View {
        TimelineView(.animation) { timeline in
            let pulse = 0.8 + 0.2 * sin(timeline.date.timeIntervalSinceReferenceDate * 2.0)

            ZStack {
                Circle()
                    .fill(isSelected ? Color.tarotGold : Color.tarotIvory.opacity(0.4))
                    .frame(width: isSelected ? 12 : 8, height: isSelected ? 12 : 8)
                    .scaleEffect(isSelected ? 1.0 : pulse)
                    .shadow(color: isSelected ? Color.tarotGold : .clear, radius: 4)

                if isSelected {
                    Circle()
                        .stroke(Color.tarotGold, lineWidth: 1)
                        .frame(width: 24, height: 24)
                        .scaleEffect(1.0 + 0.2 * sin(timeline.date.timeIntervalSinceReferenceDate * 3.0))
                        .opacity(0.4)
                }
            }
        }
    }
}

private struct DestinyReadingNode {
    let id: UUID
    let entry: JournalEntry
    var position: CGPoint
}

private struct Edge {
    let from: Int
    let to: Int
    let isMajor: Bool
}
