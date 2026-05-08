import CoreGraphics
import Foundation

public struct AnnotationItem: Equatable, Identifiable {
    public let id: UUID
    public var kind: AnnotationKind
    public var center: CGPoint
    public var trailingPoint: CGPoint?
    public var displayValue: String?

    public init(
        id: UUID = UUID(),
        kind: AnnotationKind,
        center: CGPoint,
        trailingPoint: CGPoint? = nil,
        displayValue: String? = nil
    ) {
        self.id = id
        self.kind = kind
        self.center = center
        self.trailingPoint = trailingPoint
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

    static func box(start: CGPoint, end: CGPoint) -> AnnotationItem {
        AnnotationItem(kind: .box, center: start, trailingPoint: end)
    }

    static func arrow(center: CGPoint) -> AnnotationItem {
        AnnotationItem(kind: .arrow, center: center)
    }

    static func arrow(start: CGPoint, end: CGPoint) -> AnnotationItem {
        AnnotationItem(kind: .arrow, center: start, trailingPoint: end)
    }

    static func number(value: String, center: CGPoint, tailPoint: CGPoint? = nil) -> AnnotationItem {
        AnnotationItem(kind: .number, center: center, trailingPoint: tailPoint, displayValue: value)
    }

    static func mosaic(center: CGPoint) -> AnnotationItem {
        AnnotationItem(kind: .mosaic, center: center)
    }

    static func floatingPin(center: CGPoint) -> AnnotationItem {
        AnnotationItem(kind: .floatingPin, center: center)
    }

    static func backdrop(center: CGPoint) -> AnnotationItem {
        AnnotationItem(kind: .backdrop, center: center)
    }
}
