import CoreGraphics
import SwiftUI

public struct AnnotationColor: Equatable, Codable, Sendable {
    public var red: Double
    public var green: Double
    public var blue: Double
    public var alpha: Double

    public init(red: Double, green: Double, blue: Double, alpha: Double = 1.0) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    public var swiftUIColor: Color {
        Color(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }

    public var cgColor: CGColor {
        CGColor(red: red, green: green, blue: blue, alpha: alpha)
    }
}

public enum AnnotationColorTool: String, CaseIterable, Sendable {
    case rectangle
    case arrow
    case text
    case counter
    case backdrop
}

public extension AnnotationColor {
    static func defaultColor(for tool: AnnotationColorTool) -> AnnotationColor {
        switch tool {
        case .rectangle:
            AnnotationColor(red: 0.98, green: 0.86, blue: 0.20, alpha: 0.95)
        case .arrow:
            AnnotationColor(red: 0.95, green: 0.25, blue: 0.25, alpha: 0.95)
        case .text:
            AnnotationColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.96)
        case .counter:
            AnnotationColor(red: 0.97, green: 0.20, blue: 0.16, alpha: 0.95)
        case .backdrop:
            AnnotationColor(red: 0.08, green: 0.08, blue: 0.10, alpha: 0.35)
        }
    }
}

public extension AnnotationColorTool {
    var defaultStrokeWidth: Double {
        switch self {
        case .rectangle: 2.0
        case .arrow: 3.0
        case .text: 0
        case .counter: 0
        case .backdrop: 1.5
        }
    }

    var defaultFontSize: Double {
        switch self {
        case .text: 20.0
        case .rectangle, .arrow, .counter, .backdrop: 0
        }
    }
}

