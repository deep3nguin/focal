import Foundation

public struct ParsedTaskSuggestion: Codable, Sendable, Identifiable, Equatable {
    public let id: UUID
    public let title: String
    public let suggestedStartTime: String?
    public let estimatedMinutes: Int?

    public init(
        id: UUID = UUID(),
        title: String,
        suggestedStartTime: String? = nil,
        estimatedMinutes: Int? = nil
    ) {
        self.id = id
        self.title = title
        self.suggestedStartTime = suggestedStartTime
        self.estimatedMinutes = estimatedMinutes
    }

    private enum CodingKeys: String, CodingKey {
        case title
        case suggestedStartTime
        case estimatedMinutes
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.title = try container.decode(String.self, forKey: .title)
        self.suggestedStartTime = try container.decodeIfPresent(String.self, forKey: .suggestedStartTime)
        self.estimatedMinutes = try container.decodeIfPresent(Int.self, forKey: .estimatedMinutes)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(title, forKey: .title)
        try container.encodeIfPresent(suggestedStartTime, forKey: .suggestedStartTime)
        try container.encodeIfPresent(estimatedMinutes, forKey: .estimatedMinutes)
    }
}
