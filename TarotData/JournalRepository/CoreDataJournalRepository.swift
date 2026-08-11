import CoreData
import Foundation
import TarotCore

/// Core Data-backed journal storage. The reading is stored as a single Codable
/// payload so catalog changes do not require a migration for the journal schema.
public final class CoreDataJournalRepository: JournalRepository {
    private let container: NSPersistentContainer

    public init(inMemory: Bool = false) {
        let model = NSManagedObjectModel()
        let entity = NSEntityDescription()
        entity.name = "JournalEntry"
        entity.managedObjectClassName = "NSManagedObject"

        let id = NSAttributeDescription()
        id.name = "id"; id.attributeType = .UUIDAttributeType; id.isOptional = false
        let savedAt = NSAttributeDescription()
        savedAt.name = "savedAt"; savedAt.attributeType = .dateAttributeType; savedAt.isOptional = false
        let payload = NSAttributeDescription()
        payload.name = "payload"; payload.attributeType = .binaryDataAttributeType; payload.isOptional = false
        entity.properties = [id, savedAt, payload]
        model.entities = [entity]

        container = NSPersistentContainer(name: "TarotJournal", managedObjectModel: model)
        if inMemory { container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null") }
        container.loadPersistentStores { _, error in
            precondition(error == nil, "Unable to load Tarot journal store: \(error!.localizedDescription)")
        }
    }

    public func save(entry: JournalEntry) throws {
        let context = container.viewContext
        do {
            let request = NSFetchRequest<NSManagedObject>(entityName: "JournalEntry")
            request.predicate = NSPredicate(format: "id == %@", entry.id as CVarArg)
            let object = try context.fetch(request).first ?? NSEntityDescription.insertNewObject(forEntityName: "JournalEntry", into: context)
            object.setValue(entry.id, forKey: "id")
            object.setValue(entry.savedAt, forKey: "savedAt")
            object.setValue(try JSONEncoder().encode(JournalEntryDTO(entry)), forKey: "payload") 
            try context.save()
        } catch { throw TarotError.persistenceFailed(operation: "guardar la lectura", underlying: error) }
    }

    public func fetchAll() -> [JournalEntry] {
        let request = NSFetchRequest<NSManagedObject>(entityName: "JournalEntry")
        request.sortDescriptors = [NSSortDescriptor(key: "savedAt", ascending: false)]
        return (try? container.viewContext.fetch(request))?.compactMap(decode) ?? []
    }

    public func fetch(id: UUID) -> JournalEntry? {
        let request = NSFetchRequest<NSManagedObject>(entityName: "JournalEntry")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        return (try? container.viewContext.fetch(request))?.first.flatMap(decode)
    }

    public func delete(id: UUID) throws {
        let context = container.viewContext
        do {
            let request = NSFetchRequest<NSManagedObject>(entityName: "JournalEntry")
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            try context.fetch(request).forEach(context.delete)
            try context.save()
        } catch { throw TarotError.persistenceFailed(operation: "eliminar la lectura", underlying: error) }
    }

    private func decode(_ object: NSManagedObject) -> JournalEntry? {
        guard let data = object.value(forKey: "payload") as? Data else { return nil }
        return try? JSONDecoder().decode(JournalEntryDTO.self, from: data).domain
    }
}

private struct JournalEntryDTO: Codable {
    struct CardDTO: Codable {
        let id: Int
        let name: String
        let number: String?
        let suit: String?
        let arcanaType: String
        let imageName: String
        let upright: InterpretationDTO
        let reversed: InterpretationDTO

        init(_ card: TarotCore.Card) {
            id = card.id
            name = card.name
            number = card.number
            suit = card.suit?.rawValue
            arcanaType = card.arcanaType.rawValue
            imageName = card.imageName
            upright = .init(card.uprightMeaning)
            reversed = .init(card.reversedMeaning)
        }

        var domain: TarotCore.Card {
            TarotCore.Card(
                id: id,
                name: name,
                number: number,
                suit: suit.flatMap { TarotCore.CardSuit(rawValue: $0) },
                arcanaType: TarotCore.ArcanaType(rawValue: arcanaType) ?? .major,
                imageName: imageName,
                uprightMeaning: upright.domain,
                reversedMeaning: reversed.domain
            )
        }
    }

    struct InterpretationDTO: Codable {
        let summary: String
        let keywords: [String]
        let contextual: [String: String]

        init(_ value: TarotCore.Interpretation) {
            summary = value.summary
            keywords = value.keywords
            contextual = Dictionary(uniqueKeysWithValues: value.contextual.map { ($0.key.rawValue, $0.value) })
        }

        var domain: TarotCore.Interpretation {
            TarotCore.Interpretation(
                cards: [],
                summary: summary,
                keywords: keywords,
                contextual: Dictionary(uniqueKeysWithValues: contextual.compactMap { key, value in
                    TarotCore.SpreadPositionType(rawValue: key).map { ($0, value) }
                })
            )
        }
    }

    struct DrawnDTO: Codable {
        let card: CardDTO
        let reversed: Bool
        let positionName: String
        let displayName: String

        init(_ value: TarotCore.DrawnCard) {
            card = .init(value.card)
            reversed = value.isReversed
            positionName = value.position.name
            displayName = value.position.displayName
        }

        var domain: TarotCore.DrawnCard {
            TarotCore.DrawnCard(
                card: card.domain,
                isReversed: reversed,
                position: TarotCore.SpreadPosition(name: positionName, displayName: displayName, layoutCoordinate: .zero)
            )
        }
    }

    let id: UUID
    let typeRaw: String?
    let createdAt: Date?
    let savedAt: Date
    let notes: String
    let synced: Bool
    let cards: [DrawnDTO]

    var type: TarotCore.SpreadType? {
        guard let typeRaw else { return nil }
        return TarotCore.SpreadType(rawValue: typeRaw)
    }

    init(_ value: JournalEntry) {
        id = value.id
        typeRaw = value.spread.type?.rawValue
        createdAt = value.spread.createdAt
        savedAt = value.savedAt
        notes = value.notes
        synced = value.isSyncedToCloud
        cards = value.spread.drawnCards.map(DrawnDTO.init)
    }

    var domain: JournalEntry {
        JournalEntry(
            id: id,
            spread: TarotCore.Spread(type: type ?? .threeCard, drawnCards: cards.map(\.domain), createdAt: createdAt ?? savedAt),
            savedAt: savedAt,
            notes: notes,
            isSyncedToCloud: synced
        )
    }

    enum CodingKeys: String, CodingKey {
        case id, createdAt, savedAt, notes, synced, cards
        case typeRaw
        case type
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        if let typeRawValue = try? container.decodeIfPresent(String.self, forKey: .typeRaw) {
            typeRaw = typeRawValue
        } else if let typeValue = try? container.decodeIfPresent(String.self, forKey: .type) {
            typeRaw = typeValue
        } else {
            typeRaw = nil
        }
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        savedAt = try container.decode(Date.self, forKey: .savedAt)
        notes = try container.decode(String.self, forKey: .notes)
        synced = try container.decode(Bool.self, forKey: .synced)
        cards = try container.decode([DrawnDTO].self, forKey: .cards)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(typeRaw, forKey: .typeRaw)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encode(savedAt, forKey: .savedAt)
        try container.encode(notes, forKey: .notes)
        try container.encode(synced, forKey: .synced)
        try container.encode(cards, forKey: .cards)
    }
}
