import CoreGraphics
import CoreText
import Foundation

public struct CompositionRenderer {
    public init() {}

    public func render(baseImage: CGImage, annotations: [AnnotationItem]) -> CGImage {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: nil,
            width: baseImage.width,
            height: baseImage.height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return baseImage
        }

        let canvas = CGRect(x: 0, y: 0, width: baseImage.width, height: baseImage.height)
        context.draw(baseImage, in: canvas)
        for item in annotations {
            draw(item: item, in: context)
        }
        return context.makeImage() ?? baseImage
    }

    private func draw(item: AnnotationItem, in context: CGContext) {
        switch item.kind {
        case .text:
            let value = (item.displayValue ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            guard value.isEmpty == false else { break }
            drawCenteredText(
                value,
                at: item.center,
                in: context,
                fontSize: 24,
                fontName: "HelveticaNeue-Medium",
                color: CGColor(red: 1, green: 1, blue: 1, alpha: 0.96)
            )
        case .box:
            context.setStrokeColor(CGColor(red: 0.98, green: 0.86, blue: 0.20, alpha: 0.95))
            context.setLineWidth(3)
            if let end = item.trailingPoint {
                context.stroke(CGRect(
                    x: min(item.center.x, end.x),
                    y: min(item.center.y, end.y),
                    width: abs(end.x - item.center.x),
                    height: abs(end.y - item.center.y)
                ))
            } else {
                context.stroke(CGRect(x: item.center.x - 45, y: item.center.y - 30, width: 90, height: 60))
            }
        case .arrow:
            context.setStrokeColor(CGColor(red: 0.95, green: 0.25, blue: 0.25, alpha: 0.95))
            context.setLineWidth(4)
            if let end = item.trailingPoint {
                context.move(to: item.center)
                context.addLine(to: end)
                context.strokePath()
                let angle = atan2(end.y - item.center.y, end.x - item.center.x)
                let headLength: CGFloat = 16
                let left = CGPoint(
                    x: end.x - headLength * cos(angle - .pi / 6),
                    y: end.y - headLength * sin(angle - .pi / 6)
                )
                let right = CGPoint(
                    x: end.x - headLength * cos(angle + .pi / 6),
                    y: end.y - headLength * sin(angle + .pi / 6)
                )
                context.move(to: end)
                context.addLine(to: left)
                context.move(to: end)
                context.addLine(to: right)
                context.strokePath()
            } else {
                context.move(to: CGPoint(x: item.center.x - 35, y: item.center.y - 20))
                context.addLine(to: CGPoint(x: item.center.x + 25, y: item.center.y + 20))
                context.strokePath()
                context.setFillColor(CGColor(red: 0.95, green: 0.25, blue: 0.25, alpha: 0.95))
                context.beginPath()
                context.move(to: CGPoint(x: item.center.x + 35, y: item.center.y + 24))
                context.addLine(to: CGPoint(x: item.center.x + 16, y: item.center.y + 17))
                context.addLine(to: CGPoint(x: item.center.x + 27, y: item.center.y + 4))
                context.closePath()
                context.fillPath()
            }
        case .number:
            let bubbleRect = CGRect(x: item.center.x - 14, y: item.center.y - 14, width: 28, height: 28)
            context.setFillColor(CGColor(red: 0.97, green: 0.20, blue: 0.16, alpha: 0.95))
            context.fillEllipse(in: bubbleRect)
            let value = (item.displayValue ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            if value.isEmpty == false {
                drawCenteredText(
                    value,
                    at: item.center,
                    in: context,
                    fontSize: 14,
                    fontName: "HelveticaNeue-Bold",
                    color: CGColor(red: 1, green: 1, blue: 1, alpha: 0.98)
                )
            }
        case .mosaic:
            let area = CGRect(x: item.center.x - 46, y: item.center.y - 32, width: 92, height: 64)
            let tile: CGFloat = 8
            var row = 0
            var y = area.minY
            while y < area.maxY {
                var column = 0
                var x = area.minX
                while x < area.maxX {
                    let rect = CGRect(
                        x: x,
                        y: y,
                        width: min(tile, area.maxX - x),
                        height: min(tile, area.maxY - y)
                    )
                    let bright = (row + column).isMultiple(of: 2)
                    if bright {
                        context.setFillColor(CGColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 0.86))
                    } else {
                        context.setFillColor(CGColor(red: 0.45, green: 0.45, blue: 0.45, alpha: 0.86))
                    }
                    context.fill(rect)
                    column += 1
                    x += tile
                }
                row += 1
                y += tile
            }
            context.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.75))
            context.setLineWidth(1.5)
            context.stroke(area)
        case .floatingPin:
            context.setFillColor(CGColor(red: 0.93, green: 0.33, blue: 0.56, alpha: 0.95))
            context.fillEllipse(in: CGRect(x: item.center.x - 9, y: item.center.y - 9, width: 18, height: 18))
            context.beginPath()
            context.move(to: CGPoint(x: item.center.x, y: item.center.y - 10))
            context.addLine(to: CGPoint(x: item.center.x - 5, y: item.center.y - 22))
            context.addLine(to: CGPoint(x: item.center.x + 5, y: item.center.y - 22))
            context.closePath()
            context.fillPath()
        case .backdrop:
            let rect = CGRect(x: item.center.x - 90, y: item.center.y - 55, width: 180, height: 110)
            context.setFillColor(CGColor(red: 0, green: 0, blue: 0, alpha: 0.30))
            context.fill(rect)
            context.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.65))
            context.setLineWidth(1.5)
            context.stroke(rect)
        }
    }

    private func drawCenteredText(
        _ text: String,
        at center: CGPoint,
        in context: CGContext,
        fontSize: CGFloat,
        fontName: String,
        color: CGColor
    ) {
        let font = CTFontCreateWithName(fontName as CFString, fontSize, nil)
        let attributes: [CFString: Any] = [
            kCTFontAttributeName: font,
            kCTForegroundColorAttributeName: color
        ]
        guard let attributed = CFAttributedStringCreate(nil, text as CFString, attributes as CFDictionary) else { return }
        let line = CTLineCreateWithAttributedString(attributed)
        let bounds = CTLineGetBoundsWithOptions(line, .useGlyphPathBounds)
        context.saveGState()
        context.textMatrix = .identity
        context.textPosition = CGPoint(
            x: center.x - bounds.width / 2 - bounds.minX,
            y: center.y - bounds.height / 2 - bounds.minY
        )
        CTLineDraw(line, context)
        context.restoreGState()
    }
}
