import CoreGraphics
import XCTest
@testable import LumiShotKit

final class CompositionRendererTests: XCTestCase {
    func testRenderAppliesAnnotationOverlay() {
        let base = Self.makeImage(gray: 0.2)
        let annotations = [AnnotationItem.number(value: "1", center: CGPoint(x: 20, y: 20))]
        let sut = CompositionRenderer()

        let rendered = sut.render(baseImage: base, annotations: annotations)

        XCTAssertEqual(rendered.width, base.width)
        XCTAssertEqual(rendered.height, base.height)
        XCTAssertNotEqual(
            Self.pixelRGBA(at: CGPoint(x: 20, y: 20), in: rendered),
            Self.pixelRGBA(at: CGPoint(x: 20, y: 20), in: base)
        )
    }

    private static func pixelRGBA(at point: CGPoint, in image: CGImage) -> UInt32 {
        guard
            let data = image.dataProvider?.data,
            let pointer = CFDataGetBytePtr(data),
            Int(point.x) >= 0,
            Int(point.y) >= 0,
            Int(point.x) < image.width,
            Int(point.y) < image.height
        else {
            return 0
        }
        let x = Int(point.x)
        let y = Int(point.y)
        let bytesPerPixel = image.bitsPerPixel / 8
        let index = y * image.bytesPerRow + x * bytesPerPixel
        let r = UInt32(pointer[index])
        let g = UInt32(pointer[index + 1])
        let b = UInt32(pointer[index + 2])
        let a = UInt32(pointer[index + 3])
        return (r << 24) | (g << 16) | (b << 8) | a
    }

    private static func makeImage(gray: CGFloat) -> CGImage {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(
            data: nil,
            width: 40,
            height: 40,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        context.setFillColor(gray: gray, alpha: 1.0)
        context.fill(CGRect(x: 0, y: 0, width: 40, height: 40))
        return context.makeImage()!
    }
}
