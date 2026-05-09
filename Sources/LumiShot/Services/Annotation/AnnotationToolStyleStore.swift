import Foundation

@MainActor
public final class AnnotationToolStyleStore: ObservableObject {
    @Published private var colors: [AnnotationColorTool: AnnotationColor]
    @Published private var strokeWidths: [AnnotationColorTool: Double]
    @Published private var fontSizes: [AnnotationColorTool: Double]
    @Published private var backdropCornerRadius: Double
    @Published private var backdropInset: Double
    @Published private var backdropShadow: Double
    @Published private var backdropInnerRadius: Double
    @Published private var backdropGradientColors: [AnnotationColor]?

    private let defaults: UserDefaults
    private let colorPrefix = "annotation.color."
    private let strokePrefix = "annotation.stroke."
    private let fontPrefix = "annotation.font."
    private let backdropCornerRadiusKey = "annotation.backdrop.cornerRadius"
    private let backdropInsetKey = "annotation.backdrop.inset"
    private let backdropShadowKey = "annotation.backdrop.shadow"
    private let backdropInnerRadiusKey = "annotation.backdrop.innerRadius"
    private let backdropGradientKey = "annotation.backdrop.gradient.colors"

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        var loaded: [AnnotationColorTool: AnnotationColor] = [:]
        var loadedStrokes: [AnnotationColorTool: Double] = [:]
        var loadedFonts: [AnnotationColorTool: Double] = [:]
        for tool in AnnotationColorTool.allCases {
            if let color = Self.loadColor(for: tool, defaults: defaults, prefix: colorPrefix) {
                loaded[tool] = color
            } else {
                loaded[tool] = AnnotationColor.defaultColor(for: tool)
            }
            let stroke = defaults.object(forKey: strokePrefix + tool.rawValue) as? Double ?? tool.defaultStrokeWidth
            loadedStrokes[tool] = stroke
            let font = defaults.object(forKey: fontPrefix + tool.rawValue) as? Double ?? tool.defaultFontSize
            loadedFonts[tool] = font
        }
        self.colors = loaded
        self.strokeWidths = loadedStrokes
        self.fontSizes = loadedFonts
        self.backdropCornerRadius = defaults.object(forKey: backdropCornerRadiusKey) as? Double ?? 16
        self.backdropInset = defaults.object(forKey: backdropInsetKey) as? Double ?? 24
        self.backdropShadow = defaults.object(forKey: backdropShadowKey) as? Double ?? 0.45
        self.backdropInnerRadius = defaults.object(forKey: backdropInnerRadiusKey) as? Double ?? 12
        if let data = defaults.data(forKey: backdropGradientKey),
           let decoded = try? JSONDecoder().decode([AnnotationColor].self, from: data),
           decoded.isEmpty == false {
            self.backdropGradientColors = decoded
        } else {
            self.backdropGradientColors = nil
        }
    }

    public func color(for tool: AnnotationColorTool) -> AnnotationColor {
        colors[tool] ?? AnnotationColor.defaultColor(for: tool)
    }

    public func setColor(_ color: AnnotationColor, for tool: AnnotationColorTool) {
        colors[tool] = color
        let data = try? JSONEncoder().encode(color)
        defaults.set(data, forKey: key(for: tool))
    }

    public func strokeWidth(for tool: AnnotationColorTool) -> Double {
        strokeWidths[tool] ?? tool.defaultStrokeWidth
    }

    public func setStrokeWidth(_ value: Double, for tool: AnnotationColorTool) {
        strokeWidths[tool] = value
        defaults.set(value, forKey: strokeKey(for: tool))
    }

    public func fontSize(for tool: AnnotationColorTool) -> Double {
        fontSizes[tool] ?? tool.defaultFontSize
    }

    public func setFontSize(_ value: Double, for tool: AnnotationColorTool) {
        fontSizes[tool] = value
        defaults.set(value, forKey: fontKey(for: tool))
    }

    public func currentBackdropCornerRadius() -> Double {
        backdropCornerRadius
    }

    public func setBackdropCornerRadius(_ value: Double) {
        backdropCornerRadius = value
        defaults.set(value, forKey: backdropCornerRadiusKey)
    }

    public func currentBackdropInset() -> Double {
        backdropInset
    }

    public func setBackdropInset(_ value: Double) {
        backdropInset = value
        defaults.set(value, forKey: backdropInsetKey)
    }

    public func currentBackdropShadow() -> Double {
        backdropShadow
    }

    public func setBackdropShadow(_ value: Double) {
        backdropShadow = value
        defaults.set(value, forKey: backdropShadowKey)
    }

    public func currentBackdropInnerRadius() -> Double {
        backdropInnerRadius
    }

    public func setBackdropInnerRadius(_ value: Double) {
        backdropInnerRadius = value
        defaults.set(value, forKey: backdropInnerRadiusKey)
    }

    public func currentBackdropGradientColors() -> [AnnotationColor]? {
        backdropGradientColors
    }

    public func setBackdropGradientColors(_ colors: [AnnotationColor]?) {
        backdropGradientColors = colors
        if let colors, colors.isEmpty == false, let data = try? JSONEncoder().encode(colors) {
            defaults.set(data, forKey: backdropGradientKey)
        } else {
            defaults.removeObject(forKey: backdropGradientKey)
        }
    }

    private func key(for tool: AnnotationColorTool) -> String {
        colorPrefix + tool.rawValue
    }

    private func strokeKey(for tool: AnnotationColorTool) -> String {
        strokePrefix + tool.rawValue
    }

    private func fontKey(for tool: AnnotationColorTool) -> String {
        fontPrefix + tool.rawValue
    }

    private static func loadColor(
        for tool: AnnotationColorTool,
        defaults: UserDefaults,
        prefix: String
    ) -> AnnotationColor? {
        let key = prefix + tool.rawValue
        guard let data = defaults.data(forKey: key) else { return nil }
        guard let decoded = try? JSONDecoder().decode(AnnotationColor.self, from: data) else { return nil }
        return decoded
    }
}

