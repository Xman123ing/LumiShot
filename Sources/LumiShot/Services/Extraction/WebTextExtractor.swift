import CoreGraphics
import Foundation

public struct WebTextExtractor {
    public typealias DOMExtractor = (URL) -> String?
    public typealias SnapshotRenderer = (URL) -> CGImage?

    private let domExtractor: DOMExtractor
    private let snapshotRenderer: SnapshotRenderer
    private let ocrEngine: OCREngine

    public init(
        ocrEngine: OCREngine,
        domExtractor: @escaping DOMExtractor = { _ in nil },
        snapshotRenderer: @escaping SnapshotRenderer = { _ in nil }
    ) {
        self.ocrEngine = ocrEngine
        self.domExtractor = domExtractor
        self.snapshotRenderer = snapshotRenderer
    }

    public func extract(from url: URL) async throws -> ExtractedTextDocument {
        if let text = domExtractor(url), !text.isEmpty {
            return ExtractedTextDocument(content: text, path: .webDOM)
        }
        guard let image = snapshotRenderer(url) else {
            return ExtractedTextDocument(content: "", path: .webOCRFallback)
        }
        let result = try await ocrEngine.recognize(image: image, languageHints: ["zh-Hans", "en-US"])
        return ExtractedTextDocument(content: result.text, path: .webOCRFallback)
    }
}
