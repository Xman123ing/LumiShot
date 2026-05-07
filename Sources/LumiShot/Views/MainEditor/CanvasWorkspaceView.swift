import AppKit
import SwiftUI

struct CanvasWorkspaceView: View {
    let items: [AnnotationItem]
    let hasCapture: Bool
    let captureImage: CGImage?

    init(
        items: [AnnotationItem],
        hasCapture: Bool,
        captureImage: CGImage? = nil
    ) {
        self.items = items
        self.hasCapture = hasCapture
        self.captureImage = captureImage
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.white.opacity(0.72))

            if let captureImage {
                Image(nsImage: NSImage(cgImage: captureImage, size: NSSize(width: captureImage.width, height: captureImage.height)))
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(contentMode: .fit)
                    .padding(12)
            }

            if !items.isEmpty {
                AnnotationCanvasView(items: items)
                    .padding(12)
            }

            if items.isEmpty {
                placeholderOverlay
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var placeholderOverlay: some View {
        if captureImage != nil {
            Text(emptyPlaceholderText)
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(.black.opacity(0.42), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        } else {
            Text(emptyPlaceholderText)
                .font(.system(size: 13))
                .foregroundStyle(.black.opacity(0.45))
        }
    }

    private var emptyPlaceholderText: String {
        if hasCapture {
            return "Captured. Add annotations from the top toolbar."
        }
        return "Capture your screen and annotate from the top toolbar."
    }
}
