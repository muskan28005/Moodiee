import Foundation
import Security

final class KeychainHelper {
    static let standard = KeychainHelper()

    func save<T: Codable>(_ value: T, forKey key: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]

        SecItemDelete(query as CFDictionary)

        let attributes: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]

        SecItemAdd(attributes as CFDictionary, nil)
    }

    func read<T: Codable>(forKey key: String) -> T? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var dataTypeRef: AnyObject?

        if SecItemCopyMatching(query as CFDictionary, &dataTypeRef) == noErr,
           let data = dataTypeRef as? Data,
           let decoded = try? JSONDecoder().decode(T.self, from: data) {
            return decoded
        }

        return nil
    }
}
