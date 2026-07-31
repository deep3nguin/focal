import XCTest
import SwiftUI
@testable import DesignSystem

final class DesignSystemTests: XCTestCase {
    func testColorsInitialization() {
        XCTAssertNotNil(FocalColors.backgroundDark)
        XCTAssertNotNil(FocalColors.primaryAccent)
        XCTAssertNotNil(FocalColors.secondaryAccent)
    }
}
