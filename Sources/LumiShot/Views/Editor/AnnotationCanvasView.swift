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
                }
            }
        }
    }
}
