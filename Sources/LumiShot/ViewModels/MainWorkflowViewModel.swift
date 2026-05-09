import CoreGraphics
import Foundation

@MainActor
public final class MainWorkflowViewModel: ObservableObject {
    @Published public private(set) var diagnostics: SessionDiagnostics = .newSession()
    @Published public private(set) var currentCapture: CaptureAsset?
    @Published public private(set) var extractedText: ExtractedTextDocument?
    @Published public private(set) var annotationStore = AnnotationStore()

    private let captureService: CaptureServicing
    private let imageTextExtractor: ImageTextExtractor
    private let exportService: ExportService
    private let compositionRenderer: CompositionRenderer

    public init(
        captureService: CaptureServicing,
        imageTextExtractor: ImageTextExtractor,
        exportService: ExportService = ExportService(),
        compositionRenderer: CompositionRenderer = CompositionRenderer()
    ) {
        self.captureService = captureService
        self.imageTextExtractor = imageTextExtractor
        self.exportService = exportService
        self.compositionRenderer = compositionRenderer
    }

    public func runCapture(mode: CaptureMode, region: CGRect? = nil) async throws {
        currentCapture = try await captureService.capture(mode: mode, region: region)
        annotationStore = AnnotationStore()
        extractedText = nil
        diagnostics.captureStatus = "success:\(mode.rawValue)"
    }

    public func addNumberAnnotation(color: AnnotationColor? = nil, strokeWidth: Double? = nil) {
        objectWillChange.send()
        _ = annotationStore.addNumber(at: CGPoint(x: 40, y: 40), color: color, strokeWidth: strokeWidth)
    }

    public func addTextAnnotation(_ value: String = "Text", color: AnnotationColor? = nil) {
        objectWillChange.send()
        _ = annotationStore.addText(value, at: CGPoint(x: 90, y: 60), color: color)
    }

    public func addBoxAnnotation(color: AnnotationColor? = nil) {
        objectWillChange.send()
        _ = annotationStore.addBox(at: CGPoint(x: 160, y: 90), color: color)
    }

    @discardableResult
    public func addBoxAnnotation(
        from start: CGPoint,
        to end: CGPoint,
        color: AnnotationColor? = nil,
        strokeWidth: Double? = nil
    ) -> AnnotationItem {
        objectWillChange.send()
        return annotationStore.addBox(from: start, to: end, color: color, strokeWidth: strokeWidth)
    }

    public func addArrowAnnotation(color: AnnotationColor? = nil) {
        objectWillChange.send()
        _ = annotationStore.addArrow(at: CGPoint(x: 210, y: 120), color: color)
    }

    @discardableResult
    public func addArrowAnnotation(
        from start: CGPoint,
        to end: CGPoint,
        color: AnnotationColor? = nil,
        strokeWidth: Double? = nil
    ) -> AnnotationItem {
        objectWillChange.send()
        return annotationStore.addArrow(from: start, to: end, color: color, strokeWidth: strokeWidth)
    }

    public func addMosaicAnnotation() {
        objectWillChange.send()
        _ = annotationStore.addMosaic(at: CGPoint(x: 250, y: 150))
    }

    public func addFloatingPinAnnotation() {
        objectWillChange.send()
        _ = annotationStore.addFloatingPin(at: CGPoint(x: 220, y: 120))
    }

    public func addBackdropAnnotation(color: AnnotationColor? = nil) {
        objectWillChange.send()
        _ = annotationStore.addBackdrop(at: CGPoint(x: 260, y: 170), color: color)
    }

    @discardableResult
    public func addTextAnnotation(
        at point: CGPoint,
        value: String = "Text",
        color: AnnotationColor? = nil,
        fontSize: Double? = nil
    ) -> AnnotationItem {
        objectWillChange.send()
        return annotationStore.addText(value, at: point, color: color, fontSize: fontSize)
    }

    @discardableResult
    public func addNumberAnnotation(
        at point: CGPoint,
        tailPoint: CGPoint? = nil,
        color: AnnotationColor? = nil,
        strokeWidth: Double? = nil
    ) -> AnnotationItem {
        objectWillChange.send()
        return annotationStore.addNumber(at: point, tailPoint: tailPoint, color: color, strokeWidth: strokeWidth)
    }

    public func updateTextAnnotation(id: UUID, value: String) {
        objectWillChange.send()
        annotationStore.updateText(id: id, value: value)
    }

    public func updateNumberAnnotation(id: UUID, value: String) {
        objectWillChange.send()
        annotationStore.updateNumber(id: id, value: value)
    }

    public func updateAnnotationTail(id: UUID, point: CGPoint) {
        objectWillChange.send()
        annotationStore.updateTrailingPoint(id: id, point: point)
    }

    public func updateAnnotationStyle(
        id: UUID,
        color: AnnotationColor? = nil,
        strokeWidth: Double? = nil,
        fontSize: Double? = nil
    ) {
        objectWillChange.send()
        annotationStore.updateStyle(id: id, color: color, strokeWidth: strokeWidth, fontSize: fontSize)
    }

    public func moveAnnotation(id: UUID, delta: CGPoint) {
        objectWillChange.send()
        annotationStore.moveItem(id: id, delta: delta)
    }

    public func setAnnotationPosition(id: UUID, center: CGPoint, trailingPoint: CGPoint?) {
        objectWillChange.send()
        annotationStore.setItemPosition(id: id, center: center, trailingPoint: trailingPoint)
    }

    public func replaceAnnotations(with items: [AnnotationItem]) {
        objectWillChange.send()
        annotationStore.replaceAll(with: items)
    }

    public func removeAnnotation(id: UUID) {
        objectWillChange.send()
        annotationStore.removeItem(id: id)
    }

    public func extractTextFromCurrentAsset() async throws {
        let image = currentCapture?.image ?? Self.makeFallbackImage()
        let output = try await imageTextExtractor.extract(from: image)
        extractedText = output
        diagnostics.extractionStatus = "success:\(output.path)"
    }

    public func applyOCRText(_ text: String, path: ExtractionPath = .imageOCR) {
        extractedText = ExtractedTextDocument(content: text, path: path)
        diagnostics.extractionStatus = "success:\(path)"
    }

    public func exportCurrent() throws -> ExportURLs {
        let image = composedImage()
        let urls = try exportService.exportPNG(
            image: image,
            baseName: timestampedExportBaseName(),
            directory: defaultExportDirectory()
        )
        diagnostics.exportStatus = "success"
        return urls
    }

    public func composedImage() -> CGImage {
        let baseImage = currentCapture?.image ?? Self.makeFallbackImage()
        return compositionRenderer.render(baseImage: baseImage, annotations: annotationStore.items)
    }

    public static func mockedSuccessPath() -> MainWorkflowViewModel {
        let captureService = MockCaptureService()
        let extractor = ImageTextExtractor(ocrEngine: MockOCR())
        return MainWorkflowViewModel(captureService: captureService, imageTextExtractor: extractor)
    }

    public static func live() -> MainWorkflowViewModel {
        let capture = CaptureService(permissionService: CapturePermissionService())
        let imageExtractor = ImageTextExtractor(ocrEngine: VisionOCREngine())
        return MainWorkflowViewModel(captureService: capture, imageTextExtractor: imageExtractor)
    }

    static func makeFallbackImage() -> CGImage {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(
            data: nil,
            width: 12,
            height: 12,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        context.setFillColor(gray: 0.4, alpha: 1.0)
        context.fill(CGRect(x: 0, y: 0, width: 12, height: 12))
        return context.makeImage()!
    }

    private func defaultExportDirectory() -> URL {
        let downloads = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
        return downloads ?? FileManager.default.homeDirectoryForCurrentUser
    }

    private func timestampedExportBaseName(date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return formatter.string(from: date)
    }
}

private struct MockCaptureService: CaptureServicing {
    func capture(mode: CaptureMode, region: CGRect?) async throws -> CaptureAsset {
        let _ = region
        return CaptureAsset(mode: mode, image: makeMockImage())
    }

    private func makeMockImage() -> CGImage {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(
            data: nil,
            width: 12,
            height: 12,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        context.setFillColor(gray: 0.5, alpha: 1.0)
        context.fill(CGRect(x: 0, y: 0, width: 12, height: 12))
        return context.makeImage()!
    }
}

private struct MockOCR: OCREngine {
    func recognize(image: CGImage, languageHints: [String]) async throws -> OCRResult {
        let _ = image
        let _ = languageHints
        return OCRResult(text: "mock-extracted-text")
    }
}
