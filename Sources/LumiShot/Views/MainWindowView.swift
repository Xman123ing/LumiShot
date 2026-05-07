import AppKit
import SwiftUI

public struct MainWindowView: View {
    @StateObject private var viewModel = MainWorkflowViewModel.live()
    @State private var toastMessage: String?
    @State private var toastDismissToken = 0
    @State private var selectedMode: CaptureMode = .fullScreen
    @State private var regionX = "100"
    @State private var regionY = "100"
    @State private var regionWidth = "800"
    @State private var regionHeight = "500"

    public init() {}

    public var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.18, green: 0.18, blue: 0.20),
                    Color(red: 0.13, green: 0.13, blue: 0.15),
                    Color(red: 0.20, green: 0.19, blue: 0.22)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                TopToolbarView(
                    selectedMode: $selectedMode,
                    zoomText: "100%",
                    onCapture: {
                        Task {
                            do {
                                try await viewModel.runCapture(
                                    mode: selectedMode,
                                    region: regionRectForSelection()
                                )
                                showToast("Capture completed.")
                            } catch {
                                showToast("Capture failed: \(error.localizedDescription)")
                            }
                        }
                    },
                    onCopy: copyCurrentCaptureImage,
                    onSave: saveCurrentCaptureImage,
                    onAddBox: {
                        viewModel.addBoxAnnotation()
                        showToast("Rectangle added.")
                    },
                    onAddArrow: {
                        viewModel.addArrowAnnotation()
                        showToast("Arrow added.")
                    },
                    onAddText: {
                        viewModel.addTextAnnotation("Text")
                        showToast("Text added.")
                    },
                    onAddNumber: {
                        viewModel.addNumberAnnotation()
                        showToast("Counter added.")
                    },
                    onBackdrop: {
                        showToast("Backdrop style selected.")
                    },
                    onFloatingPin: {
                        viewModel.addTextAnnotation("Pin")
                        showToast("Floating pin added.")
                    }
                )
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.black.opacity(0.28))

                if selectedMode == .region {
                    HStack(spacing: 8) {
                        Text("Region")
                            .foregroundStyle(.white.opacity(0.72))
                        regionField("x", value: $regionX)
                        regionField("y", value: $regionY)
                        regionField("w", value: $regionWidth)
                        regionField("h", value: $regionHeight)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.black.opacity(0.18))
                }

                CanvasWorkspaceView(
                    items: viewModel.annotationStore.items,
                    hasCapture: viewModel.currentCapture != nil,
                    captureImage: viewModel.currentCapture?.image
                )
                    .padding(16)
            }
            .foregroundStyle(.white)
            .background(.black.opacity(0.22))
            .clipShape(RoundedRectangle(cornerRadius: StyleTokens.cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: StyleTokens.cornerRadius, style: .continuous)
                    .stroke(.white.opacity(0.12), lineWidth: 1)
            }
            .padding(14)

            ToastBannerView(message: $toastMessage, dismissToken: toastDismissToken)
        }
        .onReceive(NotificationCenter.default.publisher(for: LumiShotNotifications.didExtractOCRText)) { notification in
            if let text = notification.userInfo?[LumiShotNotifications.extractedTextKey] as? String {
                viewModel.applyOCRText(text)
                showToast("OCR applied (\(text.count) chars).")
            }
        }
        .preferredColorScheme(.dark)
        .fontDesign(.rounded)
    }

    private func regionRectForSelection() -> CGRect? {
        guard selectedMode == .region else { return nil }
        guard
            let x = Double(regionX),
            let y = Double(regionY),
            let width = Double(regionWidth),
            let height = Double(regionHeight)
        else {
            return nil
        }
        return CGRect(x: x, y: y, width: width, height: height)
    }

    private func regionField(_ label: String, value: Binding<String>) -> some View {
        TextField(label, text: value)
            .textFieldStyle(.roundedBorder)
            .frame(width: 82)
    }

    private func showToast(_ text: String) {
        toastDismissToken += 1
        toastMessage = text
    }

    private func copyCurrentCaptureImage() {
        guard let image = viewModel.currentCapture?.image else {
            showToast("Nothing to copy.")
            return
        }
        let size = NSSize(width: image.width, height: image.height)
        let nsImage = NSImage(cgImage: image, size: size)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.writeObjects([nsImage])
        showToast("Copied screenshot.")
    }

    private func saveCurrentCaptureImage() {
        do {
            let urls = try viewModel.exportCurrent()
            showToast("Saved: \(urls.png.lastPathComponent)")
        } catch {
            showToast("Save failed: \(error.localizedDescription)")
        }
    }
}
