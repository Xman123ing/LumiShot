import XCTest
@testable import LumiShot

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
