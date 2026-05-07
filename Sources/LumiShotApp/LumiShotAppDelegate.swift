import AppKit
import Carbon
import LumiShotKit

@MainActor
final class LumiShotAppDelegate: NSObject, NSApplicationDelegate {
    private let hotkeyService = GlobalHotkeyService()
    private let regionOCRCoordinator = RegionOCRCoordinator()
    private var userDefaultsObserver: NSObjectProtocol?
    private var triggerObserver: NSObjectProtocol?
    private var lastRegisteredOCRShortcut: OCRShortcutConfiguration?

    func applicationDidFinishLaunching(_ notification: Notification) {
        registerShortcutFromSettings()
        userDefaultsObserver = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.registerShortcutFromSettings()
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
        hotkeyService.onHotkeyPressed = { [weak self] in
            Task { @MainActor [weak self] in
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
        hotkeyService.unregister()
    }

    private func registerShortcutFromSettings() {
        let shortcut = OCRShortcutConfiguration.load()
        guard shortcut != lastRegisteredOCRShortcut else { return }
        if hotkeyService.register(shortcut: shortcut) {
            lastRegisteredOCRShortcut = shortcut
        } else {
            lastRegisteredOCRShortcut = nil
        }
    }
}

@MainActor
private final class RegionOCRCoordinator {
    private let ocrEngine = VisionOCREngine()
    private var overlayController: SelectionOverlayWindowController?

    func beginSelection() {
        guard overlayController == nil else { return }
        let controller = SelectionOverlayWindowController { [weak self] rect in
            self?.overlayController = nil
            self?.performOCR(for: rect)
        }
        overlayController = controller
        controller.show()
    }

    private func performOCR(for rect: CGRect) {
        guard rect.width > 8, rect.height > 8 else { return }
        guard let image = CGWindowListCreateImage(
            rect,
            .optionOnScreenOnly,
            kCGNullWindowID,
            [.bestResolution]
        ) else { return }
        let engine = ocrEngine
        Task { [engine] in
            let result = try? await engine.recognize(image: image, languageHints: ["zh-Hans", "en-US"])
            let text = result?.text ?? ""
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(text, forType: .string)
            NotificationCenter.default.post(
                name: LumiShotNotifications.didExtractOCRText,
                object: nil,
                userInfo: [LumiShotNotifications.extractedTextKey: text]
            )
            await MainActor.run {
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }
}
