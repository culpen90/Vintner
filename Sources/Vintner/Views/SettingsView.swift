import SwiftUI
import VintnerCore

struct SettingsView: View {
    @AppStorage(SettingsKeys.wineExecutablePath) private var winePath = WineRuntimeSettings.defaultWineBinaryPath
    @AppStorage(SettingsKeys.defaultWindowsVersion) private var defaultWindowsVersionRaw = WindowsVersion.windows11.rawValue
    @AppStorage(SettingsKeys.defaultArchitecture) private var defaultArchitectureRaw = WineArchitecture.win64.rawValue
    @AppStorage(SettingsKeys.enableEsync) private var enableEsync = true
    @AppStorage(SettingsKeys.enableMsync) private var enableMsync = false
    @AppStorage(SettingsKeys.preferDXVK) private var preferDXVK = true
    @AppStorage(SettingsKeys.suppressMonoGeckoPrompts) private var suppressMonoGeckoPrompts = true

    var body: some View {
        TabView {
            Form {
                TextField("Wine binary", text: $winePath)
                    .textFieldStyle(.roundedBorder)

                Picker("Default Windows version", selection: $defaultWindowsVersionRaw) {
                    ForEach(WindowsVersion.allCases) { version in
                        Text(version.rawValue).tag(version.rawValue)
                    }
                }

                Picker("Default architecture", selection: $defaultArchitectureRaw) {
                    ForEach(WineArchitecture.allCases) { architecture in
                        Text(architecture.label).tag(architecture.rawValue)
                    }
                }
            }
            .scenePadding()
            .tabItem {
                Label("General", systemImage: "gear")
            }

            Form {
                Toggle("Enable Esync", isOn: $enableEsync)
                Toggle("Enable Msync", isOn: $enableMsync)
                Toggle("Prefer DXVK", isOn: $preferDXVK)
                Toggle("Suppress Mono and Gecko prompts", isOn: $suppressMonoGeckoPrompts)
            }
            .scenePadding()
            .tabItem {
                Label("Runtime", systemImage: "speedometer")
            }
        }
        .frame(width: 500, height: 280)
    }
}
