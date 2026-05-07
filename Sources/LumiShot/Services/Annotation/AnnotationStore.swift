import CoreGraphics
import Foundation

public final class AnnotationStore {
    public private(set) var items: [AnnotationItem] = []
    private var nextNumber: Int = 1

    public init() {}

    @discardableResult
    public func addText(_ value: String, at point: CGPoint) -> AnnotationItem {
        let item = AnnotationItem.text(value: value, center: point)
        items.append(item)
        return item
    }

    @discardableResult
    public func addBox(at point: CGPoint) -> AnnotationItem {
        let item = AnnotationItem.box(center: point)
        items.append(item)
        return item
    }

    @discardableResult
    public func addArrow(at point: CGPoint) -> AnnotationItem {
        let item = AnnotationItem.arrow(center: point)
        items.append(item)
        return item
    }

    @discardableResult
    public func addNumber(at point: CGPoint) -> AnnotationItem {
        let item = AnnotationItem.number(value: "\(nextNumber)", center: point)
        nextNumber += 1
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
}
