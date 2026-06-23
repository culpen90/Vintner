import Foundation
import Observation

public struct WineRuntimeSettings: Equatable, Sendable {
    public static let defaultWineBinaryPath = "/opt/homebrew/bin/wine"

    public var wineBinaryPath: String
    public var enableEsync: Bool
    public var enableMsync: Bool
    public var preferDXVK: Bool
    public var suppressMonoGeckoPrompts: Bool

    public init(
        wineBinaryPath: String = Self.defaultWineBinaryPath,
        enableEsync: Bool = true,
        enableMsync: Bool = false,
        preferDXVK: Bool = true,
        suppressMonoGeckoPrompts: Bool = true
    ) {
        self.wineBinaryPath = wineBinaryPath
        self.enableEsync = enableEsync
        self.enableMsync = enableMsync
        self.preferDXVK = preferDXVK
        self.suppressMonoGeckoPrompts = suppressMonoGeckoPrompts
    }
}

public enum WineTool: Equatable, Sendable {
    case wine(executablePath: String?, arguments: [String])
    case wineboot
    case winecfg

    fileprivate var binaryName: String {
        switch self {
        case .wine:
            "wine"
        case .wineboot:
            "wineboot"
        case .winecfg:
            "winecfg"
        }
    }
}

public struct WineCommand: Equatable, Sendable {
    public var executableURL: URL
    public var arguments: [String]
    public var environment: [String: String]
    public var workingDirectoryURL: URL?

    public init(
        executableURL: URL,
        arguments: [String],
        environment: [String: String],
        workingDirectoryURL: URL?
    ) {
        self.executableURL = executableURL
        self.arguments = arguments
        self.environment = environment
        self.workingDirectoryURL = workingDirectoryURL
    }
}

public enum WineRunnerError: LocalizedError, Equatable {
    case missingExecutable
    case missingWineBinary(String)
    case launchFailed(String)

    public var errorDescription: String? {
        switch self {
        case .missingExecutable:
            "Choose a Windows executable before launching this bottle."
        case .missingWineBinary(let path):
            "Wine could not be found at \(path). Update the path in Settings."
        case .launchFailed(let message):
            message
        }
    }
}

@MainActor
@Observable
public final class WineRunner {
    public private(set) var runningBottleIDs: Set<Bottle.ID> = []

    public init() {}

    public func command(
        for bottle: Bottle,
        tool: WineTool,
        settings: WineRuntimeSettings,
        baseEnvironment: [String: String] = ProcessInfo.processInfo.environment
    ) throws -> WineCommand {
        let winePath = Self.expandedPath(settings.wineBinaryPath)
        guard !winePath.isEmpty else {
            throw WineRunnerError.missingWineBinary(settings.wineBinaryPath)
        }

        let wineURL = URL(fileURLWithPath: winePath)
        var executableURL = wineURL
        var arguments: [String] = []
        var workingDirectoryURL: URL?

        switch tool {
        case .wine(let executablePath, let launchArguments):
            guard let executablePath, !executablePath.isEmpty else {
                throw WineRunnerError.missingExecutable
            }
            executableURL = wineURL
            arguments = [executablePath] + launchArguments
            workingDirectoryURL = URL(fileURLWithPath: executablePath).deletingLastPathComponent()
        case .wineboot:
            executableURL = siblingToolURL(named: tool.binaryName, wineURL: wineURL)
            arguments = ["-u"]
        case .winecfg:
            executableURL = siblingToolURL(named: tool.binaryName, wineURL: wineURL)
        }

        return WineCommand(
            executableURL: executableURL,
            arguments: arguments,
            environment: environment(for: bottle, settings: settings, baseEnvironment: baseEnvironment),
            workingDirectoryURL: workingDirectoryURL
        )
    }

    public func run(
        _ tool: WineTool,
        for bottle: Bottle,
        settings: WineRuntimeSettings
    ) async throws -> Int32 {
        let command = try command(for: bottle, tool: tool, settings: settings)

        guard FileManager.default.isExecutableFile(atPath: command.executableURL.path) else {
            throw WineRunnerError.missingWineBinary(command.executableURL.path)
        }

        runningBottleIDs.insert(bottle.id)
        defer { runningBottleIDs.remove(bottle.id) }

        return try await Self.run(command)
    }

    public static func run(_ command: WineCommand) async throws -> Int32 {
        try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = command.executableURL
            process.arguments = command.arguments
            process.environment = command.environment
            process.currentDirectoryURL = command.workingDirectoryURL

            let nullOutput = FileHandle(forWritingAtPath: "/dev/null")
            process.standardOutput = nullOutput
            process.standardError = nullOutput
            process.terminationHandler = { process in
                nullOutput?.closeFile()
                continuation.resume(returning: process.terminationStatus)
            }

            do {
                try process.run()
            } catch {
                continuation.resume(throwing: WineRunnerError.launchFailed(error.localizedDescription))
            }
        }
    }

    private func environment(
        for bottle: Bottle,
        settings: WineRuntimeSettings,
        baseEnvironment: [String: String]
    ) -> [String: String] {
        var environment = baseEnvironment
        environment["WINEPREFIX"] = bottle.prefixPath
        environment["WINEARCH"] = bottle.architecture.rawValue

        environment["WINEESYNC"] = settings.enableEsync ? "1" : nil
        environment["WINEMSYNC"] = settings.enableMsync ? "1" : nil

        if settings.preferDXVK {
            environment["DXVK_LOG_LEVEL"] = "none"
        }

        if settings.suppressMonoGeckoPrompts {
            environment["WINEDLLOVERRIDES"] = "mscoree,mshtml="
        }

        return environment
    }

    private func siblingToolURL(named name: String, wineURL: URL) -> URL {
        wineURL.deletingLastPathComponent().appendingPathComponent(name)
    }

    private static func expandedPath(_ path: String) -> String {
        let trimmed = path.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix("~") else { return trimmed }
        return NSString(string: trimmed).expandingTildeInPath
    }
}
