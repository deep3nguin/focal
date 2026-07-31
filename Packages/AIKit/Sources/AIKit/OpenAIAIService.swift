import Foundation
import Domain

public final class OpenAIAIService: AIServiceProtocol, Sendable {
    private let keyStore: APIKeyStoring
    private let session: URLSession

    public init(keyStore: APIKeyStoring, session: URLSession = .shared) {
        self.keyStore = keyStore
        self.session = session
    }

    public func parseBrainDump(_ text: String) async throws -> [ParsedTaskSuggestion] {
        guard let apiKey = try keyStore.retrieve(for: .openAI), !apiKey.isEmpty else {
            throw AIServiceError.missingAPIKey
        }

        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            throw AIServiceError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let prompt = "Extract discrete tasks from this brain dump. Return ONLY a JSON object with key 'tasks', which is an array of items with title (string), suggestedStartTime (string optional), estimatedMinutes (number optional). Text: \(text)"

        let body: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": [
                ["role": "system", "content": "You are a daily planning assistant that extracts structured tasks."],
                ["role": "user", "content": prompt]
            ],
            "response_format": ["type": "json_object"]
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            throw AIServiceError.network(error.localizedDescription)
        }

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw AIServiceError.network(error.localizedDescription)
        }

        guard let http = response as? HTTPURLResponse else {
            throw AIServiceError.invalidResponse
        }

        if http.statusCode == 429 {
            throw AIServiceError.rateLimited
        }
        guard (200...299).contains(http.statusCode) else {
            throw AIServiceError.invalidResponse
        }

        do {
            let envelope = try JSONDecoder().decode(OpenAIEnvelope.self, from: data)
            guard let contentText = envelope.choices.first?.message.content,
                  let jsonData = contentText.data(using: .utf8) else {
                throw AIServiceError.invalidResponse
            }
            let taskContainer = try JSONDecoder().decode(OpenAITaskContainer.self, from: jsonData)
            return taskContainer.tasks
        } catch let e as AIServiceError {
            throw e
        } catch {
            throw AIServiceError.decoding(error.localizedDescription)
        }
    }
}

private struct OpenAIEnvelope: Decodable {
    struct Choice: Decodable {
        struct Message: Decodable {
            let content: String
        }
        let message: Message
    }
    let choices: [Choice]
}

private struct OpenAITaskContainer: Decodable {
    let tasks: [ParsedTaskSuggestion]
}
