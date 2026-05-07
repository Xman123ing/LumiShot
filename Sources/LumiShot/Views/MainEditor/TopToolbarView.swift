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
    let onAddMosaic: () -> Void
    let onBackdrop: () -> Void
    let onFloatingPin: () -> Void
    private let toolbarIconSize: CGFloat = 13
    private let toolbarButtonWidth: CGFloat = 30

    var body: some View {
        HStack(spacing: 8) {
            primaryAnnotationButtons

            secondaryAnnotationButtons

            moreToolsMenu

            Spacer(minLength: 12)
            toolbarDivider

            Button(action: onCopy) {
                Image(systemName: "doc.on.doc")
                    .modifier(ToolbarIconStyle(size: toolbarIconSize, width: toolbarButtonWidth))
            }
            .buttonStyle(.bordered)
            .help("Copy")

            Button(action: onSave) {
                Image(systemName: "externaldrive")
                    .modifier(ToolbarIconStyle(size: toolbarIconSize, width: toolbarButtonWidth))
            }
            .buttonStyle(.bordered)
            .help("Save")

            Text(zoomText)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.72))
                .monospacedDigit()
                .help("Zoom")
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
            Button(action: primaryAction(for: tool)) {
                Image(systemName: primaryIcon(for: tool))
                    .modifier(ToolbarIconStyle(size: toolbarIconSize, width: toolbarButtonWidth))
            }
            .buttonStyle(.bordered)
            .help(primaryLabel(for: tool))
        }
    }

    @ViewBuilder
    private var secondaryAnnotationButtons: some View {
        ForEach(ToolbarTool.moreTools, id: \.self) { tool in
            Button(action: secondaryAction(for: tool)) {
                Image(systemName: secondaryIcon(for: tool))
                    .modifier(ToolbarIconStyle(size: toolbarIconSize, width: toolbarButtonWidth))
            }
            .buttonStyle(.bordered)
            .help(secondaryLabel(for: tool))
        }
    }

    private var moreToolsMenu: some View {
        Menu {
            Menu("Capture Mode") {
                ForEach(CaptureMode.allCases, id: \.self) { mode in
                    Button {
                        selectedMode = mode
                    } label: {
                        if selectedMode == mode {
                            Label(modeLabel(mode), systemImage: "checkmark")
                        } else {
                            Text(modeLabel(mode))
                        }
                    }
                }
            }
            Divider()
            Button("Capture Screenshot", action: onCapture)
            Button("Mosaic", action: onAddMosaic)
            Divider()
            Button("Settings") {
                openSettings()
            }
        } label: {
            Image(systemName: "ellipsis")
                .modifier(ToolbarIconStyle(size: toolbarIconSize, width: toolbarButtonWidth))
        }
        .menuStyle(.borderlessButton)
        .buttonStyle(.bordered)
        .menuIndicator(.hidden)
        .help("More")
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

    private func primaryIcon(for tool: ToolbarTool) -> String {
        switch tool {
        case .rectangle: "rectangle.dashed"
        case .arrow: "arrow.up.right"
        case .text: "textformat"
        case .counter: "1.circle"
        case .floatingPin, .backdrop: "questionmark"
        }
    }

    private func secondaryLabel(for tool: ToolbarTool) -> String {
        switch tool {
        case .floatingPin: "Floating Pin"
        case .backdrop: "Backdrop"
        case .rectangle, .arrow, .text, .counter: ""
        }
    }

    private func secondaryIcon(for tool: ToolbarTool) -> String {
        switch tool {
        case .floatingPin: "pin"
        case .backdrop: "rectangle.lefthalf.inset.filled"
        case .rectangle, .arrow, .text, .counter: "questionmark"
        }
    }

    private func secondaryAction(for tool: ToolbarTool) -> () -> Void {
        switch tool {
        case .floatingPin: onFloatingPin
        case .backdrop: onBackdrop
        case .rectangle, .arrow, .text, .counter: {}
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
        case .region: "Region"
        case .window: "Window"
        case .fullScreen: "Full Screen"
        case .scrolling: "Scrolling"
        }
    }

}

private struct ToolbarIconStyle: ViewModifier {
    let size: CGFloat
    let width: CGFloat

    func body(content: Content) -> some View {
        content
            .font(.system(size: size, weight: .semibold))
            .frame(width: width)
            .symbolRenderingMode(.hierarchical)
    }
}
