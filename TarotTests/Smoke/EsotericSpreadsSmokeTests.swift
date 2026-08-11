import XCTest
@testable import TarotCore

final class EsotericSpreadsSmokeTests: XCTestCase {
    func testAllSpreadTypesHavePositions() {
        for type in SpreadType.allCases {
            let positions = type.positions
            XCTAssertFalse(positions.isEmpty, "SpreadType.\(type.rawValue) should have positions defined")
        }
    }

    func testSpreadPositionsHaveRequiredFields() {
        for type in SpreadType.allCases {
            let positions = type.positions
            for position in positions {
                XCTAssertFalse(position.name.isEmpty, "SpreadType.\(type.rawValue) position name should not be empty")
                XCTAssertFalse(position.displayName.isEmpty, "SpreadType.\(type.rawValue) position displayName should not be empty")
            }
        }
    }

    func testSpreadPositionNamesAreUnique() {
        for type in SpreadType.allCases {
            let positions = type.positions
            let names = positions.map(\.name)
            let uniqueNames = Set(names)
            XCTAssertEqual(names.count, uniqueNames.count, "SpreadType.\(type.rawValue) should have unique position names")
        }
    }
}
