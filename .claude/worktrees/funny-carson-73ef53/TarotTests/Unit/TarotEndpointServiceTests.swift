import XCTest
@testable import TarotCore

final class TarotEndpointServiceTests: XCTestCase {
    func testRootResponseIsReadyForTheAppEndpoint() {
        let service = DefaultTarotEndpointService(appName: "Tarot")

        let response = service.makeRootResponse()

        XCTAssertEqual(response.appName, "Tarot")
        XCTAssertEqual(response.endpoint, "/")
        XCTAssertEqual(response.status, "ok")
        XCTAssertFalse(response.message.isEmpty)
    }
}
