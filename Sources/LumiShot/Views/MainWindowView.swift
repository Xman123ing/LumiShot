import AppKit
import SwiftUI

@MainActor
private enum CaptureSessionGate {
    private static var inProgress = false

    static func begin() -> Bool {
        guard inProgress == false else { return false }
        inProgress = true
        return true
    }

    static func end() {
        inProgress = false
    }
}

public struct MainWindowView: View {
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var viewModel = MainWorkflowViewModel.live()
    @StateObject private var toolStyleStore = AnnotationToolStyleStore()
    @AppStorage("annotation.backdrop.enabled") private var backdropEnabled = false
    @State private var toastMessage: String?
    @State private var toastDismissToken = 0
    @State private var captureRegionSelector = InteractiveCaptureRegionSelector()
    @State private var activeDrawingTool: ToolbarTool?
    @State private var zoomScale: Double = 1.0
    @State private var textEditingState: TextInlineEditingState?
    @State private var counterEditingState: CounterInlineEditingState?
    @State private var annotationUndoStack: [[AnnotationItem]] = []
    @State private var movingAnnotationIDs: Set<UUID> = []
    @State private var paletteTool: AnnotationColorTool?
    @State private var paletteTargetAnnotationID: UUID?
    @State private var hoveredAnnotationID: UUID?
    @State private var showBackdropPanel = false

    public init() {}

    public var body: some View {
        ZStack {
            windowBackgroundGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                TopToolbarView(
                    activeTool: activeDrawingTool,
                    zoomLevel: zoomScale,
                    onExtractOCR: {
                        commitPendingTextEditingIfNeeded()
                        NotificationCenter.default.post(name: LumiShotNotifications.triggerExtractOCR, object: nil)
                        showToast("OCR selection started.")
                    },
                    onCapture: {
                        commitPendingTextEditingIfNeeded()
                        triggerCapture()
                    },
                    onMove: {
                        commitPendingTextEditingIfNeeded()
                        activeDrawingTool = nil
                        showToast("Move ready: hover an annotation and drag.")
                    },
                    onUndo: undoLastAnnotationChange,
                    onCopy: copyCurrentCaptureImage,
                    onSave: saveCurrentCaptureImage,
                    onSelectPrimaryTool: { tool in
                        commitPendingTextEditingIfNeeded()
                        commitPendingCounterEditingIfNeeded()
                        activeDrawingTool = activeDrawingTool == tool ? nil : tool
                        if activeDrawingTool != nil {
                            textEditingState = nil
                            counterEditingState = nil
                        }
                        if showBackdropPanel == false {
                            paletteTool = nil
                        }
                        paletteTargetAnnotationID = nil
                        if let activeDrawingTool {
                            if activeDrawingTool == .text {
                                paletteTargetAnnotationID = latestAnnotationID(for: .text)
                            }
                            showToast("\(label(for: activeDrawingTool)) tool activated.")
                        } else {
                            showToast("Drawing tool deactivated.")
                        }
                    },
                    onAddMosaic: {
                        commitPendingTextEditingIfNeeded()
                        commitPendingCounterEditingIfNeeded()
                        pushUndoSnapshot()
                        viewModel.addMosaicAnnotation()
                        showToast("Mosaic added.")
                    },
                    onBackdrop: {
                        commitPendingCounterEditingIfNeeded()
                        if backdropEnabled == false {
                            backdropEnabled = true
                            showToast("Backdrop enabled.")
                        } else {
                            showToast("Backdrop panel opened.")
                        }
                        showBackdropPanel = true
                        paletteTool = nil
                        paletteTargetAnnotationID = nil
                    },
                    onFloatingPin: {
                        commitPendingTextEditingIfNeeded()
                        commitPendingCounterEditingIfNeeded()
                        guard let currentCapture = viewModel.currentCapture else {
                            showToast("Nothing to pin.")
                            return
                        }
                        FloatingPinService.shared.pin(
                            image: viewModel.composedImage(),
                            displaySize: currentCapture.logicalSize
                        )
                        showToast("Pinned capture to desktop.")
                    },
                    onSelectZoom: { level in
                        zoomScale = level
                        showToast("Zoom \(Int(level * 100))%")
                    }
                )
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(toolbarBackgroundColor)

                CanvasWorkspaceView(
                    items: viewModel.annotationStore.items,
                    hasCapture: viewModel.currentCapture != nil,
                    captureImage: viewModel.currentCapture?.image,
                    captureLogicalSize: viewModel.currentCapture?.logicalSize,
                    zoomScale: zoomScale,
                    activeTool: activeDrawingTool,
                    backdropEnabled: backdropEnabled,
                    backdropColor: toolStyleStore.color(for: .backdrop),
                    backdropGradientColors: toolStyleStore.currentBackdropGradientColors(),
                    backdropBorderWidth: toolStyleStore.strokeWidth(for: .backdrop),
                    backdropCornerRadius: toolStyleStore.currentBackdropCornerRadius(),
                    backdropInnerRadius: toolStyleStore.currentBackdropInnerRadius(),
                    backdropInset: toolStyleStore.currentBackdropInset(),
                    backdropShadow: toolStyleStore.currentBackdropShadow(),
                    previewArrowStrokeWidth: toolStyleStore.strokeWidth(for: .arrow),
                    previewArrowColor: toolStyleStore.color(for: .arrow),
                    onDrawRequest: { request in
                        handleDrawRequest(request)
                    },
                    onTextDoubleClick: { annotationID in
                        beginTextEditing(annotationID: annotationID)
                    },
                    textEditingState: textEditingState,
                    onTextEditingStateChange: { state in
                        textEditingState = state
                    },
                    onTextCommit: { state in
                        pushUndoSnapshot()
                        viewModel.updateTextAnnotation(id: state.annotationID, value: state.draftText)
                        textEditingState = nil
                        showToast("Text updated.")
                    },
                    counterEditingState: counterEditingState,
                    onCounterEditingStateChange: { state in
                        counterEditingState = state
                    },
                    onCounterCommit: { state in
                        pushUndoSnapshot()
                        let normalized = normalizeCounterValue(state.draftValue)
                        viewModel.updateNumberAnnotation(id: state.annotationID, value: normalized)
                        counterEditingState = nil
                        showToast("Counter updated.")
                    },
                    onCounterTap: { annotationID in
                        beginCounterEditing(annotationID: annotationID)
                    },
                    onAnnotationHoverChange: { annotationID in
                        hoveredAnnotationID = annotationID
                    },
                    onDeleteRequest: { annotationID in
                        deleteAnnotation(id: annotationID)
                    },
                    onAnnotationMove: { annotationID, center, trailing, isFinal in
                        if movingAnnotationIDs.contains(annotationID) == false {
                            pushUndoSnapshot()
                            movingAnnotationIDs.insert(annotationID)
                        }
                        viewModel.setAnnotationPosition(id: annotationID, center: center, trailingPoint: trailing)
                        if isFinal {
                            movingAnnotationIDs.remove(annotationID)
                        }
                    }
                )
                .padding(16)
                .overlay(alignment: .topTrailing) {
                    if showBackdropPanel {
                        BackdropStylePaletteDockView(
                            selectedColor: toolStyleStore.color(for: .backdrop),
                            cornerRadius: toolStyleStore.currentBackdropCornerRadius(),
                            innerRadius: toolStyleStore.currentBackdropInnerRadius(),
                            inset: toolStyleStore.currentBackdropInset(),
                            shadow: toolStyleStore.currentBackdropShadow(),
                            onSwatchSelect: { swatch in
                                toolStyleStore.setBackdropGradientColors(swatch.gradientColors)
                                toolStyleStore.setColor(swatch.color, for: .backdrop)
                            },
                            onCornerRadiusChange: { value in
                                toolStyleStore.setBackdropCornerRadius(value)
                            },
                            onInnerRadiusChange: { value in
                                toolStyleStore.setBackdropInnerRadius(value)
                            },
                            onInsetChange: { value in
                                toolStyleStore.setBackdropInset(value)
                            },
                            onShadowChange: { value in
                                toolStyleStore.setBackdropShadow(value)
                            },
                            onRemove: {
                                backdropEnabled = false
                                showToast("Backdrop removed.")
                            },
                            onClose: {
                                showBackdropPanel = false
                                showToast("Backdrop panel closed.")
                            }
                        )
                        .padding(.top, 24)
                        .padding(.trailing, 26)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    } else if let paletteTool {
                        Group {
                            AnnotationStylePaletteDockView(
                                tool: paletteTool,
                                selectedColor: toolStyleStore.color(for: paletteTool),
                                sliderValue: sliderValue(for: paletteTool, targetID: paletteTargetAnnotationID),
                                sliderRange: sliderRange(for: paletteTool),
                                onColorChange: { color in
                                    toolStyleStore.setColor(color, for: paletteTool)
                                    applyPaletteChange(tool: paletteTool, color: color)
                                },
                                onSliderChange: { value in
                                    applySliderChange(tool: paletteTool, value: value)
                                }
                            )
                        }
                        .padding(.top, 24)
                        .padding(.trailing, 26)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
            }
            .foregroundStyle(Color.primary)
            .background(mainCardBackgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: StyleTokens.cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: StyleTokens.cornerRadius, style: .continuous)
                    .stroke(cardBorderColor, lineWidth: 1)
            }
            .padding(14)

            ToastBannerView(message: $toastMessage, dismissToken: toastDismissToken)
        }
        .onReceive(NotificationCenter.default.publisher(for: LumiShotNotifications.didExtractOCRText)) { notification in
            if let text = notification.userInfo?[LumiShotNotifications.extractedTextKey] as? String {
                viewModel.applyOCRText(text)
                showToast("OCR applied (\(text.count) chars).")
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: LumiShotNotifications.triggerCapture)) { _ in
            triggerCapture()
        }
        .onReceive(NotificationCenter.default.publisher(for: LumiShotNotifications.triggerCopyCapture)) { _ in
            copyCurrentCaptureImage()
        }
        .onReceive(NotificationCenter.default.publisher(for: LumiShotNotifications.triggerSaveCapture)) { _ in
            saveCurrentCaptureImage()
        }
        .onReceive(NotificationCenter.default.publisher(for: LumiShotNotifications.triggerUndoAnnotation)) { _ in
            undoLastAnnotationChange()
        }
        .onDeleteCommand {
            if let targetID = currentDeletionCandidateID {
                deleteAnnotation(id: targetID)
            } else {
                showToast("No annotation to delete.")
            }
        }
        .fontDesign(.rounded)
    }

    private var windowBackgroundGradient: LinearGradient {
        if colorScheme == .dark {
            return LinearGradient(
                colors: [
                    Color(red: 0.18, green: 0.18, blue: 0.20),
                    Color(red: 0.13, green: 0.13, blue: 0.15),
                    Color(red: 0.20, green: 0.19, blue: 0.22)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        return LinearGradient(
            colors: [
                Color(red: 0.95, green: 0.96, blue: 0.99),
                Color(red: 0.93, green: 0.95, blue: 0.98),
                Color(red: 0.97, green: 0.98, blue: 1.00)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var toolbarBackgroundColor: Color {
        colorScheme == .dark ? .black.opacity(0.28) : .white.opacity(0.78)
    }

    private var mainCardBackgroundColor: Color {
        colorScheme == .dark ? .black.opacity(0.22) : .white.opacity(0.70)
    }

    private var cardBorderColor: Color {
        colorScheme == .dark ? .white.opacity(0.12) : .black.opacity(0.10)
    }

    private func showToast(_ text: String) {
        toastDismissToken += 1
        toastMessage = text
    }

    private func copyCurrentCaptureImage() {
        guard viewModel.currentCapture != nil else {
            showToast("Nothing to copy.")
            return
        }
        let image = composedImageForOutput()
        let size = NSSize(width: image.width, height: image.height)
        let nsImage = NSImage(cgImage: image, size: size)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.writeObjects([nsImage])
        showToast("Copied screenshot.")
    }

    private func saveCurrentCaptureImage() {
        do {
            let urls = try viewModel.exportCurrent()
            showToast("Saved: \(urls.png.lastPathComponent)")
        } catch {
            showToast("Save failed: \(error.localizedDescription)")
        }
    }

    private func triggerCapture() {
        guard CaptureSessionGate.begin() else {
            showToast("Capture is already in progress.")
            return
        }
        commitPendingTextEditingIfNeeded()
        commitPendingCounterEditingIfNeeded()
        captureRegionSelector.beginSelection(
            autoRestore: false,
            bringLumiShotToFrontForOverlay: false
        ) { selectionRect in
            NSCursor.arrow.set()
            guard let selectionRect else {
                self.captureRegionSelector.restoreWindowsIfNeeded()
                NotificationCenter.default.post(name: LumiShotNotifications.requestOpenMainWindow, object: nil)
                CaptureSessionGate.end()
                self.showToast("Capture cancelled.")
                return
            }
            Task {
                do {
                    try await self.viewModel.runCapture(
                        mode: .region,
                        region: selectionRect
                    )
                    self.textEditingState = nil
                    self.counterEditingState = nil
                    self.annotationUndoStack = []
                    self.hoveredAnnotationID = nil
                    self.captureRegionSelector.restoreWindowsIfNeeded()
                    NotificationCenter.default.post(name: LumiShotNotifications.requestOpenMainWindow, object: nil)
                    CaptureSessionGate.end()
                    self.showToast("Capture completed.")
                } catch {
                    self.captureRegionSelector.restoreWindowsIfNeeded()
                    NotificationCenter.default.post(name: LumiShotNotifications.requestOpenMainWindow, object: nil)
                    CaptureSessionGate.end()
                    self.showToast("Capture failed: \(captureErrorMessage(error))")
                }
            }
        }
    }

    private func captureErrorMessage(_ error: Error) -> String {
        guard let captureError = error as? CaptureError else {
            return error.localizedDescription
        }
        switch captureError {
        case .permissionDenied:
            return "Screen recording permission denied."
        case .unsupportedMode:
            return "Capture mode is unsupported."
        case .invalidRegion:
            return "Selected region is invalid."
        case .captureFailed:
            return "Failed to capture selected region."
        }
    }

    private func handleDrawRequest(_ request: AnnotationDrawRequest) {
        commitPendingTextEditingIfNeeded()
        commitPendingCounterEditingIfNeeded()
        pushUndoSnapshot()
        let selectedColor = request.tool.colorTool.map { toolStyleStore.color(for: $0) }
        switch request.tool {
        case .rectangle:
            let stroke = toolStyleStore.strokeWidth(for: .rectangle)
            let item = viewModel.addBoxAnnotation(
                from: request.start,
                to: request.end,
                color: selectedColor,
                strokeWidth: stroke
            )
            paletteTool = .rectangle
            paletteTargetAnnotationID = item.id
            showToast("Rectangle added.")
        case .arrow:
            let stroke = toolStyleStore.strokeWidth(for: .arrow)
            let item = viewModel.addArrowAnnotation(
                from: request.start,
                to: request.end,
                color: selectedColor,
                strokeWidth: stroke
            )
            paletteTool = .arrow
            paletteTargetAnnotationID = item.id
            showToast("Arrow added.")
        case .text:
            let fontSize = toolStyleStore.fontSize(for: .text)
            let item = viewModel.addTextAnnotation(
                at: request.end,
                value: "",
                color: selectedColor,
                fontSize: fontSize
            )
            textEditingState = TextInlineEditingState(annotationID: item.id, draftText: item.displayValue ?? "")
            paletteTool = .text
            paletteTargetAnnotationID = item.id
            showToast("Text added. Press Enter to finish editing.")
        case .counter:
            let stroke = toolStyleStore.strokeWidth(for: .counter)
            let item = viewModel.addNumberAnnotation(at: request.end, color: selectedColor, strokeWidth: stroke)
            paletteTool = .counter
            paletteTargetAnnotationID = item.id
            showToast("Counter added.")
        case .floatingPin, .backdrop:
            break
        }
    }

    private func beginTextEditing(annotationID: UUID) {
        commitPendingCounterEditingIfNeeded()
        if textEditingState?.annotationID != annotationID {
            commitPendingTextEditingIfNeeded()
        }
        guard let item = viewModel.annotationStore.item(id: annotationID), item.kind == .text else { return }
        paletteTool = .text
        paletteTargetAnnotationID = annotationID
        textEditingState = TextInlineEditingState(
            annotationID: annotationID,
            draftText: item.displayValue ?? ""
        )
    }

    private func commitPendingTextEditingIfNeeded() {
        guard let state = textEditingState else { return }
        pushUndoSnapshot()
        viewModel.updateTextAnnotation(id: state.annotationID, value: state.draftText)
        textEditingState = nil
    }

    private func beginCounterEditing(annotationID: UUID) {
        commitPendingTextEditingIfNeeded()
        if counterEditingState?.annotationID != annotationID {
            commitPendingCounterEditingIfNeeded()
        }
        guard let item = viewModel.annotationStore.item(id: annotationID), item.kind == .number else { return }
        paletteTool = .counter
        paletteTargetAnnotationID = annotationID
        counterEditingState = CounterInlineEditingState(
            annotationID: annotationID,
            draftValue: item.displayValue ?? "1"
        )
    }

    private func commitPendingCounterEditingIfNeeded() {
        guard let state = counterEditingState else { return }
        pushUndoSnapshot()
        let normalized = normalizeCounterValue(state.draftValue)
        viewModel.updateNumberAnnotation(id: state.annotationID, value: normalized)
        counterEditingState = nil
    }

    private func pushUndoSnapshot() {
        let current = viewModel.annotationStore.items
        if annotationUndoStack.last == current {
            return
        }
        annotationUndoStack.append(current)
        if annotationUndoStack.count > 50 {
            annotationUndoStack.removeFirst(annotationUndoStack.count - 50)
        }
    }

    private func undoLastAnnotationChange() {
        guard let last = annotationUndoStack.popLast() else {
            showToast("Nothing to undo.")
            return
        }
        textEditingState = nil
        counterEditingState = nil
        movingAnnotationIDs = []
        paletteTargetAnnotationID = nil
        hoveredAnnotationID = nil
        viewModel.replaceAnnotations(with: last)
        showToast("Undo applied.")
    }

    private func bringMainWindowToFront() {
        NSApp.unhide(nil)
        _ = NSRunningApplication.current.activate(options: [.activateAllWindows, .activateIgnoringOtherApps])
    }

    private func composedImageForOutput() -> CGImage {
        let composed = viewModel.composedImage()
        guard backdropEnabled else { return composed }
        return renderBackdropFrame(for: composed)
    }

    private func renderBackdropFrame(for image: CGImage) -> CGImage {
        let padding = CGFloat(toolStyleStore.currentBackdropInset())
        let width = Int(CGFloat(image.width) + padding * 2)
        let height = Int(CGFloat(image.height) + padding * 2)
        guard
            let context = CGContext(
                data: nil,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: 0,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )
        else {
            return image
        }
        let cardRect = CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height))
        let radius = toolStyleStore.currentBackdropCornerRadius()
        let innerRadius = toolStyleStore.currentBackdropInnerRadius()
        let rounded = CGPath(
            roundedRect: cardRect.insetBy(dx: 0.5, dy: 0.5),
            cornerWidth: radius,
            cornerHeight: radius,
            transform: nil
        )
        context.addPath(rounded)
        if let gradientColors = toolStyleStore.currentBackdropGradientColors(), gradientColors.count >= 2 {
            context.saveGState()
            context.addPath(rounded)
            context.clip()
            let cgColors = gradientColors.map { $0.cgColor } as CFArray
            let locations = stride(from: 0, through: 1, by: 1.0 / Double(gradientColors.count - 1)).map { CGFloat($0) }
            if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: cgColors, locations: locations) {
                context.drawLinearGradient(
                    gradient,
                    start: CGPoint(x: cardRect.minX, y: cardRect.maxY),
                    end: CGPoint(x: cardRect.maxX, y: cardRect.minY),
                    options: []
                )
            }
            context.restoreGState()
        } else {
            context.setFillColor(toolStyleStore.color(for: .backdrop).cgColor)
            context.fillPath()
        }
        context.addPath(rounded)
        context.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.72))
        context.setLineWidth(toolStyleStore.strokeWidth(for: .backdrop))
        context.strokePath()

        let shadowLevel = toolStyleStore.currentBackdropShadow()
        let imageRect = CGRect(
            x: padding,
            y: padding,
            width: CGFloat(image.width),
            height: CGFloat(image.height)
        )
        let imageRounded = CGPath(
            roundedRect: imageRect,
            cornerWidth: innerRadius,
            cornerHeight: innerRadius,
            transform: nil
        )
        if shadowLevel > 0 {
            context.saveGState()
            context.setShadow(
                offset: CGSize(width: 0, height: -(shadowLevel * 4)),
                blur: shadowLevel * 24,
                color: CGColor(red: 0, green: 0, blue: 0, alpha: shadowLevel * 0.6)
            )
            context.addPath(imageRounded)
            context.setFillColor(CGColor(red: 0, green: 0, blue: 0, alpha: 0.04))
            context.fillPath()
            context.restoreGState()
        }
        context.saveGState()
        context.addPath(imageRounded)
        context.clip()
        context.draw(image, in: imageRect)
        context.restoreGState()
        return context.makeImage() ?? image
    }

    private func label(for tool: ToolbarTool) -> String {
        switch tool {
        case .rectangle: "Rectangle"
        case .arrow: "Arrow"
        case .text: "Text"
        case .counter: "Counter"
        case .floatingPin: "Floating Pin"
        case .backdrop: "Backdrop"
        }
    }

    private func sliderValue(for tool: AnnotationColorTool, targetID: UUID?) -> Double {
        if let targetID = targetID ?? resolvePaletteTargetID(for: tool),
           let item = viewModel.annotationStore.item(id: targetID) {
            if tool == .text {
                return item.fontSize ?? toolStyleStore.fontSize(for: .text)
            }
            return item.strokeWidth ?? toolStyleStore.strokeWidth(for: tool)
        }
        if tool == .text {
            return toolStyleStore.fontSize(for: .text)
        }
        return toolStyleStore.strokeWidth(for: tool)
    }

    private func sliderRange(for tool: AnnotationColorTool) -> ClosedRange<Double> {
        tool == .text ? 12...64 : 1...12
    }

    private func applyPaletteChange(tool: AnnotationColorTool, color: AnnotationColor) {
        guard let targetID = resolvePaletteTargetID(for: tool) else { return }
        paletteTargetAnnotationID = targetID
        pushUndoSnapshot()
        viewModel.updateAnnotationStyle(id: targetID, color: color)
    }

    private func applySliderChange(tool: AnnotationColorTool, value: Double) {
        if tool == .text {
            toolStyleStore.setFontSize(value, for: tool)
        } else {
            toolStyleStore.setStrokeWidth(value, for: tool)
        }
        guard let targetID = resolvePaletteTargetID(for: tool) else { return }
        paletteTargetAnnotationID = targetID
        pushUndoSnapshot()
        if tool == .text {
            viewModel.updateAnnotationStyle(id: targetID, fontSize: value)
        } else {
            viewModel.updateAnnotationStyle(id: targetID, strokeWidth: value)
        }
    }

    private func resolvePaletteTargetID(for tool: AnnotationColorTool) -> UUID? {
        if let paletteTargetAnnotationID {
            return paletteTargetAnnotationID
        }
        switch tool {
        case .rectangle:
            return latestAnnotationID(for: .box)
        case .arrow:
            return latestAnnotationID(for: .arrow)
        case .text:
            return latestAnnotationID(for: .text)
        case .counter:
            return latestAnnotationID(for: .number)
        case .backdrop:
            return latestAnnotationID(for: .backdrop)
        }
    }

    private func latestAnnotationID(for kind: AnnotationKind) -> UUID? {
        viewModel.annotationStore.items.last(where: { $0.kind == kind })?.id
    }

    private var currentDeletionCandidateID: UUID? {
        if let editingID = textEditingState?.annotationID {
            return editingID
        }
        if let editingID = counterEditingState?.annotationID {
            return editingID
        }
        if let hoveredAnnotationID {
            return hoveredAnnotationID
        }
        return paletteTargetAnnotationID
    }

    private func deleteAnnotation(id: UUID) {
        guard viewModel.annotationStore.item(id: id) != nil else { return }
        pushUndoSnapshot()
        viewModel.removeAnnotation(id: id)

        if textEditingState?.annotationID == id {
            textEditingState = nil
        }
        if counterEditingState?.annotationID == id {
            counterEditingState = nil
        }
        if paletteTargetAnnotationID == id {
            paletteTargetAnnotationID = nil
        }
        if hoveredAnnotationID == id {
            hoveredAnnotationID = nil
        }
        movingAnnotationIDs.remove(id)
        showToast("Annotation deleted.")
    }

    private func normalizeCounterValue(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "1" }
        return String(trimmed.prefix(3))
    }

}
private enum BackdropPresetCategory: String, CaseIterable, Identifiable {
    case solid = "Solid"
    case colormix = "Colormix"
    case image = "Image"

    var id: String { rawValue }
}

private struct BackdropStylePaletteDockView: View {
    @Environment(\.colorScheme) private var colorScheme
    let selectedColor: AnnotationColor
    let cornerRadius: Double
    let innerRadius: Double
    let inset: Double
    let shadow: Double
    let onSwatchSelect: (BackdropSwatch) -> Void
    let onCornerRadiusChange: (Double) -> Void
    let onInnerRadiusChange: (Double) -> Void
    let onInsetChange: (Double) -> Void
    let onShadowChange: (Double) -> Void
    let onRemove: () -> Void
    let onClose: () -> Void

    @State private var category: BackdropPresetCategory = .colormix

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                sliderColumn(
                    title: "Backdrop",
                    valueText: nil,
                    value: inset,
                    range: 8...56,
                    onChange: onInsetChange
                )
                sliderColumn(
                    title: "Shadow",
                    valueText: nil,
                    value: shadow,
                    range: 0...1,
                    onChange: onShadowChange
                )
            }

            HStack(alignment: .top, spacing: 12) {
                sliderColumn(
                    title: "Outer Radius",
                    valueText: nil,
                    value: cornerRadius,
                    range: 6...36,
                    onChange: onCornerRadiusChange
                )
                sliderColumn(
                    title: "Inner Radius",
                    valueText: nil,
                    value: innerRadius,
                    range: 0...36,
                    onChange: onInnerRadiusChange
                )
            }

            Picker("Preset", selection: $category) {
                ForEach(BackdropPresetCategory.allCases) { item in
                    Text(item.rawValue).tag(item)
                }
            }
            .pickerStyle(.segmented)

            LazyVGrid(columns: Array(repeating: GridItem(.fixed(42), spacing: 10), count: 6), spacing: 10) {
                ForEach(Array(swatches(for: category).enumerated()), id: \.offset) { entry in
                    let swatch = entry.element
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(fillStyle(for: swatch))
                        .frame(width: 42, height: 42)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(
                                    swatchBorderColor(isSelected: isSameColor(swatch.color, selectedColor)),
                                    lineWidth: 1.5
                                )
                        )
                        .shadow(color: .black.opacity(0.18), radius: 4, y: 2)
                        .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .onTapGesture {
                            onSwatchSelect(swatch)
                        }
                }
            }

            HStack(spacing: 10) {
                Spacer()
                BackdropPanelActionButton(title: "Remove", prominent: false, onTap: onRemove)
                BackdropPanelActionButton(title: "OK", prominent: true, onTap: onClose)
            }
        }
        .frame(width: 300, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(panelBorderColor, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.22), radius: 12, y: 8)
    }

    private func fillStyle(for swatch: BackdropSwatch) -> AnyShapeStyle {
        if let gradient = swatch.gradientColors?.map(\.swiftUIColor), gradient.count >= 2 {
            return AnyShapeStyle(LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
        } else {
            return AnyShapeStyle(swatch.color.swiftUIColor)
        }
    }

    private func sliderColumn(
        title: String,
        valueText: String?,
        value: Double,
        range: ClosedRange<Double>,
        onChange: @escaping (Double) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.primary)
                if let valueText {
                    Spacer(minLength: 0)
                    Text(valueText)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }
            Slider(
                value: Binding(
                    get: { value },
                    set: { onChange($0) }
                ),
                in: range
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func swatches(for category: BackdropPresetCategory) -> [BackdropSwatch] {
        switch category {
        case .solid:
            return [
                .solid(.init(red: 0.08, green: 0.08, blue: 0.10, alpha: 0.35)),
                .solid(.init(red: 0.15, green: 0.16, blue: 0.18, alpha: 0.38)),
                .solid(.init(red: 0.20, green: 0.12, blue: 0.10, alpha: 0.35)),
                .solid(.init(red: 0.10, green: 0.16, blue: 0.20, alpha: 0.35)),
                .solid(.init(red: 0.15, green: 0.10, blue: 0.20, alpha: 0.35)),
                .solid(.init(red: 0.25, green: 0.25, blue: 0.28, alpha: 0.30))
            ]
        case .colormix:
            return [
                .gradient(
                    color: .init(red: 0.20, green: 0.66, blue: 0.98, alpha: 0.40),
                    colors: [
                        .init(red: 0.31, green: 0.80, blue: 1.0, alpha: 0.40),
                        .init(red: 0.07, green: 0.36, blue: 0.86, alpha: 0.40)
                    ]
                ),
                .gradient(
                    color: .init(red: 0.05, green: 0.47, blue: 0.72, alpha: 0.40),
                    colors: [
                        .init(red: 0.07, green: 0.66, blue: 0.86, alpha: 0.40),
                        .init(red: 0.02, green: 0.13, blue: 0.40, alpha: 0.40)
                    ]
                ),
                .gradient(
                    color: .init(red: 0.45, green: 0.21, blue: 0.42, alpha: 0.38),
                    colors: [
                        .init(red: 0.08, green: 0.50, blue: 0.67, alpha: 0.38),
                        .init(red: 0.94, green: 0.40, blue: 0.15, alpha: 0.38),
                        .init(red: 0.26, green: 0.09, blue: 0.45, alpha: 0.38)
                    ]
                ),
                .gradient(
                    color: .init(red: 0.73, green: 0.30, blue: 0.61, alpha: 0.38),
                    colors: [
                        .init(red: 0.98, green: 0.73, blue: 0.46, alpha: 0.38),
                        .init(red: 0.88, green: 0.15, blue: 0.63, alpha: 0.38),
                        .init(red: 0.19, green: 0.03, blue: 0.56, alpha: 0.38)
                    ]
                ),
                .gradient(
                    color: .init(red: 0.68, green: 0.48, blue: 0.66, alpha: 0.38),
                    colors: [
                        .init(red: 0.55, green: 0.62, blue: 0.91, alpha: 0.38),
                        .init(red: 0.99, green: 0.68, blue: 0.53, alpha: 0.38),
                        .init(red: 0.44, green: 0.12, blue: 0.36, alpha: 0.38)
                    ]
                ),
                .gradient(
                    color: .init(red: 0.59, green: 0.58, blue: 0.50, alpha: 0.36),
                    colors: [
                        .init(red: 0.80, green: 0.84, blue: 0.85, alpha: 0.36),
                        .init(red: 0.88, green: 0.79, blue: 0.63, alpha: 0.36),
                        .init(red: 0.08, green: 0.17, blue: 0.28, alpha: 0.36)
                    ]
                )
            ]
        case .image:
            return [
                .solid(.init(red: 0.11, green: 0.15, blue: 0.20, alpha: 0.34)),
                .solid(.init(red: 0.20, green: 0.24, blue: 0.30, alpha: 0.34)),
                .solid(.init(red: 0.26, green: 0.22, blue: 0.18, alpha: 0.34)),
                .solid(.init(red: 0.18, green: 0.22, blue: 0.16, alpha: 0.34)),
                .solid(.init(red: 0.15, green: 0.14, blue: 0.24, alpha: 0.34)),
                .solid(.init(red: 0.26, green: 0.25, blue: 0.22, alpha: 0.30))
            ]
        }
    }

    private func isSameColor(_ lhs: AnnotationColor, _ rhs: AnnotationColor) -> Bool {
        abs(lhs.red - rhs.red) < 0.001 &&
        abs(lhs.green - rhs.green) < 0.001 &&
        abs(lhs.blue - rhs.blue) < 0.001 &&
        abs(lhs.alpha - rhs.alpha) < 0.001
    }

    private func swatchBorderColor(isSelected: Bool) -> Color {
        if colorScheme == .dark {
            return .white.opacity(isSelected ? 0.95 : 0.18)
        }
        return .black.opacity(isSelected ? 0.68 : 0.16)
    }

    private var panelBorderColor: Color {
        colorScheme == .dark ? .white.opacity(0.18) : .black.opacity(0.12)
    }
}

private struct BackdropSwatch {
    let color: AnnotationColor
    let gradientColors: [AnnotationColor]?

    static func solid(_ color: AnnotationColor) -> BackdropSwatch {
        BackdropSwatch(color: color, gradientColors: nil)
    }

    static func gradient(color: AnnotationColor, colors: [AnnotationColor]) -> BackdropSwatch {
        BackdropSwatch(color: color, gradientColors: colors)
    }
}

private struct BackdropPanelActionButton: View {
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    let prominent: Bool
    let onTap: () -> Void
    @State private var hovered = false

    var body: some View {
        Button(action: onTap) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(backgroundColor, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(borderColor, lineWidth: 1)
                )
                .shadow(color: .black.opacity(hovered ? 0.30 : 0.18), radius: hovered ? 7 : 4, y: 2)
                .foregroundStyle(prominent ? Color.white : Color.primary)
        }
        .buttonStyle(.plain)
        .onHover { hovered in
            self.hovered = hovered
        }
    }

    private var backgroundColor: Color {
        if prominent {
            return hovered ? Color.accentColor.opacity(0.95) : Color.accentColor.opacity(0.82)
        }
        if colorScheme == .dark {
            return hovered ? Color.white.opacity(0.22) : Color.white.opacity(0.14)
        }
        return hovered ? Color.black.opacity(0.12) : Color.black.opacity(0.08)
    }

    private var borderColor: Color {
        if colorScheme == .dark {
            return .white.opacity(hovered ? 0.45 : 0.22)
        }
        return .black.opacity(hovered ? 0.26 : 0.14)
    }
}

private struct AnnotationStylePaletteDockView: View {
    @Environment(\.colorScheme) private var colorScheme
    let tool: AnnotationColorTool
    let selectedColor: AnnotationColor
    let sliderValue: Double
    let sliderRange: ClosedRange<Double>
    let onColorChange: (AnnotationColor) -> Void
    let onSliderChange: (Double) -> Void
    @State private var showColorSheet = false
    @State private var showCustomPicker = false

    private let quickColors: [AnnotationColor] = [
        .init(red: 1.0, green: 0.24, blue: 0.25),
        .init(red: 0.99, green: 0.84, blue: 0.20),
        .init(red: 0.30, green: 0.83, blue: 0.43),
        .init(red: 0.30, green: 0.68, blue: 1.0),
        .init(red: 0.72, green: 0.53, blue: 1.0),
        .init(red: 1.0, green: 1.0, blue: 1.0),
        .init(red: 0.12, green: 0.13, blue: 0.15)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        showColorSheet.toggle()
                    }
                } label: {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(selectedColor.swiftUIColor)
                        .frame(width: 32, height: 32)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(colorScheme == .dark ? .white.opacity(0.45) : .black.opacity(0.24), lineWidth: 1.2)
                        )
                }
                .buttonStyle(.plain)

                HStack(spacing: 8) {
                    Slider(
                        value: Binding(
                            get: { sliderValue },
                            set: { newValue in
                                onSliderChange(newValue)
                            }
                        ),
                        in: sliderRange
                    )
                    .frame(width: 180)
                }
            }

            if showColorSheet {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 10) {
                    ForEach(Array(quickColors.enumerated()), id: \.offset) { entry in
                        let color = entry.element
                        Circle()
                            .fill(color.swiftUIColor)
                            .frame(width: 18, height: 18)
                            .overlay(
                                Circle()
                                    .stroke(
                                        quickColorBorder(isSelected: isSameColor(color, selectedColor)),
                                        lineWidth: 1.5
                                    )
                            )
                            .contentShape(Circle())
                            .onTapGesture {
                                onColorChange(color)
                            }
                    }

                        Button("Custom") {
                            showCustomPicker.toggle()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }

                    if showCustomPicker {
                        ColorPicker(
                            "Custom",
                            selection: Binding(
                                get: { selectedColor.swiftUIColor },
                                set: { newColor in
                                    let ns = NSColor(newColor).usingColorSpace(.deviceRGB) ?? .white
                                    onColorChange(
                                        AnnotationColor(
                                            red: Double(ns.redComponent),
                                            green: Double(ns.greenComponent),
                                            blue: Double(ns.blueComponent),
                                            alpha: Double(ns.alphaComponent)
                                        )
                                    )
                                }
                            ),
                            supportsOpacity: false
                        )
                        .labelsHidden()
                    }
                }
                .padding(.top, 2)
            }
        }
        .frame(width: 290, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(colorScheme == .dark ? .white.opacity(0.18) : .black.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.22), radius: 12, y: 8)
    }

    private func toolTitle(_ tool: AnnotationColorTool) -> String {
        switch tool {
        case .rectangle: "Rectangle"
        case .arrow: "Arrow"
        case .text: "Text"
        case .counter: "Counter"
        case .backdrop: "Backdrop"
        }
    }

    private func isSameColor(_ lhs: AnnotationColor, _ rhs: AnnotationColor) -> Bool {
        abs(lhs.red - rhs.red) < 0.001 &&
        abs(lhs.green - rhs.green) < 0.001 &&
        abs(lhs.blue - rhs.blue) < 0.001 &&
        abs(lhs.alpha - rhs.alpha) < 0.001
    }

    private func quickColorBorder(isSelected: Bool) -> Color {
        if colorScheme == .dark {
            return .white.opacity(isSelected ? 0.95 : 0.16)
        }
        return .black.opacity(isSelected ? 0.68 : 0.14)
    }
}
