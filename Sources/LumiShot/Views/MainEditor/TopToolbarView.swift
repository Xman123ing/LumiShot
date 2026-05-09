import SwiftUI

struct TopToolbarView: View {
    @Environment(\.openSettings) private var openSettings
    @Environment(\.colorScheme) private var colorScheme

    let activeTool: ToolbarTool?
    let zoomLevel: Double

    let onExtractOCR: () -> Void
    let onCapture: () -> Void
    let onMove: () -> Void
    let onUndo: () -> Void
    let onCopy: () -> Void
    let onSave: () -> Void
    let onSelectPrimaryTool: (ToolbarTool) -> Void
    let onAddMosaic: () -> Void
    let onBackdrop: () -> Void
    let onFloatingPin: () -> Void
    let onSelectZoom: (Double) -> Void
    private let toolbarIconSize: CGFloat = 13
    private let toolbarButtonWidth: CGFloat = 30
    private let zoomLevels: [Double] = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]

    var body: some View {
        HStack(spacing: 8) {
            Button(action: onExtractOCR) {
                Image(systemName: "text.viewfinder")
                    .modifier(ToolbarIconStyle(size: toolbarIconSize, width: toolbarButtonWidth))
            }
            .buttonStyle(.bordered)
            .help("Extract OCR")

            toolbarDivider

            primaryAnnotationButtons

            moveButton

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

            Button(action: onUndo) {
                Image(systemName: "arrow.uturn.backward")
                    .modifier(ToolbarIconStyle(size: toolbarIconSize, width: toolbarButtonWidth))
            }
            .buttonStyle(.bordered)
            .help("Undo")

            Button(action: onSave) {
                Image(systemName: "externaldrive")
                    .modifier(ToolbarIconStyle(size: toolbarIconSize, width: toolbarButtonWidth))
            }
            .buttonStyle(.bordered)
            .help("Save")

            Menu {
                ForEach(zoomLevels, id: \.self) { level in
                    Button(action: { onSelectZoom(level) }) {
                        if abs(level - zoomLevel) < 0.001 {
                            Label("\(Int(level * 100))%", systemImage: "checkmark")
                        } else {
                            Text("\(Int(level * 100))%")
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text("\(Int(zoomLevel * 100))%")
                        .font(.system(size: 12, weight: .medium))
                        .monospacedDigit()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                }
                .frame(minWidth: 62)
            }
            .menuStyle(.borderlessButton)
            .buttonStyle(.bordered)
            .help("Zoom")
        }
    }

    @ViewBuilder
    private var moveButton: some View {
        Button(action: onMove) {
            Image(systemName: "hand.point.up.left.fill")
                .modifier(ToolbarIconStyle(size: toolbarIconSize, width: toolbarButtonWidth))
        }
        .buttonStyle(.bordered)
        .help("Move")
    }

    private var toolbarDivider: some View {
        Divider()
            .frame(height: 20)
            .overlay(
                colorScheme == .dark ? Color.white.opacity(0.2) : Color.black.opacity(0.16)
            )
    }

    @ViewBuilder
    private var primaryAnnotationButtons: some View {
        ForEach(ToolbarTool.primaryTools, id: \.self) { tool in
            if activeTool == tool {
                Button(action: { onSelectPrimaryTool(tool) }) {
                    Image(systemName: primaryIcon(for: tool))
                        .modifier(ToolbarIconStyle(size: toolbarIconSize, width: toolbarButtonWidth))
                }
                .buttonStyle(.borderedProminent)
                .help(primaryLabel(for: tool))
            } else {
                Button(action: { onSelectPrimaryTool(tool) }) {
                    Image(systemName: primaryIcon(for: tool))
                        .modifier(ToolbarIconStyle(size: toolbarIconSize, width: toolbarButtonWidth))
                }
                .buttonStyle(.bordered)
                .help(primaryLabel(for: tool))
            }
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
