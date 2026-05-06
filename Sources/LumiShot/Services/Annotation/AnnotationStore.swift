import CoreGraphics
import Foundation

public final class AnnotationStore {
    public private(set) var items: [AnnotationItem] = []
    private var nextNumber: Int = 1

    public init() {}

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
}
