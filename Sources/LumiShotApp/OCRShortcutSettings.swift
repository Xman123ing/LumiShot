import AppKit
import SwiftUI
import LumiShotKit

struct OCRShortcutSettingsView: View {
    @AppStorage(OCRShortcutStorage.key) private var key: String = "e"
    @AppStorage(OCRShortcutStorage.useCommand) private var useCommand: Bool = true
    @AppStorage(OCRShortcutStorage.useShift) private var useShift: Bool = false
    @AppStorage(OCRShortcutStorage.useOption) private var useOption: Bool = false
    @AppStorage(OCRShortcutStorage.useControl) private var useControl: Bool = false
    @State private var isRecording = false
    @State private var localMonitor: Any?

    private static let recorderModifierMask: NSEvent.ModifierFlags = [.command, .shift, .option, .control]

    var body: some View {
        Form {
            Section("OCR Shortcut") {
                Text("Current: \(shortcutLabel)")
                    .foregroundStyle(.secondary)

                if isRecording {
                    Text("Press Esc to cancel")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Button(isRecording ? "Recording… press a letter or number" : "Record Shortcut") {
                    startRecording()
                }
                .buttonStyle(.borderedProminent)
                .disabled(isRecording)
                .accessibilityLabel(isRecording ? "Recording shortcut" : "Record shortcut")
                .help("Capture a letter or number with optional Command, Shift, Option, or Control.")

                Button("Reset to Default (Command + E)") {
                    stopRecording()
                    key = "e"
                    useCommand = true
                    useShift = false
                    useOption = false
                    useControl = false
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("Reset OCR shortcut to Command-E")
            }
        }
        .padding()
        .frame(width: 360)
        .onDisappear {
            stopRecording()
        }
    }

    private var shortcutLabel: String {
        var parts: [String] = []
        if useControl { parts.append("Control") }
        if useOption { parts.append("Option") }
        if useShift { parts.append("Shift") }
        if useCommand { parts.append("Command") }
        parts.append(key.uppercased())
        return parts.joined(separator: " + ")
    }

    private func startRecording() {
        stopRecording()
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
            key = String(first)
            useCommand = flags.contains(.command)
            useShift = flags.contains(.shift)
            useOption = flags.contains(.option)
            useControl = flags.contains(.control)
            stopRecording()
            return nil
        }
    }

    private func stopRecording() {
        if let localMonitor {
            NSEvent.removeMonitor(localMonitor)
            self.localMonitor = nil
        }
        isRecording = false
    }
}
