import SwiftUI
import TarotCore
import TarotData

struct SharedDestinyView: View {
    // Swift 5.7+ requires explicit `any` when using a protocol as a concrete type.
    // This property receives the injected service from the parent view.
    let soulLinks: any SoulLinksServiceProtocol

    private var partner: TarotData.SoulLink {
        soulLinks.activeLinks.first ?? TarotData.SoulLink(partnerID: "demo", partnerName: "Alma Espejo", resonanceScore: 0.85)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.tarotBackground.ignoresSafeArea()
                Color.tarotBackgroundGradient.ignoresSafeArea()

                VStack(spacing: 30) {
                    VStack(spacing: 16) {
                        Text("Sincronía de Almas")
                            .font(.luxuryTitle2)
                            .foregroundStyle(Color.tarotIvory)
                            .multilineTextAlignment(.center)

                        Text("Vínculo Energético con \(partner.partnerName)")
                            .font(.luxurySubheadline)
                            .foregroundStyle(Color.tarotIvory.opacity(0.6))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)

                    // Resonance Gauge
                    VStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .stroke(Color.tarotGold.opacity(0.15), lineWidth: 12)
                                .frame(width: 200, height: 200)

                            Circle()
                                .trim(from: 0, to: partner.resonanceScore)
                                .stroke(
                                    LinearGradient(colors: [.tarotGold, .tarotBurgundy], startPoint: .topLeading, endPoint: .bottomTrailing),
                                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                                )
                                .frame(width: 200, height: 200)
                                .rotationEffect(.degrees(-90))

                            VStack {
                                Text("\(Int(partner.resonanceScore * 100))%")
                                    .font(.system(size: 42, weight: .bold, design: .serif))
                                    .foregroundStyle(Color.tarotGold)
                                Text("Resonancia")
                                    .font(.caption)
                                    .foregroundStyle(Color.tarotIvory.opacity(0.5))
                            }
                        }
                        .padding()
                        .luxuryGlass(cornerRadius: 100)

                        Text("El flujo energético entre ustedes indica una conexión \(resonanceDescription(for: partner.resonanceScore))")
                            .font(.luxuryCaption)
                            .foregroundStyle(Color.tarotIvory.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }

                    // Destiny Insights
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Perspectivas del Destino")
                            .font(.headline)
                            .foregroundStyle(Color.tarotGold)
                            .padding(.horizontal)

                        VStack(spacing: 12) {
                            InsightRow(icon: "sparkles", title: "Sinergia", description: "Alta compatibilidad en los planos espirituales y emocionales.")
                            InsightRow(icon: "heart.fill", title: "Atracción", description: "Fuerte magnetismo basado en complementariedad de sombras.")
                            InsightRow(icon: "moon.stars.fill", title: "Karma", description: "Vínculo ancestral que busca resolución en esta encarnación.")
                        }
                        .padding()
                        .background(Color.tarotPanel.opacity(0.6))
                        .cornerRadius(20)
                        .padding(.horizontal)
                    }

                    Spacer()

                    Button {
                        // Action to refresh or sync
                    } label: {
                        Text("Sincronizar Energías")
                            .font(.luxuryCaption.bold())
                            .foregroundStyle(Color.tarotIvory)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 24)
                            .background(Capsule().fill(Color.tarotGold.opacity(0.8)))
                    }
                    .padding(.bottom, 40)
                }
            }
        }
    }

    private func resonanceDescription(for score: Double) -> String {
        if score > 0.9 { return "excepcional y trascendente" }
        if score > 0.7 { return "profunda y armónica" }
        if score > 0.5 { return "estándar y en crecimiento" }
        return "compleja y en proceso de aprendizaje"
    }
}

struct InsightRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Color.tarotGold)
                .font(.system(size: 16))
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title).bold().font(.subheadline).foregroundStyle(Color.tarotIvory)
                Text(description).font(.caption).foregroundStyle(Color.tarotIvory.opacity(0.6))
            }
        }
    }
}
