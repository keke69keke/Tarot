import Foundation
import TarotCore

public final class DeterministicDailyCardService: DailyCardService {
    private let cards: [Card]
    private let defaults: UserDefaults
    private let calendar: Calendar
    private let lunarService: LunarServiceProtocol

    public init(cards: [Card], lunarService: LunarServiceProtocol, userDefaults: UserDefaults = .standard, calendar: Calendar = .current) {
        self.cards = cards
        self.lunarService = lunarService
        self.defaults = userDefaults
        self.calendar = calendar
    }
    public func dailyCard(for date: Date) -> Card {
        precondition(!cards.isEmpty, "A daily card service needs a non-empty deck")
        let year = calendar.component(.year, from: date)
        let day = calendar.ordinality(of: .day, in: .year, for: date) ?? 1

        // Incorporate moon phase into the seed to create a cosmic signature
        let moonPhase = lunarService.phase(for: date)
        let moonHash = moonPhase.hashValue

        let seed = (year * 366 + day) ^ moonHash
        return cards[abs(seed) % cards.count]
    }
    public func isRevealed(for date: Date) -> Bool { defaults.bool(forKey: key(for: date)) }
    public func markRevealed(for date: Date) { defaults.set(true, forKey: key(for: date)) }
    private func key(for date: Date) -> String { "tarot.daily.revealed.\(calendar.startOfDay(for: date).timeIntervalSince1970)" }
}
