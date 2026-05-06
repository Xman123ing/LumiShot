import CoreGraphics
import Foundation

public protocol CaptureServicing: Sendable {
    func capture(mode: CaptureMode) async throws -> CaptureAsset
}

public enum CaptureError: Error {
    case permissionDenied
    case unsupportedMode
    case captureFailed
}

public struct CaptureService: CaptureServicing {
    private let permissionService: CapturePermissionService

    public init(permissionService: CapturePermissionService) {
        self.permissionService = permissionService
    }

    public func capture(mode: CaptureMode) async throws -> CaptureAsset {
        if permissionService.currentState() != .granted {
            let granted = permissionService.requestAccess()
            guard granted else { throw CaptureError.permissionDenied }
        }

        switch mode {
        case .fullScreen:
            guard let image = CGDisplayCreateImage(CGMainDisplayID()) else {
                throw CaptureError.captureFailed
            }
            return CaptureAsset(mode: mode, image: image)
        case .region, .window, .scrolling:
            throw CaptureError.unsupportedMode
        }
    }
}
