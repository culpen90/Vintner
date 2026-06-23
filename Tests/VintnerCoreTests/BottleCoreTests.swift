import XCTest
@testable import VintnerCore

final class BottleCoreTests: XCTestCase {
    func testSlugNormalizesBottleNames() {
        XCTAssertEqual(BottleFactory.slug(for: "  Half-Life 2: Update! "), "half-life-2-update")
        XCTAssertEqual(BottleFactory.slug(for: "!!!"), "bottle")
    }

    func testStorageCreatesAndRoundTripsBottleManifest() throws {
        let rootURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("VintnerTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: rootURL) }

        let storage = BottleStorage(rootURL: rootURL)
        let bottle = try storage.createBottle(
            from: BottleDraft(
                name: "Myst",
                windowsVersion: .windows11,
                architecture: .win64,
                notes: "Classic puzzle evening"
            )
        )

        XCTAssertTrue(FileManager.default.fileExists(atPath: bottle.prefixPath))
        XCTAssertTrue(FileManager.default.fileExists(atPath: storage.manifestURL.path))

        let loaded = try storage.loadBottles()
        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded.first?.id, bottle.id)
        XCTAssertEqual(loaded.first?.name, "Myst")
        XCTAssertEqual(loaded.first?.notes, "Classic puzzle evening")
        XCTAssertEqual(loaded.first?.prefixPath, bottle.prefixPath)
    }

    @MainActor
    func testWineCommandBuildsEnvironmentAndArguments() throws {
        let bottle = Bottle(
            id: UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!,
            name: "Test",
            folderName: "test",
            prefixPath: "/tmp/vintner-test",
            executablePath: "/Games/Test/Game.exe",
            launchArguments: "-windowed",
            windowsVersion: .windows10,
            architecture: .win64
        )

        let runner = WineRunner()
        let command = try runner.command(
            for: bottle,
            tool: .wine(executablePath: bottle.executablePath, arguments: ["-windowed"]),
            settings: WineRuntimeSettings(
                wineBinaryPath: "/opt/homebrew/bin/wine",
                enableEsync: true,
                enableMsync: false,
                preferDXVK: true,
                suppressMonoGeckoPrompts: true
            ),
            baseEnvironment: ["PATH": "/usr/bin"]
        )

        XCTAssertEqual(command.executableURL.path, "/opt/homebrew/bin/wine")
        XCTAssertEqual(command.arguments, ["/Games/Test/Game.exe", "-windowed"])
        XCTAssertEqual(command.workingDirectoryURL?.path, "/Games/Test")
        XCTAssertEqual(command.environment["WINEPREFIX"], "/tmp/vintner-test")
        XCTAssertEqual(command.environment["WINEARCH"], "win64")
        XCTAssertEqual(command.environment["WINEESYNC"], "1")
        XCTAssertNil(command.environment["WINEMSYNC"])
        XCTAssertEqual(command.environment["DXVK_LOG_LEVEL"], "none")
        XCTAssertEqual(command.environment["WINEDLLOVERRIDES"], "mscoree,mshtml=")
    }
}
