import SwiftUI
import SwiftData

struct ScriptListView: View {
    let scripts: [Script]
    @Binding var selectedScript: Script?
    let onDelete: ([Script]) -> Void
    let onCreate: () -> Void

    var body: some View {
        List(selection: $selectedScript) {
            Section {
            } header: {
                Image("RecTextLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 24)
                    .padding(.top, 2)
                    .padding(.bottom, 8)
                    .padding(.leading, -2)
            }
            ForEach(scripts) { script in
                ScriptRow(script: script, onDelete: { onDelete([script]) })
                    .tag(script)
                    .contextMenu {
                        Button {
                        } label: {
                            Label("Duplicate", systemImage: "doc.on.doc")
                        }
                        Divider()
                        Button(role: .destructive) {
                            onDelete([script])
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            onDelete([script])
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .transition(
                        .asymmetric(
                            insertion: .scale(scale: 0.95).combined(with: .opacity),
                            removal: .scale(scale: 0.95).combined(with: .opacity)
                        )
                    )
            }
            .onDelete { indexSet in
                let toDelete = indexSet.map { scripts[$0] }
                onDelete(toDelete)
            }
        }
        .listStyle(.sidebar)
        .onDeleteCommand {
            if let selected = selectedScript {
                onDelete([selected])
            }
        }
        .overlay {
            if scripts.isEmpty {
                ContentUnavailableView {
                    Label("No Scripts", systemImage: "doc.text")
                } description: {
                    Text("Create a new script to get started.")
                } actions: {
                    Button("New Script") { onCreate() }
                        .buttonStyle(.borderedProminent)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            HStack(spacing: 6) {
                Button { onCreate() } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .medium))
                        Text("New Script")
                            .font(.system(size: 12))
                    }
                    .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .onHover { h in
                    if h { NSCursor.pointingHand.push() } else { NSCursor.pop() }
                }

                Spacer()

                Text("\(scripts.count)")
                    .font(.system(size: 11).monospacedDigit())
                    .foregroundStyle(.quaternary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 1)
                    .background(.white.opacity(0.04), in: Capsule())
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(.bar)
        }
    }
}

// MARK: - Script Row (Notion-style: title + date/preview inline)

struct ScriptRow: View {
    @Bindable var script: Script
    var onDelete: (() -> Void)?
    @State private var isHovered = false

    private var preview: String {
        if script.content.isEmpty { return "Empty" }
        let lines = script.content.components(separatedBy: .newlines)
        if lines.count > 1 {
            let second = lines[1].trimmingCharacters(in: .whitespaces)
            if !second.isEmpty { return String(second.prefix(40)) }
        }
        return String(lines.first?.prefix(40) ?? "")
    }

    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(script.title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(script.updatedAt.formatted(.relative(presentation: .named)))
                    Text(preview)
                        .lineLimit(1)
                }
                .font(.system(size: 11))
                .foregroundStyle(.quaternary)
            }

            Spacer(minLength: 0)

            if isHovered, let onDelete {
                Button { onDelete() } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 10))
                        .foregroundStyle(.red.opacity(0.7))
                        .frame(width: 20, height: 20)
                        .background(.red.opacity(0.06), in: RoundedRectangle(cornerRadius: 4, style: .continuous))
                }
                .buttonStyle(.plain)
                .transition(.opacity.combined(with: .scale(scale: 0.85)))
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 4)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(.white.opacity(isHovered ? 0.03 : 0))
        )
        .scaleEffect(isHovered ? 1.005 : 1.0)
        .onHover { h in
            withAnimation(.easeOut(duration: 0.15)) { isHovered = h }
        }
    }
}
