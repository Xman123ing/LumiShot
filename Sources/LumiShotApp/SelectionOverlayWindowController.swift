import AppKit

final class SelectionOverlayWindowController: NSWindowController {
    private let completion: (CGRect) -> Void

    init(completion: @escaping (CGRect) -> Void) {
        self.completion = completion
        let frame = NSScreen.screens.map(\.frame).reduce(CGRect.null) { partial, next in
            partial.union(next)
        }
        let window = NSWindow(
            contentRect: frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        window.level = .screenSaver
        window.backgroundColor = .clear
        window.isOpaque = false
        window.ignoresMouseEvents = false
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.hasShadow = false

        super.init(window: window)
        window.contentView = SelectionOverlayView(
            frame: frame,
            onFinished: { [weak self] rect in
                self?.close()
                self?.completion(rect)
            }
        )
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    func show() {
        window?.orderFrontRegardless()
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

private final class SelectionOverlayView: NSView {
    private let onFinished: (CGRect) -> Void
    private var startPoint: NSPoint?
    private var currentPoint: NSPoint?

    init(frame frameRect: NSRect, onFinished: @escaping (CGRect) -> Void) {
        self.onFinished = onFinished
        super.init(frame: frameRect)
        wantsLayer = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override func mouseDown(with event: NSEvent) {
        startPoint = convert(event.locationInWindow, from: nil)
        currentPoint = startPoint
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        currentPoint = convert(event.locationInWindow, from: nil)
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        currentPoint = convert(event.locationInWindow, from: nil)
        needsDisplay = true
        guard let selection = normalizedSelectionRect(), let window else { return }
        let screenRect = window.convertToScreen(selection)
        onFinished(screenRect)
    }

    override func draw(_ dirtyRect: NSRect) {
        NSColor(calibratedWhite: 0.0, alpha: 0.5).setFill()
        bounds.fill()

        guard let selection = normalizedSelectionRect() else { return }
        NSColor.clear.setFill()
        selection.fill(using: .clear)

        NSColor.white.setStroke()
        let path = NSBezierPath(rect: selection)
        path.lineWidth = 2
        path.stroke()
    }

    private func normalizedSelectionRect() -> CGRect? {
        guard let startPoint, let currentPoint else { return nil }
        let minX = min(startPoint.x, currentPoint.x)
        let minY = min(startPoint.y, currentPoint.y)
        let maxX = max(startPoint.x, currentPoint.x)
        let maxY = max(startPoint.y, currentPoint.y)
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }
}
