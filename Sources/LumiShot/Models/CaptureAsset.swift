import CoreGraphics
import Foundation

public struct CaptureAsset: Equatable, @unchecked Sendable {
    public let id: UUID
    public let mode: CaptureMode
    public let createdAt: Date
    public let image: CGImage?

    public init(
        id: UUID = UUID(),
        mode: CaptureMode,
        createdAt: Date = Date(),
        image: CGImage? = nil
    ) {
        self.id = id
        self.mode = mode
        self.createdAt = createdAt
        self.image = image
    }

    public static func == (lhs: CaptureAsset, rhs: CaptureAsset) -> Bool {
        lhs.id == rhs.id && lhs.mode == rhs.mode
    }
}
