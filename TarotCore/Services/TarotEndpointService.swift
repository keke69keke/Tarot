import Foundation

public protocol TarotEndpointServiceProtocol {
    func makeRootResponse() -> TarotEndpointResponse
}

public final class DefaultTarotEndpointService: TarotEndpointServiceProtocol {
    private let appName: String

    public init(appName: String) {
        self.appName = appName
    }

    public func makeRootResponse() -> TarotEndpointResponse {
        TarotEndpointResponse(
            appName: appName,
            endpoint: "/",
            status: "ok",
            message: "\(appName) is ready."
        )
    }
}
