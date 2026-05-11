import Foundation
import os

private let appLogger = Logger(subsystem: "com.lumishot.app", category: "Lifecycle")
private let logWriteQueue = DispatchQueue(label: "com.lumishot.app.log-write")

func logToDownloads(_ message: String) {
    let timestamp = ISO8601DateFormatter().string(from: Date())
    let line = "[\(timestamp)] \(message)\n"
    appLogger.info("\(line, privacy: .public)")

    logWriteQueue.async {
        let downloadsURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser
        let logURL = downloadsURL.appendingPathComponent("LumiShot_Runtime_Log.txt")
        guard let data = line.data(using: .utf8) else { return }

        if FileManager.default.fileExists(atPath: logURL.path) {
            if let fileHandle = try? FileHandle(forWritingTo: logURL) {
                defer { try? fileHandle.close() }
                do {
                    try fileHandle.seekToEnd()
                    try fileHandle.write(contentsOf: data)
                } catch {
                    // Ignore logging write errors to avoid affecting app flow.
                }
            }
        } else {
            try? data.write(to: logURL, options: .atomic)
        }
    }
}
