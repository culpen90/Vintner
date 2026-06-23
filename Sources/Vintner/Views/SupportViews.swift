import SwiftUI
import VintnerCore

extension Color {
    static let vintnerBurgundy = Color(red: 0.56, green: 0.12, blue: 0.22)
    static let vintnerGreen = Color(red: 0.11, green: 0.43, blue: 0.31)
    static let vintnerCanvas = Color(nsColor: .windowBackgroundColor)
}

extension ActivityKind {
    var symbolName: String {
        switch self {
        case .info:
            "info.circle"
        case .running:
            "hourglass"
        case .success:
            "checkmark.circle.fill"
        case .warning:
            "exclamationmark.triangle.fill"
        case .failure:
            "xmark.octagon.fill"
        }
    }

    var tint: Color {
        switch self {
        case .info:
            .secondary
        case .running:
            .blue
        case .success:
            Color.vintnerGreen
        case .warning:
            .orange
        case .failure:
            .red
        }
    }
}

struct Panel<Content: View>: View {
    let title: String
    let systemImage: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(title, systemImage: systemImage)
                .font(.headline)

            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(.quaternary, lineWidth: 1)
        }
    }
}

struct MetricPill: View {
    let title: String
    let systemImage: String

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.caption.weight(.medium))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(.quaternary.opacity(0.35), in: Capsule())
    }
}

struct EmptyBottleDetailView: View {
    var onCreate: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "wineglass")
                .font(.system(size: 58))
                .foregroundStyle(Color.vintnerBurgundy)

            Text("No Bottle Selected")
                .font(.title.weight(.semibold))

            Text("Create a bottle to keep a Wine prefix, launch target, and runtime settings together.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 420)

            Button {
                onCreate()
            } label: {
                Label("New Bottle", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.vintnerCanvas)
    }
}

struct ActivityPanel: View {
    @Environment(BottleLibrary.self) private var library

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Activity")
                .font(.headline)

            if library.activity.isEmpty {
                ContentUnavailableView(
                    "No Activity",
                    systemImage: "clock",
                    description: Text("Launches and prefix changes will appear here.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(library.activity) { event in
                            ActivityRow(event: event)
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(.thinMaterial)
    }
}

private struct ActivityRow: View {
    let event: ActivityEvent

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: event.kind.symbolName)
                .foregroundStyle(event.kind.tint)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 3) {
                Text(event.message)
                    .lineLimit(3)
                Text(event.date.formatted(date: .omitted, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .font(.caption)
    }
}

extension String {
    func shellSplit() -> [String] {
        var arguments: [String] = []
        var current = ""
        var quote: Character?

        for character in self {
            if character == "\"" || character == "'" {
                if quote == character {
                    quote = nil
                } else if quote == nil {
                    quote = character
                } else {
                    current.append(character)
                }
            } else if character.isWhitespace && quote == nil {
                if !current.isEmpty {
                    arguments.append(current)
                    current = ""
                }
            } else {
                current.append(character)
            }
        }

        if !current.isEmpty {
            arguments.append(current)
        }

        return arguments
    }
}
