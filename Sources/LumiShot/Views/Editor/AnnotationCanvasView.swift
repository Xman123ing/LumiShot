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
                        sizeControl: CGFloat(item.strokeWidth ?? 0),
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
                        taperedArrowPath(from: item.center, to: end, sizeControl: CGFloat(item.strokeWidth ?? 3))
                            .fill(item.color?.swiftUIColor ?? AnnotationColor.defaultColor(for: .arrow).swiftUIColor)
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

    private func taperedArrowPath(from start: CGPoint, to end: CGPoint, sizeControl: CGFloat) -> Path {
        let dx = end.x - start.x
        let dy = end.y - start.y
        let length = hypot(dx, dy)
        guard length > 2 else {
            var dot = Path()
            dot.addEllipse(in: CGRect(x: start.x - 1, y: start.y - 1, width: 2, height: 2))
            return dot
        }
        let ux = dx / length
        let uy = dy / length
        let nx = -uy
        let ny = ux

        let clamped = min(max(sizeControl, 1), 12)
        let tailWidth = max(5, clamped * 1.0)
        let headLength = min(max(clamped * 3.8 + length * 0.18, 16), length * 0.56)
        let neckWidth = max(10, clamped * 1.9 + length * 0.02)
        let headWidth = max(neckWidth * 1.35, clamped * 3.4 + length * 0.05)
        let headBase = CGPoint(x: end.x - ux * headLength, y: end.y - uy * headLength)

        let tailLeft = CGPoint(x: start.x + nx * tailWidth * 0.5, y: start.y + ny * tailWidth * 0.5)
        let tailRight = CGPoint(x: start.x - nx * tailWidth * 0.5, y: start.y - ny * tailWidth * 0.5)
        let neckLeft = CGPoint(x: headBase.x + nx * neckWidth * 0.5, y: headBase.y + ny * neckWidth * 0.5)
        let neckRight = CGPoint(x: headBase.x - nx * neckWidth * 0.5, y: headBase.y - ny * neckWidth * 0.5)
        let leftWing = CGPoint(x: headBase.x + nx * headWidth * 0.5, y: headBase.y + ny * headWidth * 0.5)
        let rightWing = CGPoint(x: headBase.x - nx * headWidth * 0.5, y: headBase.y - ny * headWidth * 0.5)

        var path = Path()
        path.move(to: tailLeft)
        path.addLine(to: neckLeft)
        path.addLine(to: leftWing)
        path.addLine(to: end)
        path.addLine(to: rightWing)
        path.addLine(to: neckRight)
        path.addLine(to: tailRight)
        path.closeSubpath()
        return path
    }
}

private struct CounterBubbleView: View {
    let id: UUID
    let text: String
    let center: CGPoint
    let fillColor: Color
    let sizeControl: CGFloat
    let enableTap: Bool
    let onTap: ((UUID) -> Void)?

    var body: some View {
        let diameter = counterDiameter(for: sizeControl)
        let ringWidth = max(1.2, diameter * 0.08)
        let fontSize = max(12, diameter * 0.48)
        ZStack {
            Circle()
                .fill(fillColor)
                .frame(width: diameter, height: diameter)
                .overlay(
                    Circle()
                        .stroke(.white.opacity(0.82), lineWidth: ringWidth)
                )
            Text(text)
                .font(.system(size: fontSize, weight: .bold))
                .foregroundStyle(.white)
        }
        .position(center)
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            guard enableTap else { return }
            onTap?(id)
        }
    }

    private func counterDiameter(for sizeControl: CGFloat) -> CGFloat {
        // Counter slider range is 1...12. Map it to a clear visual size range.
        let clamped = min(max(sizeControl, 1), 12)
        return 20 + clamped * 2.8
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
