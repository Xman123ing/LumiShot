public struct ScrollCaptureCoordinator {
    private let stitcher: ScrollStitcher

    public init(stitcher: ScrollStitcher = ScrollStitcher()) {
        self.stitcher = stitcher
    }

    public func finalize(frames: [ScrollFrame]) -> ScrollStitchResult {
        stitcher.stitch(frames: frames)
    }
}
