public enum ToolbarTool: String, CaseIterable, Equatable, Sendable {
    case rectangle
    case arrow
    case text
    case counter
    case floatingPin
    case backdrop

    public static let primaryTools: [ToolbarTool] = [.rectangle, .arrow, .text, .counter]
    public static let moreTools: [ToolbarTool] = [.floatingPin, .backdrop]
}
