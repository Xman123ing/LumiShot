import CoreGraphics

public struct OCRResult: Equatable, Sendable {
    public let text: String

    public init(text: String) {
        self.text = text
    }
}

public protocol OCREngine: Sendable {
    func recognize(image: CGImage, languageHints: [String]) async throws -> OCRResult
}
