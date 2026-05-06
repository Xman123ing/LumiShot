import XCTest
@testable import LumiShot

final class AnnotationStoreTests: XCTestCase {
    func testNumberToolAutoIncrementsAndRemainsEditable() {
        let sut = AnnotationStore()
        let first = sut.addNumber(at: .zero)
        let second = sut.addNumber(at: CGPoint(x: 12, y: 12))
        XCTAssertEqual(first.displayValue, "1")
        XCTAssertEqual(second.displayValue, "2")
        sut.updateNumber(id: second.id, value: "9")
        XCTAssertEqual(sut.item(id: second.id)?.displayValue, "9")
    }
}
