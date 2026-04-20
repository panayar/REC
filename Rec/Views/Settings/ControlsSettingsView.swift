import SwiftUI

struct ControlsSettingsView: View {
    var body: some View {
        Form {
            Section {
                shortcutRow("Start / Stop Teleprompter", shortcut: "Cmd + Return")
                shortcutRow("Pause / Resume", shortcut: "Space (when active)")
                shortcutRow("Speed Up", shortcut: "Cmd + ]")
                shortcutRow("Speed Down", shortcut: "Cmd + [")
                shortcutRow("Toggle Mirror Mode", shortcut: "Cmd + Shift + M")
                shortcutRow("New Script", shortcut: "Cmd + N")
            } header: {
                Text("Keyboard Shortcuts")
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("The teleprompter overlay supports these gestures:")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    gestureRow("Drag", description: "Move the teleprompter window")
                    gestureRow("Scroll", description: "Manually adjust position")
                }
            } header: {
                Text("Gestures")
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private func shortcutRow(_ action: String, shortcut: String) -> some View {
        HStack {
            Text(action)
            Spacer()
            Text(shortcut)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 4))
        }
    }

    private func gestureRow(_ gesture: String, description: String) -> some View {
        HStack(alignment: .top) {
            Text(gesture)
                .font(.caption.bold())
                .frame(width: 60, alignment: .leading)
            Text(description)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
