import XCTest
@testable import LumiShotKit

final class StyleTokensTests: XCTestCase {
    func testSidebarWidthIsStable() {
        XCTAssertEqual(StyleTokens.sidebarWidth, 240)
    }
}
