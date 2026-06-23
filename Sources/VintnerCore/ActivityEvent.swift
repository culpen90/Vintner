import Foundation

public enum ActivityKind: String, Codable, Hashable, Sendable {
    case info
    case running
    case success
    case warning
    case failure
}

public struct ActivityEvent: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var kind: ActivityKind
    public var message: String
    public var date: Date

    public init(
        id: UUID = UUID(),
        kind: ActivityKind,
        message: String,
        date: Date = Date()
    ) {
        self.id = id
        self.kind = kind
        self.message = message
        self.date = date
    }
}
