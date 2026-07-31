import Foundation

public struct ParseBrainDumpUseCase: Sendable {
    private let aiService: AIServiceProtocol

    public init(aiService: AIServiceProtocol) {
        self.aiService = aiService
    }

    public func execute(_ text: String) async throws -> [ParsedTaskSuggestion] {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        return try await aiService.parseBrainDump(trimmed)
    }
}
