import Foundation
import Security

/// A helper class to interact with the macOS Keychain for secure data storage.
class KeychainHelper {

    static let standard = KeychainHelper()
    // A unique identifier for your app's keychain items.
    // It's a good practice to make this specific to your app bundle identifier.
    private let service = "com.jules.tasker.credentials"

    private init() {}

    /// Saves a string value to the Keychain.
    /// - Parameters:
    ///   - value: The string to save.
    ///   - account: A unique key (account name) to identify this item.
    func save(_ value: String, for account: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.invalidData
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        // First, try to update an existing item
        let attributes: [String: Any] = [kSecValueData as String: data]
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)

        // If the item doesn't exist, add it
        if status == errSecItemNotFound {
            var newItemQuery = query
            newItemQuery[kSecValueData as String] = data
            let addStatus = SecItemAdd(newItemQuery as CFDictionary, nil)
            guard addStatus == errSecSuccess else {
                throw KeychainError.unhandledError(status: addStatus)
            }
        } else if status != errSecSuccess {
            throw KeychainError.unhandledError(status: status)
        }
    }

    /// Loads a string value from the Keychain.
    /// - Parameter account: The unique key (account name) used to save the item.
    /// - Returns: The string value, or `nil` if not found.
    func load(for account: String) throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        if status == errSecItemNotFound {
            return nil // Item not found, which is a valid case
        }
        guard status == errSecSuccess else {
            throw KeychainError.unhandledError(status: status)
        }
        guard let data = item as? Data else {
            throw KeychainError.unexpectedData
        }

        return String(data: data, encoding: .utf8)
    }

    /// Deletes an item from the Keychain.
    /// - Parameter account: The unique key (account name) of the item to delete.
    func delete(for account: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unhandledError(status: status)
        }
    }
}

/// Custom errors for Keychain operations.
enum KeychainError: Error {
    case unhandledError(status: OSStatus)
    case unexpectedData
    case invalidData
}