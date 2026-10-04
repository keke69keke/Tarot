// Feature: tarot-iphone-app
// Smoke test: la geometria del fondo por capas (reparto de estrellas, parallax y azar
// determinista). El fondo paso de una sola capa con dos profundidades a cinco capas con
// parallax, giro 3D y desenfoque por distancia; estos tests fijan lo que no se ve a simple
// vista: que el reparto cuadre, que el desplazamiento este acotado y que la capa cercana se
// mueva mas que la lejana, y que el mismo seed de siempre el mismo cielo (si eso se rompe,
// el fondo daria saltos al navegar entre pestañas).

import XCTest
@testable import TarotCore

final class StarfieldLayoutTests: XCTestCase {

    func testHayAlMenosCuatroCapasConProfundidadYParallaxCrecientes() {
        let layers = StarfieldLayout.layers
        XCTAssertGreaterThanOrEqual(layers.count, 4, "el fondo debe tener al menos 4 capas de profundidad")

        let depths = layers.map(\.depth)
        XCTAssertEqual(depths, depths.sorted(), "las capas deben venir de la mas lejana a la mas cercana")
        XCTAssertEqual(depths.first ?? -1, 0, accuracy: 0.0001)
        XCTAssertEqual(depths.last ?? -1, 1, accuracy: 0.0001)

        let parallax = layers.map(\.parallax)
        XCTAssertEqual(parallax, parallax.sorted(), "la capa mas cercana debe moverse mas que la lejana")
        XCTAssertLessThan(parallax.first ?? 1, parallax.last ?? 0)

        // Profundidad de campo: la bruma disminuye desde el fondo hasta la capa nitida
        // (la de las estrellas medias) y la ultima capa, que es bokeh de primer plano,
        // va desenfocada a proposito: es lo que da la sensacion de tener algo delante.
        let starLayerBlurs = layers.dropLast().map(\.blur)
        XCTAssertEqual(starLayerBlurs, starLayerBlurs.sorted(by: >), "la bruma debe decrecer hacia la capa nitida")
        let sharpest = layers.min(by: { $0.blur < $1.blur })
        XCTAssertEqual(sharpest?.blur, 0, "debe existir una capa nitida")
        XCTAssertGreaterThan(layers.first?.blur ?? 0, 0.5, "el polvo lejano debe ir con bruma")
        XCTAssertGreaterThan(layers.last?.blur ?? 0, 0.5, "el bokeh de primer plano va desenfocado a proposito")
    }

    func testElRepartoDeEstrellasSumaElTotal() {
        for total in [0, 1, 4, 5, 12, 110, 500] {
            let counts = StarfieldLayout.counts(total: total)
            XCTAssertEqual(counts.count, StarfieldLayout.layers.count, "para total=\(total)")
            XCTAssertEqual(counts.reduce(0, +), total, "para total=\(total) el reparto debe cuadrar")
            XCTAssertTrue(counts.allSatisfy { $0 >= 0 }, "para total=\(total)")
        }
    }

    func testElDesplazamientoEstaAcotadoYCreceConLaProfundidad() {
        let strength: CGFloat = 26
        // A proposito fuera de rango: la funcion debe recortar a -1...1.
        let input = CGSize(width: 5, height: -3)
        var previous = CGFloat.zero

        for layer in StarfieldLayout.layers {
            let offset = StarfieldLayout.parallaxOffset(
                parallax: layer.parallax, depth: layer.depth, input: input, maxOffset: strength
            )
            XCTAssertLessThanOrEqual(abs(offset.width), strength, "la capa \(layer.depth) se sale del limite")
            XCTAssertLessThanOrEqual(abs(offset.height), strength, "la capa \(layer.depth) se sale del limite")
            XCTAssertGreaterThanOrEqual(abs(offset.width) + 0.0001, previous, "la capa \(layer.depth) deberia moverse mas que la anterior")
            previous = abs(offset.width)
        }

        // Sin entrada (reposo) no hay desplazamiento.
        let rest = StarfieldLayout.parallaxOffset(parallax: 1, depth: 1, input: .zero, maxOffset: strength)
        XCTAssertEqual(rest.width, 0, accuracy: 0.0001)
        XCTAssertEqual(rest.height, 0, accuracy: 0.0001)
    }

    func testElRepartoDeLasCientoDiezEstrellasEsElEsperado() {
        // Valor dorado: si alguien toca las proporciones, el reparto cambia y este test lo
        // dice. Un test que solo compruebe la suma pasaria con cualquier particion.
        XCTAssertEqual(StarfieldLayout.counts(total: 110), [44, 31, 22, 10, 3])
        // El reparto no crece con la profundidad: hay mas polvo lejano que motas cercanas.
        let counts = StarfieldLayout.counts(total: 110)
        XCTAssertEqual(counts, counts.sorted(by: >))
    }

    func testCadaCapaRecibeEstrellasDistintas() {
        // Las capas se generan con semillas distintas a proposito: si todas compartieran
        // semilla, las cinco nubes caerian exactamente una encima de otra y el parallax no
        // se veria, sin que ningun otro test se quejase.
        let spec = StarfieldLayout.layers[0]
        let a = StarfieldLayout.stars(seed: 7, count: 12, spec: spec)
        let b = StarfieldLayout.stars(seed: 8, count: 12, spec: spec)
        XCTAssertNotEqual(a, b)
        XCTAssertTrue(zip(a, b).allSatisfy { $0.x != $1.x || $0.y != $1.y })
    }

    func testLaOpacidadAcompanaALaProfundidadSalvoElBokehDePrimerPlano() {
        // El polvo lejano no puede volver a quedar invisible: demasiado tenue y demasiado
        // desenfocado fue el primer defecto de esta version.
        let layers = StarfieldLayout.layers
        XCTAssertGreaterThanOrEqual(layers[0].opacityRange.lowerBound, 0.2, "el polvo lejano debe verse")
        // La capa nitida es la mas contrastada.
        XCTAssertEqual(layers[3].opacityRange.upperBound, 1.0, accuracy: 0.0001)
        // El bokeh de primer plano conserva nucleo (si no, se lee como una mancha).
        XCTAssertGreaterThanOrEqual(layers[4].opacityRange.lowerBound, 0.4, "el bokeh necesita nucleo brillante")
        // Solo la capa de delante suma luz.
        XCTAssertEqual(layers.filter(\.addsLight).count, 1)
        XCTAssertEqual(layers.last?.addsLight, true)
    }

    func testLoLejanoEsMasFrioYLoCercanoMasCalido() {
        // Perspectiva atmosferica: con la misma semilla, la capa del fondo debe salir mas
        // lavada (tirando a blanco) que la de delante. Es la pista de profundidad que
        // funciona incluso con el fondo quieto.
        func mediaCalidez(_ indice: Int) -> Double {
            let capa = StarfieldLayout.layers[indice]
            let estrellas = StarfieldLayout.stars(seed: 99, count: 60, spec: capa)
            return estrellas.map(\.warmth).reduce(0, +) / Double(estrellas.count)
        }
        let lejana = mediaCalidez(0)
        let media = mediaCalidez(2)
        let cercana = mediaCalidez(4)
        XCTAssertLessThan(lejana, media)
        XCTAssertLessThan(media, cercana)
        XCTAssertLessThanOrEqual(lejana, 0.35, "el polvo lejano no debe llegar al ambar")
    }

    func testElCieloEsDeterministaConElMismoSeed() {

        let spec = StarfieldLayout.layers[2]
        let a = StarfieldLayout.stars(seed: 42, count: 20, spec: spec)
        let b = StarfieldLayout.stars(seed: 42, count: 20, spec: spec)
        let c = StarfieldLayout.stars(seed: 43, count: 20, spec: spec)

        XCTAssertEqual(a, b, "el mismo seed debe dar el mismo cielo (nada de saltos al navegar)")
        XCTAssertNotEqual(a, c, "otro seed debe dar otro cielo")
        XCTAssertEqual(a.count, 20)
        XCTAssertTrue(a.allSatisfy { (0...1).contains($0.x) && (0...1).contains($0.y) })
        XCTAssertTrue(a.allSatisfy { spec.sizeRange.contains($0.size) })
        XCTAssertTrue(a.allSatisfy { spec.opacityRange.contains($0.opacity) })
        XCTAssertTrue(a.allSatisfy { (0...1).contains($0.warmth) })

        XCTAssertTrue(StarfieldLayout.stars(seed: 42, count: 0, spec: spec).isEmpty)
    }

    func testLaEscalaDeCoberturaTapaElDesplazamientoDeCadaCapa() {
        // Cada capa, al moverse a tope, debe seguir cubriendo el marco: si la escala se queda
        // corta aparece una franja sin estrellas en un borde.
        let tamano = CGSize(width: 390, height: 844)
        let fuerza: CGFloat = 26
        for capa in StarfieldLayout.layers {
            let escala = StarfieldLayout.coverScale(parallax: capa.parallax, size: tamano, maxOffset: fuerza)
            let cobertura = tamano.width / 2 * (escala - 1)
            let necesario = fuerza * CGFloat(capa.parallax)
            // Lo que importa: que la cobertura llegue al recorrido (sin franja) y que sobre
            // margen para el estrechamiento que provoca la perspectiva del giro 3D.
            XCTAssertGreaterThanOrEqual(cobertura, necesario - 1e-6,
                "la capa con profundidad \(capa.depth) deja el borde al aire")
            XCTAssertGreaterThanOrEqual(cobertura - necesario, 5.5,
                "la capa con profundidad \(capa.depth) se queda sin margen para el giro")
        }
    }

    func testSinElFactorDosQuedariaFranjaVacia() {
        // Regresion: hubo una version que calculaba la escala con la mitad del recorrido,
        // creyendo que sobraba, y las capas cercanas dejaban 7 pt sin estrellas al inclinar
        // a tope. Con esa formula corta la cobertura no llega al desplazamiento.
        let tamano = CGSize(width: 390, height: 844)
        let fuerza: CGFloat = 26
        guard let capa = StarfieldLayout.layers.last else { return XCTFail("sin capas") }
        let necesario = fuerza * CGFloat(capa.parallax)
        let escalaCorta = 1 + necesario / tamano.width
        XCTAssertLessThan(tamano.width / 2 * (escalaCorta - 1), necesario)
        XCTAssertGreaterThanOrEqual(
            StarfieldLayout.coverScale(parallax: capa.parallax, size: tamano, maxOffset: fuerza),
            escalaCorta
        )
    }

    func testLaEscalaDeCoberturaCreceConLaProfundidadYSinMovimientoEsUno() {
        let tamano = CGSize(width: 390, height: 844)
        let escalas = StarfieldLayout.layers.map {
            StarfieldLayout.coverScale(parallax: $0.parallax, size: tamano, maxOffset: 26)
        }
        XCTAssertEqual(escalas, escalas.sorted())
        XCTAssertGreaterThanOrEqual(escalas[0], 1.0)
        XCTAssertEqual(StarfieldLayout.coverScale(parallax: 0, size: tamano, maxOffset: 0, margin: 0), 1.0)
        XCTAssertEqual(StarfieldLayout.coverScale(parallax: 1, size: .zero, maxOffset: 26), 1.0)
    }
}
