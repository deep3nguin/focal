import Security
import Foundation
import Domain

public final class KeychainService: APIKeyStoring, @unchecked Sendable {
    private let service: String

    public init(service: String = "com.focal.apikeys") {
        self.service = service
    }

    public func save(_ key: String, for provider: AIProvider) throws {
        guard let data = key.data(using: .utf8) else {
            throw KeychainError.encodingFailed
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: provider.rawValue
        ]
        SecItemDelete(query as CFDictionary)

        var attributes = query
        attributes[kSecValueData as String] = data
        attributes[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly

        let status = SecItemAdd(attributes as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.unhandledStatus(status)
        }
    }

    public func retrieve(for provider: AIProvider) throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: provider.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess, let data = result as? Data else {
            throw KeychainError.unhandledStatus(status)
        }
        guard let secret = String(data: data, encoding: .utf8) else {
            throw KeychainError.decodingFailed
        }
        return secret
    }

    public func delete(for provider: AIProvider) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: provider.rawValue
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unhandledStatus(status)
        }
    }
}

public final class InMemoryKeyStore: APIKeyStoring, @unchecked Sendable {
    private var storage: [AIProvider: String] = [:]
    private let lock = NSLock()

    public init() {}

    public func save(_ key: String, for provider: AIProvider) throws {
        lock.lock()
        defer { lock.unlock() }
        storage[provider] = key
    }

    public func retrieve(for provider: AIProvider) throws -> String? {
        lock.lock()
        defer { lock.unlock() }
        return storage[provider]
    }

    public func delete(for provider: AIProvider) throws {
        lock.lock()
        defer { lock.unlock() }
        storage.removeValue(forKey: provider)
    }
}
