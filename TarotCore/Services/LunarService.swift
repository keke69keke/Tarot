import Foundation

/// Calculates and provides information about the current lunar phase.
public protocol LunarServiceProtocol {
    /// Returns the current moon phase as a descriptive string.
    func currentPhase() -> String

    /// Returns the phase for a specific date.
    func phase(for date: Date) -> String
}

public final class LunarService: LunarServiceProtocol {

    public enum MoonPhase: String, CaseIterable {
        case new = "Luna Nueva"
        case waxingCrescent = "Luna Creciente"
        case firstQuarter = "Cuarto Creciente"
        case waxingGibbous = "Gibosa Creciente"
        case full = "Luna Llena"
        case waningGibbous = "Gibosa Menguante"
        case lastQuarter = "Cuarto Menguante"
        case waningCrescent = "Luna Menguante"

        public var description: String { self.rawValue }
    }

    public init() {}

    public func currentPhase() -> String {
        return phase(for: Date())
    }

    public func phase(for date: Date) -> String {
        let phaseIndex = calculateMoonPhaseIndex(for: date)
        return MoonPhase.allCases[phaseIndex].description
    }

    /// Simple astronomical approximation for moon phase index (0-7).
    /// Based on the average synodic month (29.53059 days).
    private func calculateMoonPhaseIndex(for date: Date) -> Int {
        // Known New Moon: 2000-01-06 18:14 UTC
        let knownNewMoon = Date(timeIntervalSince1970: 947156040)
        let secondsInSynodicMonth: TimeInterval = 29.53059 * 24 * 60 * 60

        let diff = date.timeIntervalSince(knownNewMoon)
        let phaseProgress = (diff / secondsInSynodicMonth).truncatingRemainder(dividingBy: 1.0)

        // Ensure positive remainder
        let normalizedProgress = phaseProgress < 0 ? phaseProgress + 1.0 : phaseProgress

        // Map 0.0...1.0 to 0...7 index
        return Int(normalizedProgress * 8.0) % 8
    }
}
