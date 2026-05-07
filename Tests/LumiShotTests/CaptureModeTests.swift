import XCTest
@testable import LumiShotKit

final class CaptureModeTests: XCTestCase {
    func testAllPrimaryModesAvailable() {
        XCTAssertEqual(CaptureMode.allCases, [.region, .window, .fullScreen, .scrolling])
    }
}
