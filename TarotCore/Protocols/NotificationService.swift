import Foundation

/// Types of triggers supported by the notification system.
public enum NotificationTrigger {
    case daily(hour: Int)
    case timeInterval(seconds: TimeInterval)
    case date(Date)
}

/// Wrapper around `UNUserNotificationCenter` for reminders and proactive guidance.
public protocol NotificationService {

    /// Requests the user's permission to show notifications.
    ///
    /// - Returns: `true` when permission was granted.
    func requestPermission() async -> Bool

    /// Schedules a repeating daily notification at `hour` (24-hour clock).
    ///
    /// `hour` must be in the range 6 … 22; values outside this range must cause
    /// `TarotError.validationFailed` to be thrown (Requirement 4.6).
    /// Replaces any previously scheduled daily notification.
    ///
    /// - Throws: `TarotError.validationFailed` for out-of-range `hour`.
    ///           `TarotError.notificationPermissionDenied` when permission has not been granted.
    func scheduleDailyNotification(hour: Int) async throws

    /// Schedules a one-off notification with a specific title and body.
    func scheduleNotification(title: String, body: String, trigger: NotificationTrigger) async throws

    /// Cancels any pending daily notification.
    func cancelDailyNotification() async
}
