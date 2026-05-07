import SwiftUI

public struct AnnotationCanvasView: View {
    public let items: [AnnotationItem]

    public init(items: [AnnotationItem]) {
        self.items = items
    }

    public var body: some View {
        ZStack {
            ForEach(items) { item in
                switch item.kind {
                case .number:
                    Text(item.displayValue ?? "")
                        .font(.system(size: 14, weight: .bold))
                        .padding(8)
                        .background(.orange.opacity(0.8), in: Circle())
                        .position(item.center)
                case .text:
                    Text(item.displayValue ?? "Text")
                        .position(item.center)
                case .box:
                    Rectangle()
                        .stroke(.yellow, lineWidth: 2)
                        .frame(width: 80, height: 50)
                        .position(item.center)
                case .arrow:
                    Image(systemName: "arrow.right")
                        .foregroundStyle(.red)
                        .position(item.center)
                case .mosaic:
                    MosaicBlockView()
                        .frame(width: 92, height: 64)
                        .position(item.center)
                }
            }
        }
    }
}

private struct MosaicBlockView: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(.black.opacity(0.28))
            VStack(spacing: 2) {
                ForEach(0..<4, id: \.self) { row in
                    HStack(spacing: 2) {
                        ForEach(0..<6, id: \.self) { column in
                            Rectangle()
                                .fill(tileColor(row: row, column: column))
                        }
                    }
                }
            }
            .padding(6)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(.white.opacity(0.65), lineWidth: 1)
        )
    }

    private func tileColor(row: Int, column: Int) -> Color {
        let even = (row + column).isMultiple(of: 2)
        return even ? Color.white.opacity(0.72) : Color.gray.opacity(0.58)
    }
}
