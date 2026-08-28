import Foundation
import Security

public protocol KeychainServiceProtocol {
    func read(_ key: String) -> String?
    func write(_ value: String, for key: String) -> Bool
    func delete(_ key: String) -> Bool
}

public class KeychainService: KeychainServiceProtocol {
    public init() {}

    public func read(_ key: String) -> String? {
        var query = baseQuery(for: key)
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        query[kSecReturnData as String] = kCFBooleanTrue

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        guard status == errSecSuccess,
              let data = item as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }
        return value
    }

    public func write(_ value: String, for key: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }

        var query = baseQuery(for: key)
        query[kSecValueData as String] = data

        let status = SecItemAdd(query as CFDictionary, nil)

        if status == errSecDuplicateItem {
            return update(value, for: key)
        }
        return status == errSecSuccess
    }

    public func delete(_ key: String) -> Bool {
        let query = baseQuery(for: key)
        return SecItemDelete(query as CFDictionary) == errSecSuccess
    }

    private func baseQuery(for key: String) -> [String: Any] {
        return [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.gvstii.tarotapp",
            kSecAttrAccount as String: key
        ]
    }

    private func update(_ value: String, for key: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }
        let query = baseQuery(for: key)
        let attributes: [String: Any] = [kSecValueData as String: data]
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        return status == errSecSuccess
    }
}
