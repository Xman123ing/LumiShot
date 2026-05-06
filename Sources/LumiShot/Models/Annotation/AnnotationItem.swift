import CoreGraphics
import Foundation

public struct AnnotationItem: Equatable, Identifiable {
    public let id: UUID
    public var kind: AnnotationKind
    public var center: CGPoint
    public var displayValue: String?

    public init(id: UUID = UUID(), kind: AnnotationKind, center: CGPoint, displayValue: String? = nil) {
        self.id = id
        self.kind = kind
        self.center = center
        self.displayValue = displayValue
    }
}

public extension AnnotationItem {
    static func number(value: String, center: CGPoint) -> AnnotationItem {
        AnnotationItem(kind: .number, center: center, displayValue: value)
    }
}
