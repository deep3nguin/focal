import Foundation
import Domain

public enum AIServiceFactory {
    public static func make(provider: AIProvider, keyStore: APIKeyStoring) -> AIServiceProtocol {
        switch provider {
        case .gemini:
            return GeminiAIService(keyStore: keyStore)
        case .openAI:
            return OpenAIAIService(keyStore: keyStore)
        }
    }
}
