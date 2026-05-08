import XCTest
@testable import LumiShotKit

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

    func testTextBoxArrowMosaicFloatingPinBackdropToolsCanBeAddedAndTextUpdated() {
        let sut = AnnotationStore()
        let textItem = sut.addText("hello", at: CGPoint(x: 10, y: 20))
        let boxItem = sut.addBox(at: CGPoint(x: 40, y: 50))
        let arrowItem = sut.addArrow(at: CGPoint(x: 80, y: 90))
        let mosaicItem = sut.addMosaic(at: CGPoint(x: 110, y: 120))
        let pinItem = sut.addFloatingPin(at: CGPoint(x: 130, y: 140))
        let backdropItem = sut.addBackdrop(at: CGPoint(x: 150, y: 160))

        XCTAssertEqual(textItem.kind, .text)
        XCTAssertEqual(boxItem.kind, .box)
        XCTAssertEqual(arrowItem.kind, .arrow)
        XCTAssertEqual(mosaicItem.kind, .mosaic)
        XCTAssertEqual(pinItem.kind, .floatingPin)
        XCTAssertEqual(backdropItem.kind, .backdrop)
        XCTAssertEqual(textItem.displayValue, "hello")

        sut.updateText(id: textItem.id, value: "updated")
        XCTAssertEqual(sut.item(id: textItem.id)?.displayValue, "updated")
    }
}
