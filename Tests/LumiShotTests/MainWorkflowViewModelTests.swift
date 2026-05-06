import XCTest
@testable import LumiShot

final class MainWorkflowViewModelTests: XCTestCase {
    @MainActor
    func testWorkflowProducesExportAfterCaptureAnnotateExtract() async throws {
        let sut = MainWorkflowViewModel.mockedSuccessPath()
        try await sut.runCapture(mode: .region)
        sut.addNumberAnnotation()
        try await sut.extractTextFromCurrentAsset()
        let output = try sut.exportCurrent()
        XCTAssertEqual(output.png.pathExtension, "png")
        XCTAssertFalse(sut.diagnostics.sessionID.isEmpty)
    }
}
