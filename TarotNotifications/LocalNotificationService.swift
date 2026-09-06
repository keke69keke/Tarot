import Foundation
import TarotCore
import UserNotifications

public final class LocalNotificationService: NotificationService {
    private let center: UNUserNotificationCenter
    private let identifier = "tarot.daily-card"
    public init(center: UNUserNotificationCenter = .current()) { self.center = center }
    public static func isValidNotificationHour(_ hour: Int) -> Bool { (6...22).contains(hour) }
    public func requestPermission() async -> Bool { (try? await center.requestAuthorization(options: [.alert, .badge, .sound])) ?? false }
    public func scheduleDailyNotification(hour: Int) async throws {
        guard Self.isValidNotificationHour(hour) else { throw TarotError.validationFailed(field: "hora", reason: "debe estar entre 6 y 22") }
        let enabled = await requestPermission()
        guard enabled else { throw TarotError.notificationPermissionDenied }
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        let content = UNMutableNotificationContent(); content.title = "Tu carta del día"; content.body = "Toca para revelar tu guía de hoy."; content.sound = .default
        let trigger = UNCalendarNotificationTrigger(dateMatching: DateComponents(hour: hour), repeats: true)
        try await center.add(UNNotificationRequest(identifier: identifier, content: content, trigger: trigger))
    }

    public func scheduleNotification(title: String, body: String, trigger: NotificationTrigger) async throws {
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

    public func cancelDailyNotification() async { center.removePendingNotificationRequests(withIdentifiers: [identifier]) }
}
