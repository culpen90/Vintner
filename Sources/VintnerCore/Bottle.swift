import Foundation

public enum WindowsVersion: String, Codable, CaseIterable, Identifiable, Sendable {
    case windows7 = "Windows 7"
    case windows10 = "Windows 10"
    case windows11 = "Windows 11"

    public var id: String { rawValue }
}

public enum WineArchitecture: String, Codable, CaseIterable, Identifiable, Sendable {
    case win32
    case win64

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .win32:
            "32-bit"
        case .win64:
            "64-bit"
        }
    }
}

public struct Bottle: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var name: String
    public var folderName: String
    public var prefixPath: String
    public var executablePath: String?
    public var launchArguments: String
    public var windowsVersion: WindowsVersion
    public var architecture: WineArchitecture
    public var notes: String
    public var createdAt: Date
    public var lastRunAt: Date?

    public init(
        id: UUID = UUID(),
        name: String,
        folderName: String,
        prefixPath: String,
        executablePath: String? = nil,
        launchArguments: String = "",
        windowsVersion: WindowsVersion,
        architecture: WineArchitecture,
        notes: String = "",
        createdAt: Date = Date(),
        lastRunAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.folderName = folderName
        self.prefixPath = prefixPath
        self.executablePath = executablePath
        self.launchArguments = launchArguments
        self.windowsVersion = windowsVersion
        self.architecture = architecture
        self.notes = notes
        self.createdAt = createdAt
        self.lastRunAt = lastRunAt
    }

    public var executableURL: URL? {
        guard let executablePath, !executablePath.isEmpty else { return nil }
        return URL(fileURLWithPath: executablePath)
    }
}

public struct BottleDraft: Hashable, Sendable {
    public var name: String
    public var windowsVersion: WindowsVersion
    public var architecture: WineArchitecture
    public var notes: String

    public init(
        name: String,
        windowsVersion: WindowsVersion,
        architecture: WineArchitecture,
        notes: String = ""
    ) {
        self.name = name
        self.windowsVersion = windowsVersion
        self.architecture = architecture
        self.notes = notes
    }
}

public enum BottleFactory {
    public static func makeBottle(
        from draft: BottleDraft,
        bottlesDirectoryURL: URL,
        id: UUID = UUID(),
        createdAt: Date = Date()
    ) -> Bottle {
        let baseSlug = slug(for: draft.name)
        let suffix = id.uuidString.prefix(8).lowercased()
        let folderName = "\(baseSlug)-\(suffix)"
        let prefixURL = bottlesDirectoryURL.appendingPathComponent(folderName, isDirectory: true)

        return Bottle(
            id: id,
            name: draft.name.trimmingCharacters(in: .whitespacesAndNewlines),
            folderName: folderName,
            prefixPath: prefixURL.path,
            windowsVersion: draft.windowsVersion,
            architecture: draft.architecture,
            notes: draft.notes.trimmingCharacters(in: .whitespacesAndNewlines),
            createdAt: createdAt
        )
    }

    public static func slug(for name: String) -> String {
        let folded = name
            .lowercased()
            .unicodeScalars
            .map { CharacterSet.alphanumerics.contains($0) ? String($0) : "-" }
            .joined()

        let collapsed = folded
            .split(separator: "-", omittingEmptySubsequences: true)
            .joined(separator: "-")

        return collapsed.isEmpty ? "bottle" : collapsed
    }
}
