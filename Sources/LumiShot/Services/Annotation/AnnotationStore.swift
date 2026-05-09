import CoreGraphics
import Foundation

public final class AnnotationStore {
    public private(set) var items: [AnnotationItem] = []
    private var nextNumber: Int = 1

    public init() {}

    @discardableResult
    public func addText(
        _ value: String,
        at point: CGPoint,
        color: AnnotationColor? = nil,
        fontSize: Double? = nil
    ) -> AnnotationItem {
        let item = AnnotationItem.text(value: value, center: point, color: color, fontSize: fontSize)
        items.append(item)
        return item
    }

    @discardableResult
    public func addBox(at point: CGPoint, color: AnnotationColor? = nil, strokeWidth: Double? = nil) -> AnnotationItem {
        let item = AnnotationItem.box(center: point, color: color, strokeWidth: strokeWidth)
        items.append(item)
        return item
    }

    @discardableResult
    public func addBox(
        from start: CGPoint,
        to end: CGPoint,
        color: AnnotationColor? = nil,
        strokeWidth: Double? = nil
    ) -> AnnotationItem {
        let item = AnnotationItem.box(start: start, end: end, color: color, strokeWidth: strokeWidth)
        items.append(item)
        return item
    }

    @discardableResult
    public func addArrow(at point: CGPoint, color: AnnotationColor? = nil, strokeWidth: Double? = nil) -> AnnotationItem {
        let item = AnnotationItem.arrow(center: point, color: color, strokeWidth: strokeWidth)
        items.append(item)
        return item
    }

    @discardableResult
    public func addArrow(
        from start: CGPoint,
        to end: CGPoint,
        color: AnnotationColor? = nil,
        strokeWidth: Double? = nil
    ) -> AnnotationItem {
        let item = AnnotationItem.arrow(start: start, end: end, color: color, strokeWidth: strokeWidth)
        items.append(item)
        return item
    }

    @discardableResult
    public func addNumber(
        at point: CGPoint,
        tailPoint: CGPoint? = nil,
        color: AnnotationColor? = nil,
        strokeWidth: Double? = nil
    ) -> AnnotationItem {
        let item = AnnotationItem.number(
            value: "\(nextNumber)",
            center: point,
            tailPoint: tailPoint,
            color: color,
            strokeWidth: strokeWidth
        )
        nextNumber += 1
        items.append(item)
        return item
    }

    @discardableResult
    public func addMosaic(at point: CGPoint) -> AnnotationItem {
        let item = AnnotationItem.mosaic(center: point)
        items.append(item)
        return item
    }

    @discardableResult
    public func addFloatingPin(at point: CGPoint) -> AnnotationItem {
        let item = AnnotationItem.floatingPin(center: point)
        items.append(item)
        return item
    }

    @discardableResult
    public func addBackdrop(at point: CGPoint, color: AnnotationColor? = nil, strokeWidth: Double? = nil) -> AnnotationItem {
        let item = AnnotationItem.backdrop(center: point, color: color, strokeWidth: strokeWidth)
        items.append(item)
        return item
    }

    public func item(id: UUID) -> AnnotationItem? {
        items.first(where: { $0.id == id })
    }

    public func updateNumber(id: UUID, value: String) {
        guard let index = items.firstIndex(where: { $0.id == id && $0.kind == .number }) else { return }
        items[index].displayValue = value
    }

    public func updateText(id: UUID, value: String) {
        guard let index = items.firstIndex(where: { $0.id == id && $0.kind == .text }) else { return }
        items[index].displayValue = value
    }

    public func updateTrailingPoint(id: UUID, point: CGPoint) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].trailingPoint = point
    }

    public func updateStyle(
        id: UUID,
        color: AnnotationColor? = nil,
        strokeWidth: Double? = nil,
        fontSize: Double? = nil
    ) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        if let color {
            items[index].color = color
        }
        if let strokeWidth {
            items[index].strokeWidth = strokeWidth
        }
        if let fontSize {
            items[index].fontSize = fontSize
        }
    }

    public func moveItem(id: UUID, delta: CGPoint) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].center = CGPoint(
            x: items[index].center.x + delta.x,
            y: items[index].center.y + delta.y
        )
        if let trailing = items[index].trailingPoint {
            items[index].trailingPoint = CGPoint(
                x: trailing.x + delta.x,
                y: trailing.y + delta.y
            )
        }
    }

    public func setItemPosition(id: UUID, center: CGPoint, trailingPoint: CGPoint?) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].center = center
        items[index].trailingPoint = trailingPoint
    }

    public func replaceAll(with items: [AnnotationItem]) {
        self.items = items
        let maxNumber = items
            .filter { $0.kind == .number }
            .compactMap { Int($0.displayValue ?? "") }
            .max() ?? 0
        nextNumber = maxNumber + 1
    }

    public func removeItem(id: UUID) {
        items.removeAll { $0.id == id }
    }

}
