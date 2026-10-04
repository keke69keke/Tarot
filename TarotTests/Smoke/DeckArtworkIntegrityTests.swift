// Feature: tarot-iphone-app
// Smoke tests: integridad del arte de cada mazo (existencia, contenido e identidad por carta).
//
// Regresion cubierta: los 78 PNG de Hello Kitty eran negro solido (brillo 6-12, una unica
// huella para los 78 archivos) y los 78 de Marsella eran cartas casi en blanco (56 de 78
// identicas entre si). El smoke test anterior solo comprobaba existencia y tamano de archivo
// (>10 KB), asi que ambos fallos pasaron inadvertidos.

import XCTest
import CoreGraphics
import ImageIO
@testable import TarotCore
@testable import TarotData
@testable import TarotContent

final class DeckArtworkIntegrityTests: XCTestCase {

    // MARK: - Modelo

    private struct ArtworkSample {
        let name: String
        let meanBrightness: Double
        let darkFraction: Double
        let aspect: Double
        let fingerprint: String
    }

    private struct DeckPolicy {
        let label: String
        let assetPrefix: String?
        let minBrightness: Double
        let maxBrightness: Double
        let minDarkFraction: Double
        let maxDarkFraction: Double
        /// Aspecto exigido cuando el mazo se dibuja con `.fill` sobre el marco por defecto de
        /// CardFace (150x220): si el arte no encaja, la app recorta la ilustracion.
        /// Hello Kitty esta autorizado a 0.6816 y encaja; Marsella (0.536) y Rider-Waite (0.569)
        /// se muestran con `.fit`/recorte asumido, por eso no se les exige aqui.
        let frameAspectTolerance: Double?
    }

    /// Marco por defecto de `CardFace` (`CGSize(width: 150, height: 220)`).
    private static let frameAspect = 150.0 / 220.0

    private static let policies: [DeckPolicy] = [
        DeckPolicy(label: "Rider-Waite (base)", assetPrefix: nil,
                   minBrightness: 20, maxBrightness: 245,
                   minDarkFraction: 0.02, maxDarkFraction: 0.90,
                   frameAspectTolerance: nil),
        DeckPolicy(label: "Hello Kitty", assetPrefix: "helloKitty",
                   minBrightness: 20, maxBrightness: 245,
                   minDarkFraction: 0.02, maxDarkFraction: 0.90,
                   frameAspectTolerance: 0.02),
        DeckPolicy(label: "Marsella", assetPrefix: "marseille",
                   minBrightness: 20, maxBrightness: 245,
                   minDarkFraction: 0.02, maxDarkFraction: 0.90,
                   frameAspectTolerance: nil)
    ]

    // MARK: - Muestreo de una imagen

    private func sample(url: URL, grid: Int = 16) -> ArtworkSample? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else { return nil }
        var buffer = [UInt8](repeating: 0, count: grid * grid)
        guard let context = CGContext(data: &buffer, width: grid, height: grid,
                                      bitsPerComponent: 8, bytesPerRow: grid,
                                      space: CGColorSpaceCreateDeviceGray(),
                                      bitmapInfo: CGImageAlphaInfo.none.rawValue) else { return nil }
        context.interpolationQuality = .high
        context.draw(image, in: CGRect(x: 0, y: 0, width: grid, height: grid))
        let values = buffer.map(Double.init)
        return ArtworkSample(
            name: url.lastPathComponent,
            meanBrightness: values.reduce(0, +) / Double(values.count),
            darkFraction: Double(buffer.filter { $0 < 100 }.count) / Double(buffer.count),
            aspect: Double(image.width) / Double(image.height),
            fingerprint: buffer.map { $0 < 128 ? "1" : "0" }.joined()
        )
    }

    // MARK: - Reglas

    private func problems(for samples: [ArtworkSample], policy: DeckPolicy) -> [String] {
        var issues: [String] = []
        if samples.count != 78 {
            issues.append("\(policy.label): se esperaban 78 cartas con arte, hay \(samples.count)")
        }
        for sample in samples {
            if sample.meanBrightness < policy.minBrightness || sample.meanBrightness > policy.maxBrightness {
                issues.append(String(format: "%@: brillo medio %.1f fuera de [%.0f, %.0f] (placeholder en blanco o en negro)",
                                     sample.name, sample.meanBrightness, policy.minBrightness, policy.maxBrightness))
            }
            if sample.darkFraction < policy.minDarkFraction {
                issues.append(String(format: "%@: fraccion oscura %.3f < %.2f (la imagen esta vacia)",
                                     sample.name, sample.darkFraction, policy.minDarkFraction))
            }
            if sample.darkFraction > policy.maxDarkFraction {
                issues.append(String(format: "%@: fraccion oscura %.3f > %.2f (la imagen es un bloque solido)",
                                     sample.name, sample.darkFraction, policy.maxDarkFraction))
            }
            if let tolerance = policy.frameAspectTolerance {
                let delta = abs(sample.aspect - Self.frameAspect)
                if delta > tolerance {
                    issues.append(String(format: "%@: aspecto %.4f se desvia %.4f del marco %.4f; el recorte de .fill cortaria la ilustracion",
                                         sample.name, sample.aspect, delta, Self.frameAspect))
                }
            }
        }
        if let minAspect = samples.map(\.aspect).min(), let maxAspect = samples.map(\.aspect).max(),
           maxAspect - minAspect > 0.03 {
            issues.append(String(format: "%@: aspecto no uniforme (%.4f a %.4f)", policy.label, minAspect, maxAspect))
        }
        let distinct = Set(samples.map(\.fingerprint)).count
        if distinct < samples.count {
            issues.append("\(policy.label): solo \(distinct) imagenes distintas de \(samples.count) (hay arte duplicado entre cartas)")
        }
        return issues
    }

    // MARK: - Tests

    func testEveryDeckHasDistinctNonEmptyArtwork() throws {
        let repository = try BundleCardRepository(bundle: .tarotContent, settings: UserDefaultsSettingsRepository())
        let cards = repository.allCards()
        XCTAssertEqual(cards.count, 78, "El catalogo debe tener 78 cartas para poder validar los mazos")

        for policy in Self.policies {
            var samples: [ArtworkSample] = []
            for card in cards {
                let assetName = policy.assetPrefix.map { "\($0)_\(card.imageName)" } ?? card.imageName
                let cleanName = assetName.replacingOccurrences(of: ".png", with: "")
                // El arte puede estar en HEIC (mas ligero) o en PNG heredado.
                guard let url = ["png", "heic"].compactMap({ Bundle.tarotContent.url(forResource: cleanName, withExtension: $0) }).first else {
                    XCTFail("\(policy.label): falta la imagen \(cleanName) (.heic/.png) en el bundle TarotContent")
                    continue
                }
                guard let artwork = sample(url: url) else {
                    XCTFail("\(policy.label): no se pudo leer \(cleanName)")
                    continue
                }
                samples.append(artwork)
            }
            let issues = problems(for: samples, policy: policy)
            XCTAssertTrue(issues.isEmpty, "\(policy.label) tiene arte invalido:\n" + issues.prefix(12).joined(separator: "\n"))
        }
    }

    /// Autocomprobacion: las reglas deben rechazar exactamente los fallos que ya ocurrieron.
    func testIntegrityRulesRejectTheKnownBrokenDecks() {
        let helloPolicy = Self.policies[1]

        func deck(mean: Double, dark: Double, aspect: Double, distinct: Int) -> [ArtworkSample] {
            (0..<78).map { index in
                ArtworkSample(name: "card_\(String(format: "%02d", index)).png",
                              meanBrightness: mean, darkFraction: dark, aspect: aspect,
                              fingerprint: "fp\(index % distinct)")
            }
        }

        // Mazo sano: no debe haber incidencias.
        XCTAssertTrue(problems(for: deck(mean: 120, dark: 0.30, aspect: 0.6816, distinct: 78),
                               policy: helloPolicy).isEmpty)

        // Hello Kitty antiguo: 78 PNG negros identicos.
        let blackIssues = problems(for: deck(mean: 8, dark: 1.0, aspect: 0.62, distinct: 1), policy: helloPolicy)
        XCTAssertFalse(blackIssues.isEmpty, "La regla debe detectar un mazo negro")
        XCTAssertTrue(blackIssues.contains { $0.contains("brillo medio") }, "Debe reportar el brillo fuera de rango")
        XCTAssertTrue(blackIssues.contains { $0.contains("bloque solido") }, "Debe reportar el bloque solido")
        XCTAssertTrue(blackIssues.contains { $0.contains("distintas") }, "Debe reportar el arte duplicado")

        // Marsella antiguo: cartas casi en blanco y repetidas.
        let blankIssues = problems(for: deck(mean: 205, dark: 0.01, aspect: 0.6214, distinct: 20), policy: helloPolicy)
        XCTAssertTrue(blankIssues.contains { $0.contains("vacia") }, "Debe reportar la imagen vacia")
        XCTAssertTrue(blankIssues.contains { $0.contains("distintas") }, "Debe reportar el arte duplicado")

        // Aspecto desviado del marco: .fill recortaria la carta.
        let aspectIssues = problems(for: deck(mean: 120, dark: 0.30, aspect: 0.5358, distinct: 78), policy: helloPolicy)
        XCTAssertTrue(aspectIssues.contains { $0.contains("aspecto") }, "Debe reportar el desvio de aspecto")
    }
}
