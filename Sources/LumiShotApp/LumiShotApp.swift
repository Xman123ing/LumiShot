import SwiftUI
import LumiShot

@main
struct LumiShotAppMain: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup("LumiShot") {
            MainWindowView()
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1180, height: 760)
    }
}
