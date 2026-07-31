import XCTest
@testable import Domain

final class MockAIService: AIServiceProtocol {
    var stubbedSuggestions: [ParsedTaskSuggestion] = []
    var shouldFail: Bool = false

    func parseBrainDump(_ text: String) async throws -> [ParsedTaskSuggestion] {
        if shouldFail {
            throw AIServiceError.invalidResponse
        }
        return stubbedSuggestions
    }
}

final class DomainTests: XCTestCase {
    func testParseBrainDumpEmptyTextReturnsEmpty() async throws {
        let mockService = MockAIService()
        let useCase = ParseBrainDumpUseCase(aiService: mockService)

        let result = try await useCase.execute("   ")
        XCTAssertTrue(result.isEmpty)
    }

    func testParseBrainDumpReturnsSuggestions() async throws {
        let mockService = MockAIService()
        mockService.stubbedSuggestions = [
            ParsedTaskSuggestion(title: "Task 1", estimatedMinutes: 15),
            ParsedTaskSuggestion(title: "Task 2", estimatedMinutes: 30)
        ]
        let useCase = ParseBrainDumpUseCase(aiService: mockService)

        let result = try await useCase.execute("Do task 1 and task 2")
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0].title, "Task 1")
        XCTAssertEqual(result[1].title, "Task 2")
    }
}
