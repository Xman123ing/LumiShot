import XCTest
@testable import LumiShot

final class StyleTokensTests: XCTestCase {
    func testSidebarWidthIsStable() {
        XCTAssertEqual(StyleTokens.sidebarWidth, 240)
    }
}
