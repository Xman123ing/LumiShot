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

    public init(
        captureService: CaptureServicing,
        imageTextExtractor: ImageTextExtractor,
        exportService: ExportService = ExportService()
    ) {
        self.captureService = captureService
        self.imageTextExtractor = imageTextExtractor
        self.exportService = exportService
    }

    public func runCapture(mode: CaptureMode) async throws {
        currentCapture = try await captureService.capture(mode: mode)
        diagnostics.captureStatus = "success:\(mode.rawValue)"
    }

    public func addNumberAnnotation() {
        _ = annotationStore.addNumber(at: CGPoint(x: 40, y: 40))
    }

    public func extractTextFromCurrentAsset() async throws {
        let image = currentCapture?.image ?? Self.makeFallbackImage()
        let output = try await imageTextExtractor.extract(from: image)
        extractedText = output
        diagnostics.extractionStatus = "success:\(output.path)"
    }

    public func exportCurrent() throws -> ExportURLs {
        let text = extractedText?.content ?? ""
        let image = currentCapture?.image ?? Self.makeFallbackImage()
        let urls = try exportService.exportAll(
            image: image,
            text: text,
            baseName: "lumishot-export",
            directory: FileManager.default.temporaryDirectory
        )
        diagnostics.exportStatus = "success"
        return urls
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
}

private struct MockCaptureService: CaptureServicing {
    func capture(mode: CaptureMode) async throws -> CaptureAsset {
        CaptureAsset(mode: mode, image: makeMockImage())
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
