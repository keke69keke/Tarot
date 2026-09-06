import Foundation
import TarotCore
import Combine

/// Service that monitors user patterns and environment to provide proactive spiritual guidance.
public final class ProactiveGuidanceService: ObservableObject {
    private let journalRepository: JournalRepository
    private let patternsService: PatternRecognitionServiceProtocol
    private let notifications: NotificationService
    private let settings: SettingsRepository

    public init(journalRepository: JournalRepository, patternsService: PatternRecognitionServiceProtocol, notifications: NotificationService, settings: SettingsRepository) {
        self.journalRepository = journalRepository
        self.patternsService = patternsService
        self.notifications = notifications
        self.settings = settings
    }

    /// Analyzes recent entries for recurring shadow themes and triggers a notification if a loop is detected.
    public func analyzeForShadowLoops() async {
        do {
            let themes = try await patternsService.identifyRecurringThemes(limit: 5)

            // Look for high-intensity negative themes (simplified example)
            let shadowKeywords = ["ansiedad", "miedo", "tristeza", "estancamiento", "culpa", "soledad"]
            let detectedShadows = themes.filter { theme in
                shadowKeywords.contains { keyword in theme.lowercased().contains(keyword) }
            }

            if detectedShadows.count >= 2 {
                await triggerShadowWorkNotification(themes: detectedShadows)
            }
        } catch {
            print("ProactiveGuidanceService: Error analyzing shadow loops: \(error)")
        }
    }

    private func triggerShadowWorkNotification(themes: [String]) async {
        let themeList = themes.joined(separator: ", ")
        let content = "He notado una energía recurrente de \(themeList). Es un momento propicio para una lectura de 'Trabajo de Sombras' y liberar estas cargas."

        do {
            try await notifications.scheduleNotification(
                title: "Sincronía del Alma",
                body: content,
                trigger: .timeInterval(seconds: 60 * 60 * 24) // Every 24h or a specific interval
            )
        } catch {
            print("ProactiveGuidanceService: Error scheduling notification: \(error)")
        }
    }

    /// Checks if the user's current journey aligns with their initial ritual intention.
    public func checkIntentionAlignment() async -> String? {
        let currentSettings = settings.load()
        guard !currentSettings.userName.isEmpty else { return nil }

        // This would typically use AI to compare the last few entries with the intention
        // For now, we return a placeholder that can be expanded
        return "Tus lecturas recientes resuenan con tu intención inicial de crecimiento."
    }
}
