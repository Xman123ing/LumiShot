import CoreGraphics

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
            context.setFillColor(CGColor(red: 0.10, green: 0.82, blue: 0.85, alpha: 0.85))
            context.fillEllipse(in: CGRect(x: item.center.x - 7, y: item.center.y - 7, width: 14, height: 14))
        case .box:
            context.setStrokeColor(CGColor(red: 0.98, green: 0.86, blue: 0.20, alpha: 0.95))
            context.setLineWidth(3)
            context.stroke(CGRect(x: item.center.x - 45, y: item.center.y - 30, width: 90, height: 60))
        case .arrow:
            context.setStrokeColor(CGColor(red: 0.95, green: 0.25, blue: 0.25, alpha: 0.95))
            context.setLineWidth(4)
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
        case .number:
            context.setFillColor(CGColor(red: 1.0, green: 0.55, blue: 0.12, alpha: 0.9))
            context.fillEllipse(in: CGRect(x: item.center.x - 12, y: item.center.y - 12, width: 24, height: 24))
            context.setStrokeColor(CGColor(red: 1.0, green: 0.90, blue: 0.75, alpha: 0.95))
            context.setLineWidth(2)
            context.strokeEllipse(in: CGRect(x: item.center.x - 12, y: item.center.y - 12, width: 24, height: 24))
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
        }
    }
}
