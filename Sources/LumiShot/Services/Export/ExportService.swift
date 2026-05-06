import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

public struct ExportURLs {
    public let png: URL
    public let jpeg: URL
    public let text: URL
    public let markdown: URL
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

    public func exportAll(image: CGImage, text: String, baseName: String, directory: URL) throws -> ExportURLs {
        if !fileManager.fileExists(atPath: directory.path) {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        let pngURL = directory.appendingPathComponent("\(baseName).png")
        let jpgURL = directory.appendingPathComponent("\(baseName).jpg")
        let txtURL = directory.appendingPathComponent("\(baseName).txt")
        let mdURL = directory.appendingPathComponent("\(baseName).md")
        try write(image: image, to: pngURL, type: UTType.png.identifier as CFString)
        try write(image: image, to: jpgURL, type: UTType.jpeg.identifier as CFString)
        try text.write(to: txtURL, atomically: true, encoding: .utf8)
        try text.write(to: mdURL, atomically: true, encoding: .utf8)
        return ExportURLs(png: pngURL, jpeg: jpgURL, text: txtURL, markdown: mdURL)
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
