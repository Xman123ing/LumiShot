@preconcurrency import AppKit
import Carbon
import LumiShotKit
import SwiftUI

final class LumiShotAppDelegate: NSObject, NSApplicationDelegate {
    private static let defaultMainWindowSize = NSSize(width: 1180, height: 760)
    private static let minimumMainWindowSize = NSSize(width: 900, height: 620)

    private let regionOCRCoordinator = RegionOCRCoordinator()
    private var triggerObserver: NSObjectProtocol?
    private var shortcutSettingsObserver: NSObjectProtocol?
    private var openMainWindowObserver: NSObjectProtocol?
    private var hotkeyServices: [AppShortcutAction: GlobalHotkeyService] = [:]
    private var lastRegisteredShortcuts: [AppShortcutAction: OCRShortcutConfiguration] = [:]
    private let globalHotkeyActions: Set<AppShortcutAction> = [.capture, .extractOCR]
    private var statusItem: NSStatusItem?
    private var fallbackMainWindowController: NSWindowController?

    deinit {
        logToDownloads("LumiShotAppDelegate deinit")
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        logToDownloads("applicationDidFinishLaunching started")
        AppAppearanceManager.applyCurrent()
        setupStatusItem()
        prepareFallbackMainWindowControllerIfNeeded()
        setupHotkeyServices()
        registerShortcutsFromSettings()
        triggerObserver = NotificationCenter.default.addObserver(
            forName: LumiShotNotifications.triggerExtractOCR,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            logToDownloads("triggerExtractOCR notification received")
            self?.regionOCRCoordinator.beginSelection()
        }
        shortcutSettingsObserver = NotificationCenter.default.addObserver(
            forName: .appShortcutSettingsDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.registerShortcutsFromSettings()
        }
        openMainWindowObserver = NotificationCenter.default.addObserver(
            forName: LumiShotNotifications.requestOpenMainWindow,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            logToDownloads("requestOpenMainWindow notification received")
            self?.openMainAppWindowOnMainThread()
        }
        logToDownloads("applicationDidFinishLaunching finished")
    }

    func applicationWillTerminate(_ notification: Notification) {
        logToDownloads("applicationWillTerminate started")
        if let triggerObserver {
            NotificationCenter.default.removeObserver(triggerObserver)
        }
        if let shortcutSettingsObserver {
            NotificationCenter.default.removeObserver(shortcutSettingsObserver)
        }
        if let openMainWindowObserver {
            NotificationCenter.default.removeObserver(openMainWindowObserver)
        }
        for service in hotkeyServices.values {
            service.unregister()
        }
        logToDownloads("applicationWillTerminate finished")
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        .terminateNow
    }

    nonisolated func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    nonisolated func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }

    // Intercept "reopen" Apple Events (e.g. clicking the Dock icon while running windowless).
    // Returning false prevents SwiftUI's applicationOpenUntitledFile from trying to create a new
    // WindowGroup window, which crashes on macOS 26.x beta due to a @MainActor executor check bug
    // during the initial NSHostingView setup.
    nonisolated func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        logToDownloads("applicationShouldHandleReopen, hasVisibleWindows=\(flag)")
        guard !flag else { return false }
        DispatchQueue.main.async { [weak self] in
            self?.openMainAppWindowOnMainThread()
        }
        return false
    }

    @objc nonisolated private func openMainAppWindow() {
        DispatchQueue.main.async { [weak self] in
            self?.openMainAppWindowOnMainThread()
        }
    }

    private func openMainAppWindowOnMainThread() {
        logToDownloads("openMainAppWindowOnMainThread: begin")
        NSApp.unhide(nil)
        _ = NSRunningApplication.current.activate(options: [.activateAllWindows])
        prepareFallbackMainWindowControllerIfNeeded()
        if revealExistingWindow() == false {
            logToDownloads("openMainAppWindowOnMainThread: no reusable window, creating fallback")
            presentFallbackMainWindow()
        } else {
            logToDownloads("openMainAppWindowOnMainThread: reused existing window")
        }
    }

    @objc nonisolated private func quitApp() {
        DispatchQueue.main.async {
            NSApp.terminate(nil)
        }
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem?.button {
            let appIcon = NSApp.applicationIconImage.copy() as? NSImage
            appIcon?.size = NSSize(width: 18, height: 18)
            appIcon?.isTemplate = false
            button.image = appIcon
            button.imagePosition = .imageOnly
            button.toolTip = "LumiShot"
        }
        let menu = NSMenu()
        let reopenItem = NSMenuItem(title: "Reopen", action: #selector(openMainAppWindow), keyEquivalent: "")
        reopenItem.target = self
        menu.addItem(reopenItem)
        menu.addItem(NSMenuItem.separator())
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        statusItem?.menu = menu
    }

    private func setupHotkeyServices() {
        var idSeed: UInt32 = 1
        for action in AppShortcutAction.allCases where globalHotkeyActions.contains(action) {
            let service = GlobalHotkeyService(id: idSeed)
            idSeed += 1
            service.onHotkeyPressed = { [weak self] in
                DispatchQueue.main.async {
                    self?.dispatchHotkeyAction(action)
                }
            }
            hotkeyServices[action] = service
        }
    }

    private func dispatchHotkeyAction(_ action: AppShortcutAction) {
        logToDownloads("dispatchHotkeyAction called for action: \(action)")
        if action == .extractOCR {
            logToDownloads("dispatchHotkeyAction: posting extractOCR trigger")
            NotificationCenter.default.post(name: action.triggerNotification, object: nil)
            return
        }
        if action == .capture {
            // Do NOT activate LumiShot for capture hotkey; keep current foreground app.
            logToDownloads("dispatchHotkeyAction: ensuring capture support window without activation")
            ensureCaptureSupportWindowWithoutActivation()
            logToDownloads("dispatchHotkeyAction: posting capture trigger (no app activation)")
            NotificationCenter.default.post(name: action.triggerNotification, object: nil)
            return
        }
        openMainAppWindowOnMainThread()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            logToDownloads("dispatchHotkeyAction: posting trigger for action \(action)")
            NotificationCenter.default.post(name: action.triggerNotification, object: nil)
        }
    }

    private func registerShortcutsFromSettings() {
        for action in AppShortcutAction.allCases {
            guard globalHotkeyActions.contains(action) else {
                hotkeyServices[action]?.unregister()
                lastRegisteredShortcuts[action] = nil
                continue
            }
            let shortcut = AppShortcutStore.load(action).configuration
            if lastRegisteredShortcuts[action] == shortcut {
                continue
            }
            guard let service = hotkeyServices[action] else { continue }
            if service.register(shortcut: shortcut) {
                lastRegisteredShortcuts[action] = shortcut
                logToDownloads("registerShortcutsFromSettings: registered \(action) with key=\(shortcut.storageKey), cmd=\(shortcut.useCommand), shift=\(shortcut.useShift), opt=\(shortcut.useOption), ctrl=\(shortcut.useControl)")
            } else {
                lastRegisteredShortcuts[action] = nil
                logToDownloads("registerShortcutsFromSettings: failed to register \(action) with key=\(shortcut.storageKey)")
            }
        }
    }

    @discardableResult
    private func revealExistingWindow() -> Bool {
        let fallback = fallbackMainWindowController?.window
        let appWindows = NSApp.windows.filter { window in
            window.canBecomeMain && (window.contentViewController != nil || window.isVisible)
        }
        let primaryCandidates = appWindows.filter { window in
            guard let fallback else { return true }
            return window !== fallback
        }
        // Keep fallback as last resort only; otherwise it can create a duplicate visible main window.
        let candidates: [NSWindow]
        if primaryCandidates.isEmpty {
            candidates = fallback.map { [ $0 ] } ?? []
        } else {
            candidates = primaryCandidates
        }
        logToDownloads("revealExistingWindow: primary=\(primaryCandidates.count), fallbackIncluded=\(primaryCandidates.isEmpty && fallback != nil)")
        for target in candidates {
            normalizeMainWindowFrameIfNeeded(target)
            if target.isMiniaturized {
                target.deminiaturize(nil)
            }
            target.makeKeyAndOrderFront(nil)
            target.orderFrontRegardless()
            // If a candidate cannot become visible, continue and let fallback create a new window.
            if target.isVisible {
                logToDownloads("revealExistingWindow: success title=\(target.title)")
                return true
            }
        }
        logToDownloads("revealExistingWindow: no visible window after attempt")
        return false
    }

    private func presentFallbackMainWindow() {
        prepareFallbackMainWindowControllerIfNeeded()
        if let window = fallbackMainWindowController?.window {
            logToDownloads("presentFallbackMainWindow: reuse existing fallback window")
            normalizeMainWindowFrameIfNeeded(window)
            if window.isMiniaturized {
                window.deminiaturize(nil)
            }
            window.makeKeyAndOrderFront(nil)
            window.orderFrontRegardless()
            return
        }

        logToDownloads("presentFallbackMainWindow: fallback controller unavailable unexpectedly")
    }

    private func ensureCaptureSupportWindowWithoutActivation() {
        prepareFallbackMainWindowControllerIfNeeded()
        // Keep listener view alive, but do not steal focus from foreground app.
        fallbackMainWindowController?.window?.orderOut(nil)
    }

    private func prepareFallbackMainWindowControllerIfNeeded() {
        if fallbackMainWindowController == nil {
            fallbackMainWindowController = makeFallbackMainWindowController()
            logToDownloads("prepareFallbackMainWindowControllerIfNeeded: created fallback controller")
        }
        _ = fallbackMainWindowController?.window
        if let window = fallbackMainWindowController?.window {
            normalizeMainWindowFrameIfNeeded(window)
        }
    }

    private func normalizeMainWindowFrameIfNeeded(_ window: NSWindow) {
        let frame = window.frame
        let tooSmall = frame.width < Self.minimumMainWindowSize.width || frame.height < Self.minimumMainWindowSize.height
        guard tooSmall else { return }
        logToDownloads("normalizeMainWindowFrameIfNeeded: fixing abnormal frame=\(frame)")
        let targetSize = Self.defaultMainWindowSize
        if let screenFrame = window.screen?.visibleFrame ?? NSScreen.main?.visibleFrame {
            let x = screenFrame.midX - targetSize.width / 2
            let y = screenFrame.midY - targetSize.height / 2
            window.setFrame(NSRect(x: x, y: y, width: targetSize.width, height: targetSize.height), display: false)
        } else {
            window.setContentSize(targetSize)
        }
    }

    private func makeFallbackMainWindowController() -> NSWindowController {
        let window = NSWindow(
            contentRect: NSRect(origin: NSPoint(x: 140, y: 120), size: Self.defaultMainWindowSize),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "LumiShot"
        window.isReleasedWhenClosed = false
        window.setContentSize(Self.defaultMainWindowSize)
        window.minSize = Self.minimumMainWindowSize
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.contentViewController = NSHostingController(rootView: MainWindowView())
        return NSWindowController(window: window)
    }

}

private final class RegionOCRCoordinator {
    private let ocrEngine = VisionOCREngine()
    private var overlayController: SelectionOverlayWindowController?
    @MainActor private let statusPresenter = OCRStatusToastPresenter()

    func beginSelection() {
        logToDownloads("RegionOCRCoordinator.beginSelection started")
        guard overlayController == nil else { return }
        let controller = SelectionOverlayWindowController { [weak self] rect in
            self?.overlayController = nil
            guard let rect else { return }
            self?.performOCR(for: rect)
        }
        overlayController = controller
        controller.show()
        logToDownloads("RegionOCRCoordinator.beginSelection finished")
    }

    private func performOCR(for rect: CGRect) {
        let selectedRegion = rect.standardized
        guard selectedRegion.width > 8, selectedRegion.height > 8 else {
            logToDownloads("RegionOCRCoordinator.performOCR ignored tiny selection")
            return
        }
        logToDownloads("RegionOCRCoordinator.performOCR started rect=\(selectedRegion)")
        let engine = ocrEngine
        let statusPresenter = statusPresenter
        Task.detached { [engine] in
            try? await Task.sleep(for: .milliseconds(120))
            guard let image = CaptureService.defaultRegionImageProvider(region: selectedRegion) else {
                await MainActor.run {
                    logToDownloads("RegionOCRCoordinator.performOCR failed: capture image unavailable")
                    statusPresenter.show(success: false)
                    NotificationCenter.default.post(
                        name: LumiShotNotifications.didExtractOCRText,
                        object: nil,
                        userInfo: [LumiShotNotifications.extractedTextKey: ""]
                    )
                }
                return
            }
            let primaryResult = try? await engine.recognize(image: image, languageHints: ["zh-Hans", "en-US"])
            let fallbackResult = try? await engine.recognize(image: image, languageHints: [])
            let text = (primaryResult?.text ?? fallbackResult?.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let success = text.isEmpty == false
            await MainActor.run {
                logToDownloads("RegionOCRCoordinator.performOCR finished success=\(success) text_length=\(text.count)")
            }
            if text.isEmpty == false {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(text, forType: .string)
            }
            await MainActor.run {
                statusPresenter.show(success: success)
                NotificationCenter.default.post(
                    name: LumiShotNotifications.didExtractOCRText,
                    object: nil,
                    userInfo: [LumiShotNotifications.extractedTextKey: text]
                )
            }
        }
    }
}

@MainActor
private final class OCRStatusToastPresenter {
    private var panel: NSPanel?
    private var dismissWorkItem: DispatchWorkItem?

    func show(success: Bool) {
        dismissWorkItem?.cancel()

        let message = success ? "Text extraction succeeded" : "Text extraction failed"
        let content = OCRStatusToastView(message: message, success: success)
        let hostView = NSHostingView(rootView: content)
        hostView.translatesAutoresizingMaskIntoConstraints = false
        hostView.wantsLayer = true
        hostView.layer?.backgroundColor = NSColor.clear.cgColor
        let fitting = hostView.fittingSize
        let panelSize = NSSize(
            width: max(220, ceil(fitting.width)),
            height: max(78, ceil(fitting.height))
        )

        let panel = makeOrReusePanel()
        panel.setContentSize(panelSize)
        let container = NSView(frame: NSRect(origin: .zero, size: panelSize))
        container.wantsLayer = true
        container.layer?.backgroundColor = NSColor.clear.cgColor
        panel.contentView = container
        panel.contentView?.addSubview(hostView)
        NSLayoutConstraint.activate([
            hostView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            hostView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            hostView.topAnchor.constraint(equalTo: container.topAnchor),
            hostView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        position(panel: panel)
        panel.alphaValue = 0
        panel.orderFrontRegardless()

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.16
            panel.animator().alphaValue = 1
        }

        let work = DispatchWorkItem { [weak panel] in
            guard let panel else { return }
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.25
                panel.animator().alphaValue = 0
            }, completionHandler: {
                panel.orderOut(nil)
            })
        }
        dismissWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: work)
    }

    private func makeOrReusePanel() -> NSPanel {
        if let panel {
            return panel
        }
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 260, height: 78),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.level = .statusBar
        panel.ignoresMouseEvents = true
        panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient, .ignoresCycle]
        self.panel = panel
        return panel
    }

    private func position(panel: NSPanel) {
        let mousePoint = NSEvent.mouseLocation
        let targetScreen = NSScreen.screens.first(where: { $0.frame.contains(mousePoint) }) ?? NSScreen.main
        let visibleFrame = (targetScreen?.visibleFrame ?? NSScreen.screens.first?.visibleFrame) ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let x = visibleFrame.midX - panel.frame.width / 2
        let y = visibleFrame.minY + 64
        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }
}

private struct OCRStatusToastView: View {
    let message: String
    let success: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: success ? "checkmark.circle.fill" : "xmark.octagon.fill")
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(success ? Color.green : Color.red)
            Text(message)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.primary)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .stroke(Color.white.opacity(0.32), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.25), radius: 12, y: 6)
        .fixedSize(horizontal: true, vertical: false)
    }
}
