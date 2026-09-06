import Foundation

/// Represents a message in a spiritual dialogue with the AI.
public struct ChatMessage: Identifiable, Equatable {
    public enum Role {
        case user
        case assistant
        case system
    }

    public let id: UUID
    public let role: Role
    public let content: String
    public let timestamp: Date

    public init(role: Role, content: String, id: UUID = UUID(), timestamp: Date = .now) {
        self.role = role
        self.content = content
        self.id = id
        self.timestamp = timestamp
    }

    public static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        lhs.id == rhs.id && lhs.role == rhs.role && lhs.content == rhs.content
    }
}
