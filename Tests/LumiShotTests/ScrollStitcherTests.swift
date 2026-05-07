import XCTest
@testable import LumiShotKit

final class ScrollStitcherTests: XCTestCase {
    func testStitchReturnsSequenceFallbackWhenOverlapLow() {
        let sut = ScrollStitcher(minimumOverlapScore: 0.80)
        let result = sut.stitch(frames: [.mock(score: 0.35), .mock(score: 0.30)])
        XCTAssertEqual(result, .fallbackSequence)
    }
}
