import Foundation
import TarotCore

/// Repository for persisting and retrieving dream entries.
public final class CoreDataDreamRepository: DreamRepositoryProtocol {
    // In a real implementation, this would use CoreData.
    // For this high-end prototype, we use a thread-safe in-memory store with persistence simulation.
    private var storage: [UUID: DreamEntry] = [:]
    private let queue = DispatchQueue(label: "com.tarot.dreamrepo", attributes: .concurrent)

    public init() {}

    public func save(entry: DreamEntry) throws {
        queue.async(flags: .barrier) {
            self.storage[entry.id] = entry
        }
    }

    public func fetchAll() -> [DreamEntry] {
        queue.sync {
            Array(storage.values).sorted { $0.savedAt > $1.savedAt }
        }
    }

    public func delete(id: UUID) throws {
        queue.async(flags: .barrier) {
            self.storage.removeValue(forKey: id)
        }
    }

    public func findBySymbol(_ symbol: String) -> [DreamEntry] {
        queue.sync {
            storage.values.filter { $0.identifiedSymbols.contains(where: { $0.localizedCaseInsensitiveContains(symbol) }) }
        }
    }
}
