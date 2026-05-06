import XCTest
@testable import LumiShot

final class ExtractionPipelineTests: XCTestCase {
    func testPdfFallsBackToOCRWhenTextLayerEmpty() async throws {
        let sut = PDFTextExtractor(
            ocrEngine: MockOCREngine(result: "fallback text"),
            textLayerExtractor: { _ in "" }
        )
        let output = try await sut.extract(from: .fixtureEmptyTextLayerPDF)
        XCTAssertEqual(output.content, "fallback text")
        XCTAssertEqual(output.path, .pdfOCRFallback)
    }
}

private struct MockOCREngine: OCREngine {
    let result: String

    func recognize(image: CGImage, languageHints: [String]) async throws -> OCRResult {
        let _ = image
        let _ = languageHints
        return OCRResult(text: result)
    }
}

private extension URL {
    static let fixtureEmptyTextLayerPDF = URL(fileURLWithPath: "/tmp/fixture-empty-text-layer.pdf")
}
