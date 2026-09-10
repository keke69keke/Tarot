import Foundation

/// The AstralSynchronicity service provides real-time planetary data to synchronize the app with the cosmos.
public protocol PlanetaryServiceProtocol {
    /// Returns the current dominant planet and its associated energy.
    func currentDominantPlanet() -> PlanetaryInfluence

    /// Checks if a specific planet is currently in retrograde.
    func isRetrograde(_ planet: Planet) -> Bool

    /// Returns the current overall astral "mood" (e.g., "Analytical", "Romantic", "Volatile").
    func currentAstralMood() -> String
}

public struct PlanetaryInfluence {
    public let planet: Planet
    public let energy: String
    public let mood: String
}

public final class PlanetaryService: PlanetaryServiceProtocol {
    public init() {}

    public func currentDominantPlanet() -> PlanetaryInfluence {
        // In a production environment, this would call an Ephemeris API.
        // For now, we use a deterministic simulation based on the current date.
        let date = Date()
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: date) ?? 1

        let planets = Planet.allCases
        let planet = planets[dayOfYear % planets.count]

        switch planet {
        case .sun: return PlanetaryInfluence(planet: planet, energy: "Vitalidad", mood: "Radiante")
        case .moon: return PlanetaryInfluence(planet: planet, energy: "Intuición", mood: "Fluido")
        case .mercury: return PlanetaryInfluence(planet: planet, energy: "Comunicación", mood: "Analítico")
        case .venus: return PlanetaryInfluence(planet: planet, energy: "Amor", mood: "Armonioso")
        case .mars: return PlanetaryInfluence(planet: planet, energy: "Acción", mood: "Impulsivo")
        case .jupiter: return PlanetaryInfluence(planet: planet, energy: "Expansión", mood: "Optimista")
        case .saturn: return PlanetaryInfluence(planet: planet, energy: "Disciplina", mood: "Restrictivo")
        case .uranus: return PlanetaryInfluence(planet: planet, energy: "Innovación", mood: "Errático")
        case .neptune: return PlanetaryInfluence(planet: planet, energy: "Espiritualidad", mood: "Onírico")
        case .pluto: return PlanetaryInfluence(planet: planet, energy: "Transformación", mood: "Intenso")
        }
    }

    public func isRetrograde(_ planet: Planet) -> Bool {
        // Simulated retrograde cycles
        let date = Date()
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: date) ?? 1

        switch planet {
        case .mercury: return (dayOfYear % 120) < 20 // Mercury is retrograde often
        case .venus: return (dayOfYear % 150) < 15
        case .mars: return (dayOfYear % 780) < 60
        default: return false
        }
    }

    public func currentAstralMood() -> String {
        let influence = currentDominantPlanet()
        return influence.mood
    }
}
