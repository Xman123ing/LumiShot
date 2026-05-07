import XCTest
@testable import LumiShotKit

final class CapturePermissionServiceTests: XCTestCase {
    override func setUp() {
        super.setUp()
        CapturePermissionService.resetSessionGrantForTesting()
    }

    override func tearDown() {
        CapturePermissionService.resetSessionGrantForTesting()
        super.tearDown()
    }

    func testDeniedPermissionMapsToDeniedState() {
        let sut = CapturePermissionService(checker: { .denied })
        XCTAssertEqual(sut.currentState(), .denied)
    }

    func testNotDeterminedStateIsSupported() {
        let sut = CapturePermissionService(checker: { .notDetermined })
        XCTAssertEqual(sut.currentState(), .notDetermined)
    }

    func testSessionGrantIsRememberedAfterRequestAccess() {
        let sut = CapturePermissionService(
            checker: { .notDetermined },
            requester: { true }
        )

        XCTAssertEqual(sut.currentState(), .notDetermined)
        XCTAssertTrue(sut.requestAccess())
        XCTAssertEqual(sut.currentState(), .granted)
    }
}
