import SwiftUI
import VintnerCore

@main
struct VintnerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
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

private final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }
}
