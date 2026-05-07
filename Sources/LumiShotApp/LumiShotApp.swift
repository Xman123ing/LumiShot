import SwiftUI
import LumiShotKit

@main
struct LumiShotAppMain: App {
    @NSApplicationDelegateAdaptor(LumiShotAppDelegate.self) private var appDelegate
    @AppStorage(OCRShortcutStorage.key) private var ocrShortcutKey: String = "e"
    @AppStorage(OCRShortcutStorage.useCommand) private var ocrShortcutUseCommand: Bool = true
    @AppStorage(OCRShortcutStorage.useShift) private var ocrShortcutUseShift: Bool = false
    @AppStorage(OCRShortcutStorage.useOption) private var ocrShortcutUseOption: Bool = false
    @AppStorage(OCRShortcutStorage.useControl) private var ocrShortcutUseControl: Bool = false

    var body: some Scene {
        WindowGroup("LumiShot") {
            MainWindowView()
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1180, height: 760)
        .commands {
            let shortcut = OCRShortcutConfiguration(
                storageKey: ocrShortcutKey,
                useCommand: ocrShortcutUseCommand,
                useShift: ocrShortcutUseShift,
                useOption: ocrShortcutUseOption,
                useControl: ocrShortcutUseControl
            )
            CommandMenu("LumiShot") {
                Button("Extract OCR") {
                    NotificationCenter.default.post(name: LumiShotNotifications.triggerExtractOCR, object: nil)
                }
                .keyboardShortcut(shortcut.key, modifiers: shortcut.modifiers)
            }
        }

        Settings {
            OCRShortcutSettingsView()
        }
    }
}
