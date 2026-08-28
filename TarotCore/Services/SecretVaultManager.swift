import Foundation
import Combine
import CryptoKit

public struct SecretVaultEntry: Identifiable, Codable, Hashable {
    public let id: UUID
    public var title: String
    public var notes: String
    public var imageFileName: String
    public let dateAdded: Date
    
    public init(id: UUID = UUID(), title: String, notes: String = "", imageFileName: String, dateAdded: Date = Date()) {
        self.id = id
        self.title = title
        self.notes = notes
        self.imageFileName = imageFileName
        self.dateAdded = dateAdded
    }
}

@MainActor
public class SecretVaultManager: ObservableObject {
    @Published public private(set) var entries: [SecretVaultEntry] = []
    @Published public private(set) var isUnlocked: Bool = false
    
    private let pinDefaultsKey = "TarotSecretVault_PIN"
    private let pinSaltKey = "TarotSecretVault_PIN_Salt"
    private let entriesDefaultsKey = "TarotSecretVault_Entries"
    
    public init() {
        loadEntries()
    }
    
    public var hasPINSet: Bool {
        UserDefaults.standard.string(forKey: pinDefaultsKey) != nil
    }
    
    private func hashPIN(_ pin: String, salt: Data) -> String {
        let pinData = pin.data(using: .utf8)!
        let combined = salt + pinData
        let hash = SHA256.hash(data: combined)
        return hash.map { String(format: "%02x", $0) }.joined()
    }
    
    public func setPIN(_ pin: String) {
        let salt = Data((0..<16).map { _ in UInt8.random(in: 0...255) })
        let hash = hashPIN(pin, salt: salt)
        UserDefaults.standard.set(salt.base64EncodedString(), forKey: pinSaltKey)
        UserDefaults.standard.set(hash, forKey: pinDefaultsKey)
        isUnlocked = true
    }
    
    public func unlock(with pin: String) -> Bool {
        guard let savedHash = UserDefaults.standard.string(forKey: pinDefaultsKey) else {
            // First time setup — no PIN at all
            setPIN(pin)
            return true
        }

        // Migration: old version stored plain PIN without salt
        guard let saltBase64 = UserDefaults.standard.string(forKey: pinSaltKey),
              let salt = Data(base64Encoded: saltBase64) else {
            // Legacy plain PIN stored; compare directly and upgrade to hashed storage if correct
            if savedHash == pin {
                // Upgrade to salted hash transparently
                let newSalt = Data((0..<16).map { _ in UInt8.random(in: 0...255) })
                let newHash = hashPIN(pin, salt: newSalt)
                UserDefaults.standard.set(newSalt.base64EncodedString(), forKey: pinSaltKey)
                UserDefaults.standard.set(newHash, forKey: pinDefaultsKey)
                isUnlocked = true
                return true
            }
            return false
        }

        let inputHash = hashPIN(pin, salt: salt)
        if savedHash == inputHash {
            isUnlocked = true
            return true
        }
        return false
    }
    
    public func lock() {
        isUnlocked = false
    }
    
    public func getVaultDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let vaultFolder = paths[0].appendingPathComponent(".SecretTarotVault", isDirectory: true)
        
        if !FileManager.default.fileExists(atPath: vaultFolder.path) {
            try? FileManager.default.createDirectory(at: vaultFolder, withIntermediateDirectories: true, attributes: nil)
        }
        return vaultFolder
    }
    
    public func savePhoto(data: Data, title: String, notes: String) -> SecretVaultEntry? {
        let fileName = "\(UUID().uuidString).jpg"
        let destinationURL = getVaultDirectory().appendingPathComponent(fileName)
        
        do {
            try data.write(to: destinationURL)
            let entry = SecretVaultEntry(title: title.isEmpty ? "Lectura Fásica \(Date().formatted(date: .numeric, time: .shortened))" : title, notes: notes, imageFileName: fileName)
            entries.insert(entry, at: 0)
            saveEntries()
            return entry
        } catch {
            print("Error saving vault photo: \(error)")
            return nil
        }
    }
    
    public func deleteEntry(_ entry: SecretVaultEntry) {
        entries.removeAll { $0.id == entry.id }
        let fileURL = getVaultDirectory().appendingPathComponent(entry.imageFileName)
        try? FileManager.default.removeItem(at: fileURL)
        saveEntries()
    }
    
    public func getImageURL(for entry: SecretVaultEntry) -> URL {
        return getVaultDirectory().appendingPathComponent(entry.imageFileName)
    }
    
    private func loadEntries() {
        if let data = UserDefaults.standard.data(forKey: entriesDefaultsKey),
           let decoded = try? JSONDecoder().decode([SecretVaultEntry].self, from: data) {
            self.entries = decoded
        }
    }
    
    private func saveEntries() {
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: entriesDefaultsKey)
        }
    }
}
