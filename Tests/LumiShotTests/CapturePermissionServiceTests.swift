import XCTest
@testable import LumiShotKit

final class CapturePermissionServiceTests: XCTestCase {
    func testDeniedPermissionMapsToDeniedState() {
        let sut = CapturePermissionService(checker: { .denied })
        XCTAssertEqual(sut.currentState(), .denied)
    }

    func testNotDeterminedStateIsSupported() {
        let sut = CapturePermissionService(checker: { .notDetermined })
        XCTAssertEqual(sut.currentState(), .notDetermined)
    }
}
