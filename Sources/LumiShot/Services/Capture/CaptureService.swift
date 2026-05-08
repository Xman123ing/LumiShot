import AppKit
import CoreGraphics
import Foundation

public protocol CaptureServicing: Sendable {
    func capture(mode: CaptureMode, region: CGRect?) async throws -> CaptureAsset
}

public enum CaptureError: Error, Equatable {
    case permissionDenied
    case unsupportedMode
    case invalidRegion
    case captureFailed
}

public struct CaptureService: CaptureServicing {
    public typealias FullScreenImageProvider = @Sendable () -> CGImage?
    public typealias RegionImageProvider = @Sendable (CGRect) -> CGImage?
    public typealias WindowImageProvider = @Sendable () -> CGImage?
    public typealias ScrollingImageProvider = @Sendable () -> CGImage?

    private let permissionService: CapturePermissionService
    private let fullScreenImageProvider: FullScreenImageProvider
    private let regionImageProvider: RegionImageProvider
    private let windowImageProvider: WindowImageProvider
    private let scrollingImageProvider: ScrollingImageProvider

    public init(
        permissionService: CapturePermissionService,
        fullScreenImageProvider: @escaping FullScreenImageProvider = Self.defaultFullScreenImageProvider,
        regionImageProvider: @escaping RegionImageProvider = Self.defaultRegionImageProvider,
        windowImageProvider: @escaping WindowImageProvider = Self.defaultWindowImageProvider,
        scrollingImageProvider: @escaping ScrollingImageProvider = Self.defaultScrollingImageProvider
    ) {
        self.permissionService = permissionService
        self.fullScreenImageProvider = fullScreenImageProvider
        self.regionImageProvider = regionImageProvider
        self.windowImageProvider = windowImageProvider
        self.scrollingImageProvider = scrollingImageProvider
    }

    public func capture(mode: CaptureMode, region: CGRect? = nil) async throws -> CaptureAsset {
        if permissionService.currentState() != .granted {
            let granted = permissionService.requestAccess()
            guard granted else { throw CaptureError.permissionDenied }
        }

        switch mode {
        case .fullScreen:
            guard let image = fullScreenImageProvider() else {
                throw CaptureError.captureFailed
            }
            return CaptureAsset(mode: mode, image: image, logicalSize: nil)
        case .region:
            guard let region, region.width > 0, region.height > 0 else {
                throw CaptureError.invalidRegion
            }
            guard let image = regionImageProvider(region) else {
                throw CaptureError.captureFailed
            }
            return CaptureAsset(mode: mode, image: image, logicalSize: region.standardized.size)
        case .window:
            guard let image = windowImageProvider() else {
                throw CaptureError.captureFailed
            }
            return CaptureAsset(mode: mode, image: image, logicalSize: nil)
        case .scrolling:
            guard let image = scrollingImageProvider() else {
                throw CaptureError.captureFailed
            }
            return CaptureAsset(mode: mode, image: image, logicalSize: nil)
        }
    }

    public static func defaultFullScreenImageProvider() -> CGImage? {
        CGDisplayCreateImage(CGMainDisplayID())
    }

    public static func defaultRegionImageProvider(region: CGRect) -> CGImage? {
        let appKitRegion = region.standardized
        let scale = NSScreen.screens.first(where: { $0.frame.contains(CGPoint(x: appKitRegion.midX, y: appKitRegion.midY)) })?.backingScaleFactor ?? 2
        let pixelAlignedRegion = CGRect(
            x: (appKitRegion.origin.x * scale).rounded() / scale,
            y: (appKitRegion.origin.y * scale).rounded() / scale,
            width: (appKitRegion.width * scale).rounded() / scale,
            height: (appKitRegion.height * scale).rounded() / scale
        )
        let desktopFrame = NSScreen.screens.map(\.frame).reduce(CGRect.null) { partial, next in
            partial.union(next)
        }
        let quartzRect = CGRect(
            x: pixelAlignedRegion.origin.x,
            y: desktopFrame.maxY - pixelAlignedRegion.maxY,
            width: pixelAlignedRegion.width,
            height: pixelAlignedRegion.height
        ).standardized
        return CGWindowListCreateImage(
            quartzRect,
            .optionOnScreenOnly,
            kCGNullWindowID,
            [.bestResolution]
        )
    }

    public static func defaultWindowImageProvider() -> CGImage? {
        CGWindowListCreateImage(
            .null,
            .optionOnScreenOnly,
            kCGNullWindowID,
            [.bestResolution]
        )
    }

    public static func defaultScrollingImageProvider() -> CGImage? {
        // V1 fallback: use current display snapshot when dedicated scrolling capture is unavailable.
        defaultFullScreenImageProvider()
    }
}
