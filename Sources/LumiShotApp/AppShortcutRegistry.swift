import Foundation
import LumiShotKit

extension Notification.Name {
    static let appShortcutSettingsDidChange = Notification.Name("app.shortcut.settings.did.change")
}

enum AppShortcutAction: CaseIterable {
    case capture
    case copy
    case save
    case extractOCR

    var title: String {
        switch self {
        case .capture: return "Capture Screenshot"
        case .copy: return "Copy Capture"
        case .save: return "Save Capture"
        case .extractOCR: return "Extract OCR"
        }
    }

    var triggerNotification: Notification.Name {
        switch self {
        case .capture:
            return LumiShotNotifications.triggerCapture
        case .copy:
            return LumiShotNotifications.triggerCopyCapture
        case .save:
            return LumiShotNotifications.triggerSaveCapture
        case .extractOCR:
            return LumiShotNotifications.triggerExtractOCR
        }
    }

    var defaults: (key: String, useCommand: Bool, useShift: Bool, useOption: Bool, useControl: Bool) {
        switch self {
        case .capture:
            return ("r", true, true, false, false)
        case .copy:
            return ("c", true, false, false, false)
        case .save:
            return ("s", true, false, false, false)
        case .extractOCR:
            return (OCRShortcutConfiguration.defaultStorageKey, true, false, false, false)
        }
    }

    var keyStorage: String {
        switch self {
        case .capture: return "settings.shortcut.capture.key"
        case .copy: return "settings.shortcut.copy.key"
        case .save: return "settings.shortcut.save.key"
        case .extractOCR: return OCRShortcutStorage.key
        }
    }

    var commandStorage: String {
        switch self {
        case .capture: return "settings.shortcut.capture.useCommand"
        case .copy: return "settings.shortcut.copy.useCommand"
        case .save: return "settings.shortcut.save.useCommand"
        case .extractOCR: return OCRShortcutStorage.useCommand
        }
    }

    var shiftStorage: String {
        switch self {
        case .capture: return "settings.shortcut.capture.useShift"
        case .copy: return "settings.shortcut.copy.useShift"
        case .save: return "settings.shortcut.save.useShift"
        case .extractOCR: return OCRShortcutStorage.useShift
        }
    }

    var optionStorage: String {
        switch self {
        case .capture: return "settings.shortcut.capture.useOption"
        case .copy: return "settings.shortcut.copy.useOption"
        case .save: return "settings.shortcut.save.useOption"
        case .extractOCR: return OCRShortcutStorage.useOption
        }
    }

    var controlStorage: String {
        switch self {
        case .capture: return "settings.shortcut.capture.useControl"
        case .copy: return "settings.shortcut.copy.useControl"
        case .save: return "settings.shortcut.save.useControl"
        case .extractOCR: return OCRShortcutStorage.useControl
        }
    }
}

struct AppShortcutRecord {
    var key: String
    var useCommand: Bool
    var useShift: Bool
    var useOption: Bool
    var useControl: Bool

    var configuration: OCRShortcutConfiguration {
        OCRShortcutConfiguration(
            storageKey: key,
            useCommand: useCommand,
            useShift: useShift,
            useOption: useOption,
            useControl: useControl
        )
    }
}

enum AppShortcutStore {
    static func load(_ action: AppShortcutAction, defaults: UserDefaults = .standard) -> AppShortcutRecord {
        let base = action.defaults
        let hasCommandSetting = defaults.object(forKey: action.commandStorage) != nil
        return AppShortcutRecord(
            key: defaults.string(forKey: action.keyStorage) ?? base.key,
            useCommand: hasCommandSetting ? defaults.bool(forKey: action.commandStorage) : base.useCommand,
            useShift: defaults.object(forKey: action.shiftStorage) != nil ? defaults.bool(forKey: action.shiftStorage) : base.useShift,
            useOption: defaults.object(forKey: action.optionStorage) != nil ? defaults.bool(forKey: action.optionStorage) : base.useOption,
            useControl: defaults.object(forKey: action.controlStorage) != nil ? defaults.bool(forKey: action.controlStorage) : base.useControl
        )
    }

    static func save(_ action: AppShortcutAction, record: AppShortcutRecord, defaults: UserDefaults = .standard) {
        defaults.set(record.configuration.storageKey, forKey: action.keyStorage)
        defaults.set(record.useCommand, forKey: action.commandStorage)
        defaults.set(record.useShift, forKey: action.shiftStorage)
        defaults.set(record.useOption, forKey: action.optionStorage)
        defaults.set(record.useControl, forKey: action.controlStorage)
    }
}
