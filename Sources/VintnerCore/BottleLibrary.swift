import Foundation
import Observation

@MainActor
@Observable
public final class BottleLibrary {
    public private(set) var bottles: [Bottle] = []
    public private(set) var activity: [ActivityEvent] = []
    public private(set) var isLoaded = false
    public var selectedBottleID: Bottle.ID?
    public var lastErrorMessage: String?

    private let storage: BottleStorage

    public init(storage: BottleStorage = .applicationSupport) {
        self.storage = storage
    }

    public var selectedBottle: Bottle? {
        guard let selectedBottleID else { return bottles.first }
        return bottles.first { $0.id == selectedBottleID }
    }

    public func load() {
        do {
            bottles = try storage.loadBottles()
            if selectedBottleID == nil {
                selectedBottleID = bottles.first?.id
            }
            isLoaded = true
            record(.init(kind: .info, message: "Loaded \(bottles.count) bottle\(bottles.count == 1 ? "" : "s")."))
        } catch {
            lastErrorMessage = error.localizedDescription
            record(.init(kind: .failure, message: "Could not load the bottle library."))
        }
    }

    @discardableResult
    public func createBottle(from draft: BottleDraft, createDirectory: Bool = true) throws -> Bottle {
        let bottle = try storage.createBottle(from: draft, createDirectory: createDirectory)
        bottles.append(bottle)
        sortBottles()
        selectedBottleID = bottle.id
        record(.init(kind: .success, message: "Created \(bottle.name)."))
        return bottle
    }

    public func updateBottle(_ bottle: Bottle) throws {
        guard let index = bottles.firstIndex(where: { $0.id == bottle.id }) else { return }
        bottles[index] = bottle
        sortBottles()
        try storage.saveBottles(bottles)
    }

    public func deleteBottle(_ bottle: Bottle, removeFiles: Bool = false) throws {
        bottles.removeAll { $0.id == bottle.id }
        try storage.saveBottles(bottles)

        if removeFiles {
            try storage.removePrefixDirectory(for: bottle)
        }

        if selectedBottleID == bottle.id {
            selectedBottleID = bottles.first?.id
        }

        record(.init(kind: .warning, message: "Deleted \(bottle.name)."))
    }

    public func createPrefixDirectory(for bottle: Bottle) throws {
        try storage.createPrefixDirectory(for: bottle)
        record(.init(kind: .success, message: "Prepared prefix for \(bottle.name)."))
    }

    public func markLaunched(_ bottleID: Bottle.ID) {
        guard var bottle = bottles.first(where: { $0.id == bottleID }) else { return }
        bottle.lastRunAt = Date()
        try? updateBottle(bottle)
    }

    public func record(_ event: ActivityEvent) {
        activity.insert(event, at: 0)
        if activity.count > 80 {
            activity.removeLast(activity.count - 80)
        }
    }

    private func sortBottles() {
        bottles.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
}
