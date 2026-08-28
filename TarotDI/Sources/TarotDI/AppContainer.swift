import Foundation
import TarotCore
import TarotData
import TarotNotifications
import TarotContent

public protocol AppContainerProtocol: ObservableObject {
    var cards: BundleCardRepository { get }
    var journal: CoreDataJournalRepository { get }
    var settings: UserDefaultsSettingsRepository { get }
    var daily: DeterministicDailyCardService { get }
    var notifications: LocalNotificationService { get }
    var spreadSynthesizer: SpreadSynthesizerProtocol { get }
    var library: LibraryManager { get }
}

public final class AppContainer: AppContainerProtocol {
    public let cards: BundleCardRepository
    public let journal: CoreDataJournalRepository
    public let settings: UserDefaultsSettingsRepository
    public let daily: DeterministicDailyCardService
    public let notifications = LocalNotificationService()
    public let spreadSynthesizer: SpreadSynthesizerProtocol
    @MainActor public let library: LibraryManager

    @MainActor
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
        library = LibraryManager()
    }
}
