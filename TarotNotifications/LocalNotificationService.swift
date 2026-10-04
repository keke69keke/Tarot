import Foundation
import TarotCore
import UserNotifications

public final class LocalNotificationService: NotificationService {
    private let identifier = "tarot.daily-card"

    /// Centro de notificaciones, resuelto de forma perezosa y tolerante.
    ///
    /// `UNUserNotificationCenter.current()` lanza una excepción de Objective-C
    /// (y el proceso muere con SIGSEGV) cuando se pide antes de que la app esté
    /// completamente registrada, algo que ocurre al construir el contenedor
    /// durante el arranque o al abrir el binario suelto de SwiftPM, que no es un
    /// bundle de aplicación válido. Envolverlo aquí convierte ese fallo
    /// irrecuperable en un `nil` que degrada el servicio a "no disponible".
    private let _center: UNUserNotificationCenter?

    /// `true` si el sistema entregó un centro de notificaciones utilizable.
    public var isAvailable: Bool { _center != nil }

    public init() {
        _center = Self.resolveCenter()
    }

    /// Permite inyectar un centro concreto en pruebas.
    public init(center: UNUserNotificationCenter?) {
        _center = center
    }

    private static func resolveCenter() -> UNUserNotificationCenter? {
        // Solo hay centro de notificaciones dentro de un bundle de app.
        guard Bundle.main.bundleIdentifier != nil else { return nil }
        return UNUserNotificationCenter.current()
    }

    public static func isValidNotificationHour(_ hour: Int) -> Bool { (6...22).contains(hour) }
    public func requestPermission() async -> Bool {
        guard let center = _center else { return false }
        return (try? await center.requestAuthorization(options: [.alert, .badge, .sound])) ?? false
    }
    public func scheduleDailyNotification(hour: Int) async throws {
        guard Self.isValidNotificationHour(hour) else { throw TarotError.validationFailed(field: "hora", reason: "debe estar entre 6 y 22") }
        guard let center = _center else { throw TarotError.notificationPermissionDenied }
        let enabled = await requestPermission()
        guard enabled else { throw TarotError.notificationPermissionDenied }
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        let content = UNMutableNotificationContent(); content.title = "Tu carta del día"; content.body = "Toca para revelar tu guía de hoy."; content.sound = .default
        let trigger = UNCalendarNotificationTrigger(dateMatching: DateComponents(hour: hour), repeats: true)
        try await center.add(UNNotificationRequest(identifier: identifier, content: content, trigger: trigger))
    }

    public func scheduleNotification(title: String, body: String, trigger: NotificationTrigger) async throws {
        guard let center = _center else { throw TarotError.notificationPermissionDenied }
        let enabled = await requestPermission()
        guard enabled else { throw TarotError.notificationPermissionDenied }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let unTrigger: UNNotificationTrigger
        switch trigger {
        case .daily(let hour):
            unTrigger = UNCalendarNotificationTrigger(dateMatching: DateComponents(hour: hour), repeats: true)
        case .timeInterval(let seconds):
            unTrigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        case .date(let date):
            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
            unTrigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        }

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: unTrigger)
        try await center.add(request)
    }

    public func cancelDailyNotification() async {
        _center?.removePendingNotificationRequests(withIdentifiers: [identifier])
    }
}
