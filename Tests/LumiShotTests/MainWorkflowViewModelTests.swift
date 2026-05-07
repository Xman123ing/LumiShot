import CoreGraphics
import XCTest
@testable import LumiShotKit

final class MainWorkflowViewModelTests: XCTestCase {
    @MainActor
    func testWorkflowProducesExportAfterCaptureAnnotateExtract() async throws {
        let sut = MainWorkflowViewModel.mockedSuccessPath()
        try await sut.runCapture(mode: .region)
        sut.addNumberAnnotation()
        try await sut.extractTextFromCurrentAsset()
        let output = try sut.exportCurrent()
        XCTAssertEqual(output.png.pathExtension, "png")
        XCTAssertFalse(sut.diagnostics.sessionID.isEmpty)
    }

    @MainActor
    func testRunCapturePassesRegionToCaptureService() async throws {
        let expectedRegion = CGRect(x: 5, y: 8, width: 240, height: 160)
        let recorder = CaptureRecorder()
        let captureSpy = CaptureServiceSpy(recorder: recorder)
        let sut = MainWorkflowViewModel(
            captureService: captureSpy,
            imageTextExtractor: ImageTextExtractor(ocrEngine: WorkflowMockOCR())
        )

        try await sut.runCapture(mode: .region, region: expectedRegion)

        let recorded = await recorder.snapshot()
        XCTAssertEqual(recorded.mode, .region)
        XCTAssertEqual(recorded.region, expectedRegion)
    }

    @MainActor
    func testAddAnnotationToolsAppendExpectedKinds() {
        let sut = MainWorkflowViewModel.mockedSuccessPath()

        sut.addTextAnnotation("hello")
        sut.addBoxAnnotation()
        sut.addArrowAnnotation()
        sut.addNumberAnnotation()
        sut.addMosaicAnnotation()

        XCTAssertEqual(sut.annotationStore.items.map(\.kind), [.text, .box, .arrow, .number, .mosaic])
        XCTAssertEqual(sut.annotationStore.items.first?.displayValue, "hello")
    }

    @MainActor
    func testToolbarPrimaryAnnotationActionsAddExpectedItems() {
        let sut = MainWorkflowViewModel.mockedSuccessPath()

        for tool in ToolbarTool.primaryTools {
            switch tool {
            case .rectangle:
                sut.addBoxAnnotation()
            case .arrow:
                sut.addArrowAnnotation()
            case .text:
                sut.addTextAnnotation()
            case .counter:
                sut.addNumberAnnotation()
            case .floatingPin, .backdrop:
                XCTFail("Unexpected tool in ToolbarTool.primaryTools: \(tool)")
            }
        }

        XCTAssertEqual(sut.annotationStore.items.map(\.kind), [.box, .arrow, .text, .number])
    }

    @MainActor
    func testApplyOCRTextStoresExtractedDocumentForBackgroundOCRFlow() {
        let sut = MainWorkflowViewModel.mockedSuccessPath()

        sut.applyOCRText("piped OCR from notification")

        XCTAssertEqual(sut.extractedText?.content, "piped OCR from notification")
        XCTAssertEqual(sut.extractedText?.path, .imageOCR)
        XCTAssertEqual(sut.diagnostics.extractionStatus, "success:imageOCR")
    }
}

private struct CaptureServiceSpy: CaptureServicing {
    let recorder: CaptureRecorder

    func capture(mode: CaptureMode, region: CGRect?) async throws -> CaptureAsset {
        await recorder.record(mode: mode, region: region)
        return CaptureAsset(mode: mode, image: makeWorkflowMockImage())
    }
}

private struct WorkflowMockOCR: OCREngine {
    func recognize(image: CGImage, languageHints: [String]) async throws -> OCRResult {
        let _ = image
        let _ = languageHints
        return OCRResult(text: "ok")
    }
}

private actor CaptureRecorder {
    private(set) var mode: CaptureMode?
    private(set) var region: CGRect?

    func record(mode: CaptureMode, region: CGRect?) {
        self.mode = mode
        self.region = region
    }

    func snapshot() -> (mode: CaptureMode?, region: CGRect?) {
        (mode, region)
    }
}

private func makeWorkflowMockImage() -> CGImage {
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let context = CGContext(
        data: nil,
        width: 8,
        height: 8,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )!
    context.setFillColor(gray: 0.3, alpha: 1.0)
    context.fill(CGRect(x: 0, y: 0, width: 8, height: 8))
    return context.makeImage()!
}
