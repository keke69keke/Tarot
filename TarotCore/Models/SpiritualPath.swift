import Foundation
import TarotCore

/// A structured spiritual journey consisting of milestones.
public struct SpiritualPath: Identifiable, Codable {
    public let id: UUID
    public let title: String
    public let objective: String
    public let milestones: [Milestone]
    public let rewardBadge: String // Symbol for the Destiny Map

    public init(id: UUID = UUID(), title: String, objective: String, milestones: [Milestone], rewardBadge: String) {
        self.id = id
        self.title = title
        self.objective = objective
        self.milestones = milestones
        self.rewardBadge = rewardBadge
    }
}

/// A single requirement within a spiritual path.
public struct Milestone: Identifiable, Codable {
    public let id: UUID
    public let title: String
    public let description: String
    public let requirement: MilestoneRequirement

    public enum MilestoneRequirement: Codable {
        case reading(spread: SpreadType)
        case reflection(prompt: String)
        case study(topic: String)
    }

    public init(id: UUID = UUID(), title: String, description: String, requirement: MilestoneRequirement) {
        self.id = id
        self.title = title
        self.description = description
        self.requirement = requirement
    }
}

/// Tracking for a user's progress through a specific path.
public struct PathProgress: Identifiable, Codable {
    public let id: UUID
    public let pathId: UUID
    public var completedMilestones: Set<UUID>
    public var isCompleted: Bool { completedMilestones.count == totalMilestones }
    public var totalMilestones: Int = 0

    public init(id: UUID = UUID(), pathId: UUID, completedMilestones: Set<UUID> = []) {
        self.id = id
        self.pathId = pathId
        self.completedMilestones = completedMilestones
    }
}
