import SwiftData
import Foundation

public enum FocalSchemaV1: VersionedSchema {
    public static let versionIdentifier = Schema.Version(1, 0, 0)
    public static var models: [any PersistentModel.Type] {
        [DailyPlan.self, TimeBlock.self, TaskItem.self, BrainDumpEntry.self]
    }
}

@Model
public final class DailyPlan {
    @Attribute(.unique) public var dayIdentifier: String
    public var date: Date

    @Relationship(deleteRule: .cascade, inverse: \TimeBlock.plan)
    public var timeBlocks: [TimeBlock] = []

    public init(date: Date) {
        self.date = Calendar.current.startOfDay(for: date)
        self.dayIdentifier = Self.identifier(for: date)
    }

    public static func identifier(for date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = .current
        return f.string(from: date)
    }
}

@Model
public final class TimeBlock {
    public var title: String
    public var startTime: Date
    public var endTime: Date
    public var colorHex: String
    public var icon: String
    public var isCompleted: Bool = false
    public var sortOrder: Int = 0

    public var plan: DailyPlan?

    @Relationship(deleteRule: .cascade, inverse: \TaskItem.timeBlock)
    public var tasks: [TaskItem] = []

    public init(
        title: String,
        startTime: Date,
        endTime: Date,
        colorHex: String = "#6366F1",
        icon: String = "clock.fill"
    ) {
        self.title = title
        self.startTime = startTime
        self.endTime = endTime
        self.colorHex = colorHex
        self.icon = icon
    }
}

@Model
public final class TaskItem {
    public var title: String
    public var isDone: Bool = false
    public var notes: String?
    public var sortOrder: Int = 0

    public var timeBlock: TimeBlock?

    public init(title: String, notes: String? = nil) {
        self.title = title
        self.notes = notes
    }
}

@Model
public final class BrainDumpEntry {
    @Attribute(.unique) public var id: UUID
    public var text: String
    public var createdAt: Date
    public var isProcessed: Bool = false

    public init(text: String) {
        self.id = UUID()
        self.text = text
        self.createdAt = .now
    }
}
