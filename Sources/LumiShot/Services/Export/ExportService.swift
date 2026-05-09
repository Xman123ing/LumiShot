import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

public struct ExportURLs {
    public let png: URL
}

public enum ExportError: Error {
    case unableToCreateDestination
    case finalizeFailed
}

public struct ExportService {
    private let fileManager: FileManager

    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    public func exportPNG(image: CGImage, baseName: String, directory: URL) throws -> ExportURLs {
        if !fileManager.fileExists(atPath: directory.path) {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        let pngURL = uniquePNGURL(baseName: baseName, directory: directory)
        try write(image: image, to: pngURL, type: UTType.png.identifier as CFString)
        return ExportURLs(png: pngURL)
    }

    private func uniquePNGURL(baseName: String, directory: URL) -> URL {
        let primaryURL = directory.appendingPathComponent("\(baseName).png")
        if fileManager.fileExists(atPath: primaryURL.path) == false {
            return primaryURL
        }
        var index = 1
        while true {
            let candidate = directory.appendingPathComponent("\(baseName)-\(String(format: "%02d", index)).png")
            if fileManager.fileExists(atPath: candidate.path) == false {
                return candidate
            }
            index += 1
        }
    }

    private func write(image: CGImage, to url: URL, type: CFString) throws {
        guard let destination = CGImageDestinationCreateWithURL(url as CFURL, type, 1, nil) else {
            throw ExportError.unableToCreateDestination
        }
        CGImageDestinationAddImage(destination, image, nil)
        if !CGImageDestinationFinalize(destination) {
            throw ExportError.finalizeFailed
        }
    }
}
