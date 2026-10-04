import XCTest
@testable import TarotCore

/// El motor lunar es puro y determinista: estas pruebas fijan los hitos del
/// ciclo (luna nueva, llena, cuartos), la periodicidad y que las ocho fases
/// aparezcan siempre en orden.
final class LunarCycleTests: XCTestCase {

    private let unDia: TimeInterval = 86_400

    func testLunaNuevaDeReferencia() {
        let p = LunarCycle.position(for: LunarCycle.referenceNewMoon)
        XCTAssertEqual(p.kind, .newMoon)
        XCTAssertLessThan(p.age, 0.2, "La edad debe arrancar en 0")
        XCTAssertLessThan(p.illumination, 0.01, "La luna nueva no esta iluminada")
    }

    func testLunaLlenaAMediaLunacion() {
        let llena = LunarCycle.referenceNewMoon.addingTimeInterval(LunarCycle.synodicMonth / 2 * unDia)
        let p = LunarCycle.position(for: llena)
        XCTAssertEqual(p.kind, .fullMoon)
        XCTAssertGreaterThan(p.illumination, 0.99, "La luna llena esta entera")
    }

    func testLosCuartosCabenDondeToca() {
        let creciente = LunarCycle.position(for: LunarCycle.referenceNewMoon.addingTimeInterval(LunarCycle.synodicMonth / 4 * unDia))
        XCTAssertEqual(creciente.kind, .firstQuarter)
        let menguante = LunarCycle.position(for: LunarCycle.referenceNewMoon.addingTimeInterval(LunarCycle.synodicMonth * 3 / 4 * unDia))
        XCTAssertEqual(menguante.kind, .lastQuarter)
    }

    func testIluminacionSiempreEntreCeroYUno() {
        for i in 0..<400 {
            let fecha = LunarCycle.referenceNewMoon.addingTimeInterval(Double(i) * 0.9137 * unDia)
            let p = LunarCycle.position(for: fecha)
            XCTAssertTrue((0...1).contains(p.illumination), "Iluminacion fuera de rango en \(fecha)")
            XCTAssertTrue((0..<LunarCycle.synodicMonth).contains(p.age), "Edad fuera de rango en \(fecha)")
        }
    }

    func testPeriodicidadDeUnMesSinodico() {
        let base = Date(timeIntervalSince1970: 1_700_000_000)
        for i in 0..<12 {
            let fecha = base.addingTimeInterval(Double(i) * 3.3 * unDia)
            let a = LunarCycle.position(for: fecha)
            let b = LunarCycle.position(for: fecha.addingTimeInterval(LunarCycle.synodicMonth * unDia))
            XCTAssertEqual(a.kind, b.kind, "La fase se repite cada mes sinodico")
            XCTAssertEqual(a.illumination, b.illumination, accuracy: 0.02)
        }
    }

    func testLasOchoFasesAparecenEnOrden() {
        var vistas: [LunarPhaseKind] = []
        for i in 0..<200 {
            let fecha = LunarCycle.referenceNewMoon.addingTimeInterval(Double(i) * 0.2 * unDia)
            let kind = LunarCycle.position(for: fecha).kind
            if vistas.last != kind { vistas.append(kind) }
        }
        XCTAssertEqual(Array(vistas.prefix(8)), LunarPhaseKind.allCases, "El ciclo pasa por las ocho fases en orden")
    }

    func testDiasHastaLaProximaFase() {
        let desdeNueva = LunarCycle.daysUntil(.fullMoon, from: LunarCycle.referenceNewMoon)
        XCTAssertEqual(desdeNueva, LunarCycle.synodicMonth / 2, accuracy: 0.1)
        let siguienteNueva = LunarCycle.daysUntil(.newMoon, from: LunarCycle.referenceNewMoon)
        XCTAssertEqual(siguienteNueva, LunarCycle.synodicMonth, accuracy: 0.1, "Desde una luna nueva, la siguiente esta a un mes sinodico")
        // Estando a mitad de ciclo, el cuarto creciente vuelve a quedar a tres cuartos.
        let aMitad = LunarCycle.referenceNewMoon.addingTimeInterval(LunarCycle.synodicMonth / 2 * unDia)
        XCTAssertEqual(LunarCycle.daysUntil(.firstQuarter, from: aMitad), LunarCycle.synodicMonth * 3 / 4, accuracy: 0.2)
    }

    func testLasCuatroProximasFasesVanEnOrden() {
        let proximas = LunarCycle.upcoming(after: LunarCycle.referenceNewMoon, count: 4).map { $0.kind }
        XCTAssertEqual(proximas, [.waxingCrescent, .firstQuarter, .waxingGibbous, .fullMoon])
        let fechas = LunarCycle.upcoming(after: LunarCycle.referenceNewMoon, count: 4).map { $0.date }
        XCTAssertEqual(fechas, fechas.sorted(), "Vienen ordenadas en el tiempo")
    }

    func testCadaFaseTieneSuRitual() {
        for fase in LunarPhaseKind.allCases {
            XCTAssertFalse(fase.ritual.isEmpty, "\(fase.rawValue) necesita ritual")
            XCTAssertFalse(fase.intencion.isEmpty, "\(fase.rawValue) necesita intencion")
            XCTAssertFalse(fase.palabra.isEmpty)
        }
    }
}
