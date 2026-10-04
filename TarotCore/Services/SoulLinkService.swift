import Foundation

/// Service that manages "Soul Linking" between users, calculating spiritual resonance based on their destiny patterns.
public final class SoulLinkService: ObservableObject {
    @Published public private(set) var activeLinks: [SoulLink] = []

    private let settings: SettingsRepository
    private let patternsService: PatternRecognitionServiceProtocol

    public init(settings: SettingsRepository, patternsService: PatternRecognitionServiceProtocol) {
        self.settings = settings
        self.patternsService = patternsService
        loadLinks()
    }

    /// Links the current user with another user via a unique Soul ID.
    public func linkSoul(partnerID: String, partnerName: String, partnerPatterns: [String]) async throws {
        // Calculate resonance based on common spiritual themes/patterns
        let myPatterns = try await patternsService.identifyRecurringThemes(limit: 5)
        let score = calculateResonance(my: myPatterns, partner: partnerPatterns)

        let newLink = SoulLink(
            partnerID: partnerID,
            partnerName: partnerName,
            linkedAt: .now,
            resonanceScore: score
        )

        activeLinks.append(newLink)
        saveLinks()
    }

    private func calculateResonance(my: [String], partner: [String]) -> Double {
        guard !my.isEmpty && !partner.isEmpty else { return 0.5 }

        let commonThemes = Set(my).intersection(Set(partner))
        let totalUniqueThemes = Set(my).union(Set(partner)).count

        // Jaccard similarity as a baseline for resonance
        let similarity = Double(commonThemes.count) / Double(totalUniqueThemes)

        // Add a small organic variance to make it feel "spiritual" and not purely mathematical
        let variance = Double.random(in: -0.05...0.05)
        return max(0.0, min(1.0, similarity + variance))
    }


    // MARK: - Local linking (nombre + fecha opcional)

    /// Vincula un alma localmente. La resonancia se deriva de forma determinista
    /// (nombres + fecha) para que sea estable entre sesiones.
    @discardableResult
    public func addLink(partnerName: String, birthDate: Date? = nil) -> SoulLink {
        let clean = partnerName.trimmingCharacters(in: .whitespacesAndNewlines)
        let name = clean.isEmpty ? "Alma" : clean
        let score = Self.resonance(owner: ownerName, partner: name, birthDate: birthDate, salt: 0)
        let link = SoulLink(
            partnerID: UUID().uuidString,
            partnerName: name,
            resonanceScore: score
        )
        activeLinks.append(link)
        saveLinks()
        return link
    }

    /// Recalcula la resonancia con una deriva determinista por día.
    @discardableResult
    public func synchronize(_ link: SoulLink) -> SoulLink {
        guard let index = activeLinks.firstIndex(where: { $0.id == link.id }) else { return link }
        let day = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let score = Self.resonance(owner: ownerName, partner: link.partnerName, birthDate: nil, salt: day)
        let updated = SoulLink(
            id: link.id,
            partnerID: link.partnerID,
            partnerName: link.partnerName,
            linkedAt: link.linkedAt,
            resonanceScore: score
        )
        activeLinks[index] = updated
        saveLinks()
        return updated
    }

    /// Descripción legible del nivel de resonancia.
    public func description(for score: Double) -> String {
        if score > 0.9 { return "excepcional y trascendente" }
        if score > 0.7 { return "profunda y armónica" }
        if score > 0.5 { return "estándar y en crecimiento" }
        return "compleja y en proceso de aprendizaje"
    }

    private var ownerName: String { "Tú" }

    static func resonance(owner: String, partner: String, birthDate: Date?, salt: Int) -> Double {
        var seed = 7
        for scalar in ([owner, partner].sorted().joined(separator: "·")).unicodeScalars {
            seed = (seed &* 31 &+ Int(scalar.value)) % 1_000_000
        }
        if let birthDate {
            let c = Calendar.current.dateComponents([.year, .month, .day], from: birthDate)
            seed = (seed &* 31 &+ (c.year ?? 0) &+ (c.month ?? 0) * 13 &+ (c.day ?? 0) * 7) % 1_000_000
        }
        seed = (seed &* 31 &+ salt * 17) % 1_000_000
        let frac = Double(seed % 1000) / 1000.0
        return min(0.99, max(0.35, 0.35 + frac * 0.64))
    }

    /// Hash estable para variar las lecturas sin aleatoriedad.
    public static func stableHash(_ text: String) -> Int {
        var seed = 7
        for scalar in text.lowercased().unicodeScalars { seed = (seed &* 31 &+ Int(scalar.value)) % 1_000_000 }
        return seed
    }

    public func unlinkSoul(partnerID: String) {
        activeLinks.removeAll { $0.partnerID == partnerID }
        saveLinks()
    }

    private func saveLinks() {
        if let encoded = try? JSONEncoder().encode(activeLinks) {
            settings.saveValue(encoded, forKey: "soul_links")
        }
    }

    private func loadLinks() {
        if let data = settings.loadValue(forKey: "soul_links") as? Data,
           let decoded = try? JSONDecoder().decode([SoulLink].self, from: data) {
            activeLinks = decoded
        }
    }
}
