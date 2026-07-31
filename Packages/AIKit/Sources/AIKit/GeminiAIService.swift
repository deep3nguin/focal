import Foundation
import Domain

public final class GeminiAIService: AIServiceProtocol, Sendable {
    private let keyStore: APIKeyStoring
    private let session: URLSession

    public init(keyStore: APIKeyStoring, session: URLSession = .shared) {
        self.keyStore = keyStore
        self.session = session
    }

    public func parseBrainDump(_ text: String) async throws -> [ParsedTaskSuggestion] {
        guard let apiKey = try keyStore.retrieve(for: .gemini), !apiKey.isEmpty else {
            throw AIServiceError.missingAPIKey
        }

        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=\(apiKey)") else {
            throw AIServiceError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let prompt = "Extract discrete tasks from this brain dump. Return a JSON array of objects with fields: title (string), suggestedStartTime (string optional), estimatedMinutes (number optional). Text: \(text)"

        let body: [String: Any] = [
            "contents": [["parts": [["text": prompt]]]],
            "generationConfig": [
                "responseMimeType": "application/json",
                "responseSchema": Self.taskListSchema
            ]
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
            let envelope = try JSONDecoder().decode(GeminiEnvelope.self, from: data)
            guard let jsonText = envelope.candidates.first?.content.parts.first?.text,
                  let jsonData = jsonText.data(using: .utf8) else {
                throw AIServiceError.invalidResponse
            }
            return try JSONDecoder().decode([ParsedTaskSuggestion].self, from: jsonData)
        } catch let e as AIServiceError {
            throw e
        } catch {
            throw AIServiceError.decoding(error.localizedDescription)
        }
    }

    private static var taskListSchema: [String: Any] {
        [
            "type": "ARRAY",
            "items": [
                "type": "OBJECT",
                "properties": [
                    "title": ["type": "STRING"],
                    "suggestedStartTime": ["type": "STRING", "nullable": true],
                    "estimatedMinutes": ["type": "INTEGER", "nullable": true]
                ],
                "required": ["title"]
            ]
        ]
    }
}

private struct GeminiEnvelope: Decodable {
    struct Candidate: Decodable {
        struct Content: Decodable {
            struct Part: Decodable {
                let text: String
            }
            let parts: [Part]
        }
        let content: Content
    }
    let candidates: [Candidate]
}
