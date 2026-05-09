import AppKit
import SwiftUI

@MainActor
public final class FloatingPinService {
    public static let shared = FloatingPinService()

    private var windows: [NSWindowController] = []

    private init() {}

    public func pin(image: CGImage, displaySize: CGSize? = nil) {
        let imageSize = resolvedDisplaySize(for: image, preferred: displaySize)
        let nsImage = NSImage(cgImage: image, size: imageSize)
        let controller = FloatingPinWindowController(image: nsImage) { [weak self] closed in
            self?.windows.removeAll { $0 === closed }
        }
        windows.append(controller)
        controller.showWindow(nil)
        controller.window?.orderFrontRegardless()
    }

    private func resolvedDisplaySize(for image: CGImage, preferred: CGSize?) -> NSSize {
        if let preferred, preferred.width > 0, preferred.height > 0 {
            return NSSize(width: preferred.width, height: preferred.height)
        }
        let scale = max(1.0, NSScreen.main?.backingScaleFactor ?? 2.0)
        return NSSize(width: CGFloat(image.width) / scale, height: CGFloat(image.height) / scale)
    }
}

private final class FloatingPinWindowController: NSWindowController, NSWindowDelegate {
    private let onClose: (NSWindowController) -> Void
    private let aspectRatio: CGFloat

    init(image: NSImage, onClose: @escaping (NSWindowController) -> Void) {
        self.onClose = onClose
        self.aspectRatio = max(0.1, image.size.width / max(1, image.size.height))
        let imageSize = NSSize(width: max(1, image.size.width), height: max(1, image.size.height))
        let size = NSSize(width: max(1, imageSize.width), height: max(1, imageSize.height))
        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.titled, .closable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.minSize = NSSize(width: 120, height: 90)
        window.showsResizeIndicator = true
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = true
        window.standardWindowButton(.closeButton)?.isHidden = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true
        super.init(window: window)
        window.delegate = self
        window.setContentSize(imageSize)
        window.contentAspectRatio = imageSize
        let hostView = NSHostingView(
            rootView: FloatingPinPreview(image: image) { [weak window] in
                window?.close()
            }
        )
        hostView.wantsLayer = true
        hostView.layer?.backgroundColor = NSColor.clear.cgColor
        window.contentView = hostView
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override func close() {
        super.close()
        onClose(self)
    }

    func windowWillResize(_ sender: NSWindow, to frameSize: NSSize) -> NSSize {
        guard aspectRatio > 0 else { return frameSize }
        let minHeight = sender.minSize.height
        let minWidth = sender.minSize.width
        let widthDrivenHeight = frameSize.width / aspectRatio
        let heightDrivenWidth = frameSize.height * aspectRatio
        let useWidth = abs(widthDrivenHeight - frameSize.height) <= abs(heightDrivenWidth - frameSize.width)
        var target: NSSize
        if useWidth {
            target = NSSize(width: max(minWidth, frameSize.width), height: max(minHeight, widthDrivenHeight))
        } else {
            target = NSSize(width: max(minWidth, heightDrivenWidth), height: max(minHeight, frameSize.height))
        }
        if target.width < minWidth {
            target.width = minWidth
            target.height = max(minHeight, minWidth / aspectRatio)
        }
        if target.height < minHeight {
            target.height = minHeight
            target.width = max(minWidth, minHeight * aspectRatio)
        }
        return target
    }
}

private struct FloatingPinPreview: View {
    let image: NSImage
    let onClose: () -> Void
    @State private var closeHovered = false

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.28), radius: 18, y: 8)
                Image(nsImage: image)
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                VStack {
                    HStack {
                        Spacer()
                        Button(action: onClose) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(4)
                                .background(
                                    Circle()
                                        .fill(.black.opacity(closeHovered ? 0.42 : 0.28))
                                        .shadow(color: .black.opacity(closeHovered ? 0.42 : 0.25), radius: closeHovered ? 6 : 3, y: 1)
                                )
                                .scaleEffect(closeHovered ? 1.08 : 1.0)
                        }
                        .buttonStyle(.plain)
                        .onHover { hovered in
                            closeHovered = hovered
                        }
                        .padding(.top, 8)
                        .padding(.trailing, 8)
                    }
                    Spacer()
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .frame(minWidth: 120, minHeight: 90)
    }
}
