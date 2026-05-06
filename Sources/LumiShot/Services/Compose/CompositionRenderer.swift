import CoreGraphics

public struct CompositionRenderer {
    public init() {}

    public func render(baseImage: CGImage, annotations: [AnnotationItem]) -> CGImage {
        let _ = annotations
        // V1 skeleton: returns base image; annotation rasterization will be added in next iteration.
        return baseImage
    }
}
