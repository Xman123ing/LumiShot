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
            return CaptureAsset(
                mode: mode,
                image: image,
                logicalSize: logicalRegionSize(for: region, capturedImage: image)
            )
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
        guard let targetScreen = NSScreen.screens.first(where: { $0.frame.contains(CGPoint(x: appKitRegion.midX, y: appKitRegion.midY)) }) else {
            return nil
        }
        let scale = targetScreen.backingScaleFactor
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
        if let image = CGWindowListCreateImage(
            quartzRect,
            .optionOnScreenOnly,
            kCGNullWindowID,
            [.bestResolution]
        ) {
            return image
        }

        // Fallback for fullscreen/space edge cases where window-list region capture can return nil.
        return captureRegionFromDisplay(pixelAlignedRegion, on: targetScreen, scale: scale)
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

    private func logicalRegionSize(for region: CGRect, capturedImage: CGImage) -> CGSize {
        let standardized = region.standardized
        let scale = NSScreen.screens.first(where: { $0.frame.contains(CGPoint(x: standardized.midX, y: standardized.midY)) })?.backingScaleFactor ?? 2
        return CGSize(
            width: CGFloat(capturedImage.width) / scale,
            height: CGFloat(capturedImage.height) / scale
        )
    }

    private static func captureRegionFromDisplay(_ region: CGRect, on screen: NSScreen, scale: CGFloat) -> CGImage? {
        guard
            let screenNumber = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber
        else {
            return nil
        }
        let displayID = CGDirectDisplayID(screenNumber.uint32Value)

        let screenFrame = screen.frame
        let clipped = region.intersection(screenFrame).standardized
        guard clipped.width > 0, clipped.height > 0 else {
            return nil
        }

        let localX = clipped.origin.x - screenFrame.origin.x
        let localY = clipped.origin.y - screenFrame.origin.y
        let displayPixelRect = CGRect(
            x: (localX * scale).rounded(),
            y: ((screenFrame.height - localY - clipped.height) * scale).rounded(),
            width: (clipped.width * scale).rounded(),
            height: (clipped.height * scale).rounded()
        ).standardized

        guard displayPixelRect.width > 0, displayPixelRect.height > 0 else {
            return nil
        }
        return CGDisplayCreateImage(displayID, rect: displayPixelRect)
    }
}
