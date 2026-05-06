import CoreGraphics
import XCTest
@testable import LumiShot

final class ExportServiceTests: XCTestCase {
    func testExportsPNGAndMarkdownToDisk() throws {
        let sut = ExportService(fileManager: .default)
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let urls = try sut.exportAll(image: .fixtureCGImage, text: "Hello", baseName: "sample", directory: tmp)
        XCTAssertTrue(urls.png.pathExtension == "png")
        XCTAssertTrue(urls.markdown.pathExtension == "md")
        XCTAssertTrue(FileManager.default.fileExists(atPath: urls.png.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: urls.markdown.path))
    }
}

private extension CGImage {
    static var fixtureCGImage: CGImage {
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
        context.setFillColor(gray: 0.5, alpha: 1.0)
        context.fill(CGRect(x: 0, y: 0, width: 10, height: 10))
        return context.makeImage()!
    }
}
