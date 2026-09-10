import SwiftUI
import TarotData
import TarotCore
import TarotDI

@MainActor
public final class SettingsViewModel: ObservableObject {
    @Published public var settings: UserSettings
    private let repository: SettingsRepository

    public init(repository: SettingsRepository) {
        self.repository = repository
        self.settings = repository.load()
    }

    public func persist() {
        repository.save(settings)
    }
}
