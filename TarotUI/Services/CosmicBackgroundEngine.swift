import SwiftUI
import TarotCore

/// A state machine that maps cosmic context (lunar phase, reading energy) to visual parameters for the background.
public final class CosmicBackgroundEngine: ObservableObject, CosmicBackgroundEngineProtocol {
    @Published public var particleSpeed: Double = 1.0
    @Published public var particleDensity: Double = 1.0
    @Published public var primaryColor: Color = .tarotBackground
    @Published public var accentColor: Color = .tarotGold.opacity(0.1)
    @Published public var isZenMode: Bool = false

    private let lunarService: LunarServiceProtocol
    private let planetaryService: PlanetaryServiceProtocol
    private var timer: Timer?

    public init(lunarService: LunarServiceProtocol, planetaryService: PlanetaryServiceProtocol) {
        self.lunarService = lunarService
        self.planetaryService = planetaryService
        updateCosmicState()
        setupTimer()
    }

    public func setZenMode(_ enabled: Bool) {
        withAnimation(.easeInOut(duration: 3.0)) {
            isZenMode = enabled
        }
        updateCosmicState()
    }

    private func setupTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { [weak self] _ in
            self?.updateCosmicState()
        }
    }

    /// Updates the visual parameters based on the current lunar phase and dominant planet.
    public func updateCosmicState() {
        let phase = lunarService.currentPhase()
        let influence = planetaryService.currentDominantPlanet()

        if isZenMode {
            // Zen Palette: Soft, muted, focused on tranquility
            primaryColor = Color(red: 0.02, green: 0.03, blue: 0.08) // Deep void blue
            particleDensity = 0.3
            particleSpeed = 0.3
            accentColor = Color.white.opacity(0.05)
            return
        }

        // Layer 1: Lunar Base (Broad cycles)
        switch phase {
        case "Luna Nueva":
            primaryColor = Color(red: 0.05, green: 0.02, blue: 0.12) // Deep indigo
            particleDensity = 0.6
        case "Luna Llena":
            primaryColor = Color(red: 0.12, green: 0.10, blue: 0.20) // Pearlescent purple
            particleDensity = 1.5
        case "Luna Creciente", "Cuarto Creciente", "Gibosa Creciente":
            primaryColor = .tarotBackground
            particleDensity = 1.0
        case "Luna Menguante", "Cuarto Menguante", "Gibosa Menguante":
            primaryColor = Color(red: 0.08, green: 0.05, blue: 0.15) // Muted purple
            particleDensity = 0.8
        default:
            primaryColor = .tarotBackground
            particleDensity = 1.0
        }

        // Layer 2: Planetary Overlay (Daily energy)
        switch influence.planet {
        case .sun:
            particleSpeed = 1.4
            accentColor = .white
        case .moon:
            particleSpeed = 0.6
            accentColor = Color(white: 0.9, opacity: 0.3) // Soft Pearl
        case .mercury:
            particleSpeed = 1.2
            accentColor = Color(red: 0.0, green: 1.0, blue: 1.0, opacity: 0.2) // Electric Cyan
        case .venus:
            particleSpeed = 0.4
            accentColor = Color.tarotGold.opacity(0.2)
        case .mars:
            particleSpeed = 1.8
            accentColor = Color.orange.opacity(0.2)
        case .jupiter:
            particleSpeed = 1.2
            accentColor = Color.purple.opacity(0.2)
        case .saturn:
            particleSpeed = 0.5
            accentColor = Color.gray.opacity(0.2)
        case .uranus:
            particleSpeed = 1.5
            accentColor = Color.magenta.opacity(0.2)
        case .neptune:
            particleSpeed = 0.7
            accentColor = Color.blue.opacity(0.2)
        case .pluto:
            particleSpeed = 0.9
            accentColor = Color.indigo.opacity(0.2)
        }
    }

    /// Adjusts the visuals based on the dominant energy of a reading.
    public func updateForReading(dominantSuit: CardSuit?) {
        guard let suit = dominantSuit else { return }

        switch suit {
        case .wands: // Fire - Energetic, fast, warm
            particleSpeed = 1.5
            accentColor = Color.orange.opacity(0.15)
        case .cups: // Water - Fluid, slow, cool
            particleSpeed = 0.5
            accentColor = Color.blue.opacity(0.15)
        case .swords: // Air - Sharp, erratic, light
            particleSpeed = 1.2
            accentColor = Color.white.opacity(0.1)
        case .pentacles: // Earth - Stable, slow, dense
            particleSpeed = 0.7
            accentColor = Color.green.opacity(0.1)
        }
    }

    /// Adjusts visuals based on the user's heart rate.
    public func updateForBiometrics(heartRate: Double, state: SoulState) {
        if heartRate == 0 { return }

        // In Zen mode, biometric influence is dampened to maintain tranquility
        let multiplier = isZenMode ? 0.2 : 1.0

        // Scale speed: 60 BPM -> 0.8x, 100 BPM -> 1.5x
        let speedFactor = 0.8 + (heartRate - 60) * 0.01
        particleSpeed = max(0.3, min(2.5, speedFactor * multiplier + (isZenMode ? 0.3 : 0)))

        // Adjust accent color based on state
        switch state {
        case .calm:
            accentColor = isZenMode ? Color.white.opacity(0.1) : Color.blue.opacity(0.2)
        case .elevated:
            accentColor = isZenMode ? Color.tarotGold.opacity(0.1) : Color.tarotGold.opacity(0.2)
        case .stressed:
            accentColor = isZenMode ? Color.red.opacity(0.05) : Color.red.opacity(0.2)
        case .unknown:
            break
        }
    }
}
