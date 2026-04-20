import SwiftUI

struct PositionSettingsView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Form {
            Section {
                Picker("Position", selection: $appState.positionModeRaw) {
                    ForEach(PositionMode.allCases, id: \.self) { mode in
                        Text(mode.label).tag(mode.rawValue)
                    }
                }
                .pickerStyle(.radioGroup)

                if appState.positionMode == .custom {
                    HStack {
                        Text("X Position")
                        Slider(value: $appState.customX, in: 0...2000, step: 10)
                        Text("\(Int(appState.customX))")
                            .monospacedDigit()
                            .frame(width: 50, alignment: .trailing)
                    }

                    HStack {
                        Text("Y Position")
                        Slider(value: $appState.customY, in: 0...1400, step: 10)
                        Text("\(Int(appState.customY))")
                            .monospacedDigit()
                            .frame(width: 50, alignment: .trailing)
                    }
                }
            } header: {
                Text("Teleprompter Position")
            }

            Section {
                Toggle("Mirror Mode", isOn: $appState.isMirrored)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Mirror mode flips the text horizontally for use with beam-splitter teleprompter hardware.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Overlay")
            }

            Section {
                VStack(alignment: .leading, spacing: 12) {
                    positionPreview
                }
            } header: {
                Text("Preview")
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private var positionPreview: some View {
        ZStack {
            // Screen representation
            RoundedRectangle(cornerRadius: 8)
                .fill(.quaternary)
                .frame(width: 200, height: 130)
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(.tertiary, lineWidth: 1)
                }

            // Notch
            RoundedRectangle(cornerRadius: 4)
                .fill(.tertiary)
                .frame(width: 50, height: 8)
                .offset(y: -61)

            // Teleprompter strip indicator
            RoundedRectangle(cornerRadius: 3)
                .fill(.blue.opacity(0.6))
                .frame(width: 80, height: 16)
                .offset(y: prompterPreviewOffset)
        }
        .frame(maxWidth: .infinity)
    }

    private var prompterPreviewOffset: CGFloat {
        switch appState.positionMode {
        case .notch: return -53
        case .top: return -40
        case .bottom: return 50
        case .custom: return 0
        }
    }
}
