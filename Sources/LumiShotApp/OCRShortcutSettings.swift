import AppKit
import LumiShotKit
import SwiftUI

struct OCRShortcutSettingsView: View {
    @State private var recordingAction: AppShortcutAction?
    @State private var isRecording = false
    @State private var localMonitor: Any?
    @State private var shortcuts: [AppShortcutAction: AppShortcutRecord] = {
        var map: [AppShortcutAction: AppShortcutRecord] = [:]
        for action in AppShortcutAction.allCases {
            map[action] = AppShortcutStore.load(action)
        }
        return map
    }()

    private static let recorderModifierMask: NSEvent.ModifierFlags = [.command, .shift, .option, .control]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Shortcuts")
                .font(.title3.weight(.semibold))
                .padding(.horizontal)
                .padding(.top, 8)

            List {
                Section("Shortcut Module") {
                    ForEach(AppShortcutAction.allCases, id: \.self) { action in
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
        .frame(width: 420, height: 280)
        .onDisappear {
            stopRecording()
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
            let raw = event.charactersIgnoringModifiers?.lowercased() ?? ""

            guard let first = raw.first, first.isLetter || first.isNumber else {
                return event
            }
            applyRecordedShortcut(action: action, key: String(first), flags: flags)
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
    }

    private func resetToDefault() {
        for action in AppShortcutAction.allCases {
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
    }
}
