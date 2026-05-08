import CoreGraphics
import XCTest
@testable import LumiShotKit

final class CaptureDefaultRegionResolverTests: XCTestCase {
    func testPrefersFrontMostWindowUnderPointer() {
        let windows = [
            CaptureWindowSnapshot(frame: CGRect(x: 90, y: 90, width: 300, height: 200), ownerPID: 200, layer: 0, alpha: 1),
            CaptureWindowSnapshot(frame: CGRect(x: 80, y: 80, width: 600, height: 400), ownerPID: 300, layer: 0, alpha: 1)
        ]
        let result = CaptureDefaultRegionResolver.resolve(
            pointer: CGPoint(x: 120, y: 120),
            windows: windows,
            screens: [CGRect(x: 0, y: 0, width: 1440, height: 900)],
            excludedOwnerPID: 999
        )
        XCTAssertEqual(result, windows[0].frame.standardized)
    }

    func testSkipsOwnProcessWindowsAndFallsThrough() {
        let windows = [
            CaptureWindowSnapshot(frame: CGRect(x: 100, y: 100, width: 200, height: 150), ownerPID: 111, layer: 0, alpha: 1),
            CaptureWindowSnapshot(frame: CGRect(x: 90, y: 90, width: 300, height: 200), ownerPID: 222, layer: 0, alpha: 1)
        ]
        let result = CaptureDefaultRegionResolver.resolve(
            pointer: CGPoint(x: 120, y: 120),
            windows: windows,
            screens: [CGRect(x: 0, y: 0, width: 1280, height: 800)],
            excludedOwnerPID: 111
        )
        XCTAssertEqual(result, windows[1].frame.standardized)
    }

    func testFallsBackToContainingScreenWhenNoWindowMatches() {
        let screens = [
            CGRect(x: 0, y: 0, width: 1440, height: 900),
            CGRect(x: 1440, y: 0, width: 1440, height: 900)
        ]
        let result = CaptureDefaultRegionResolver.resolve(
            pointer: CGPoint(x: 1600, y: 300),
            windows: [],
            screens: screens,
            excludedOwnerPID: 999
        )
        XCTAssertEqual(result, screens[1].standardized)
    }

    func testPrefersFrontmostOwnerWindowWhenPointerOverlapping() {
        let windows = [
            CaptureWindowSnapshot(frame: CGRect(x: 100, y: 100, width: 300, height: 240), ownerPID: 333, layer: 0, alpha: 1),
            CaptureWindowSnapshot(frame: CGRect(x: 120, y: 120, width: 280, height: 220), ownerPID: 444, layer: 0, alpha: 1)
        ]
        let result = CaptureDefaultRegionResolver.resolve(
            pointer: CGPoint(x: 150, y: 150),
            windows: windows,
            screens: [CGRect(x: 0, y: 0, width: 1440, height: 900)],
            excludedOwnerPID: 999,
            frontmostOwnerPID: 444
        )
        XCTAssertEqual(result, windows[1].frame.standardized)
    }
}
