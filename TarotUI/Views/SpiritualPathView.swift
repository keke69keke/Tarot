import SwiftUI
import TarotCore
import TarotDI

struct SpiritualPathView: View {
    @EnvironmentObject var container: AppContainer
    @StateObject private var viewModel = PathViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.tarotBackground.ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 32) {
                        VStack(alignment: .leading, spacing: 12) {
                            EyebrowLabel(text: "ASCENSIÓN ESPIRITUAL")
                            Text("El Camino del Maestro")
                                .font(.system(size: 32, weight: .bold, design: .serif))
                                .foregroundStyle(Color.tarotIvory)
                            Text("Recorre senderos de autodescubrimiento. Cada hito completado es un paso hacia la maestría de tu propio espejo.")
                                .font(.system(size: 15, weight: .regular, design: .serif))
                                .foregroundStyle(Color.tarotIvory.opacity(0.55))
                                .lineSpacing(4)
                        }
                        .padding(.horizontal, 4)
                        .padding(.top, 12)

                        LazyVStack(spacing: 24) {
                            ForEach(viewModel.paths, id: \.id) { path in
                                PathCard(path: path, progress: viewModel.getProgress(for: path))
                                    .onTapGesture {
                                        // Navigate to path detail (TBD)
                                    }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("Senda de Crecimiento")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct PathCard: View {
    let path: SpiritualPath
    let progress: PathProgress?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(path.title)
                        .font(.system(size: 20, weight: .bold, design: .serif))
                        .foregroundStyle(Color.tarotGold)
                    Text(path.objective)
                        .font(.system(size: 13, weight: .regular, design: .serif))
                        .foregroundStyle(Color.tarotIvory.opacity(0.6))
                        .lineLimit(2)
                }
                Spacer()
                if progress?.isCompleted == true {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(Color.tarotGold)
                        .font(.system(size: 24))
                }
            }

            // Progress bar
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    ProgressView(value: progressValue)
                        .tint(Color.tarotGold)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(10)
                    Text("\(Int(progressValue * 100))%")
                        .font(.system(size: 12, weight: .bold, design: .serif))
                        .foregroundStyle(Color.tarotGold)
                }
                Text("Hitos: \(progress?.completedMilestones.count ?? 0) / \(path.milestones.count)")
                    .font(.system(size: 11, design: .serif))
                    .foregroundStyle(Color.tarotIvory.opacity(0.4))
            }
        }
        .padding(20)
        .luxuryGlass(cornerRadius: 24)
    }

    private var progressValue: Double {
        guard let progress = progress else { return 0 }
        return Double(progress.completedMilestones.count) / Double(path.milestones.count)
    }
}

class PathViewModel: ObservableObject {
    @Published var paths: [SpiritualPath] = []
    var service: PathProgressProtocol = PathProgressService()

    init() {
        paths = service.getAllPaths()
    }

    func getProgress(for path: SpiritualPath) -> PathProgress? {
        service.getProgress(for: path.id)
    }
}
