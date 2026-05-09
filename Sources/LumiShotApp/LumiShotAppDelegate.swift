@preconcurrency import AppKit
import Carbon
import LumiShotKit

final class LumiShotAppDelegate: NSObject, NSApplicationDelegate {
    private let regionOCRCoordinator = RegionOCRCoordinator()
    private var triggerObserver: NSObjectProtocol?
    private var hotkeyServices: [AppShortcutAction: GlobalHotkeyService] = [:]
    private var lastRegisteredShortcuts: [AppShortcutAction: OCRShortcutConfiguration] = [:]
    private let globalHotkeyActions: Set<AppShortcutAction> = [.capture, .extractOCR]
    private var statusItem: NSStatusItem?

    deinit {
        logToDownloads("LumiShotAppDelegate deinit")
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        logToDownloads("applicationDidFinishLaunching started")
        AppAppearanceManager.applyCurrent()
        setupStatusItem()
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
        logToDownloads("applicationDidFinishLaunching finished")
    }

    func applicationWillTerminate(_ notification: Notification) {
        logToDownloads("applicationWillTerminate started")
        if let triggerObserver {
            NotificationCenter.default.removeObserver(triggerObserver)
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
        NSApp.unhide(nil)
        _ = NSRunningApplication.current.activate(options: [.activateAllWindows])
        NSApp.mainWindow?.makeKeyAndOrderFront(nil)
        NSApp.keyWindow?.makeKeyAndOrderFront(nil)
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
        let openItem = NSMenuItem(title: "Open App", action: #selector(openMainAppWindow), keyEquivalent: "")
        openItem.target = self
        menu.addItem(openItem)
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
        if action == .extractOCR || action == .capture {
            NotificationCenter.default.post(name: action.triggerNotification, object: nil)
            return
        }
        openMainAppWindowOnMainThread()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
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
            } else {
                lastRegisteredShortcuts[action] = nil
            }
        }
    }

}

private final class RegionOCRCoordinator {
    private let ocrEngine = VisionOCREngine()
    private var overlayController: SelectionOverlayWindowController?
    private var didHideMainWindow = false
    private weak var hiddenMainWindow: NSWindow?
    private var wasAppActiveWhenSelectionStarted = false

    func beginSelection() {
        logToDownloads("RegionOCRCoordinator.beginSelection started")
        guard overlayController == nil else { return }
        wasAppActiveWhenSelectionStarted = NSApp.isActive
        didHideMainWindow = false
        hiddenMainWindow = NSApp.mainWindow ?? NSApp.keyWindow
        if let mainWindow = hiddenMainWindow, mainWindow.isVisible {
            mainWindow.orderOut(nil)
            didHideMainWindow = true
        }
        let controller = SelectionOverlayWindowController { [weak self] rect in
            self?.overlayController = nil
            self?.performOCR(for: rect) { [weak self] in
                self?.restoreHiddenWindows()
            }
        }
        overlayController = controller
        controller.show()
        logToDownloads("RegionOCRCoordinator.beginSelection finished")
    }

    private func performOCR(for rect: CGRect, onFinished: @escaping () -> Void) {
        let selectedRegion = rect.standardized
        guard selectedRegion.width > 8, selectedRegion.height > 8 else {
            onFinished()
            return
        }
        let engine = ocrEngine
        Task.detached { [engine] in
            defer {
                DispatchQueue.main.async { onFinished() }
            }
            try? await Task.sleep(for: .milliseconds(120))
            guard let image = CaptureService.defaultRegionImageProvider(region: selectedRegion) else { return }
            let primaryResult = try? await engine.recognize(image: image, languageHints: ["zh-Hans", "en-US"])
            let fallbackResult = try? await engine.recognize(image: image, languageHints: [])
            let text = (primaryResult?.text ?? fallbackResult?.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            if text.isEmpty == false {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(text, forType: .string)
            }
            NotificationCenter.default.post(
                name: LumiShotNotifications.didExtractOCRText,
                object: nil,
                userInfo: [LumiShotNotifications.extractedTextKey: text]
            )
        }
    }

    private func restoreHiddenWindows() {
        if wasAppActiveWhenSelectionStarted {
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
}
