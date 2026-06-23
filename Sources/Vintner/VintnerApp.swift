import SwiftUI
import VintnerCore

@main
struct VintnerApp: App {
    @State private var library = BottleLibrary()
    @State private var runner = WineRunner()

    var body: some Scene {
        WindowGroup {
            AppShell()
                .environment(library)
                .environment(runner)
                .frame(minWidth: 1020, minHeight: 640)
        }
        .defaultSize(width: 1180, height: 760)
        .windowStyle(.hiddenTitleBar)

        Settings {
            SettingsView()
        }

        #if os(macOS)
        .commands {
            SidebarCommands()
        }
        #endif
    }
}
