import XCTest
@testable import TarotCore

final class CosmicBackgroundEngineTests: XCTestCase {

    /// Small helper matching the smoothing used in the implementation.
    private func lerp(_ a: Double, _ b: Double, _ t: Double) -> Double { a + (b - a) * t }

    func testUpdateForBiometrics_calmProducesTealAccentAndSlowerParticles() throws {
        let engine = CosmicBackgroundEngine()
        // Start from a known particle speed so the smoothing result is deterministic
        engine.particleSpeed = 1.0

        let hr = 50.0
        engine.updateForBiometrics(heartRate: hr, state: .calm)

        // Expect accent color to be the teal custom color defined in implementation
        XCTAssertEqual(engine.accentColor, .custom(red: 0.29, green: 0.68, blue: 0.84))

        // Compute expected target and smoothed value (implementation uses smoothing = 0.18)
        let clampHR = min(max(hr, 40.0), 180.0)
        let normalized = (clampHR - 40.0) / (180.0 - 40.0)
        let target = min(max(0.45 + (0.75 - 0.45) * (normalized * 0.35), 0.45), 0.95)
        let expected = lerp(1.0, target, 0.18)

        XCTAssertEqual(engine.particleSpeed, expected, accuracy: 1e-6)
    }

    func testUpdateForBiometrics_stressedHighHRProducesRedAndFasterParticles() throws {
        let engine = CosmicBackgroundEngine()
        engine.particleSpeed = 1.0

        let hr = 160.0
        engine.updateForBiometrics(heartRate: hr, state: .stressed)

        XCTAssertEqual(engine.accentColor, .custom(red: 1.0, green: 0.298, blue: 0.298))

        let clampHR = min(max(hr, 40.0), 180.0)
        let normalized = (clampHR - 40.0) / (180.0 - 40.0)
        let target = min(max(1.2 + (2.0 - 1.2) * normalized, 1.0), 2.5)
        let expected = lerp(1.0, target, 0.18)

        XCTAssertEqual(engine.particleSpeed, expected, accuracy: 1e-6)
    }

    func testUpdateForBiometrics_unknownResetsToTarotGoldAndNeutralSpeed() throws {
        let engine = CosmicBackgroundEngine()
        engine.particleSpeed = 1.2

        let hr = 100.0
        engine.updateForBiometrics(heartRate: hr, state: .unknown)

        XCTAssertEqual(engine.accentColor, .tarotGold)

        // target is 1.0 for unknown state; expect smoothing toward 1.0
        let expected = lerp(1.2, 1.0, 0.18)
        XCTAssertEqual(engine.particleSpeed, expected, accuracy: 1e-6)
    }
}
