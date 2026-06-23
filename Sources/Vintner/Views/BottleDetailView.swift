import AppKit
import SwiftUI
import UniformTypeIdentifiers
import VintnerCore

struct BottleDetailView: View {
    @Environment(BottleLibrary.self) private var library
    @Environment(WineRunner.self) private var runner

    @AppStorage(SettingsKeys.wineExecutablePath) private var winePath = WineRuntimeSettings.defaultWineBinaryPath
    @AppStorage(SettingsKeys.enableEsync) private var enableEsync = true
    @AppStorage(SettingsKeys.enableMsync) private var enableMsync = false
    @AppStorage(SettingsKeys.preferDXVK) private var preferDXVK = true
    @AppStorage(SettingsKeys.suppressMonoGeckoPrompts) private var suppressMonoGeckoPrompts = true

    @State private var isChoosingExecutable = false
    @State private var isConfirmingDelete = false

    let bottle: Bottle

    var body: some View {
        HStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    quickActions

                    HStack(alignment: .top, spacing: 16) {
                        bottleSettings
                        launchSettings
                    }

                    notesPanel
                }
                .padding(28)
                .frame(maxWidth: 760, alignment: .leading)
            }

            Divider()

            ActivityPanel()
                .frame(width: 300)
        }
        .background(Color.vintnerCanvas)
        .fileImporter(
            isPresented: $isChoosingExecutable,
            allowedContentTypes: [.item],
            allowsMultipleSelection: false,
            onCompletion: handleExecutableImport
        )
        .confirmationDialog(
            "Delete \(currentBottle.name)?",
            isPresented: $isConfirmingDelete
        ) {
            Button("Delete Bottle", role: .destructive) {
                deleteBottle()
            }
            Button("Cancel", role: .cancel) {}
        }
        .navigationTitle(currentBottle.name)
    }

    private var currentBottle: Bottle {
        library.bottles.first { $0.id == bottle.id } ?? bottle
    }

    private var isRunning: Bool {
        runner.runningBottleIDs.contains(currentBottle.id)
    }

    private var runtimeSettings: WineRuntimeSettings {
        WineRuntimeSettings(
            wineBinaryPath: winePath,
            enableEsync: enableEsync,
            enableMsync: enableMsync,
            preferDXVK: preferDXVK,
            suppressMonoGeckoPrompts: suppressMonoGeckoPrompts
        )
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 18) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.vintnerBurgundy.gradient)
                Image(systemName: "wineglass.fill")
                    .font(.system(size: 38, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: 72, height: 72)

            VStack(alignment: .leading, spacing: 8) {
                TextField("Bottle name", text: Binding(
                    get: { currentBottle.name },
                    set: { newValue in updateBottle { $0.name = newValue } }
                ))
                .textFieldStyle(.plain)
                .font(.largeTitle.weight(.bold))

                HStack(spacing: 8) {
                    MetricPill(
                        title: currentBottle.windowsVersion.rawValue,
                        systemImage: "macwindow"
                    )
                    MetricPill(
                        title: currentBottle.architecture.label,
                        systemImage: "cpu"
                    )
                    MetricPill(
                        title: currentBottle.lastRunAt?.formatted(date: .abbreviated, time: .shortened) ?? "Never launched",
                        systemImage: "clock"
                    )
                }
            }

            Spacer(minLength: 12)

            Menu {
                Button("Reveal Prefix") {
                    revealPrefix()
                }
                Button("Delete Bottle", role: .destructive) {
                    isConfirmingDelete = true
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .menuStyle(.borderlessButton)
            .help("Bottle actions")
        }
    }

    private var quickActions: some View {
        HStack(spacing: 10) {
            Button {
                Task { await launchApp() }
            } label: {
                Label(isRunning ? "Running" : "Launch", systemImage: isRunning ? "hourglass" : "play.fill")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(currentBottle.executablePath == nil || isRunning)

            Button {
                isChoosingExecutable = true
            } label: {
                Label("Choose EXE", systemImage: "target")
            }
            .controlSize(.large)

            Button {
                Task { await runTool(.winecfg, successMessage: "Opened Wine configuration.") }
            } label: {
                Label("Configure", systemImage: "slider.horizontal.3")
            }
            .controlSize(.large)
            .disabled(isRunning)

            Button {
                Task { await runTool(.wineboot, successMessage: "Initialized the prefix.") }
            } label: {
                Label("Initialize", systemImage: "arrow.clockwise")
            }
            .controlSize(.large)
            .disabled(isRunning)

            Button {
                revealPrefix()
            } label: {
                Label("Prefix", systemImage: "folder")
            }
            .controlSize(.large)
        }
    }

    private var bottleSettings: some View {
        Panel(title: "Bottle", systemImage: "shippingbox") {
            Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: 16, verticalSpacing: 14) {
                GridRow {
                    Text("Windows")
                        .foregroundStyle(.secondary)
                    Picker("Windows", selection: Binding(
                        get: { currentBottle.windowsVersion },
                        set: { newValue in updateBottle { $0.windowsVersion = newValue } }
                    )) {
                        ForEach(WindowsVersion.allCases) { version in
                            Text(version.rawValue).tag(version)
                        }
                    }
                    .labelsHidden()
                }

                GridRow {
                    Text("Architecture")
                        .foregroundStyle(.secondary)
                    Picker("Architecture", selection: Binding(
                        get: { currentBottle.architecture },
                        set: { newValue in updateBottle { $0.architecture = newValue } }
                    )) {
                        ForEach(WineArchitecture.allCases) { architecture in
                            Text(architecture.label).tag(architecture)
                        }
                    }
                    .labelsHidden()
                }

                GridRow {
                    Text("Prefix")
                        .foregroundStyle(.secondary)
                    Text(currentBottle.prefixPath)
                        .font(.system(.caption, design: .monospaced))
                        .lineLimit(2)
                        .textSelection(.enabled)
                }
            }
        }
    }

    private var launchSettings: some View {
        Panel(title: "Launch Target", systemImage: "play.rectangle") {
            VStack(alignment: .leading, spacing: 12) {
                LabeledContent("Executable") {
                    Text(currentBottle.executableURL?.lastPathComponent ?? "None")
                        .foregroundStyle(currentBottle.executablePath == nil ? .secondary : .primary)
                        .lineLimit(1)
                }

                TextField("Arguments", text: Binding(
                    get: { currentBottle.launchArguments },
                    set: { newValue in updateBottle { $0.launchArguments = newValue } }
                ))
                .textFieldStyle(.roundedBorder)

                if let executablePath = currentBottle.executablePath {
                    Text(executablePath)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .textSelection(.enabled)
                }
            }
        }
    }

    private var notesPanel: some View {
        Panel(title: "Notes", systemImage: "note.text") {
            TextEditor(text: Binding(
                get: { currentBottle.notes },
                set: { newValue in updateBottle { $0.notes = newValue } }
            ))
            .font(.body)
            .frame(minHeight: 110)
            .scrollContentBackground(.hidden)
            .background(.quaternary.opacity(0.18), in: RoundedRectangle(cornerRadius: 8))
        }
    }

    private func launchApp() async {
        await runTool(
            .wine(
                executablePath: currentBottle.executablePath,
                arguments: currentBottle.launchArguments.shellSplit()
            ),
            successMessage: "Launched \(currentBottle.name).",
            marksLaunch: true
        )
    }

    private func runTool(
        _ tool: WineTool,
        successMessage: String,
        marksLaunch: Bool = false
    ) async {
        let bottle = currentBottle

        do {
            library.record(.init(kind: .running, message: "Starting \(bottle.name)..."))
            let status = try await runner.run(tool, for: bottle, settings: runtimeSettings)

            if status == 0 {
                library.record(.init(kind: .success, message: successMessage))
                if marksLaunch {
                    library.markLaunched(bottle.id)
                }
            } else {
                library.record(.init(kind: .warning, message: "Wine exited with status \(status)."))
            }
        } catch {
            library.lastErrorMessage = error.localizedDescription
            library.record(.init(kind: .failure, message: error.localizedDescription))
        }
    }

    private func updateBottle(_ mutate: (inout Bottle) -> Void) {
        var updatedBottle = currentBottle
        mutate(&updatedBottle)

        do {
            try library.updateBottle(updatedBottle)
        } catch {
            library.lastErrorMessage = error.localizedDescription
        }
    }

    private func handleExecutableImport(_ result: Result<[URL], Error>) {
        do {
            guard let url = try result.get().first else { return }
            updateBottle { $0.executablePath = url.path }
            library.record(.init(kind: .success, message: "Linked \(url.lastPathComponent)."))
        } catch {
            library.lastErrorMessage = error.localizedDescription
        }
    }

    private func revealPrefix() {
        do {
            try library.createPrefixDirectory(for: currentBottle)
            NSWorkspace.shared.open(URL(fileURLWithPath: currentBottle.prefixPath, isDirectory: true))
        } catch {
            library.lastErrorMessage = error.localizedDescription
        }
    }

    private func deleteBottle() {
        do {
            try library.deleteBottle(currentBottle)
        } catch {
            library.lastErrorMessage = error.localizedDescription
        }
    }
}
