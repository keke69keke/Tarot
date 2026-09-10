// Create this file in your project's Sources directory
import Foundation

// MARK: - Core Enums
public enum CardOrientation: String, CaseIterable, Codable {
    case upright
    case reversed
}

public enum SpreadPosition: Hashable {
    case single
    case twoHorseshoe
    // Add other spread positions as needed
}
