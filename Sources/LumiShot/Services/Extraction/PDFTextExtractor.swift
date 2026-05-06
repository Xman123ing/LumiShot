import CoreGraphics
import Foundation

public struct PDFTextExtractor {
    public typealias TextLayerExtractor = (URL) -> String?
    public typealias PageRenderer = (URL) -> CGImage?

    private let ocrEngine: OCREngine
    private let textLayerExtractor: TextLayerExtractor
    private let pageRenderer: PageRenderer

    public init(
        ocrEngine: OCREngine,
        textLayerExtractor: @escaping TextLayerExtractor = { _ in nil },
        pageRenderer: @escaping PageRenderer = { _ in
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let context = CGContext(
                data: nil,
                width: 10,
                height: 10,
                bitsPerComponent: 8,
                bytesPerRow: 0,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )
            return context?.makeImage()
        }
    ) {
        self.ocrEngine = ocrEngine
        self.textLayerExtractor = textLayerExtractor
        self.pageRenderer = pageRenderer
    }

    public func extract(from pdfURL: URL) async throws -> ExtractedTextDocument {
        if let text = textLayerExtractor(pdfURL), !text.isEmpty {
            return ExtractedTextDocument(content: text, path: .pdfTextLayer)
        }
        guard let renderedPage = pageRenderer(pdfURL) else {
            return ExtractedTextDocument(content: "", path: .pdfOCRFallback)
        }
        let ocrText = try await ocrEngine.recognize(image: renderedPage, languageHints: ["zh-Hans", "en-US"])
        return ExtractedTextDocument(content: ocrText.text, path: .pdfOCRFallback)
    }
}
