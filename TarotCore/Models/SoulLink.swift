import Foundation

public struct SoulLink: Codable, Identifiable, Equatable {
    public let id: UUID
    public let partnerID: String
    public let partnerName: String
    public let linkedAt: Date
    public let resonanceScore: Double // 0.0 to 1.0

    public init(id: UUID = UUID(), partnerID: String, partnerName: String, linkedAt: Date = .now, resonanceScore: Double) {
        self.id = id
        self.partnerID = partnerID
        self.partnerName = partnerName
        self.linkedAt = linkedAt
        self.resonanceScore = resonanceScore
    }
}
