import SwiftUI
import LumiShotKit

@main
struct LumiShotAppMain: App {
    @NSApplicationDelegateAdaptor(LumiShotAppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup("LumiShot") {
            MainWindowView()
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1180, height: 760)
        .commands {
            CommandMenu("LumiShot") {
                Button("Capture Screenshot") {
                    NotificationCenter.default.post(name: LumiShotNotifications.triggerCapture, object: nil)
                }

                Button("Copy Capture") {
                    NotificationCenter.default.post(name: LumiShotNotifications.triggerCopyCapture, object: nil)
                }

                Button("Save Capture") {
                    NotificationCenter.default.post(name: LumiShotNotifications.triggerSaveCapture, object: nil)
                }

                Divider()

                Button("Extract OCR") {
                    NotificationCenter.default.post(name: LumiShotNotifications.triggerExtractOCR, object: nil)
                }

                Divider()

                Button("Undo Annotation") {
                    NotificationCenter.default.post(name: LumiShotNotifications.triggerUndoAnnotation, object: nil)
                }
                .keyboardShortcut("z", modifiers: [.command])
            }
        }

        Settings {
            SettingsView()
        }
    }
}
