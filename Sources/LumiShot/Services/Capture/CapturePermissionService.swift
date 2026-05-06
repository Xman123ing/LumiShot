import CoreGraphics

public enum CapturePermissionState: Equatable, Sendable {
    case granted
    case denied
    case notDetermined
}

public struct CapturePermissionService: Sendable {
    public typealias Checker = @Sendable () -> CapturePermissionState
    private let checker: Checker

    public init(checker: @escaping Checker = Self.systemPermissionCheck) {
        self.checker = checker
    }

    public func currentState() -> CapturePermissionState {
        checker()
    }

    public func requestAccess() -> Bool {
        CGRequestScreenCaptureAccess()
    }

    public static func systemPermissionCheck() -> CapturePermissionState {
        if CGPreflightScreenCaptureAccess() {
            return .granted
        }
        return .notDetermined
    }
}
