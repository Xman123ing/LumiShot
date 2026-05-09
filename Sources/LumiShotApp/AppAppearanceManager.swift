import AppKit

@MainActor
enum AppAppearanceManager {
    static func currentMode(defaults: UserDefaults = .standard) -> AppAppearanceMode {
        let raw = defaults.string(forKey: AppAppearanceMode.defaultsKey) ?? AppAppearanceMode.auto.rawValue
        return AppAppearanceMode(rawValue: raw) ?? .auto
    }

    static func applyCurrent(defaults: UserDefaults = .standard) {
        apply(mode: currentMode(defaults: defaults))
    }

    static func apply(mode: AppAppearanceMode) {
        switch mode {
        case .auto:
            NSApp.appearance = nil
        case .light:
            NSApp.appearance = NSAppearance(named: .aqua)
        case .dark:
            NSApp.appearance = NSAppearance(named: .darkAqua)
        }
    }
}
