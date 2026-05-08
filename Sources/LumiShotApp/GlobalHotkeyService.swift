import Carbon
import LumiShotKit
import os

private let globalHotkeyLogger = Logger(subsystem: "com.lumishot.LumiShot", category: "GlobalHotkey")

final class GlobalHotkeyService {
    var onHotkeyPressed: (() -> Void)?

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private var hotKeyID: EventHotKeyID

    init(id: UInt32) {
        hotKeyID = EventHotKeyID(signature: OSType(0x4C554D49), id: id) // "LUMI"
    }

    @discardableResult
    func register(shortcut: OCRShortcutConfiguration) -> Bool {
        unregister()

        guard let keyCode = KeyCodeMapper.keyCode(for: shortcut.storageKey.lowercased()) else {
            globalHotkeyLogger.debug("Unsupported hotkey storageKey: \(shortcut.storageKey)")
            return false
        }

        if eventHandler == nil {
            var eventSpec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
            let installStatus = InstallEventHandler(
                GetApplicationEventTarget(),
                { _, eventRef, userData in
                    guard let userData else { return OSStatus(eventNotHandledErr) }
                    let service = Unmanaged<GlobalHotkeyService>.fromOpaque(userData).takeUnretainedValue()
                    var hotKeyID = EventHotKeyID()
                    let status = GetEventParameter(
                        eventRef,
                        EventParamName(kEventParamDirectObject),
                        EventParamType(typeEventHotKeyID),
                        nil,
                        MemoryLayout<EventHotKeyID>.size,
                        nil,
                        &hotKeyID
                    )
                    if status == noErr && hotKeyID.id == service.hotKeyID.id {
                        service.onHotkeyPressed?()
                        return noErr
                    }
                    return OSStatus(eventNotHandledErr)
                },
                1,
                &eventSpec,
                UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()),
                &eventHandler
            )
            if installStatus != noErr {
                globalHotkeyLogger.debug("InstallEventHandler failed: \(installStatus)")
                return false
            }
        }

        let registerStatus = RegisterEventHotKey(
            UInt32(keyCode),
            carbonModifiers(from: shortcut),
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
        if registerStatus != noErr {
            globalHotkeyLogger.debug("RegisterEventHotKey failed: \(registerStatus)")
            return false
        }
        return true
    }

    func unregister() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
    }

    private func carbonModifiers(from shortcut: OCRShortcutConfiguration) -> UInt32 {
        var modifiers: UInt32 = 0
        if shortcut.useCommand { modifiers |= UInt32(cmdKey) }
        if shortcut.useShift { modifiers |= UInt32(shiftKey) }
        if shortcut.useOption { modifiers |= UInt32(optionKey) }
        if shortcut.useControl { modifiers |= UInt32(controlKey) }
        return modifiers
    }
}

private enum KeyCodeMapper {
    static func keyCode(for key: String) -> Int? {
        switch key {
        case "a": return kVK_ANSI_A
        case "b": return kVK_ANSI_B
        case "c": return kVK_ANSI_C
        case "d": return kVK_ANSI_D
        case "e": return kVK_ANSI_E
        case "f": return kVK_ANSI_F
        case "g": return kVK_ANSI_G
        case "h": return kVK_ANSI_H
        case "i": return kVK_ANSI_I
        case "j": return kVK_ANSI_J
        case "k": return kVK_ANSI_K
        case "l": return kVK_ANSI_L
        case "m": return kVK_ANSI_M
        case "n": return kVK_ANSI_N
        case "o": return kVK_ANSI_O
        case "p": return kVK_ANSI_P
        case "q": return kVK_ANSI_Q
        case "r": return kVK_ANSI_R
        case "s": return kVK_ANSI_S
        case "t": return kVK_ANSI_T
        case "u": return kVK_ANSI_U
        case "v": return kVK_ANSI_V
        case "w": return kVK_ANSI_W
        case "x": return kVK_ANSI_X
        case "y": return kVK_ANSI_Y
        case "z": return kVK_ANSI_Z
        case "0": return kVK_ANSI_0
        case "1": return kVK_ANSI_1
        case "2": return kVK_ANSI_2
        case "3": return kVK_ANSI_3
        case "4": return kVK_ANSI_4
        case "5": return kVK_ANSI_5
        case "6": return kVK_ANSI_6
        case "7": return kVK_ANSI_7
        case "8": return kVK_ANSI_8
        case "9": return kVK_ANSI_9
        default: return nil
        }
    }
}
