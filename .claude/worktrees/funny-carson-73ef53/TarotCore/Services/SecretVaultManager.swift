import Foundation
import Combine
import CryptoKit
import LocalAuthentication

public enum VaultMediaType: String, Codable {
    case photo, video, audio
}

public struct SecretVaultEntry: Identifiable, Codable, Hashable {
    public let id: UUID
    public var title: String
    public var notes: String
    public var imageFileName: String // generic fileName (photo jpg, video mov, audio m4a)
    public var mediaType: VaultMediaType
    public let dateAdded: Date
    public var duration: Double? // audio/video seconds
    
    public init(id: UUID = UUID(), title: String, notes: String = "", imageFileName: String, mediaType: VaultMediaType = .photo, dateAdded: Date = Date(), duration: Double? = nil) {
        self.id = id
        self.title = title
        self.notes = notes
        self.imageFileName = imageFileName
        self.mediaType = mediaType
        self.dateAdded = dateAdded
        self.duration = duration
    }

    // Backward compat: decode old entries without mediaType as .photo
    enum CodingKeys: String, CodingKey { case id, title, notes, imageFileName, mediaType, dateAdded, duration }
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        title = try c.decode(String.self, forKey: .title)
        notes = try c.decode(String.self, forKey: .notes)
        imageFileName = try c.decode(String.self, forKey: .imageFileName)
        mediaType = try c.decodeIfPresent(VaultMediaType.self, forKey: .mediaType) ?? .photo
        dateAdded = try c.decode(Date.self, forKey: .dateAdded)
        duration = try c.decodeIfPresent(Double.self, forKey: .duration)
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

    public var biometricEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "TarotSecretVault_BiometricEnabled") }
        set { UserDefaults.standard.set(newValue, forKey: "TarotSecretVault_BiometricEnabled") }
    }

    public var biometricTypeName: String {
        let ctx = LAContext()
        _ = ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        switch ctx.biometryType {
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        default: return "Biometría"
        }
    }

    public func canUseBiometrics() -> Bool {
        let ctx = LAContext()
        var err: NSError?
        return ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &err)
    }

    public func authenticateWithBiometrics() async -> Bool {
        guard biometricEnabled, canUseBiometrics() else { return false }
        let ctx = LAContext()
        do {
            let ok = try await ctx.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Desbloquear Bóveda Secreta")
            if ok { isUnlocked = true }
            return ok
        } catch { return false }
    }

    public func changePIN(oldPIN: String, newPIN: String) -> Bool {
        guard unlock(with: oldPIN) else { return false }
        setPIN(newPIN)
        return true
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
            let entry = SecretVaultEntry(title: title.isEmpty ? "Lectura \(Date().formatted(date: .numeric, time: .shortened))" : title, notes: notes, imageFileName: fileName, mediaType: .photo)
            entries.insert(entry, at: 0)
            saveEntries()
            return entry
        } catch {
            print("Error saving vault photo: \(error)")
            return nil
        }
    }

    public func saveVideo(from sourceURL: URL, title: String, notes: String) -> SecretVaultEntry? {
        let fileName = "\(UUID().uuidString).mov"
        let dest = getVaultDirectory().appendingPathComponent(fileName)
        do {
            if FileManager.default.fileExists(atPath: dest.path) { try FileManager.default.removeItem(at: dest) }
            try FileManager.default.copyItem(at: sourceURL, to: dest)
            let entry = SecretVaultEntry(title: title.isEmpty ? "Video \(Date().formatted(date: .numeric, time: .shortened))" : title, notes: notes, imageFileName: fileName, mediaType: .video)
            entries.insert(entry, at: 0)
            saveEntries()
            return entry
        } catch {
            print("Error saving vault video: \(error)")
            return nil
        }
    }

    public func saveAudio(data: Data, title: String, notes: String, duration: Double? = nil) -> SecretVaultEntry? {
        let fileName = "\(UUID().uuidString).m4a"
        let dest = getVaultDirectory().appendingPathComponent(fileName)
        do {
            try data.write(to: dest)
            let entry = SecretVaultEntry(title: title.isEmpty ? "Audio \(Date().formatted(date: .numeric, time: .shortened))" : title, notes: notes, imageFileName: fileName, mediaType: .audio, duration: duration)
            entries.insert(entry, at: 0)
            saveEntries()
            return entry
        } catch {
            print("Error saving vault audio: \(error)")
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
