import SwiftUI

public struct MainWindowView: View {
    @StateObject private var viewModel = MainWorkflowViewModel.live()
    @State private var actionMessage = "Ready"
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

            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("LUMISHOT")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.62))
                    Text("Capture")
                    Text("Extract")
                    Text("Export")
                    Spacer()
                }
                .padding(16)
                .frame(width: StyleTokens.sidebarWidth)
                .frame(maxHeight: .infinity, alignment: .topLeading)
                .background(.black.opacity(0.22))

                VStack(alignment: .leading, spacing: 10) {
                    Text("LumiShot V1")
                        .font(.system(size: 20, weight: .bold))
                    Text("Capture -> Annotate -> Extract -> Export")
                        .foregroundStyle(.white.opacity(0.72))
                    Text("Session: \(viewModel.diagnostics.sessionID.prefix(8))")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.62))
                    Text("Capture: \(viewModel.diagnostics.captureStatus)")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.62))
                    Text("Extract: \(viewModel.diagnostics.extractionStatus)")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.62))
                    Text("Export: \(viewModel.diagnostics.exportStatus)")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.62))
                    Text(actionMessage)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.cyan.opacity(0.9))

                    HStack(spacing: 10) {
                        Picker("Mode", selection: $selectedMode) {
                            ForEach(CaptureMode.allCases, id: \.self) { mode in
                                Text(modeLabel(mode)).tag(mode)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 180)

                        Button("Capture") {
                            Task {
                                do {
                                    try await viewModel.runCapture(
                                        mode: selectedMode,
                                        region: regionRectForSelection()
                                    )
                                    actionMessage = "Capture completed."
                                } catch {
                                    actionMessage = "Capture failed: \(error.localizedDescription)"
                                }
                            }
                        }
                        .buttonStyle(.borderedProminent)

                        Button("Extract OCR") {
                            Task {
                                do {
                                    try await viewModel.extractTextFromCurrentAsset()
                                    actionMessage = "OCR completed."
                                } catch {
                                    actionMessage = "OCR failed: \(error.localizedDescription)"
                                }
                            }
                        }
                        .buttonStyle(.bordered)

                        Button("Export") {
                            do {
                                let urls = try viewModel.exportCurrent()
                                actionMessage = "Exported: \(urls.png.lastPathComponent)"
                            } catch {
                                actionMessage = "Export failed: \(error.localizedDescription)"
                            }
                        }
                        .buttonStyle(.bordered)
                    }

                    HStack(spacing: 8) {
                        Button("Text") {
                            viewModel.addTextAnnotation("Text")
                            actionMessage = "Added text annotation."
                        }
                        .buttonStyle(.bordered)

                        Button("Box") {
                            viewModel.addBoxAnnotation()
                            actionMessage = "Added box annotation."
                        }
                        .buttonStyle(.bordered)

                        Button("Arrow") {
                            viewModel.addArrowAnnotation()
                            actionMessage = "Added arrow annotation."
                        }
                        .buttonStyle(.bordered)

                        Button("Number") {
                            viewModel.addNumberAnnotation()
                            actionMessage = "Added number annotation."
                        }
                        .buttonStyle(.bordered)
                    }

                    if selectedMode == .region {
                        HStack(spacing: 8) {
                            Text("Region")
                                .foregroundStyle(.white.opacity(0.72))
                            regionField("x", value: $regionX)
                            regionField("y", value: $regionY)
                            regionField("w", value: $regionWidth)
                            regionField("h", value: $regionHeight)
                        }
                    }

                    if let text = viewModel.extractedText?.content, !text.isEmpty {
                        Text(text)
                            .font(.system(size: 12))
                            .lineLimit(8)
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(.black.opacity(0.2), in: RoundedRectangle(cornerRadius: 8))
                    }

                    if !viewModel.annotationStore.items.isEmpty {
                        AnnotationCanvasView(items: viewModel.annotationStore.items)
                            .frame(height: 180)
                            .frame(maxWidth: .infinity)
                            .background(.black.opacity(0.2), in: RoundedRectangle(cornerRadius: 8))
                    }
                    Spacer()
                }
                .padding(24)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            .foregroundStyle(.white)
            .background(.black.opacity(0.22))
            .clipShape(RoundedRectangle(cornerRadius: StyleTokens.cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: StyleTokens.cornerRadius, style: .continuous)
                    .stroke(.white.opacity(0.12), lineWidth: 1)
            }
            .padding(14)
        }
        .preferredColorScheme(.dark)
        .fontDesign(.rounded)
    }

    private func modeLabel(_ mode: CaptureMode) -> String {
        switch mode {
        case .region:
            return "Region"
        case .window:
            return "Window"
        case .fullScreen:
            return "Full Screen"
        case .scrolling:
            return "Scrolling"
        }
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
}
