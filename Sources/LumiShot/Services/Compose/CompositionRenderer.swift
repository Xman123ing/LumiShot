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
        let canvasHeight = CGFloat(context.height)
        switch item.kind {
        case .text:
            let value = (item.displayValue ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            guard value.isEmpty == false else { break }
            let center = quartzPoint(fromTopLeft: item.center, canvasHeight: canvasHeight)
            drawCenteredText(
                value,
                at: center,
                in: context,
                fontSize: CGFloat(item.fontSize ?? 24),
                fontName: "HelveticaNeue-Medium",
                color: item.color?.cgColor ?? AnnotationColor.defaultColor(for: .text).cgColor
            )
        case .box:
            context.setStrokeColor(item.color?.cgColor ?? AnnotationColor.defaultColor(for: .rectangle).cgColor)
            context.setLineWidth(CGFloat(item.strokeWidth ?? 3))
            if let end = item.trailingPoint {
                let startQuartz = quartzPoint(fromTopLeft: item.center, canvasHeight: canvasHeight)
                let endQuartz = quartzPoint(fromTopLeft: end, canvasHeight: canvasHeight)
                context.stroke(CGRect(
                    x: min(startQuartz.x, endQuartz.x),
                    y: min(startQuartz.y, endQuartz.y),
                    width: abs(endQuartz.x - startQuartz.x),
                    height: abs(endQuartz.y - startQuartz.y)
                ))
            } else {
                let center = quartzPoint(fromTopLeft: item.center, canvasHeight: canvasHeight)
                context.stroke(CGRect(x: center.x - 45, y: center.y - 30, width: 90, height: 60))
            }
        case .arrow:
            context.setStrokeColor(item.color?.cgColor ?? AnnotationColor.defaultColor(for: .arrow).cgColor)
            context.setLineWidth(CGFloat(item.strokeWidth ?? 4))
            if let end = item.trailingPoint {
                let startQuartz = quartzPoint(fromTopLeft: item.center, canvasHeight: canvasHeight)
                let endQuartz = quartzPoint(fromTopLeft: end, canvasHeight: canvasHeight)
                context.move(to: startQuartz)
                context.addLine(to: endQuartz)
                context.strokePath()
                let angle = atan2(endQuartz.y - startQuartz.y, endQuartz.x - startQuartz.x)
                let headLength: CGFloat = 16
                let left = CGPoint(
                    x: endQuartz.x - headLength * cos(angle - .pi / 6),
                    y: endQuartz.y - headLength * sin(angle - .pi / 6)
                )
                let right = CGPoint(
                    x: endQuartz.x - headLength * cos(angle + .pi / 6),
                    y: endQuartz.y - headLength * sin(angle + .pi / 6)
                )
                context.move(to: endQuartz)
                context.addLine(to: left)
                context.move(to: endQuartz)
                context.addLine(to: right)
                context.strokePath()
            } else {
                let center = quartzPoint(fromTopLeft: item.center, canvasHeight: canvasHeight)
                context.move(to: CGPoint(x: center.x - 35, y: center.y - 20))
                context.addLine(to: CGPoint(x: center.x + 25, y: center.y + 20))
                context.strokePath()
                context.setFillColor(item.color?.cgColor ?? AnnotationColor.defaultColor(for: .arrow).cgColor)
                context.beginPath()
                context.move(to: CGPoint(x: center.x + 35, y: center.y + 24))
                context.addLine(to: CGPoint(x: center.x + 16, y: center.y + 17))
                context.addLine(to: CGPoint(x: center.x + 27, y: center.y + 4))
                context.closePath()
                context.fillPath()
            }
        case .number:
            let center = quartzPoint(fromTopLeft: item.center, canvasHeight: canvasHeight)
            let bubbleRect = CGRect(x: center.x - 14, y: center.y - 14, width: 28, height: 28)
            context.setFillColor(item.color?.cgColor ?? AnnotationColor.defaultColor(for: .counter).cgColor)
            context.fillEllipse(in: bubbleRect)
            if let stroke = item.strokeWidth, stroke > 0 {
                context.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.82))
                context.setLineWidth(CGFloat(stroke))
                context.strokeEllipse(in: bubbleRect.insetBy(dx: CGFloat(stroke) / 2, dy: CGFloat(stroke) / 2))
            }
            let value = (item.displayValue ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            if value.isEmpty == false {
                drawCenteredText(
                    value,
                    at: center,
                    in: context,
                    fontSize: 14,
                    fontName: "HelveticaNeue-Bold",
                    color: CGColor(red: 1, green: 1, blue: 1, alpha: 0.98)
                )
            }
        case .mosaic:
            let center = quartzPoint(fromTopLeft: item.center, canvasHeight: canvasHeight)
            let area = CGRect(x: center.x - 46, y: center.y - 32, width: 92, height: 64)
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
            let center = quartzPoint(fromTopLeft: item.center, canvasHeight: canvasHeight)
            context.setFillColor(CGColor(red: 0.93, green: 0.33, blue: 0.56, alpha: 0.95))
            context.fillEllipse(in: CGRect(x: center.x - 9, y: center.y - 9, width: 18, height: 18))
            context.beginPath()
            context.move(to: CGPoint(x: center.x, y: center.y - 10))
            context.addLine(to: CGPoint(x: center.x - 5, y: center.y - 22))
            context.addLine(to: CGPoint(x: center.x + 5, y: center.y - 22))
            context.closePath()
            context.fillPath()
        case .backdrop:
            let center = quartzPoint(fromTopLeft: item.center, canvasHeight: canvasHeight)
            let rect = CGRect(x: center.x - 90, y: center.y - 55, width: 180, height: 110)
            context.setFillColor(item.color?.cgColor ?? AnnotationColor.defaultColor(for: .backdrop).cgColor)
            context.fill(rect)
            context.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.65))
            context.setLineWidth(CGFloat(item.strokeWidth ?? 1.5))
            context.stroke(rect)
        }
    }

    private func quartzPoint(fromTopLeft point: CGPoint, canvasHeight: CGFloat) -> CGPoint {
        CGPoint(x: point.x, y: canvasHeight - point.y)
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
