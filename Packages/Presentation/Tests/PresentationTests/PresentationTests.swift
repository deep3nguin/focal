import XCTest
import Domain
@testable import Presentation

final class MockAIService: AIServiceProtocol {
    var stubbedSuggestions: [ParsedTaskSuggestion] = []

    func parseBrainDump(_ text: String) async throws -> [ParsedTaskSuggestion] {
        stubbedSuggestions
    }
}

final class MockKeyStore: APIKeyStoring, @unchecked Sendable {
    var keys: [AIProvider: String] = [:]

    func save(_ key: String, for provider: AIProvider) throws {
        keys[provider] = key
    }

    func retrieve(for provider: AIProvider) throws -> String? {
        keys[provider]
    }

    func delete(for provider: AIProvider) throws {
        keys.removeValue(forKey: provider)
    }
}

final class PresentationTests: XCTestCase {
    @MainActor
    func testBrainDumpViewModelParseSuccess() async throws {
        let mockService = MockAIService()
        mockService.stubbedSuggestions = [ParsedTaskSuggestion(title: "Parsed Task 1")]

        let viewModel = BrainDumpViewModel(aiService: mockService)
        viewModel.rawText = "Finish reporting"

        await viewModel.parseBrainDump()

        XCTAssertEqual(viewModel.suggestions.count, 1)
        XCTAssertEqual(viewModel.suggestions.first?.title, "Parsed Task 1")
    }

    @MainActor
    func testSettingsViewModelSaveKeys() throws {
        let mockKeyStore = MockKeyStore()
        let viewModel = SettingsViewModel(keyStore: mockKeyStore)

        viewModel.geminiAPIKey = "gemini-secret-123"
        viewModel.saveKeys()

        let savedKey = try mockKeyStore.retrieve(for: .gemini)
        XCTAssertEqual(savedKey, "gemini-secret-123")
    }

    @MainActor
    func testTimelineViewModelToggleCompletion() {
        let viewModel = TimelineViewModel()
        guard let firstBlockID = viewModel.blocks.first?.id else {
            XCTFail("No initial blocks")
            return
        }

        let initialStatus = viewModel.blocks.first?.isCompleted ?? false
        viewModel.toggleCompletion(for: firstBlockID)

        XCTAssertEqual(viewModel.blocks.first?.isCompleted, !initialStatus)
    }
}
