import Foundation

public struct SessionDiagnostics: Equatable {
    public let sessionID: String
    public var captureStatus: String
    public var extractionStatus: String
    public var exportStatus: String

    public init(sessionID: String, captureStatus: String, extractionStatus: String, exportStatus: String) {
        self.sessionID = sessionID
        self.captureStatus = captureStatus
        self.extractionStatus = extractionStatus
        self.exportStatus = exportStatus
    }

    public static func newSession() -> SessionDiagnostics {
        SessionDiagnostics(
            sessionID: UUID().uuidString,
            captureStatus: "idle",
            extractionStatus: "idle",
            exportStatus: "idle"
        )
    }
}
