import Foundation

enum AppAppearanceMode: String, CaseIterable, Identifiable {
    case auto
    case light
    case dark

    static let defaultsKey = "settings.appearance.mode"

    var id: String { rawValue }

    var displayTitle: String {
        switch self {
        case .auto:
            return "Auto"
        case .light:
            return "Light"
        case .dark:
            return "Dark"
        }
    }
}
