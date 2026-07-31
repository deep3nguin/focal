import XCTest
@testable import TimerKit

final class TimerKitTests: XCTestCase {
    func testTimerEngineStartAndPause() async throws {
        let expectation = XCTestExpectation(description: "Tick expectation")
        expectation.assertForOverFulfill = false

        let engine = FocusTimerEngine(duration: 10, onTick: { remaining in
            if remaining == 9 {
                expectation.fulfill()
            }
        })

        var isRunning = await engine.isRunning
        XCTAssertFalse(isRunning)

        await engine.start()
        isRunning = await engine.isRunning
        XCTAssertTrue(isRunning)

        await fulfillment(of: [expectation], timeout: 3.0)

        await engine.pause()
        isRunning = await engine.isRunning
        XCTAssertFalse(isRunning)
    }

    func testTimerEngineReset() async throws {
        let engine = FocusTimerEngine(duration: 10, onTick: { _ in })
        await engine.start()
        await engine.reset(to: 20)

        let remaining = await engine.remainingSeconds
        let isRunning = await engine.isRunning

        XCTAssertEqual(remaining, 20)
        XCTAssertFalse(isRunning)
    }
}
