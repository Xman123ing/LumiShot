import CoreGraphics

public struct ScrollFrame {
    public let image: CGImage?
    public let overlapScore: Double

    public init(image: CGImage?, overlapScore: Double) {
        self.image = image
        self.overlapScore = overlapScore
    }
}

public extension ScrollFrame {
    static func mock(score: Double) -> ScrollFrame {
        ScrollFrame(image: nil, overlapScore: score)
    }
}
