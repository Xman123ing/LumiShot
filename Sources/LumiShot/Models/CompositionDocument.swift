import Foundation

public struct CompositionDocument: Equatable {
    public let id: UUID
    public let title: String
    public let backgroundName: String?
    public let annotationCount: Int

    public init(id: UUID = UUID(), title: String, backgroundName: String?, annotationCount: Int) {
        self.id = id
        self.title = title
        self.backgroundName = backgroundName
        self.annotationCount = annotationCount
    }
}
