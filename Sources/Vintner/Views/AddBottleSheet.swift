import SwiftUI
import VintnerCore

struct AddBottleSheet: View {
    @Environment(BottleLibrary.self) private var library
    @Environment(\.dismiss) private var dismiss

    @AppStorage(SettingsKeys.defaultWindowsVersion) private var defaultWindowsVersionRaw = WindowsVersion.windows11.rawValue
    @AppStorage(SettingsKeys.defaultArchitecture) private var defaultArchitectureRaw = WineArchitecture.win64.rawValue

    @State private var name = ""
    @State private var windowsVersion: WindowsVersion = .windows11
    @State private var architecture: WineArchitecture = .win64
    @State private var notes = ""
    @State private var createPrefixDirectory = true

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                    Picker("Windows version", selection: $windowsVersion) {
                        ForEach(WindowsVersion.allCases) { version in
                            Text(version.rawValue).tag(version)
                        }
                    }
                    Picker("Architecture", selection: $architecture) {
                        ForEach(WineArchitecture.allCases) { architecture in
                            Text(architecture.label).tag(architecture)
                        }
                    }
                    Toggle("Create prefix folder", isOn: $createPrefixDirectory)
                }

                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                }
            }
            .formStyle(.grouped)
            .navigationTitle("New Bottle")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createBottle()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .frame(width: 460, height: 380)
        .onAppear {
            windowsVersion = WindowsVersion(rawValue: defaultWindowsVersionRaw) ?? .windows11
            architecture = WineArchitecture(rawValue: defaultArchitectureRaw) ?? .win64
        }
    }

    private func createBottle() {
        let draft = BottleDraft(
            name: name,
            windowsVersion: windowsVersion,
            architecture: architecture,
            notes: notes
        )

        do {
            try library.createBottle(from: draft, createDirectory: createPrefixDirectory)
            dismiss()
        } catch {
            library.lastErrorMessage = error.localizedDescription
        }
    }
}
