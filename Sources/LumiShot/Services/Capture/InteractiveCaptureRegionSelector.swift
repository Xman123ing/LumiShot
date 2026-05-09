import AppKit
import Carbon
import CoreGraphics
import Foundation

struct CaptureWindowSnapshot: Equatable {
    let frame: CGRect
    let ownerPID: Int32
    let layer: Int
    let alpha: Double
}

enum CaptureDefaultRegionResolver {
    static func resolve(
        pointer: CGPoint,
        windows: [CaptureWindowSnapshot],
        screens: [CGRect],
        excludedOwnerPID: Int32,
        frontmostOwnerPID: Int32? = nil
    ) -> CGRect? {
        if let frontmostOwnerPID,
           let targetWindow = windows.first(where: {
               $0.ownerPID == frontmostOwnerPID &&
               $0.ownerPID != excludedOwnerPID &&
               $0.layer == 0 &&
               $0.alpha > 0.02 &&
               $0.frame.width > 24 &&
               $0.frame.height > 24 &&
               $0.frame.contains(pointer)
           }) {
            return targetWindow.frame.standardized
        }
        if let targetWindow = windows.first(where: {
            $0.ownerPID != excludedOwnerPID &&
            $0.layer == 0 &&
            $0.alpha > 0.02 &&
            $0.frame.width > 24 &&
            $0.frame.height > 24 &&
            $0.frame.contains(pointer)
        }) {
            return targetWindow.frame.standardized
        }
        if let targetScreen = screens.first(where: { $0.contains(pointer) }) {
            return targetScreen.standardized
        }
        return screens.first?.standardized
    }

    static func resolveForScreenCapture(
        pointer: CGPoint,
        windows: [CaptureWindowSnapshot],
        screens: [CGRect],
        excludedOwnerPID: Int32,
        frontmostOwnerPID: Int32? = nil
    ) -> CGRect? {
        if let targetScreen = screens.first(where: { $0.contains(pointer) }) {
            return targetScreen.standardized
        }
        return resolve(
            pointer: pointer,
            windows: windows,
            screens: screens,
            excludedOwnerPID: excludedOwnerPID,
            frontmostOwnerPID: frontmostOwnerPID
        )
    }
}

enum CaptureOverlayCoordinateMapper {
    static func toLocal(_ globalRect: CGRect, in overlayFrame: CGRect) -> CGRect {
        globalRect.offsetBy(dx: -overlayFrame.origin.x, dy: -overlayFrame.origin.y)
    }

    static func toGlobal(_ localRect: CGRect, in overlayFrame: CGRect) -> CGRect {
        localRect.offsetBy(dx: overlayFrame.origin.x, dy: overlayFrame.origin.y)
    }
}

@MainActor
final class InteractiveCaptureRegionSelector {
    private var overlayController: CaptureSelectionOverlayWindowController?
    private var didHideMainWindow = false
    private weak var hiddenMainWindow: NSWindow?
    private var wasAppActiveWhenSelectionStarted = false

    func beginSelection(
        autoRestore: Bool = true,
        bringLumiShotToFrontForOverlay: Bool = true,
        onFinished: @escaping (CGRect?) -> Void
    ) {
        guard overlayController == nil else { return }

        wasAppActiveWhenSelectionStarted = NSApp.isActive
        didHideMainWindow = false
        hiddenMainWindow = NSApp.mainWindow ?? NSApp.keyWindow
        if let mainWindow = hiddenMainWindow, mainWindow.isVisible {
            mainWindow.orderOut(nil)
            didHideMainWindow = true
        }

        let initialRect = defaultSelectionRect()
        let controller = CaptureSelectionOverlayWindowController(initialSelection: initialRect) { [weak self] rect in
            self?.overlayController = nil
            if autoRestore {
                self?.restoreWindows()
            }
            onFinished(rect)
        }
        overlayController = controller
        controller.show(activateApp: bringLumiShotToFrontForOverlay)
    }

    func restoreWindowsIfNeeded() {
        restoreWindows()
    }

    func restoreWindowsAndBringLumiShotFront() {
        restoreWindows(forceFront: true)
    }

    private func restoreWindows(forceFront: Bool = false) {
        if forceFront || wasAppActiveWhenSelectionStarted {
            NSApp.unhide(nil)
            _ = NSRunningApplication.current.activate(options: [.activateAllWindows, .activateIgnoringOtherApps])
            if didHideMainWindow, let hiddenMainWindow {
                hiddenMainWindow.makeKeyAndOrderFront(nil)
            } else {
                NSApp.mainWindow?.makeKeyAndOrderFront(nil)
                NSApp.keyWindow?.makeKeyAndOrderFront(nil)
            }
        }
        didHideMainWindow = false
        hiddenMainWindow = nil
    }

    private func defaultSelectionRect() -> CGRect? {
        let pointer = NSEvent.mouseLocation
        let windowSnapshots = Self.fetchWindowSnapshots()
        let screenFrames = NSScreen.screens.map(\.frame)
        let excludedOwnerPID = Int32(ProcessInfo.processInfo.processIdentifier)
        let frontmostOwnerPID = NSWorkspace.shared.frontmostApplication.map { Int32($0.processIdentifier) }
        return CaptureDefaultRegionResolver.resolveForScreenCapture(
            pointer: pointer,
            windows: windowSnapshots,
            screens: screenFrames,
            excludedOwnerPID: excludedOwnerPID,
            frontmostOwnerPID: frontmostOwnerPID
        )
    }

    private static func fetchWindowSnapshots() -> [CaptureWindowSnapshot] {
        guard let windowInfos = CGWindowListCopyWindowInfo(
            [.optionOnScreenOnly, .excludeDesktopElements],
            kCGNullWindowID
        ) as? [[String: Any]] else {
            return []
        }
        let desktopFrame = NSScreen.screens.map(\.frame).reduce(CGRect.null) { partial, next in
            partial.union(next)
        }

        return windowInfos.compactMap { info in
            guard
                let boundsValue = info[kCGWindowBounds as String],
                let boundsDictionary = boundsValue as? NSDictionary,
                let owner = info[kCGWindowOwnerPID as String] as? Int
            else {
                return nil
            }
            guard let quartzFrame = CGRect(dictionaryRepresentation: boundsDictionary) else {
                return nil
            }
            let frame = CGRect(
                x: quartzFrame.origin.x,
                y: desktopFrame.maxY - quartzFrame.maxY,
                width: quartzFrame.width,
                height: quartzFrame.height
            ).standardized
            let layer = info[kCGWindowLayer as String] as? Int ?? 0
            let alpha = info[kCGWindowAlpha as String] as? Double ?? 1
            return CaptureWindowSnapshot(
                frame: frame,
                ownerPID: Int32(owner),
                layer: layer,
                alpha: alpha
            )
        }
    }
}

private final class CaptureSelectionOverlayWindowController: NSWindowController {
    private let onFinished: (CGRect?) -> Void

    init(initialSelection: CGRect?, onFinished: @escaping (CGRect?) -> Void) {
        self.onFinished = onFinished
        let frame = NSScreen.screens.map(\.frame).reduce(CGRect.null) { partial, next in
            partial.union(next)
        }
        let window = CaptureOverlayWindow(
            contentRect: frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        window.level = .screenSaver
        window.backgroundColor = .clear
        window.isOpaque = false
        window.ignoresMouseEvents = false
        // .canJoinAllSpaces conflicts with .moveToActiveSpace and triggers AppKit assertion.
        window.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
        window.hasShadow = false
        super.init(window: window)
        window.contentView = CaptureSelectionOverlayView(
            frame: CGRect(origin: .zero, size: frame.size),
            overlayFrame: frame,
            initialSelection: initialSelection,
            onFinished: { [weak self] rect in
                self?.close()
                self?.onFinished(rect)
            }
        )
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    func show(activateApp: Bool) {
        window?.orderFrontRegardless()
        window?.makeKeyAndOrderFront(nil)
        if activateApp {
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}

private final class CaptureOverlayWindow: NSWindow {
    override var canBecomeKey: Bool { true }
}

@MainActor
private enum CaptureCursorStyle {
    static let screenshot: NSCursor = {
        let size = NSSize(width: 28, height: 28)
        let image = NSImage(size: size)
        image.lockFocus()
        defer { image.unlockFocus() }

        NSColor.white.setStroke()
        let circle = NSBezierPath(ovalIn: NSRect(x: 8, y: 8, width: 12, height: 12))
        circle.lineWidth = 1.6
        circle.stroke()

        let cross = NSBezierPath()
        cross.lineWidth = 1.6
        cross.lineCapStyle = .round
        cross.move(to: NSPoint(x: 14, y: 0))
        cross.line(to: NSPoint(x: 14, y: 28))
        cross.move(to: NSPoint(x: 0, y: 14))
        cross.line(to: NSPoint(x: 28, y: 14))
        cross.stroke()

        let glow = NSBezierPath(ovalIn: NSRect(x: 7, y: 7, width: 14, height: 14))
        NSColor.black.withAlphaComponent(0.45).setStroke()
        glow.lineWidth = 0.8
        glow.stroke()

        return NSCursor(image: image, hotSpot: NSPoint(x: 14, y: 14))
    }()
}

private final class CaptureSelectionOverlayView: NSView {
    private let onFinished: (CGRect?) -> Void
    private let overlayFrame: CGRect
    private var selectionRect: CGRect?
    private var dragStartPoint: NSPoint?
    private var dragCurrentPoint: NSPoint?

    init(frame frameRect: NSRect, overlayFrame: CGRect, initialSelection: CGRect?, onFinished: @escaping (CGRect?) -> Void) {
        self.onFinished = onFinished
        self.overlayFrame = overlayFrame
        self.selectionRect = initialSelection.map { CaptureOverlayCoordinateMapper.toLocal($0, in: overlayFrame) }
        super.init(frame: frameRect)
        wantsLayer = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override var acceptsFirstResponder: Bool { true }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        window?.makeFirstResponder(self)
        window?.acceptsMouseMovedEvents = true
        window?.invalidateCursorRects(for: self)
        CaptureCursorStyle.screenshot.set()
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == UInt16(kVK_Escape) {
            NSCursor.arrow.set()
            onFinished(nil)
            return
        }
        super.keyDown(with: event)
    }

    override func resetCursorRects() {
        super.resetCursorRects()
        addCursorRect(bounds, cursor: CaptureCursorStyle.screenshot)
    }

    override func mouseMoved(with event: NSEvent) {
        CaptureCursorStyle.screenshot.set()
        super.mouseMoved(with: event)
    }

    override func mouseDown(with event: NSEvent) {
        dragStartPoint = convert(event.locationInWindow, from: nil)
        dragCurrentPoint = dragStartPoint
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        dragCurrentPoint = convert(event.locationInWindow, from: nil)
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        dragCurrentPoint = convert(event.locationInWindow, from: nil)
        if let draggedRect = normalizedDragRect(), draggedRect.width > 8, draggedRect.height > 8 {
            selectionRect = draggedRect
        }
        let globalSelection = selectionRect.map {
            CaptureOverlayCoordinateMapper.toGlobal($0, in: overlayFrame).standardized
        }
        NSCursor.arrow.set()
        onFinished(globalSelection)
    }

    override func draw(_ dirtyRect: NSRect) {
        NSColor(calibratedWhite: 0.0, alpha: 0.52).setFill()
        bounds.fill()

        let visibleSelection = normalizedDragRect() ?? selectionRect
        guard let visibleSelection else { return }

        NSColor.clear.setFill()
        visibleSelection.fill(using: .clear)

        NSColor.white.setStroke()
        let border = NSBezierPath(rect: visibleSelection)
        border.lineWidth = 2
        border.stroke()
    }

    private func normalizedDragRect() -> CGRect? {
        guard let dragStartPoint, let dragCurrentPoint else { return nil }
        let minX = min(dragStartPoint.x, dragCurrentPoint.x)
        let minY = min(dragStartPoint.y, dragCurrentPoint.y)
        let maxX = max(dragStartPoint.x, dragCurrentPoint.x)
        let maxY = max(dragStartPoint.y, dragCurrentPoint.y)
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }
}
