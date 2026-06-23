import SwiftUI
import VintnerCore

struct SidebarView: View {
    @Environment(BottleLibrary.self) private var library
    @Binding var selection: Bottle.ID?

    var body: some View {
        List(selection: $selection) {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    Label("Vintner", systemImage: "wineglass.fill")
                        .font(.title2.weight(.semibold))
                    Text("\(library.bottles.count) bottle\(library.bottles.count == 1 ? "" : "s")")
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
                .listRowSeparator(.hidden)
            }

            Section("Bottles") {
                ForEach(library.bottles) { bottle in
                    BottleRow(bottle: bottle)
                        .tag(Optional(bottle.id))
                        .contextMenu {
                            Button("Delete", role: .destructive) {
                                delete(bottle)
                            }
                        }
                }
                .onDelete { offsets in
                    offsets.map { library.bottles[$0] }.forEach(delete)
                }
            }

            if !library.activity.isEmpty {
                Section("Recent") {
                    ForEach(library.activity.prefix(4)) { event in
                        Label(event.message, systemImage: event.kind.symbolName)
                            .lineLimit(2)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationSplitViewColumnWidth(min: 260, ideal: 300, max: 360)
    }

    private func delete(_ bottle: Bottle) {
        do {
            try library.deleteBottle(bottle)
        } catch {
            library.lastErrorMessage = error.localizedDescription
        }
    }
}

private struct BottleRow: View {
    let bottle: Bottle

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "shippingbox.fill")
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Color.vintnerBurgundy)
                .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 3) {
                Text(bottle.name)
                    .font(.headline)
                    .lineLimit(1)
                Text("\(bottle.windowsVersion.rawValue) · \(bottle.architecture.label)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            if bottle.executablePath != nil {
                Image(systemName: "play.circle.fill")
                    .foregroundStyle(Color.vintnerGreen)
                    .help("Launch target configured")
            }
        }
        .padding(.vertical, 4)
    }
}
