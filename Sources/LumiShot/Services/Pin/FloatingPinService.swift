import AppKit
import SwiftUI

@MainActor
public final class FloatingPinService {
    public static let shared = FloatingPinService()

    private var windows: [NSWindowController] = []

    private init() {}

    public func pin(image: CGImage) {
        let nsImage = NSImage(cgImage: image, size: NSSize(width: image.width, height: image.height))
        let controller = FloatingPinWindowController(image: nsImage) { [weak self] closed in
            self?.windows.removeAll { $0 === closed }
        }
        windows.append(controller)
        controller.showWindow(nil)
        controller.window?.orderFrontRegardless()
    }
}

private final class FloatingPinWindowController: NSWindowController {
    private let onClose: (NSWindowController) -> Void

    init(image: NSImage, onClose: @escaping (NSWindowController) -> Void) {
        self.onClose = onClose
        let size = NSSize(width: max(260, image.size.width + 28), height: max(180, image.size.height + 28))
        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.titled, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.minSize = NSSize(width: 220, height: 140)
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = true
        window.standardWindowButton(.closeButton)?.isHidden = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true
        super.init(window: window)
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
}

private struct FloatingPinPreview: View {
    let image: NSImage
    let onClose: () -> Void
    @State private var closeHovered = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.28), radius: 18, y: 8)
            Image(nsImage: image)
                .resizable()
                .interpolation(.high)
                .aspectRatio(contentMode: .fit)
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
                .padding(.top, 18)
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
        .padding(8)
        .frame(minWidth: 260, minHeight: 180)
    }
}
