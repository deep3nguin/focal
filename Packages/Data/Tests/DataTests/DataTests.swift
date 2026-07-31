import XCTest
import SwiftData
import Domain
@testable import Data

final class DataTests: XCTestCase {
    func testInMemoryKeyStoreSaveAndRetrieve() throws {
        let store = InMemoryKeyStore()
        try store.save("test-key-123", for: .gemini)

        let retrieved = try store.retrieve(for: .gemini)
        XCTAssertEqual(retrieved, "test-key-123")

        try store.delete(for: .gemini)
        XCTAssertNil(try store.retrieve(for: .gemini))
    }

    @MainActor
    func testSwiftDataSchemaV1Persistence() throws {
        let container = SwiftDataStack.inMemoryContainer
        let context = container.mainContext

        let plan = DailyPlan(date: Date())
        let timeBlock = TimeBlock(title: "Morning Routine", startTime: Date(), endTime: Date().addingTimeInterval(1800))
        let task = TaskItem(title: "Drink Water")

        timeBlock.tasks.append(task)
        plan.timeBlocks.append(timeBlock)
        context.insert(plan)

        try context.save()

        let fetchDescriptor = FetchDescriptor<DailyPlan>()
        let plans = try context.fetch(fetchDescriptor)

        XCTAssertEqual(plans.count, 1)
        XCTAssertEqual(plans.first?.timeBlocks.count, 1)
        XCTAssertEqual(plans.first?.timeBlocks.first?.tasks.count, 1)
        XCTAssertEqual(plans.first?.timeBlocks.first?.tasks.first?.title, "Drink Water")
    }
}
