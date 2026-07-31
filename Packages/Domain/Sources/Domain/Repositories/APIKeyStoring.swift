import Foundation

public enum KeychainError: Error, Sendable, Equatable {
    case unhandledStatus(Int32)
    case encodingFailed
    case decodingFailed
}

public protocol APIKeyStoring: Sendable {
    func save(_ key: String, for provider: AIProvider) throws
    func retrieve(for provider: AIProvider) throws -> String?
    func delete(for provider: AIProvider) throws
}
