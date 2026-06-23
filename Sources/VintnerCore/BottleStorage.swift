import Foundation

public struct BottleStorage {
    public let rootURL: URL

    public init(rootURL: URL) {
        self.rootURL = rootURL
    }

    public static var applicationSupport: BottleStorage {
        let baseURL = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first ?? FileManager.default.homeDirectoryForCurrentUser

        return BottleStorage(rootURL: baseURL.appendingPathComponent("Vintner", isDirectory: true))
    }

    public var bottlesDirectoryURL: URL {
        rootURL.appendingPathComponent("Bottles", isDirectory: true)
    }

    public var manifestURL: URL {
        rootURL.appendingPathComponent("bottles.json")
    }

    public func prepareRoot() throws {
        try FileManager.default.createDirectory(
            at: bottlesDirectoryURL,
            withIntermediateDirectories: true
        )
    }

    public func loadBottles() throws -> [Bottle] {
        guard FileManager.default.fileExists(atPath: manifestURL.path) else {
            return []
        }

        let data = try Data(contentsOf: manifestURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([Bottle].self, from: data)
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    public func saveBottles(_ bottles: [Bottle]) throws {
        try prepareRoot()

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let data = try encoder.encode(
            bottles.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        )
        try data.write(to: manifestURL, options: [.atomic])
    }

    public func createBottle(from draft: BottleDraft, createDirectory: Bool = true) throws -> Bottle {
        try prepareRoot()

        var bottles = try loadBottles()
        let bottle = BottleFactory.makeBottle(
            from: draft,
            bottlesDirectoryURL: bottlesDirectoryURL
        )

        if createDirectory {
            try createPrefixDirectory(for: bottle)
        }

        bottles.append(bottle)
        try saveBottles(bottles)
        return bottle
    }

    public func createPrefixDirectory(for bottle: Bottle) throws {
        try FileManager.default.createDirectory(
            at: URL(fileURLWithPath: bottle.prefixPath, isDirectory: true),
            withIntermediateDirectories: true
        )
    }

    public func removePrefixDirectory(for bottle: Bottle) throws {
        let prefixURL = URL(fileURLWithPath: bottle.prefixPath, isDirectory: true)
        guard FileManager.default.fileExists(atPath: prefixURL.path) else { return }
        try FileManager.default.removeItem(at: prefixURL)
    }
}
