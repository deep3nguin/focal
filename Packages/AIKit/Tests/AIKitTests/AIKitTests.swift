import XCTest
import Domain
@testable import AIKit

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

final class AIKitTests: XCTestCase {
    func testAIServiceFactoryCreation() {
        let keyStore = MockKeyStore()
        let geminiService = AIServiceFactory.make(provider: .gemini, keyStore: keyStore)
        let openAIService = AIServiceFactory.make(provider: .openAI, keyStore: keyStore)

        XCTAssertNotNil(geminiService)
        XCTAssertNotNil(openAIService)
    }

    func testGeminiServiceMissingKeyThrowsError() async {
        let keyStore = MockKeyStore()
        let service = GeminiAIService(keyStore: keyStore)

        do {
            _ = try await service.parseBrainDump("Hello world")
            XCTFail("Should have thrown missingAPIKey")
        } catch AIServiceError.missingAPIKey {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
