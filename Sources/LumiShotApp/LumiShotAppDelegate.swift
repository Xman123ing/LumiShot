import AppKit
import Carbon
import LumiShotKit

@MainActor
final class LumiShotAppDelegate: NSObject, NSApplicationDelegate {
    private let regionOCRCoordinator = RegionOCRCoordinator()
    private var userDefaultsObserver: NSObjectProtocol?
    private var triggerObserver: NSObjectProtocol?
    private var hotkeyServices: [AppShortcutAction: GlobalHotkeyService] = [:]
    private var lastRegisteredShortcuts: [AppShortcutAction: OCRShortcutConfiguration] = [:]
    private var statusItem: NSStatusItem?
    private var statusMenu: NSMenu?
    private let globalHotkeyActions: Set<AppShortcutAction> = [.capture, .extractOCR]

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        setupHotkeyServices()
        registerShortcutsFromSettings()
        userDefaultsObserver = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.registerShortcutsFromSettings()
            }
        }
        triggerObserver = NotificationCenter.default.addObserver(
            forName: LumiShotNotifications.triggerExtractOCR,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.regionOCRCoordinator.beginSelection()
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let userDefaultsObserver {
            NotificationCenter.default.removeObserver(userDefaultsObserver)
        }
        if let triggerObserver {
            NotificationCenter.default.removeObserver(triggerObserver)
        }
        for service in hotkeyServices.values {
            service.unregister()
        }
    }

    private func setupStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Open App", action: #selector(openMainAppWindow), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))
        menu.items.forEach { $0.target = self }
        if let button = item.button {
            let appIcon = NSApp.applicationIconImage.copy() as? NSImage
            appIcon?.size = NSSize(width: 18, height: 18)
            appIcon?.isTemplate = false
            button.image = appIcon
            button.action = #selector(handleStatusItemClick(_:))
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        statusItem = item
        statusMenu = menu
    }

    @objc
    private func handleStatusItemClick(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else {
            openMainAppWindow()
            return
        }
        if event.type == .rightMouseUp || event.modifierFlags.contains(.control) {
            if let statusMenu, let statusItem {
                statusItem.menu = statusMenu
                statusItem.button?.performClick(nil)
                statusItem.menu = nil
            }
        } else {
            openMainAppWindow()
        }
    }

    @objc
    private func openMainAppWindow() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.windows.forEach { $0.makeKeyAndOrderFront(nil) }
    }

    @objc
    private func quitApp() {
        NSApp.terminate(nil)
    }

    private func setupHotkeyServices() {
        var idSeed: UInt32 = 1
        for action in AppShortcutAction.allCases where globalHotkeyActions.contains(action) {
            let service = GlobalHotkeyService(id: idSeed)
            idSeed += 1
            service.onHotkeyPressed = { [weak self] in
                Task { @MainActor in
                    self?.dispatchHotkeyAction(action)
                }
            }
            hotkeyServices[action] = service
        }
    }

    private func dispatchHotkeyAction(_ action: AppShortcutAction) {
        if action == .extractOCR || action == .capture {
            NotificationCenter.default.post(name: action.triggerNotification, object: nil)
            return
        }
        openMainAppWindow()
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

@MainActor
private final class RegionOCRCoordinator {
    private let ocrEngine = VisionOCREngine()
    private var overlayController: SelectionOverlayWindowController?
    private var temporarilyHiddenWindows: [NSWindow] = []
    private var wasAppActiveWhenSelectionStarted = false

    func beginSelection() {
        guard overlayController == nil else { return }
        wasAppActiveWhenSelectionStarted = NSApp.isActive
        temporarilyHiddenWindows = NSApp.windows.filter { $0.isVisible }
        for window in temporarilyHiddenWindows {
            window.orderOut(nil)
        }
        let controller = SelectionOverlayWindowController { [weak self] rect in
            self?.overlayController = nil
            self?.performOCR(for: rect) { [weak self] in
                self?.restoreHiddenWindows()
            }
        }
        overlayController = controller
        controller.show()
    }

    private func performOCR(for rect: CGRect, onFinished: @escaping @MainActor () -> Void) {
        let selectedRegion = rect.standardized
        guard selectedRegion.width > 8, selectedRegion.height > 8 else {
            onFinished()
            return
        }

        let engine = ocrEngine
        Task { [engine] in
            defer {
                Task { @MainActor in
                    onFinished()
                }
            }
            // Wait a frame so the overlay window fully disappears before capture.
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

    @MainActor
    private func restoreHiddenWindows() {
        let windows = temporarilyHiddenWindows
        temporarilyHiddenWindows = []
        guard !windows.isEmpty else { return }
        if wasAppActiveWhenSelectionStarted {
            windows.forEach { $0.makeKeyAndOrderFront(nil) }
        } else {
            windows.forEach { $0.orderBack(nil) }
        }
    }
}
