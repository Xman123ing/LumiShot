import XCTest
@testable import LumiShot

final class CaptureModeTests: XCTestCase {
    func testAllPrimaryModesAvailable() {
        XCTAssertEqual(CaptureMode.allCases, [.region, .window, .fullScreen, .scrolling])
    }
}
