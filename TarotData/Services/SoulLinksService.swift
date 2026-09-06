import Foundation
import SwiftUI

public struct SoulLink: Identifiable, Codable {
    public var id: String { partnerID }
    public let partnerID: String
    public let partnerName: String
    public let resonanceScore: Double

    public init(partnerID: String, partnerName: String, resonanceScore: Double) {
        self.partnerID = partnerID
        self.partnerName = partnerName
        self.resonanceScore = resonanceScore
    }
}

public protocol SoulLinksServiceProtocol: ObservableObject {
    var activeLinks: [SoulLink] { get }
}

public final class SoulLinksService: SoulLinksServiceProtocol {
    @Published public var activeLinks: [SoulLink] = []

    public init() {
        // Initialize with some demo data if empty
        self.activeLinks = [
            SoulLink(partnerID: "demo", partnerName: "Alma Espejo", resonanceScore: 0.85)
        ]
    }
}
