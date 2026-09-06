import Foundation

/// Protocol for repositories that manage dream-related data.
public protocol DreamRepositoryProtocol {
    func save(entry: DreamEntry) throws
    func fetchAll() -> [DreamEntry]
    func delete(id: UUID) throws
    func findBySymbol(_ symbol: String) -> [DreamEntry]
}
