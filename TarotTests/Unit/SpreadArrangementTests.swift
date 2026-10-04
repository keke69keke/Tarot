import XCTest
@testable import TarotCore

/// Regresión: cada carta de la tirada debe mapear 1:1 a las posiciones del
/// spread y el conteo final debe coincidir (12 casas, 10 sefirot, etc.).
final class SpreadArrangementTests: XCTestCase {

    func testAllSpreadsMatchPositionsCountToDrawnCards() {
        for type in SpreadType.allCases {
            let positions = type.positions
            let spread = Spread(standardPositions: positions)
            let cards = (0..<positions.count).map { i in
                Card(id: i, name: "Carta \(i)", number: nil, suit: nil,
                     arcanaType: .major, imageName: "x",
                     uprightMeaning: Interpretation(summary: "s", keywords: ["k"]),
                     reversedMeaning: Interpretation(summary: "s", keywords: ["k"]))
            }
            let drawn = cards.enumerated().map { i, card in
                DrawnCard(card: card, position: positions[min(i, positions.count - 1)], orientation: .upright)
            }
            XCTAssertEqual(drawn.count, positions.count,
                           "SpreadType.\(type.rawValue) reparto debe cubrir todas sus posiciones")
            for (i, dc) in drawn.enumerated() {
                XCTAssertEqual(dc.position.id, spread.standardPositions[i].id,
                               "SpreadType.\(type.rawValue): carta \(i) no está en su posición")
            }
        }
    }

    func testSignificatorOccupiesFirstSlotAndCountIsPreserved() {
        // Simula lo que draw() produce tras insertar el significador:
        // 11 cartas para una tirada de 12 posiciones + significador al frente.
        let positions = SpreadType.astrological.positions // 12
        let count = positions.count
        var drawn: [DrawnCard] = []
        for i in 0..<(count - 1) {
            let card = Card(id: 100 + i, name: "Menor \(i)", number: nil, suit: .wands,
                            arcanaType: .minor, imageName: "x",
                            uprightMeaning: Interpretation(summary: "s", keywords: ["k"]),
                            reversedMeaning: Interpretation(summary: "s", keywords: ["k"]))
            drawn.append(DrawnCard(card: card, position: positions[i + 1], orientation: .upright))
        }
        let sig = Card(id: 999, name: "Significador", number: nil, suit: nil,
                       arcanaType: .major, imageName: "x",
                       uprightMeaning: Interpretation(summary: "s", keywords: ["k"]),
                       reversedMeaning: Interpretation(summary: "s", keywords: ["k"]))
        drawn.insert(DrawnCard(card: sig, position: positions[0], orientation: .upright), at: 0)

        XCTAssertEqual(drawn.count, count, "con significador la tirada sigue teniendo \(count) cartas")
        XCTAssertEqual(drawn[0].card.id, sig.id)
        for (i, dc) in drawn.enumerated() {
            XCTAssertEqual(dc.position.name, positions[i].name,
                           "carta \(i) debe llevar la posición \(i) (casa \(i + 1))")
        }
    }

    func testSpreadRoundTripCodableKeepsPositions() throws {
        for type in SpreadType.allCases {
            let spread = Spread(type: type, drawnCards: [])
            let data = try JSONEncoder().encode(spread)
            let decoded = try JSONDecoder().decode(Spread.self, from: data)
            XCTAssertEqual(decoded.standardPositions.map(\.name),
                           spread.standardPositions.map(\.name),
                           "SpreadType.\(type.rawValue): posiciones se conservan al codificar")
        }
    }
}
