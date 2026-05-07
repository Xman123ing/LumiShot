import Foundation
import SwiftUI

public enum OCRShortcutStorage {
    public static let key = "settings.ocrShortcut.key"
    public static let useCommand = "settings.ocrShortcut.useCommand"
    public static let useShift = "settings.ocrShortcut.useShift"
    public static let useOption = "settings.ocrShortcut.useOption"
    public static let useControl = "settings.ocrShortcut.useControl"
}

public struct OCRShortcutConfiguration: Equatable {
    public static let defaultStorageKey = "e"

    public let storageKey: String
    public let key: KeyEquivalent
    public let modifiers: SwiftUI.EventModifiers
    public let useCommand: Bool
    public let useShift: Bool
    public let useOption: Bool
    public let useControl: Bool

    /// Normalizes a stored key to a single ASCII letter or digit for menu items and Carbon hotkeys.
    public static func normalizedStorageKey(_ raw: String?) -> String {
        guard let raw else { return defaultStorageKey }
        for c in raw.lowercased() {
            switch c {
            case "a"..."z", "0"..."9": return String(c)
            default: continue
            }
        }
        return defaultStorageKey
    }

    public init(storageKey: String?, useCommand: Bool, useShift: Bool, useOption: Bool, useControl: Bool) {
        self.storageKey = Self.normalizedStorageKey(storageKey)
        let rawKey = self.storageKey.first ?? Character(Self.defaultStorageKey)
        self.key = KeyEquivalent(rawKey)
        var eventModifiers: SwiftUI.EventModifiers = []
        if useCommand { eventModifiers.insert(.command) }
        if useShift { eventModifiers.insert(.shift) }
        if useOption { eventModifiers.insert(.option) }
        if useControl { eventModifiers.insert(.control) }
        self.modifiers = eventModifiers
        self.useCommand = useCommand
        self.useShift = useShift
        self.useOption = useOption
        self.useControl = useControl
    }

    public static func load(from defaults: UserDefaults = .standard) -> OCRShortcutConfiguration {
        let hasCommandSetting = defaults.object(forKey: OCRShortcutStorage.useCommand) != nil
        return OCRShortcutConfiguration(
            storageKey: defaults.string(forKey: OCRShortcutStorage.key),
            useCommand: hasCommandSetting ? defaults.bool(forKey: OCRShortcutStorage.useCommand) : true,
            useShift: defaults.bool(forKey: OCRShortcutStorage.useShift),
            useOption: defaults.bool(forKey: OCRShortcutStorage.useOption),
            useControl: defaults.bool(forKey: OCRShortcutStorage.useControl)
        )
    }
}
