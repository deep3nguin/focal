import Foundation

public enum AIProvider: String, Codable, Sendable, CaseIterable, Identifiable {
    case gemini
    case openAI

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .gemini:
            return "Google Gemini"
        case .openAI:
            return "OpenAI"
        }
    }
}
