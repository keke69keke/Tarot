import SwiftUI
import TarotContent
import TarotCore
import TarotData
import TarotNotifications

@MainActor public final class AppContainer: ObservableObject {
    public let cards: BundleCardRepository
    public let journal: CoreDataJournalRepository
    public let settings: UserDefaultsSettingsRepository
    public let daily: DeterministicDailyCardService
    public let notifications = LocalNotificationService()
    public let spreadSynthesizer: SpreadSynthesizerProtocol

    public init() throws {
        let repo: BundleCardRepository
        if let r = try? BundleCardRepository(bundle: .tarotContent) {
            repo = r
        } else if let r = try? BundleCardRepository(bundle: .main) {
            repo = r
        } else {
            repo = try BundleCardRepository(bundle: Bundle(for: BundleCardRepository.self))
        }
        cards = repo
        journal = CoreDataJournalRepository()
        settings = UserDefaultsSettingsRepository()
        daily = DeterministicDailyCardService(cards: cards.allCards())
        spreadSynthesizer = SpreadSynthesizer(cardRepository: cards)
    }
}
