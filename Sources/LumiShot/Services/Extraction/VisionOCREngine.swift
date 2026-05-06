import CoreGraphics
import Vision

public struct VisionOCREngine: OCREngine {
    public init() {}

    public func recognize(image: CGImage, languageHints: [String]) async throws -> OCRResult {
        var recognizedLines: [String] = []
        let request = VNRecognizeTextRequest { request, error in
            if error != nil {
                return
            }
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                return
            }
            for observation in observations {
                if let candidate = observation.topCandidates(1).first {
                    recognizedLines.append(candidate.string)
                }
            }
        }
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        if !languageHints.isEmpty {
            request.recognitionLanguages = languageHints
        }

        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        try handler.perform([request])
        return OCRResult(text: recognizedLines.joined(separator: "\n"))
    }
}
