import Foundation
import os

let appLogger = Logger(subsystem: "com.lumishot.app", category: "Lifecycle")

func logToDownloads(_ message: String) {
    appLogger.info("\(message, privacy: .public)")
    
    let downloadsURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
    let logURL = downloadsURL.appendingPathComponent("LumiShot_Crash_Log.txt")
    
    let timestamp = ISO8601DateFormatter().string(from: Date())
    let logMessage = "[\(timestamp)] \(message)\n"
    
    if let data = logMessage.data(using: .utf8) {
        if FileManager.default.fileExists(atPath: logURL.path) {
            if let fileHandle = try? FileHandle(forWritingTo: logURL) {
                fileHandle.seekToEndOfFile()
                fileHandle.write(data)
                fileHandle.closeFile()
            }
        } else {
            try? data.write(to: logURL)
        }
    }
}
