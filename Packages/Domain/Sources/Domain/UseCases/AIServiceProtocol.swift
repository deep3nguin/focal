import Foundation

public enum AIServiceError: Error, Sendable {
    case missingAPIKey
    case invalidResponse
    case rateLimited
    case network(String)
    case decoding(String)
}

public protocol AIServiceProtocol: Sendable {
    func parseBrainDump(_ text: String) async throws -> [ParsedTaskSuggestion]
}
