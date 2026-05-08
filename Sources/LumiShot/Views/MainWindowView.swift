import AppKit
import SwiftUI

public struct MainWindowView: View {
    @StateObject private var viewModel = MainWorkflowViewModel.live()
    @State private var toastMessage: String?
    @State private var toastDismissToken = 0
    @State private var captureRegionSelector = InteractiveCaptureRegionSelector()
    @State private var activeDrawingTool: ToolbarTool?
    @State private var textEditingState: TextInlineEditingState?
    @State private var backdropEnabled = false
    @State private var annotationUndoStack: [[AnnotationItem]] = []
    @State private var movingAnnotationIDs: Set<UUID> = []

    public init() {}

    public var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.18, green: 0.18, blue: 0.20),
                    Color(red: 0.13, green: 0.13, blue: 0.15),
                    Color(red: 0.20, green: 0.19, blue: 0.22)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                TopToolbarView(
                    activeTool: activeDrawingTool,
                    zoomText: "100%",
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
                        activeDrawingTool = activeDrawingTool == tool ? nil : tool
                        if let activeDrawingTool {
                            showToast("\(label(for: activeDrawingTool)) tool activated.")
                        } else {
                            showToast("Drawing tool deactivated.")
                        }
                    },
                    onAddMosaic: {
                        commitPendingTextEditingIfNeeded()
                        pushUndoSnapshot()
                        viewModel.addMosaicAnnotation()
                        showToast("Mosaic added.")
                    },
                    onBackdrop: {
                        backdropEnabled.toggle()
                        showToast(backdropEnabled ? "Backdrop enabled." : "Backdrop disabled.")
                    },
                    onFloatingPin: {
                        commitPendingTextEditingIfNeeded()
                        guard viewModel.currentCapture != nil else {
                            showToast("Nothing to pin.")
                            return
                        }
                        FloatingPinService.shared.pin(image: viewModel.composedImage())
                        showToast("Pinned capture to desktop.")
                    }
                )
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.black.opacity(0.28))

                CanvasWorkspaceView(
                    items: viewModel.annotationStore.items,
                    hasCapture: viewModel.currentCapture != nil,
                    captureImage: viewModel.currentCapture?.image,
                    captureLogicalSize: viewModel.currentCapture?.logicalSize,
                    activeTool: activeDrawingTool,
                    backdropEnabled: backdropEnabled,
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
                    onCounterTap: { _ in },
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
            }
            .foregroundStyle(.white)
            .background(.black.opacity(0.22))
            .clipShape(RoundedRectangle(cornerRadius: StyleTokens.cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: StyleTokens.cornerRadius, style: .continuous)
                    .stroke(.white.opacity(0.12), lineWidth: 1)
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
        .preferredColorScheme(.dark)
        .fontDesign(.rounded)
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
        commitPendingTextEditingIfNeeded()
        captureRegionSelector.beginSelection(
            autoRestore: false,
            bringLumiShotToFrontForOverlay: false
        ) { selectionRect in
            guard let selectionRect else {
                captureRegionSelector.restoreWindowsIfNeeded()
                showToast("Capture cancelled.")
                return
            }
            Task {
                do {
                    try await viewModel.runCapture(
                        mode: .region,
                        region: selectionRect
                    )
                    textEditingState = nil
                    annotationUndoStack = []
                    captureRegionSelector.restoreWindowsAndBringLumiShotFront()
                    bringMainWindowToFront()
                    showToast("Capture completed.")
                } catch {
                    captureRegionSelector.restoreWindowsIfNeeded()
                    showToast("Capture failed: \(error.localizedDescription)")
                }
            }
        }
    }

    private func handleDrawRequest(_ request: AnnotationDrawRequest) {
        if request.tool == .text {
            commitPendingTextEditingIfNeeded()
        }
        pushUndoSnapshot()
        switch request.tool {
        case .rectangle:
            viewModel.addBoxAnnotation(from: request.start, to: request.end)
            showToast("Rectangle added.")
        case .arrow:
            viewModel.addArrowAnnotation(from: request.start, to: request.end)
            showToast("Arrow added.")
        case .text:
            let item = viewModel.addTextAnnotation(at: request.end, value: "")
            textEditingState = TextInlineEditingState(annotationID: item.id, draftText: item.displayValue ?? "")
            showToast("Text added. Press Enter to finish editing.")
        case .counter:
            viewModel.addNumberAnnotation(at: request.end)
            showToast("Counter added.")
        case .floatingPin, .backdrop:
            break
        }
    }

    private func beginTextEditing(annotationID: UUID) {
        if textEditingState?.annotationID != annotationID {
            commitPendingTextEditingIfNeeded()
        }
        guard let item = viewModel.annotationStore.item(id: annotationID), item.kind == .text else { return }
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
        movingAnnotationIDs = []
        viewModel.replaceAnnotations(with: last)
        showToast("Undo applied.")
    }

    private func bringMainWindowToFront() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.windows.forEach { $0.makeKeyAndOrderFront(nil) }
    }

    private func composedImageForOutput() -> CGImage {
        let composed = viewModel.composedImage()
        guard backdropEnabled else { return composed }
        return renderBackdropFrame(for: composed)
    }

    private func renderBackdropFrame(for image: CGImage) -> CGImage {
        let padding: CGFloat = 24
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
        context.setFillColor(CGColor(red: 0.20, green: 0.20, blue: 0.22, alpha: 0.42))
        context.fill(cardRect)
        context.draw(
            image,
            in: CGRect(
                x: padding,
                y: padding,
                width: CGFloat(image.width),
                height: CGFloat(image.height)
            )
        )
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

}
