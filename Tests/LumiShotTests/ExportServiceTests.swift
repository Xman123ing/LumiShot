import CoreGraphics
import XCTest
@testable import LumiShotKit

final class ExportServiceTests: XCTestCase {
    func testExportsOnlyPNGToDisk() throws {
        let sut = ExportService(fileManager: .default)
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: tmp) }
        let urls = try sut.exportPNG(image: .fixtureCGImage, baseName: "sample", directory: tmp)
        let expectedMarkdownURL = tmp.appendingPathComponent("sample.md")
        let expectedTextURL = tmp.appendingPathComponent("sample.txt")
        let expectedJPEGURL = tmp.appendingPathComponent("sample.jpg")

        XCTAssertTrue(urls.png.pathExtension == "png")
        XCTAssertTrue(FileManager.default.fileExists(atPath: urls.png.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: expectedMarkdownURL.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: expectedTextURL.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: expectedJPEGURL.path))
    }

    func testAppendsSuffixWhenPNGAlreadyExists() throws {
        let sut = ExportService(fileManager: .default)
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: tmp) }
        try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
        let existing = tmp.appendingPathComponent("test-export-collision.png")
        try Data("seed".utf8).write(to: existing)

        let urls = try sut.exportPNG(image: .fixtureCGImage, baseName: "test-export-collision", directory: tmp)

        XCTAssertEqual(urls.png.lastPathComponent, "test-export-collision-01.png")
        XCTAssertTrue(FileManager.default.fileExists(atPath: urls.png.path))
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
