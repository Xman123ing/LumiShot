import SwiftUI

struct TopToolbarView: View {
    @Environment(\.openSettings) private var openSettings

    @Binding var selectedMode: CaptureMode

    let zoomText: String

    let onCapture: () -> Void
    let onCopy: () -> Void
    let onSave: () -> Void
    let onAddBox: () -> Void
    let onAddArrow: () -> Void
    let onAddText: () -> Void
    let onAddNumber: () -> Void
    let onBackdrop: () -> Void
    let onFloatingPin: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Text("LumiShot")
                .font(.system(size: 16, weight: .bold))
                .padding(.trailing, 8)

            Picker("Mode", selection: $selectedMode) {
                ForEach(CaptureMode.allCases, id: \.self) { mode in
                    Text(modeLabel(mode)).tag(mode)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 150)

            Button("Capture", action: onCapture)
                .buttonStyle(.borderedProminent)

            toolbarDivider

            primaryAnnotationButtons

            moreToolsMenu

            Spacer(minLength: 12)

            Text(zoomText)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.72))
                .monospacedDigit()

            Button("Copy", action: onCopy)
                .buttonStyle(.bordered)
            Button("Save", action: onSave)
                .buttonStyle(.bordered)

            Button {
                openSettings()
            } label: {
                Label("Settings", systemImage: "gearshape")
            }
            .buttonStyle(.bordered)
        }
    }

    private var toolbarDivider: some View {
        Divider()
            .frame(height: 20)
            .overlay(.white.opacity(0.2))
    }

    @ViewBuilder
    private var primaryAnnotationButtons: some View {
        ForEach(ToolbarTool.primaryTools, id: \.self) { tool in
            Button(primaryLabel(for: tool), action: primaryAction(for: tool))
                .buttonStyle(.bordered)
        }
    }

    private var moreToolsMenu: some View {
        Menu {
            ForEach(ToolbarTool.moreTools, id: \.self) { tool in
                Button(moreLabel(for: tool), action: moreAction(for: tool))
            }
        } label: {
            Text("More")
        }
        .menuStyle(.borderlessButton)
        .buttonStyle(.bordered)
    }

    private func primaryLabel(for tool: ToolbarTool) -> String {
        switch tool {
        case .rectangle: "Rectangle"
        case .arrow: "Arrow"
        case .text: "Text"
        case .counter: "Counter"
        case .floatingPin, .backdrop: ""
        }
    }

    private func primaryAction(for tool: ToolbarTool) -> () -> Void {
        switch tool {
        case .rectangle: onAddBox
        case .arrow: onAddArrow
        case .text: onAddText
        case .counter: onAddNumber
        case .floatingPin, .backdrop: {}
        }
    }

    private func moreLabel(for tool: ToolbarTool) -> String {
        switch tool {
        case .floatingPin: "Floating Pin"
        case .backdrop: "Backdrop"
        case .rectangle, .arrow, .text, .counter: ""
        }
    }

    private func moreAction(for tool: ToolbarTool) -> () -> Void {
        switch tool {
        case .floatingPin: onFloatingPin
        case .backdrop: onBackdrop
        case .rectangle, .arrow, .text, .counter: {}
        }
    }

    private func modeLabel(_ mode: CaptureMode) -> String {
        switch mode {
        case .region:
            return "Region"
        case .window:
            return "Window"
        case .fullScreen:
            return "Full Screen"
        case .scrolling:
            return "Scrolling"
        }
    }
}
