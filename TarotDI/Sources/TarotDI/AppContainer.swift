import Foundation
import TarotCore
import TarotNotifications
import TarotData
import TarotContent

/// The central dependency injection root for the Tarot application.
@MainActor
public protocol AppContainerProtocol: ObservableObject {
    var cards: BundleCardRepository { get }
    var journal: CoreDataJournalRepository { get }
    var dreams: DreamRepositoryProtocol { get }
    var settings: UserDefaultsSettingsRepository { get }
    var daily: DeterministicDailyCardService { get }
    var notifications: LocalNotificationService { get }
    var spreadSynthesizer: SpreadSynthesizerProtocol { get }
    var library: LibraryManager { get }
    var omniIntelligence: any OmniIntelligenceProtocol { get }
    var lunar: LunarServiceProtocol { get }
    var planetary: PlanetaryServiceProtocol { get }
    var patterns: PatternRecognitionServiceProtocol { get }
    var symbolAtlas: SymbolAtlasServiceProtocol { get }
    var reflection: ReflectionServiceProtocol { get }
    var dreamOracle: any DreamOracleProtocol { get }
    var celestialEvents: CelestialEventService { get }
    var pathProgress: any PathProgressProtocol { get }
    var somatic: SomaticService { get }
    var biometrics: BiometricService { get }
    var proactiveGuidance: ProactiveGuidanceService { get }
    var environmentOracle: EnvironmentOracleService { get }
    var soulLinks: any TarotData.SoulLinksServiceProtocol { get }
    var cosmicBackground: CosmicBackgroundEngine { get }
}

public final class AppContainer: AppContainerProtocol {

    public let cards: BundleCardRepository
    public let journal: CoreDataJournalRepository
    public let dreams: DreamRepositoryProtocol
    public let settings: UserDefaultsSettingsRepository
    public let daily: DeterministicDailyCardService
    public let notifications = LocalNotificationService()
    public let spreadSynthesizer: SpreadSynthesizerProtocol
    @MainActor public let library: LibraryManager
    @MainActor public let omniIntelligence: any OmniIntelligenceProtocol
    @MainActor public let lunar: LunarServiceProtocol
    @MainActor public let planetary: PlanetaryServiceProtocol
    @MainActor public let patterns: PatternRecognitionServiceProtocol
    @MainActor public let symbolAtlas: SymbolAtlasServiceProtocol
    @MainActor public let reflection: ReflectionServiceProtocol
    @MainActor public let dreamOracle: any DreamOracleProtocol
    @MainActor public let celestialEvents: CelestialEventService
    @MainActor public let pathProgress: any PathProgressProtocol
    @MainActor public let somatic: SomaticService
    @MainActor public let biometrics: BiometricService
    @MainActor public let proactiveGuidance: ProactiveGuidanceService
    @MainActor public let environmentOracle: EnvironmentOracleService
    @MainActor public let soulLinks: any TarotData.SoulLinksServiceProtocol
    @MainActor public let cosmicBackground: CosmicBackgroundEngine

    @MainActor
    public init() throws {
        settings = UserDefaultsSettingsRepository()

        let repo: BundleCardRepository
        if let r = try? BundleCardRepository(bundle: .tarotContent, settings: settings) {
            repo = r
        } else if let r = try? BundleCardRepository(bundle: .main, settings: settings) {
            repo = r
        } else {
            repo = try BundleCardRepository(bundle: Bundle(for: BundleCardRepository.self), settings: settings)
        }
        cards = repo
        journal = CoreDataJournalRepository()
        dreams = CoreDataDreamRepository()
        lunar = LunarService()
        planetary = PlanetaryService()

        let intelligence = OmniIntelligenceService(apiKey: settings.load().openAIKey, repository: cards, planetaryService: planetary)
        omniIntelligence = intelligence

        daily = DeterministicDailyCardService(cards: cards.allCards(), lunarService: lunar)
        spreadSynthesizer = SpreadSynthesizer(cardRepository: cards, synthesisEngine: intelligence, lunarService: lunar)
        library = LibraryManager()
        patterns = PatternRecognitionService(journalRepository: journal, aiService: intelligence)
        intelligence.patterns = patterns
        symbolAtlas = SymbolAtlasService(journalRepository: journal, cardRepository: cards)
        reflection = ReflectionService(intelligence: intelligence)

        // Platinum Ascension Services
        dreamOracle = DreamOracleService(intelligence: intelligence, repository: dreams)
        celestialEvents = CelestialEventService(notifications: notifications, planetary: planetary, lunar: lunar)
        pathProgress = PathProgressService()
        somatic = SomaticService()
        biometrics = BiometricService()
        proactiveGuidance = ProactiveGuidanceService(journalRepository: journal, patternsService: patterns, notifications: notifications, settings: settings)
        environmentOracle = EnvironmentOracleService()
        soulLinks = TarotData.SoulLinksService()
        cosmicBackground = CosmicBackgroundEngine(lunarService: lunar, planetaryService: planetary)
    }
}
