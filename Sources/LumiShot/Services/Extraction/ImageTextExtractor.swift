import CoreGraphics

public struct ImageTextExtractor {
    private let ocrEngine: OCREngine

    public init(ocrEngine: OCREngine) {
        self.ocrEngine = ocrEngine
    }

    @MainActor
    public func extract(from image: CGImage) async throws -> ExtractedTextDocument {
        let result = try await ocrEngine.recognize(
            image: image,
            languageHints: ["zh-Hans", "en-US"]
        )
        return ExtractedTextDocument(content: result.text, path: .imageOCR)
    }
}
