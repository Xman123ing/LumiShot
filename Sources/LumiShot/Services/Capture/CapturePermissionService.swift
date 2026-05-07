import CoreGraphics
import Foundation

public enum CapturePermissionState: Equatable, Sendable {
    case granted
    case denied
    case notDetermined
}

public struct CapturePermissionService: Sendable {
    public typealias Checker = @Sendable () -> CapturePermissionState
    public typealias Requester = @Sendable () -> Bool

    private static let sessionLock = NSLock()
    private static nonisolated(unsafe) var sessionGrantRecorded = false

    private let checker: Checker
    private let requester: Requester

    public init(
        checker: @escaping Checker = Self.systemPermissionCheck,
        requester: @escaping Requester = Self.systemPermissionRequest
    ) {
        self.checker = checker
        self.requester = requester
    }

    public func currentState() -> CapturePermissionState {
        let state = checker()
        switch state {
        case .granted:
            Self.recordSessionGrant()
            return .granted
        case .denied:
            return .denied
        case .notDetermined:
            return Self.hasSessionGrant() ? .granted : .notDetermined
        }
    }

    @discardableResult
    public func requestAccess() -> Bool {
        let granted = requester()
        if granted {
            Self.recordSessionGrant()
        }
        return granted
    }

    public static func systemPermissionCheck() -> CapturePermissionState {
        if CGPreflightScreenCaptureAccess() {
            return .granted
        }
        return .notDetermined
    }

    public static func systemPermissionRequest() -> Bool {
        CGRequestScreenCaptureAccess()
    }

    static func resetSessionGrantForTesting() {
        sessionLock.lock()
        sessionGrantRecorded = false
        sessionLock.unlock()
    }

    private static func recordSessionGrant() {
        sessionLock.lock()
        sessionGrantRecorded = true
        sessionLock.unlock()
    }

    private static func hasSessionGrant() -> Bool {
        sessionLock.lock()
        let granted = sessionGrantRecorded
        sessionLock.unlock()
        return granted
    }
}
