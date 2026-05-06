import CoreGraphics

public enum ScrollStitchResult: Equatable {
    case stitched(CGImage)
    case fallbackSequence

    public static func == (lhs: ScrollStitchResult, rhs: ScrollStitchResult) -> Bool {
        switch (lhs, rhs) {
        case (.fallbackSequence, .fallbackSequence):
            return true
        case let (.stitched(left), .stitched(right)):
            return left.width == right.width && left.height == right.height
        default:
            return false
        }
    }
}

public struct ScrollStitcher {
    public let minimumOverlapScore: Double

    public init(minimumOverlapScore: Double = 0.8) {
        self.minimumOverlapScore = minimumOverlapScore
    }

    public func stitch(frames: [ScrollFrame]) -> ScrollStitchResult {
        guard !frames.isEmpty else { return .fallbackSequence }
        guard frames.allSatisfy({ $0.overlapScore >= minimumOverlapScore }) else {
            return .fallbackSequence
        }
        guard let image = compose(frames) else {
            return .fallbackSequence
        }
        return .stitched(image)
    }

    private func compose(_ frames: [ScrollFrame]) -> CGImage? {
        if let first = frames.first?.image {
            return first
        }
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: nil,
            width: 2,
            height: max(frames.count, 1) * 2,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }
        context.setFillColor(gray: 0.2, alpha: 1.0)
        context.fill(CGRect(x: 0, y: 0, width: 2, height: max(frames.count, 1) * 2))
        return context.makeImage()
    }
}
