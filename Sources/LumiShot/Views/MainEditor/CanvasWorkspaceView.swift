import AppKit
import SwiftUI

struct AnnotationDrawRequest: Equatable {
    let tool: ToolbarTool
    let start: CGPoint
    let end: CGPoint
}

struct TextInlineEditingState: Equatable {
    let annotationID: UUID
    let draftText: String
}

struct CounterInlineEditingState: Equatable {
    let annotationID: UUID
    let draftValue: String
}

struct CanvasWorkspaceView: View {
    @Environment(\.colorScheme) private var colorScheme
    let items: [AnnotationItem]
    let hasCapture: Bool
    let captureImage: CGImage?
    let captureLogicalSize: CGSize?
    let zoomScale: Double
    let activeTool: ToolbarTool?
    let backdropEnabled: Bool
    let backdropColor: AnnotationColor
    let backdropGradientColors: [AnnotationColor]?
    let backdropBorderWidth: Double
    let backdropCornerRadius: Double
    let backdropInnerRadius: Double
    let backdropInset: Double
    let backdropShadow: Double
    let onDrawRequest: (AnnotationDrawRequest) -> Void
    let onTextDoubleClick: (UUID) -> Void
    let textEditingState: TextInlineEditingState?
    let onTextEditingStateChange: (TextInlineEditingState?) -> Void
    let onTextCommit: (TextInlineEditingState) -> Void
    let counterEditingState: CounterInlineEditingState?
    let onCounterEditingStateChange: (CounterInlineEditingState?) -> Void
    let onCounterCommit: (CounterInlineEditingState) -> Void
    let onCounterTap: (UUID) -> Void
    let onAnnotationHoverChange: (UUID?) -> Void
    let onDeleteRequest: (UUID) -> Void
    let onAnnotationMove: (UUID, CGPoint, CGPoint?, Bool) -> Void
    @State private var dragStartPoint: CGPoint?
    @State private var dragCurrentPoint: CGPoint?
    @State private var draggingAnnotationID: UUID?
    @State private var dragAnchorCenter: CGPoint?
    @State private var dragAnchorTrailing: CGPoint?
    @State private var hoveredAnnotationID: UUID?
    @State private var resizingArrowID: UUID?
    @State private var resizingArrowCenter: CGPoint?
    @State private var resizingRectangleID: UUID?
    @State private var resizingRectangleCenter: CGPoint?
    @FocusState private var textEditorFocused: Bool
    @FocusState private var counterEditorFocused: Bool

    init(
        items: [AnnotationItem],
        hasCapture: Bool,
        captureImage: CGImage? = nil,
        captureLogicalSize: CGSize? = nil,
        zoomScale: Double = 1.0,
        activeTool: ToolbarTool? = nil,
        backdropEnabled: Bool = false,
        backdropColor: AnnotationColor = AnnotationColor.defaultColor(for: .backdrop),
        backdropGradientColors: [AnnotationColor]? = nil,
        backdropBorderWidth: Double = AnnotationColorTool.backdrop.defaultStrokeWidth,
        backdropCornerRadius: Double = 16,
        backdropInnerRadius: Double = 12,
        backdropInset: Double = 24,
        backdropShadow: Double = 0.45,
        onDrawRequest: @escaping (AnnotationDrawRequest) -> Void = { _ in },
        onTextDoubleClick: @escaping (UUID) -> Void = { _ in },
        textEditingState: TextInlineEditingState? = nil,
        onTextEditingStateChange: @escaping (TextInlineEditingState?) -> Void = { _ in },
        onTextCommit: @escaping (TextInlineEditingState) -> Void = { _ in },
        counterEditingState: CounterInlineEditingState? = nil,
        onCounterEditingStateChange: @escaping (CounterInlineEditingState?) -> Void = { _ in },
        onCounterCommit: @escaping (CounterInlineEditingState) -> Void = { _ in },
        onCounterTap: @escaping (UUID) -> Void = { _ in },
        onAnnotationHoverChange: @escaping (UUID?) -> Void = { _ in },
        onDeleteRequest: @escaping (UUID) -> Void = { _ in },
        onAnnotationMove: @escaping (UUID, CGPoint, CGPoint?, Bool) -> Void = { _, _, _, _ in }
    ) {
        self.items = items
        self.hasCapture = hasCapture
        self.captureImage = captureImage
        self.captureLogicalSize = captureLogicalSize
        self.zoomScale = zoomScale
        self.activeTool = activeTool
        self.backdropEnabled = backdropEnabled
        self.backdropColor = backdropColor
        self.backdropGradientColors = backdropGradientColors
        self.backdropBorderWidth = backdropBorderWidth
        self.backdropCornerRadius = backdropCornerRadius
        self.backdropInnerRadius = backdropInnerRadius
        self.backdropInset = backdropInset
        self.backdropShadow = backdropShadow
        self.onDrawRequest = onDrawRequest
        self.onTextDoubleClick = onTextDoubleClick
        self.textEditingState = textEditingState
        self.onTextEditingStateChange = onTextEditingStateChange
        self.onTextCommit = onTextCommit
        self.counterEditingState = counterEditingState
        self.onCounterEditingStateChange = onCounterEditingStateChange
        self.onCounterCommit = onCounterCommit
        self.onCounterTap = onCounterTap
        self.onAnnotationHoverChange = onAnnotationHoverChange
        self.onDeleteRequest = onDeleteRequest
        self.onAnnotationMove = onAnnotationMove
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(colorScheme == .dark ? .black.opacity(0.4) : .white.opacity(0.72))

                if let captureImage {
                    let imageRect = displayImageRect(image: captureImage, in: geometry.size)
                    let imageSize = CGSize(width: captureImage.width, height: captureImage.height)
                    let displayItems = items.map { mapItemToDisplay($0, imageRect: imageRect, imageSize: imageSize) }
                    if backdropEnabled {
                        BackdropStackView(
                            imageRect: imageRect,
                            color: backdropColor.swiftUIColor,
                            gradientColors: backdropGradientColors?.map { $0.swiftUIColor },
                            cornerRadius: backdropCornerRadius,
                            inset: backdropInset
                        )
                    }
                    if backdropEnabled {
                        Image(nsImage: NSImage(cgImage: captureImage, size: displayImageSize(image: captureImage)))
                            .resizable()
                            .interpolation(.high)
                            .frame(width: imageRect.width, height: imageRect.height)
                            .clipShape(RoundedRectangle(cornerRadius: backdropInnerRadius, style: .continuous))
                            .shadow(
                                color: .black.opacity(max(0, min(0.8, backdropShadow))),
                                radius: max(0, backdropShadow * 22),
                                y: max(0, backdropShadow * 8)
                            )
                            .position(x: imageRect.midX, y: imageRect.midY)
                    } else {
                        Image(nsImage: NSImage(cgImage: captureImage, size: displayImageSize(image: captureImage)))
                            .resizable()
                            .interpolation(.high)
                            .frame(width: imageRect.width, height: imageRect.height)
                            .position(x: imageRect.midX, y: imageRect.midY)
                    }

                    if !displayItems.isEmpty {
                        AnnotationCanvasView(
                            items: displayItems,
                            enableCounterTap: activeTool == nil,
                            onTextDoubleClick: onTextDoubleClick,
                            onCounterTap: onCounterTap
                        )
                    }

                    if let editor = inlineEditor(in: imageRect, imageSize: imageSize, displayItems: displayItems) {
                        editor
                    }
                    if let counterEditor = inlineCounterEditor(in: imageRect, imageSize: imageSize, displayItems: displayItems) {
                        counterEditor
                    }
                }

                if let previewPath = previewPath(in: geometry.size) {
                    previewPath
                        .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 2, dash: [4, 3]))
                }

                if items.isEmpty {
                    placeholderOverlay
                }
            }
            .contentShape(Rectangle())
            .simultaneousGesture(drawingGesture(in: geometry.size))
            .contextMenu {
                if let hoveredAnnotationID {
                    Button(role: .destructive) {
                        onDeleteRequest(hoveredAnnotationID)
                    } label: {
                        Text("Delete")
                    }
                } else {
                    Text("No annotation")
                }
            }
            .onContinuousHover { phase in
                guard let captureImage else { return }
                switch phase {
                case .active(let location):
                    let hit = hitTestAnnotation(at: location, image: captureImage, size: geometry.size)
                    hoveredAnnotationID = hit?.id
                    onAnnotationHoverChange(hoveredAnnotationID)
                    if hit == nil {
                        NSCursor.arrow.set()
                    } else {
                        NSCursor.openHand.set()
                    }
                case .ended:
                    hoveredAnnotationID = nil
                    onAnnotationHoverChange(nil)
                    NSCursor.arrow.set()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onChange(of: activeTool) { _, _ in
            draggingAnnotationID = nil
            dragAnchorCenter = nil
            dragAnchorTrailing = nil
            resizingArrowID = nil
            resizingArrowCenter = nil
            resizingRectangleID = nil
            resizingRectangleCenter = nil
            hoveredAnnotationID = nil
            onAnnotationHoverChange(nil)
            dragStartPoint = nil
            dragCurrentPoint = nil
            NSCursor.arrow.set()
        }
    }

    @ViewBuilder
    private var placeholderOverlay: some View {
        if captureImage == nil {
            Text(emptyPlaceholderText)
                .font(.system(size: 13))
                .foregroundStyle(colorScheme == .dark ? .white.opacity(0.45) : .black.opacity(0.45))
        }
    }

    private var emptyPlaceholderText: String {
        if hasCapture {
            return "Captured. Add annotations from the top toolbar."
        }
        return "Capture your screen and annotate from the top toolbar."
    }

    private func drawingGesture(in size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard let captureImage else { return }
                if draggingAnnotationID == nil, dragStartPoint == nil {
                    let start = adjustedPointForActiveTool(value.startLocation)
                    if let hitItem = hitTestAnnotation(at: start, image: captureImage, size: size),
                       textEditingState?.annotationID != hitItem.id {
                        if activeTool == .rectangle, hitItem.kind == .box, let trailing = hitItem.trailingPoint {
                            let imageRect = displayImageRect(image: captureImage, in: size)
                            let imageSize = CGSize(width: captureImage.width, height: captureImage.height)
                            let trailingDisplay = mapToDisplayPoint(trailing, imageRect: imageRect, imageSize: imageSize)
                            if hypot(start.x - trailingDisplay.x, start.y - trailingDisplay.y) <= 16 {
                                resizingRectangleID = hitItem.id
                                resizingRectangleCenter = hitItem.center
                                NSCursor.crosshair.set()
                                return
                            }
                        }
                        if activeTool == .arrow, hitItem.kind == .arrow, let trailing = hitItem.trailingPoint {
                            let imageRect = displayImageRect(image: captureImage, in: size)
                            let imageSize = CGSize(width: captureImage.width, height: captureImage.height)
                            let trailingDisplay = mapToDisplayPoint(trailing, imageRect: imageRect, imageSize: imageSize)
                            if hypot(start.x - trailingDisplay.x, start.y - trailingDisplay.y) <= 16 {
                                resizingArrowID = hitItem.id
                                resizingArrowCenter = hitItem.center
                                NSCursor.crosshair.set()
                                return
                            }
                        }
                        draggingAnnotationID = hitItem.id
                        let imageRect = displayImageRect(image: captureImage, in: size)
                        let imageSize = CGSize(width: captureImage.width, height: captureImage.height)
                        dragAnchorCenter = mapToDisplayPoint(hitItem.center, imageRect: imageRect, imageSize: imageSize)
                        dragAnchorTrailing = hitItem.trailingPoint.map {
                            mapToDisplayPoint($0, imageRect: imageRect, imageSize: imageSize)
                        }
                        NSCursor.closedHand.set()
                    } else if activeTool != nil {
                        dragStartPoint = start
                    }
                }
                if let resizingRectangleID, let resizingRectangleCenter {
                    let current = adjustedPointForActiveTool(value.location)
                    guard let imageTrailing = convertToImagePoint(current, image: captureImage, size: size) else {
                        return
                    }
                    onAnnotationMove(resizingRectangleID, resizingRectangleCenter, imageTrailing, false)
                } else if let resizingArrowID, let resizingArrowCenter {
                    let current = adjustedPointForActiveTool(value.location)
                    guard let imageTrailing = convertToImagePoint(current, image: captureImage, size: size) else {
                        return
                    }
                    onAnnotationMove(resizingArrowID, resizingArrowCenter, imageTrailing, false)
                } else if let annotationID = draggingAnnotationID,
                   let anchorCenter = dragAnchorCenter {
                    let newCenter = CGPoint(
                        x: anchorCenter.x + value.translation.width,
                        y: anchorCenter.y + value.translation.height
                    )
                    let newTrailing = dragAnchorTrailing.map {
                        CGPoint(
                            x: $0.x + value.translation.width,
                            y: $0.y + value.translation.height
                        )
                    }
                    let imageCenter = convertToImagePoint(newCenter, image: captureImage, size: size)
                    let imageTrailing = newTrailing.flatMap {
                        convertToImagePoint($0, image: captureImage, size: size)
                    }
                    guard let imageCenter else { return }
                    onAnnotationMove(annotationID, imageCenter, imageTrailing, false)
                } else if dragStartPoint != nil {
                    dragCurrentPoint = adjustedPointForActiveTool(value.location)
                }
            }
            .onEnded { value in
                defer {
                    dragStartPoint = nil
                    dragCurrentPoint = nil
                    draggingAnnotationID = nil
                    dragAnchorCenter = nil
                    dragAnchorTrailing = nil
                    resizingArrowID = nil
                    resizingArrowCenter = nil
                    resizingRectangleID = nil
                    resizingRectangleCenter = nil
                    NSCursor.arrow.set()
                }
                guard let captureImage else { return }
                if let resizingRectangleID, let resizingRectangleCenter {
                    let current = adjustedPointForActiveTool(value.location)
                    guard let imageTrailing = convertToImagePoint(current, image: captureImage, size: size) else {
                        return
                    }
                    onAnnotationMove(resizingRectangleID, resizingRectangleCenter, imageTrailing, true)
                } else if let resizingArrowID, let resizingArrowCenter {
                    let current = adjustedPointForActiveTool(value.location)
                    guard let imageTrailing = convertToImagePoint(current, image: captureImage, size: size) else {
                        return
                    }
                    onAnnotationMove(resizingArrowID, resizingArrowCenter, imageTrailing, true)
                } else if let annotationID = draggingAnnotationID,
                   let anchorCenter = dragAnchorCenter {
                    let finalCenter = CGPoint(
                        x: anchorCenter.x + value.translation.width,
                        y: anchorCenter.y + value.translation.height
                    )
                    let finalTrailing = dragAnchorTrailing.map {
                        CGPoint(
                            x: $0.x + value.translation.width,
                            y: $0.y + value.translation.height
                        )
                    }
                    let imageCenter = convertToImagePoint(finalCenter, image: captureImage, size: size)
                    let imageTrailing = finalTrailing.flatMap {
                        convertToImagePoint($0, image: captureImage, size: size)
                    }
                    guard let imageCenter else { return }
                    onAnnotationMove(annotationID, imageCenter, imageTrailing, true)
                } else if let activeTool {
                    let startLocal = dragStartPoint ?? adjustedPointForActiveTool(value.startLocation)
                    let endLocal = adjustedPointForActiveTool(value.location)
                    guard
                        let startImage = convertToImagePoint(startLocal, image: captureImage, size: size),
                        let endImage = convertToImagePoint(endLocal, image: captureImage, size: size)
                    else { return }
                    onDrawRequest(AnnotationDrawRequest(tool: activeTool, start: startImage, end: endImage))
                }
            }
    }

    private func previewPath(in size: CGSize) -> Path? {
        guard
            let tool = activeTool,
            draggingAnnotationID == nil,
            let start = dragStartPoint,
            let end = dragCurrentPoint
        else { return nil }

        switch tool {
        case .rectangle:
            var path = Path()
            let rect = CGRect(
                x: min(start.x, end.x),
                y: min(start.y, end.y),
                width: abs(end.x - start.x),
                height: abs(end.y - start.y)
            )
            path.addRect(rect)
            return path
        case .arrow:
            var path = Path()
            path.move(to: start)
            path.addLine(to: end)
            return path
        case .text, .counter, .floatingPin, .backdrop:
            return nil
        }
    }

    private func convertToImagePoint(_ point: CGPoint, image: CGImage, size: CGSize) -> CGPoint? {
        let imageRect = displayImageRect(image: image, in: size)
        guard imageRect.contains(point), imageRect.width > 0, imageRect.height > 0 else {
            return nil
        }
        let imageSize = CGSize(width: image.width, height: image.height)
        let xRatio = (point.x - imageRect.minX) / imageRect.width
        let yRatio = (point.y - imageRect.minY) / imageRect.height
        return CGPoint(
            x: xRatio * imageSize.width,
            y: yRatio * imageSize.height
        )
    }

    private func displayImageRect(image: CGImage, in size: CGSize) -> CGRect {
        let contentRect = CGRect(origin: .zero, size: size).insetBy(dx: 12, dy: 12)
        let baseRect = aspectFitRect(
            contentSize: displayImageSize(image: image),
            in: contentRect
        )
        let zoom = max(0.25, min(3.0, zoomScale))
        let zoomedSize = CGSize(width: baseRect.width * zoom, height: baseRect.height * zoom)
        return CGRect(
            x: contentRect.midX - zoomedSize.width / 2,
            y: contentRect.midY - zoomedSize.height / 2,
            width: zoomedSize.width,
            height: zoomedSize.height
        )
    }

    private func displayImageSize(image: CGImage) -> CGSize {
        if let captureLogicalSize, captureLogicalSize.width > 0, captureLogicalSize.height > 0 {
            return captureLogicalSize
        }
        return CGSize(width: image.width, height: image.height)
    }

    private func aspectFitRect(contentSize: CGSize, in bounds: CGRect) -> CGRect {
        guard contentSize.width > 0, contentSize.height > 0, bounds.width > 0, bounds.height > 0 else {
            return bounds
        }
        let scale = min(1, min(bounds.width / contentSize.width, bounds.height / contentSize.height))
        let size = CGSize(width: contentSize.width * scale, height: contentSize.height * scale)
        let origin = CGPoint(
            x: bounds.midX - size.width / 2,
            y: bounds.midY - size.height / 2
        )
        return CGRect(origin: origin, size: size)
    }

    private func inlineEditor(in imageRect: CGRect, imageSize: CGSize, displayItems: [AnnotationItem]) -> AnyView? {
        guard
            let textEditingState,
            let item = displayItems.first(where: { $0.id == textEditingState.annotationID && $0.kind == .text })
        else {
            return nil
        }
        let draftBinding = Binding(
            get: { textEditingState.draftText },
            set: { newValue in
                onTextEditingStateChange(
                    TextInlineEditingState(annotationID: textEditingState.annotationID, draftText: newValue)
                )
            }
        )
        return AnyView(
            TextField("Text", text: draftBinding)
            .textFieldStyle(.roundedBorder)
            .frame(width: textEditorWidth(for: textEditingState.draftText))
            .position(item.center)
            .focused($textEditorFocused)
            .onAppear {
                DispatchQueue.main.async {
                    textEditorFocused = true
                }
            }
            .onSubmit {
                onTextCommit(textEditingState)
            }
        )
    }

    private func inlineCounterEditor(in imageRect: CGRect, imageSize: CGSize, displayItems: [AnnotationItem]) -> AnyView? {
        guard
            let counterEditingState,
            let item = displayItems.first(where: { $0.id == counterEditingState.annotationID && $0.kind == .number })
        else {
            return nil
        }
        let draftBinding = Binding(
            get: { counterEditingState.draftValue },
            set: { newValue in
                onCounterEditingStateChange(
                    CounterInlineEditingState(annotationID: counterEditingState.annotationID, draftValue: newValue)
                )
            }
        )
        return AnyView(
            TextField("1", text: draftBinding)
                .textFieldStyle(.roundedBorder)
                .frame(width: 58)
                .multilineTextAlignment(.center)
                .position(item.center)
                .focused($counterEditorFocused)
                .onAppear {
                    DispatchQueue.main.async {
                        counterEditorFocused = true
                    }
                }
                .onSubmit {
                    onCounterCommit(counterEditingState)
                }
        )
    }

    private func mapItemToDisplay(_ item: AnnotationItem, imageRect: CGRect, imageSize: CGSize) -> AnnotationItem {
        var mapped = item
        mapped.center = mapToDisplayPoint(item.center, imageRect: imageRect, imageSize: imageSize)
        if let trailing = item.trailingPoint {
            mapped.trailingPoint = mapToDisplayPoint(trailing, imageRect: imageRect, imageSize: imageSize)
        }
        return mapped
    }

    private func mapToDisplayPoint(_ imagePoint: CGPoint, imageRect: CGRect, imageSize: CGSize) -> CGPoint {
        guard imageSize.width > 0, imageSize.height > 0 else { return imageRect.origin }
        let x = imageRect.minX + (imagePoint.x / imageSize.width) * imageRect.width
        let y = imageRect.minY + (imagePoint.y / imageSize.height) * imageRect.height
        return CGPoint(x: x, y: y)
    }

    private func adjustedPointForActiveTool(_ point: CGPoint) -> CGPoint {
        return point
    }

    private func hitTestAnnotation(at displayPoint: CGPoint, image: CGImage, size: CGSize) -> AnnotationItem? {
        let imageRect = displayImageRect(image: image, in: size)
        let imageSize = CGSize(width: image.width, height: image.height)
        for item in items.reversed() {
            let center = mapToDisplayPoint(item.center, imageRect: imageRect, imageSize: imageSize)
            let trailing = item.trailingPoint.map { mapToDisplayPoint($0, imageRect: imageRect, imageSize: imageSize) }
            switch item.kind {
            case .text:
                let hitRect = textHitRect(
                    for: item.displayValue ?? "Text",
                    at: center,
                    fontSize: CGFloat(item.fontSize ?? 20)
                )
                if hitRect.contains(displayPoint) { return item }
            case .number:
                let radius = counterHitRadius(for: item)
                if hypot(displayPoint.x - center.x, displayPoint.y - center.y) <= radius { return item }
            case .mosaic:
                let hitRect = CGRect(x: center.x - 46, y: center.y - 32, width: 92, height: 64)
                if hitRect.contains(displayPoint) { return item }
            case .box:
                if let trailing {
                    let rect = CGRect(
                        x: min(center.x, trailing.x) - 8,
                        y: min(center.y, trailing.y) - 8,
                        width: abs(trailing.x - center.x) + 16,
                        height: abs(trailing.y - center.y) + 16
                    )
                    if rect.contains(displayPoint) { return item }
                } else {
                    let hitRect = CGRect(x: center.x - 45, y: center.y - 30, width: 90, height: 60)
                    if hitRect.contains(displayPoint) { return item }
                }
            case .arrow:
                if let trailing, distanceToSegment(point: displayPoint, a: center, b: trailing) <= 12 {
                    return item
                }
            case .floatingPin:
                if hypot(displayPoint.x - center.x, displayPoint.y - center.y) <= 16 { return item }
            case .backdrop:
                let hitRect = CGRect(x: center.x - 90, y: center.y - 55, width: 180, height: 110)
                if hitRect.contains(displayPoint) { return item }
            }
        }
        return nil
    }

    private func distanceToSegment(point p: CGPoint, a: CGPoint, b: CGPoint) -> CGFloat {
        let abx = b.x - a.x
        let aby = b.y - a.y
        let apx = p.x - a.x
        let apy = p.y - a.y
        let ab2 = abx * abx + aby * aby
        if ab2 <= .ulpOfOne {
            return hypot(apx, apy)
        }
        let t = max(0, min(1, (apx * abx + apy * aby) / ab2))
        let cx = a.x + abx * t
        let cy = a.y + aby * t
        return hypot(p.x - cx, p.y - cy)
    }

    private func textHitRect(for value: String, at center: CGPoint, fontSize: CGFloat) -> CGRect {
        let text = value.isEmpty ? "Text" : value
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: fontSize)
        ]
        let measuredWidth = (text as NSString).size(withAttributes: attrs).width
        let width = max(44, measuredWidth + 20)
        let height = max(30, fontSize + 14)
        return CGRect(x: center.x - width / 2, y: center.y - height / 2, width: width, height: height)
    }

    private func textEditorWidth(for text: String) -> CGFloat {
        let value = text.isEmpty ? "Text" : text
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: NSFont.systemFontSize)
        ]
        let textWidth = (value as NSString).size(withAttributes: attrs).width
        return min(380, max(110, textWidth + 36))
    }

    private func counterHitRadius(for item: AnnotationItem) -> CGFloat {
        let clamped = min(max(CGFloat(item.strokeWidth ?? 0), 1), 12)
        let diameter = 20 + clamped * 2.8
        return max(20, diameter / 2 + 4)
    }
}

private struct BackdropStackView: View {
    let imageRect: CGRect
    let color: Color
    let gradientColors: [Color]?
    let cornerRadius: Double
    let inset: Double

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(backdropFill)
            .frame(width: imageRect.width + (inset * 2), height: imageRect.height + (inset * 2))
            .position(x: imageRect.midX, y: imageRect.midY)
    }

    private var backdropFill: AnyShapeStyle {
        if let gradientColors, gradientColors.count >= 2 {
            return AnyShapeStyle(
                LinearGradient(colors: gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing)
            )
        }
        return AnyShapeStyle(color)
    }
}
