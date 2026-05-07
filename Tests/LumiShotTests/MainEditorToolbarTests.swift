import XCTest
@testable import LumiShotKit

final class MainEditorToolbarTests: XCTestCase {
    func testAdvancedToolsAreInMoreGroup() {
        XCTAssertTrue(ToolbarTool.moreTools.contains(.floatingPin))
        XCTAssertTrue(ToolbarTool.moreTools.contains(.backdrop))
    }

    func testPrimaryAndMoreToolsCoverAllCases() {
        let primary = ToolbarTool.primaryTools
        let more = ToolbarTool.moreTools
        let combined = Set(primary).union(Set(more))
        XCTAssertEqual(
            combined,
            Set(ToolbarTool.allCases),
            "primary + more must list every ToolbarTool exactly once overall (no omissions)"
        )
        XCTAssertEqual(primary.count + more.count, ToolbarTool.allCases.count, "no duplicate tools across primary and more")
    }

    func testPrimaryAndMoreToolGroupsAreDisjoint() {
        let overlap = Set(ToolbarTool.primaryTools).intersection(Set(ToolbarTool.moreTools))
        XCTAssertTrue(
            overlap.isEmpty,
            "primary and more must not share tools; overlap: \(overlap)"
        )
    }

    func testPrimaryAndMoreToolOrdering() {
        XCTAssertEqual(ToolbarTool.primaryTools, [.rectangle, .arrow, .text, .counter])
        XCTAssertEqual(ToolbarTool.moreTools, [.floatingPin, .backdrop])
    }
}
