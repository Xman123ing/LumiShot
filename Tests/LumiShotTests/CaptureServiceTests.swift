import CoreGraphics
import XCTest
@testable import LumiShotKit

final class CaptureServiceTests: XCTestCase {
    func testRegionCaptureReturnsRegionAssetWhenImageProviderSucceeds() async throws {
        let expectedImage = Self.makeImage(gray: 0.2)
        let expectedRegion = CGRect(x: 10, y: 20, width: 120, height: 90)
        let sut = CaptureService(
            permissionService: CapturePermissionService(checker: { .granted }),
            fullScreenImageProvider: { Self.makeImage(gray: 0.4) },
            regionImageProvider: { region in
                XCTAssertEqual(region, expectedRegion)
                return expectedImage
            }
        )

        let asset = try await sut.capture(mode: .region, region: expectedRegion)

        XCTAssertEqual(asset.mode, .region)
        XCTAssertEqual(asset.image?.width, expectedImage.width)
        XCTAssertEqual(asset.image?.height, expectedImage.height)
    }

    func testRegionCaptureThrowsInvalidRegionWhenRegionMissing() async {
        let sut = CaptureService(permissionService: CapturePermissionService(checker: { .granted }))

        do {
            _ = try await sut.capture(mode: .region, region: nil)
            XCTFail("Expected invalidRegion to be thrown")
        } catch let error as CaptureError {
            XCTAssertEqual(error, .invalidRegion)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testWindowCaptureReturnsWindowAssetWhenProviderSucceeds() async throws {
        let expectedImage = Self.makeImage(gray: 0.6)
        let sut = CaptureService(
            permissionService: CapturePermissionService(checker: { .granted }),
            windowImageProvider: { expectedImage }
        )

        let asset = try await sut.capture(mode: .window, region: nil)

        XCTAssertEqual(asset.mode, .window)
        XCTAssertEqual(asset.image?.width, expectedImage.width)
        XCTAssertEqual(asset.image?.height, expectedImage.height)
    }

    func testScrollingCaptureReturnsScrollingAssetWhenProviderSucceeds() async throws {
        let expectedImage = Self.makeImage(gray: 0.8)
        let sut = CaptureService(
            permissionService: CapturePermissionService(checker: { .granted }),
            scrollingImageProvider: { expectedImage }
        )

        let asset = try await sut.capture(mode: .scrolling, region: nil)

        XCTAssertEqual(asset.mode, .scrolling)
        XCTAssertEqual(asset.image?.width, expectedImage.width)
        XCTAssertEqual(asset.image?.height, expectedImage.height)
    }

    private static func makeImage(gray: CGFloat) -> CGImage {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(
            data: nil,
            width: 8,
            height: 8,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        context.setFillColor(gray: gray, alpha: 1.0)
        context.fill(CGRect(x: 0, y: 0, width: 8, height: 8))
        return context.makeImage()!
    }
}
