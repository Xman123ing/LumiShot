import SwiftUI

public struct AnnotationCanvasView: View {
    public let items: [AnnotationItem]
    public let enableCounterTap: Bool
    public let onTextDoubleClick: ((UUID) -> Void)?
    public let onCounterTap: ((UUID) -> Void)?

    public init(
        items: [AnnotationItem],
        enableCounterTap: Bool = true,
        onTextDoubleClick: ((UUID) -> Void)? = nil,
        onCounterTap: ((UUID) -> Void)? = nil
    ) {
        self.items = items
        self.enableCounterTap = enableCounterTap
        self.onTextDoubleClick = onTextDoubleClick
        self.onCounterTap = onCounterTap
    }

    public var body: some View {
        ZStack {
            ForEach(items) { item in
                switch item.kind {
                case .number:
                    CounterBubbleView(
                        id: item.id,
                        text: item.displayValue ?? "",
                        center: item.center,
                        fillColor: item.color?.swiftUIColor ?? AnnotationColor.defaultColor(for: .counter).swiftUIColor,
                        ringWidth: CGFloat(item.strokeWidth ?? 0),
                        enableTap: enableCounterTap,
                        onTap: onCounterTap
                    )
                case .text:
                    Text(item.displayValue ?? "Text")
                        .font(.system(size: CGFloat(item.fontSize ?? 20)))
                        .foregroundStyle(item.color?.swiftUIColor ?? AnnotationColor.defaultColor(for: .text).swiftUIColor)
                        .position(item.center)
                        .onTapGesture(count: 2) {
                            onTextDoubleClick?(item.id)
                        }
                case .box:
                    if let end = item.trailingPoint {
                        boxPath(from: item.center, to: end)
                            .stroke(
                                item.color?.swiftUIColor ?? AnnotationColor.defaultColor(for: .rectangle).swiftUIColor,
                                lineWidth: CGFloat(item.strokeWidth ?? 2)
                            )
                    } else {
                        Rectangle()
                            .stroke(
                                item.color?.swiftUIColor ?? AnnotationColor.defaultColor(for: .rectangle).swiftUIColor,
                                lineWidth: CGFloat(item.strokeWidth ?? 2)
                            )
                            .frame(width: 80, height: 50)
                            .position(item.center)
                    }
                case .arrow:
                    if let end = item.trailingPoint {
                        arrowPath(from: item.center, to: end)
                            .stroke(
                                item.color?.swiftUIColor ?? AnnotationColor.defaultColor(for: .arrow).swiftUIColor,
                                style: StrokeStyle(
                                    lineWidth: CGFloat(item.strokeWidth ?? 3),
                                    lineCap: .round,
                                    lineJoin: .round
                                )
                            )
                    } else {
                        Image(systemName: "arrow.right")
                            .foregroundStyle(item.color?.swiftUIColor ?? AnnotationColor.defaultColor(for: .arrow).swiftUIColor)
                            .position(item.center)
                    }
                case .mosaic:
                    MosaicBlockView()
                        .frame(width: 92, height: 64)
                        .position(item.center)
                case .floatingPin:
                    Image(systemName: "pin.fill")
                        .foregroundStyle(.pink)
                        .font(.system(size: 22, weight: .bold))
                        .position(item.center)
                case .backdrop:
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(item.color?.swiftUIColor ?? AnnotationColor.defaultColor(for: .backdrop).swiftUIColor)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(.white.opacity(0.65), lineWidth: 1.2)
                        )
                        .frame(width: 180, height: 110)
                        .position(item.center)
                }
            }
        }
    }

    private func boxPath(from start: CGPoint, to end: CGPoint) -> Path {
        let rect = CGRect(
            x: min(start.x, end.x),
            y: min(start.y, end.y),
            width: abs(end.x - start.x),
            height: abs(end.y - start.y)
        )
        var path = Path()
        path.addRect(rect)
        return path
    }

    private func arrowPath(from start: CGPoint, to end: CGPoint) -> Path {
        var path = Path()
        path.move(to: start)
        path.addLine(to: end)

        let angle = atan2(end.y - start.y, end.x - start.x)
        let headLength: CGFloat = 12
        let left = CGPoint(
            x: end.x - headLength * cos(angle - .pi / 6),
            y: end.y - headLength * sin(angle - .pi / 6)
        )
        let right = CGPoint(
            x: end.x - headLength * cos(angle + .pi / 6),
            y: end.y - headLength * sin(angle + .pi / 6)
        )
        path.move(to: end)
        path.addLine(to: left)
        path.move(to: end)
        path.addLine(to: right)
        return path
    }
}

private struct CounterBubbleView: View {
    let id: UUID
    let text: String
    let center: CGPoint
    let fillColor: Color
    let ringWidth: CGFloat
    let enableTap: Bool
    let onTap: ((UUID) -> Void)?

    var body: some View {
        ZStack {
            Circle()
                .fill(fillColor)
                .frame(width: 30, height: 30)
                .overlay(
                    Circle()
                        .stroke(.white.opacity(ringWidth > 0 ? 0.82 : 0), lineWidth: ringWidth)
                )
            Text(text)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)
        }
        .position(center)
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            guard enableTap else { return }
            onTap?(id)
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
