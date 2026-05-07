import SwiftUI
import LumiShotKit

@main
struct LumiShotAppMain: App {
    @NSApplicationDelegateAdaptor(LumiShotAppDelegate.self) private var appDelegate

    @AppStorage("settings.shortcut.capture.key") private var captureShortcutKey: String = "r"
    @AppStorage("settings.shortcut.capture.useCommand") private var captureShortcutUseCommand: Bool = true
    @AppStorage("settings.shortcut.capture.useShift") private var captureShortcutUseShift: Bool = true
    @AppStorage("settings.shortcut.capture.useOption") private var captureShortcutUseOption: Bool = false
    @AppStorage("settings.shortcut.capture.useControl") private var captureShortcutUseControl: Bool = false

    @AppStorage("settings.shortcut.copy.key") private var copyShortcutKey: String = "c"
    @AppStorage("settings.shortcut.copy.useCommand") private var copyShortcutUseCommand: Bool = true
    @AppStorage("settings.shortcut.copy.useShift") private var copyShortcutUseShift: Bool = false
    @AppStorage("settings.shortcut.copy.useOption") private var copyShortcutUseOption: Bool = false
    @AppStorage("settings.shortcut.copy.useControl") private var copyShortcutUseControl: Bool = false

    @AppStorage("settings.shortcut.save.key") private var saveShortcutKey: String = "s"
    @AppStorage("settings.shortcut.save.useCommand") private var saveShortcutUseCommand: Bool = true
    @AppStorage("settings.shortcut.save.useShift") private var saveShortcutUseShift: Bool = false
    @AppStorage("settings.shortcut.save.useOption") private var saveShortcutUseOption: Bool = false
    @AppStorage("settings.shortcut.save.useControl") private var saveShortcutUseControl: Bool = false

    @AppStorage(OCRShortcutStorage.key) private var ocrShortcutKey: String = OCRShortcutConfiguration.defaultStorageKey
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
            let captureShortcut = OCRShortcutConfiguration(
                storageKey: captureShortcutKey,
                useCommand: captureShortcutUseCommand,
                useShift: captureShortcutUseShift,
                useOption: captureShortcutUseOption,
                useControl: captureShortcutUseControl
            )
            let copyShortcut = OCRShortcutConfiguration(
                storageKey: copyShortcutKey,
                useCommand: copyShortcutUseCommand,
                useShift: copyShortcutUseShift,
                useOption: copyShortcutUseOption,
                useControl: copyShortcutUseControl
            )
            let saveShortcut = OCRShortcutConfiguration(
                storageKey: saveShortcutKey,
                useCommand: saveShortcutUseCommand,
                useShift: saveShortcutUseShift,
                useOption: saveShortcutUseOption,
                useControl: saveShortcutUseControl
            )
            let ocrShortcut = OCRShortcutConfiguration(
                storageKey: ocrShortcutKey,
                useCommand: ocrShortcutUseCommand,
                useShift: ocrShortcutUseShift,
                useOption: ocrShortcutUseOption,
                useControl: ocrShortcutUseControl
            )
            CommandMenu("LumiShot") {
                Button("Capture Screenshot") {
                    NotificationCenter.default.post(name: LumiShotNotifications.triggerCapture, object: nil)
                }
                .keyboardShortcut(captureShortcut.key, modifiers: captureShortcut.modifiers)

                Button("Copy Capture") {
                    NotificationCenter.default.post(name: LumiShotNotifications.triggerCopyCapture, object: nil)
                }
                .keyboardShortcut(copyShortcut.key, modifiers: copyShortcut.modifiers)

                Button("Save Capture") {
                    NotificationCenter.default.post(name: LumiShotNotifications.triggerSaveCapture, object: nil)
                }
                .keyboardShortcut(saveShortcut.key, modifiers: saveShortcut.modifiers)

                Divider()

                Button("Extract OCR") {
                    NotificationCenter.default.post(name: LumiShotNotifications.triggerExtractOCR, object: nil)
                }
                .keyboardShortcut(ocrShortcut.key, modifiers: ocrShortcut.modifiers)
            }
        }

        Settings {
            OCRShortcutSettingsView()
        }
    }
}
