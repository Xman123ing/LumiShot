import Carbon
import LumiShotKit
import SwiftUI

struct SettingsView: View {
    private static let configurableActions: [AppShortcutAction] = [.capture, .extractOCR]
    @State private var recordingAction: AppShortcutAction?
    @State private var isRecording = false
    @State private var localMonitor: Any?
    @AppStorage(AppAppearanceMode.defaultsKey) private var appearanceModeRawValue = AppAppearanceMode.auto.rawValue
    @State private var shortcuts: [AppShortcutAction: AppShortcutRecord] = {
        var map: [AppShortcutAction: AppShortcutRecord] = [:]
        for action in Self.configurableActions {
            map[action] = AppShortcutStore.load(action)
        }
        return map
    }()
    
    private static let recorderModifierMask: NSEvent.ModifierFlags = [.command, .shift, .option, .control]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Settings")
                .font(.title3.weight(.semibold))
                .padding(.horizontal)
                .padding(.top, 8)

            List {
                Section("Appearance") {
                    Picker("Theme", selection: $appearanceModeRawValue) {
                        ForEach(AppAppearanceMode.allCases) { mode in
                            Text(mode.displayTitle).tag(mode.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)

                    Text("Auto follows the current macOS Light/Dark appearance.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Shortcut Module") {
                    ForEach(Self.configurableActions, id: \.self) { action in
                        Button {
                            startRecording(for: action)
                        } label: {
                            HStack {
                                Text(action.title)
                                Spacer()
                                Text(shortcutLabel(for: action))
                                    .foregroundStyle(.secondary)
                                    .monospacedDigit()
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .help("Click to record a shortcut")
                    }
                }
            }
            .listStyle(.inset)

            if isRecording {
                Text("Recording \(recordingAction?.title ?? "shortcut")... press a letter/number, or Esc to cancel.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            }

            HStack {
                Spacer()
                Button("Reset to Default") {
                    stopRecording()
                    resetToDefault()
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal)
            .padding(.bottom, 12)
        }
        .frame(width: 420, height: 340)
        .onDisappear {
            stopRecording()
        }
        .onAppear {
            AppAppearanceManager.applyCurrent()
        }
        .onChange(of: appearanceModeRawValue) { _, newValue in
            let mode = AppAppearanceMode(rawValue: newValue) ?? .auto
            AppAppearanceManager.apply(mode: mode)
        }
    }

    private func formattedLabel(for record: AppShortcutRecord) -> String {
        var parts: [String] = []
        if record.useControl { parts.append("Control") }
        if record.useOption { parts.append("Option") }
        if record.useShift { parts.append("Shift") }
        if record.useCommand { parts.append("Command") }
        parts.append(record.configuration.storageKey.uppercased())
        return parts.joined(separator: " + ")
    }

    private func shortcutLabel(for action: AppShortcutAction) -> String {
        guard let record = shortcuts[action] else { return "-" }
        return formattedLabel(for: record)
    }

    private func startRecording(for action: AppShortcutAction) {
        stopRecording()
        recordingAction = action
        isRecording = true
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == 53 { // kVK_Escape
                stopRecording()
                return event
            }

            let flags = event.modifierFlags.intersection(Self.recorderModifierMask)
            guard let key = RecorderKeyMapper.storageKey(for: event.keyCode) else {
                return event
            }
            applyRecordedShortcut(action: action, key: key, flags: flags)
            stopRecording()
            return nil
        }
    }

    private func stopRecording() {
        if let localMonitor {
            NSEvent.removeMonitor(localMonitor)
            self.localMonitor = nil
        }
        recordingAction = nil
        isRecording = false
    }

    private func applyRecordedShortcut(action: AppShortcutAction, key: String, flags: NSEvent.ModifierFlags) {
        let record = AppShortcutRecord(
            key: key,
            useCommand: flags.contains(.command),
            useShift: flags.contains(.shift),
            useOption: flags.contains(.option),
            useControl: flags.contains(.control)
        )
        shortcuts[action] = record
        AppShortcutStore.save(action, record: record)
        NotificationCenter.default.post(name: .appShortcutSettingsDidChange, object: nil)
    }

    private func resetToDefault() {
        for action in Self.configurableActions {
            let d = action.defaults
            let record = AppShortcutRecord(
                key: d.key,
                useCommand: d.useCommand,
                useShift: d.useShift,
                useOption: d.useOption,
                useControl: d.useControl
            )
            shortcuts[action] = record
            AppShortcutStore.save(action, record: record)
        }
        NotificationCenter.default.post(name: .appShortcutSettingsDidChange, object: nil)
    }
}

private enum RecorderKeyMapper {
    static func storageKey(for keyCode: UInt16) -> String? {
        switch Int(keyCode) {
        case kVK_ANSI_A: return "a"
        case kVK_ANSI_B: return "b"
        case kVK_ANSI_C: return "c"
        case kVK_ANSI_D: return "d"
        case kVK_ANSI_E: return "e"
        case kVK_ANSI_F: return "f"
        case kVK_ANSI_G: return "g"
        case kVK_ANSI_H: return "h"
        case kVK_ANSI_I: return "i"
        case kVK_ANSI_J: return "j"
        case kVK_ANSI_K: return "k"
        case kVK_ANSI_L: return "l"
        case kVK_ANSI_M: return "m"
        case kVK_ANSI_N: return "n"
        case kVK_ANSI_O: return "o"
        case kVK_ANSI_P: return "p"
        case kVK_ANSI_Q: return "q"
        case kVK_ANSI_R: return "r"
        case kVK_ANSI_S: return "s"
        case kVK_ANSI_T: return "t"
        case kVK_ANSI_U: return "u"
        case kVK_ANSI_V: return "v"
        case kVK_ANSI_W: return "w"
        case kVK_ANSI_X: return "x"
        case kVK_ANSI_Y: return "y"
        case kVK_ANSI_Z: return "z"
        case kVK_ANSI_0: return "0"
        case kVK_ANSI_1: return "1"
        case kVK_ANSI_2: return "2"
        case kVK_ANSI_3: return "3"
        case kVK_ANSI_4: return "4"
        case kVK_ANSI_5: return "5"
        case kVK_ANSI_6: return "6"
        case kVK_ANSI_7: return "7"
        case kVK_ANSI_8: return "8"
        case kVK_ANSI_9: return "9"
        default: return nil
        }
    }
}
