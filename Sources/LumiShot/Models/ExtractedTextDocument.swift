import Foundation

public enum ExtractionPath: Equatable, Sendable {
    case imageOCR
    case webDOM
    case webOCRFallback
    case pdfTextLayer
    case pdfOCRFallback
}

public struct ExtractedTextDocument: Equatable, Sendable {
    public let content: String
    public let path: ExtractionPath

    public init(content: String, path: ExtractionPath) {
        self.content = content
        self.path = path
    }
}
