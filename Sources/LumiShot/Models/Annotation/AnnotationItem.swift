import CoreGraphics
import Foundation

public struct AnnotationItem: Equatable, Identifiable {
    public let id: UUID
    public var kind: AnnotationKind
    public var center: CGPoint
    public var trailingPoint: CGPoint?
    public var displayValue: String?
    public var color: AnnotationColor?
    public var strokeWidth: Double?
    public var fontSize: Double?

    public init(
        id: UUID = UUID(),
        kind: AnnotationKind,
        center: CGPoint,
        trailingPoint: CGPoint? = nil,
        displayValue: String? = nil,
        color: AnnotationColor? = nil,
        strokeWidth: Double? = nil,
        fontSize: Double? = nil
    ) {
        self.id = id
        self.kind = kind
        self.center = center
        self.trailingPoint = trailingPoint
        self.displayValue = displayValue
        self.color = color
        self.strokeWidth = strokeWidth
        self.fontSize = fontSize
    }
}

public extension AnnotationItem {
    static func text(
        value: String,
        center: CGPoint,
        color: AnnotationColor? = nil,
        fontSize: Double? = nil
    ) -> AnnotationItem {
        AnnotationItem(kind: .text, center: center, displayValue: value, color: color, fontSize: fontSize)
    }

    static func box(center: CGPoint, color: AnnotationColor? = nil, strokeWidth: Double? = nil) -> AnnotationItem {
        AnnotationItem(kind: .box, center: center, color: color, strokeWidth: strokeWidth)
    }

    static func box(
        start: CGPoint,
        end: CGPoint,
        color: AnnotationColor? = nil,
        strokeWidth: Double? = nil
    ) -> AnnotationItem {
        AnnotationItem(kind: .box, center: start, trailingPoint: end, color: color, strokeWidth: strokeWidth)
    }

    static func arrow(center: CGPoint, color: AnnotationColor? = nil, strokeWidth: Double? = nil) -> AnnotationItem {
        AnnotationItem(kind: .arrow, center: center, color: color, strokeWidth: strokeWidth)
    }

    static func arrow(
        start: CGPoint,
        end: CGPoint,
        color: AnnotationColor? = nil,
        strokeWidth: Double? = nil
    ) -> AnnotationItem {
        AnnotationItem(kind: .arrow, center: start, trailingPoint: end, color: color, strokeWidth: strokeWidth)
    }

    static func number(
        value: String,
        center: CGPoint,
        tailPoint: CGPoint? = nil,
        color: AnnotationColor? = nil,
        strokeWidth: Double? = nil
    ) -> AnnotationItem {
        AnnotationItem(
            kind: .number,
            center: center,
            trailingPoint: tailPoint,
            displayValue: value,
            color: color,
            strokeWidth: strokeWidth
        )
    }

    static func mosaic(center: CGPoint) -> AnnotationItem {
        AnnotationItem(kind: .mosaic, center: center)
    }

    static func floatingPin(center: CGPoint) -> AnnotationItem {
        AnnotationItem(kind: .floatingPin, center: center)
    }

    static func backdrop(center: CGPoint, color: AnnotationColor? = nil, strokeWidth: Double? = nil) -> AnnotationItem {
        AnnotationItem(kind: .backdrop, center: center, color: color, strokeWidth: strokeWidth)
    }
}
