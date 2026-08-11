import Foundation

public struct TarotEndpointResponse: Codable, Equatable {
    public let appName: String
    public let endpoint: String
    public let status: String
    public let message: String

    public init(appName: String, endpoint: String, status: String, message: String) {
        self.appName = appName
        self.endpoint = endpoint
        self.status = status
        self.message = message
    }
}
