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
    static func text(value: String, center: CGPoint) -> AnnotationItem {
        AnnotationItem(kind: .text, center: center, displayValue: value)
    }

    static func box(center: CGPoint) -> AnnotationItem {
        AnnotationItem(kind: .box, center: center)
    }

    static func arrow(center: CGPoint) -> AnnotationItem {
        AnnotationItem(kind: .arrow, center: center)
    }

    static func number(value: String, center: CGPoint) -> AnnotationItem {
        AnnotationItem(kind: .number, center: center, displayValue: value)
    }
}
