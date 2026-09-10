import Foundation

/// Service for calculating and scheduling celestial events based on planetary and lunar data.
public final class CelestialEventService {
    private let notifications: NotificationService
    private let planetary: PlanetaryServiceProtocol
    private let lunar: LunarServiceProtocol

    public init(notifications: NotificationService, planetary: PlanetaryServiceProtocol, lunar: LunarServiceProtocol) {
        self.notifications = notifications
        self.planetary = planetary
        self.lunar = lunar
    }

    /// Calculates upcoming significant celestial events and schedules alerts.
    public func syncCelestialAlerts(for intention: String? = nil) async {
        // 1. Sync Lunar Phase alerts
        let phase = lunar.currentPhase()
        if phase.contains("Llena") || phase.contains("Nueva") {
            await scheduleCosmicAlert(
                title: "Sincronía Lunar",
                body: "La luna está en fase \(phase). Un momento poderoso para la manifestación.",
                identifier: "tarot.lunar-sync"
            )
        }

        // 2. Sync Planetary Mood alerts
        let influence = planetary.currentDominantPlanet()
        let personalizedBody = intention != nil
            ? "Bajo la energía de \(influence.planet.rawValue), tu intención de '\(intention!)' encuentra un nuevo eco."
            : "La energía de \(influence.planet.rawValue) domina el cielo hoy. Mood: \(influence.mood)."

        await scheduleCosmicAlert(
            title: "Tránsito Astral",
            body: personalizedBody,
            identifier: "tarot.planetary-sync"
        )
    }

    private func scheduleCosmicAlert(title: String, body: String, identifier: String) async {
        // In a real implementation, this would calculate the exact time of the event.
        // For the prototype, we schedule it for a random time within the next 24h to simulate the effect.
        let randomOffset = Int.random(in: 1...23)
        _ = Calendar.current.date(byAdding: .hour, value: randomOffset, to: .now) ?? .now

        // Since LocalNotificationService currently only supports daily hours,
        // we'd need to extend it for specific Dates.
        // For now, we use a generic notification system if available.
        print("Scheduling cosmic alert: \(title) - \(body)")
    }
}
