import SwiftUI
import VintnerCore

private enum AppSheet: Identifiable {
    case addBottle

    var id: String {
        switch self {
        case .addBottle:
            "add-bottle"
        }
    }
}

struct AppShell: View {
    @Environment(BottleLibrary.self) private var library
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var presentedSheet: AppSheet?

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView(selection: selectedBottleBinding)
        } detail: {
            detailView
        }
        .tint(Color.vintnerBurgundy)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    presentedSheet = .addBottle
                } label: {
                    Label("New Bottle", systemImage: "plus")
                }
                .help("Create a new Wine bottle")
            }
        }
        .sheet(item: $presentedSheet) { sheet in
            switch sheet {
            case .addBottle:
                AddBottleSheet()
                    .environment(library)
            }
        }
        .task {
            if !library.isLoaded {
                library.load()
            }
        }
        .alert(
            "Vintner could not finish that",
            isPresented: Binding(
                get: { library.lastErrorMessage != nil },
                set: { isPresented in
                    if !isPresented {
                        library.lastErrorMessage = nil
                    }
                }
            )
        ) {
            Button("OK") {
                library.lastErrorMessage = nil
            }
        } message: {
            Text(library.lastErrorMessage ?? "")
        }
    }

    private var selectedBottleBinding: Binding<Bottle.ID?> {
        Binding(
            get: { library.selectedBottleID },
            set: { library.selectedBottleID = $0 }
        )
    }

    @ViewBuilder
    private var detailView: some View {
        if let bottle = library.selectedBottle {
            BottleDetailView(bottle: bottle)
                .id(bottle.id)
        } else {
            EmptyBottleDetailView {
                presentedSheet = .addBottle
            }
        }
    }
}
