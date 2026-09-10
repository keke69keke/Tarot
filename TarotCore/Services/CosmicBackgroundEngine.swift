import SwiftUI

/// Basic implementation of the cosmic background engine used by the UI.
/// Conforms to `CosmicBackgroundEngineProtocol` so callers can rely on
/// methods such as `updateForBiometrics` and `setZenMode`.
@MainActor
public final class CosmicBackgroundEngine: ObservableObject, CosmicBackgroundEngineProtocol {
    @Published public var primaryColor: Color = Color.black
    @Published public var accentColor: Color = Color.yellow
    @Published public var particleSpeed: Double = 1.0

    // Public read-only for external callers; mutated internally.
    @Published public private(set) var isZenMode: Bool = false

    // Keep references to services for future computation (unused for now).
    private let lunarService: any LunarServiceProtocol
    private let planetaryService: any PlanetaryServiceProtocol

    public init(lunarService: any LunarServiceProtocol = LunarService(), planetaryService: any PlanetaryServiceProtocol = PlanetaryService()) {
        self.lunarService = lunarService
        self.planetaryService = planetaryService
        // Initial computation could go here
        updateCosmicState()
    }

    // MARK: - CosmicBackgroundEngineProtocol

    public func setZenMode(_ enabled: Bool) {
        // Simple animation-friendly adjustments for zen mode
        isZenMode = enabled
        if enabled {
            primaryColor = .purple
            accentColor = .blue
            particleSpeed = 0.55
        } else {
            primaryColor = Color.black
            accentColor = Color.yellow
            particleSpeed = 1.0
        }
    }

    public func updateCosmicState() {
        // Placeholder: use lunar/planetary services to update colors/speed
        // For now keep defaults; this method exists to satisfy protocol and
        // to allow callers to request a refresh.
        Task { @MainActor in
            // Example: nudge particle speed slightly based on dummy factors
            particleSpeed = 1.0
        }
    }

    public func updateForBiometrics(heartRate: Double, state: SoulState) {
        // Map biometric state to visual parameters using smooth, clamped curves
        // and apply a small low-pass to avoid visual jumps when the BIOMETRICS
        // publisher emits quickly.
        func clamp(_ v: Double, min: Double, max: Double) -> Double { Swift.max(min, Swift.min(max, v)) }
        func lerp(_ a: Double, _ b: Double, _ t: Double) -> Double { a + (b - a) * t }

        // Normalize heart rate into 0...1 within a reasonable physiological window
        let hr = clamp(heartRate, min: 40.0, max: 180.0)
        let normalized = (hr - 40.0) / (180.0 - 40.0) // 0 @40bpm, 1 @180bpm

        // Compute target values based on state
        var targetAccent: Color = Color.yellow
        var targetPrimary: Color = Color.black
        var targetParticleSpeed: Double = 1.0

        switch state {
        case .calm:
            // Soft teal-blue palette for calm
            targetAccent = Color(red: 0.29, green: 0.68, blue: 0.84)
            targetPrimary = Color(red: 0.03, green: 0.08, blue: 0.12)
            // calm -> slower particles; slightly responsive to HR
            targetParticleSpeed = clamp(lerp(0.45, 0.75, normalized * 0.35), min: 0.45, max: 0.95)
        case .elevated:
            // Warm magenta/pink for elevated
            targetAccent = Color(red: 1.0, green: 0.435, blue: 0.64)
            targetPrimary = Color(red: 0.08, green: 0.03, blue: 0.12)
            targetParticleSpeed = clamp(lerp(0.95, 1.4, normalized), min: 0.9, max: 1.6)
        case .stressed:
            // High-energy red for stressed
            targetAccent = Color(red: 1.0, green: 0.298, blue: 0.298)
            targetPrimary = Color(red: 0.08, green: 0.02, blue: 0.02)
            targetParticleSpeed = clamp(lerp(1.2, 2.0, normalized), min: 1.0, max: 2.5)
        case .unknown:
            targetAccent = Color.yellow
            targetPrimary = Color.black
            targetParticleSpeed = 1.0
        }

        // Smooth transitions: blend current values toward targets.
        // Colors are discrete (CosmicColor) — we set accent/primary directly but
        // smooth particleSpeed to avoid jumps.
        accentColor = targetAccent
        primaryColor = targetPrimary
        // Apply a light low-pass filter to particleSpeed
        let smoothing: Double = 0.18
        particleSpeed = lerp(particleSpeed, targetParticleSpeed, smoothing)
    }
}

