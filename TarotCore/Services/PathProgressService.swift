import Foundation

/// Service for tracking and managing spiritual paths and soul milestones.
public protocol PathProgressProtocol: ObservableObject {
    func markMilestoneCompleted(pathId: UUID, milestoneId: UUID)
    func getProgress(for pathId: UUID) -> PathProgress?
    func getAllPaths() -> [SpiritualPath]
}

public final class PathProgressService: PathProgressProtocol {
    private var userProgress: [UUID: PathProgress] = [:]
    private let storageKey = "tarot.spiritual_progress"

    public init() {
        loadProgress()
    }

    public func markMilestoneCompleted(pathId: UUID, milestoneId: UUID) {
        var progress = userProgress[pathId] ?? PathProgress(pathId: pathId)
        progress.completedMilestones.insert(milestoneId)
        userProgress[pathId] = progress
        saveProgress()
    }

    public func getProgress(for pathId: UUID) -> PathProgress? {
        return userProgress[pathId]
    }

    public func getAllPaths() -> [SpiritualPath] {
        // In a real app, this would load from a JSON file of available paths.
        return [
            SpiritualPath(
                title: "El Despertar del Observador",
                objective: "Aprender a observar la vida sin juzgarla, usando el tarot como espejo.",
                milestones: [
                    Milestone(title: "Primera Mirada", description: "Realiza una tirada de tres cartas sobre tu estado actual.", requirement: .reading(spread: .threeCard)),
                    Milestone(title: "Sombra Revelada", description: "Reflexiona sobre la carta que más te asuste.", requirement: .reflection(prompt: "Sombra")),
                    Milestone(title: "Luz Interior", description: "Estudia el significado del Sol y la Estrella.", requirement: .study(topic: "Luz"))
                ],
                rewardBadge: "sun.max.fill"
            )
        ]
    }

    private func saveProgress() {
        if let encoded = try? JSONEncoder().encode(userProgress) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }

    private func loadProgress() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([UUID: PathProgress].self, from: data) {
            userProgress = decoded
        }
    }
}
