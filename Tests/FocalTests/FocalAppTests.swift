import XCTest
import Domain
import Data
import AIKit
import TimerKit
import Presentation
@testable import FocalAppLib

final class FocalAppTests: XCTestCase {
    @MainActor
    func testAppDependencyContainerInitialization() {
        let container = AppDependencyContainer()
        XCTAssertNotNil(container.keyStore)

        let aiService = container.makeAIService()
        XCTAssertNotNil(aiService)

        let timelineVM = container.makeTimelineViewModel()
        XCTAssertNotNil(timelineVM)

        let brainDumpVM = container.makeBrainDumpViewModel()
        XCTAssertNotNil(brainDumpVM)

        let timerVM = container.makeFocusTimerViewModel()
        XCTAssertNotNil(timerVM)

        let settingsVM = container.makeSettingsViewModel()
        XCTAssertNotNil(settingsVM)
    }
}
