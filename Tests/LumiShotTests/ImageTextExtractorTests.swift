import CoreGraphics
import XCTest
@testable import LumiShot

final class ImageTextExtractorTests: XCTestCase {
    func testImageExtractorUsesOCREngineResult() async throws {
        let extractor = ImageTextExtractor(ocrEngine: MockImageOCREngine(result: "hello ocr"))
        let output = try await extractor.extract(from: .fixtureImage)
        XCTAssertEqual(output.content, "hello ocr")
        XCTAssertEqual(output.path, .imageOCR)
    }
}

private struct MockImageOCREngine: OCREngine {
    let result: String

    func recognize(image: CGImage, languageHints: [String]) async throws -> OCRResult {
        let _ = image
        let _ = languageHints
        return OCRResult(text: result)
    }
}

private extension CGImage {
    static var fixtureImage: CGImage {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(
            data: nil,
            width: 10,
            height: 10,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        context.setFillColor(gray: 0.8, alpha: 1.0)
        context.fill(CGRect(x: 0, y: 0, width: 10, height: 10))
        return context.makeImage()!
    }
}
