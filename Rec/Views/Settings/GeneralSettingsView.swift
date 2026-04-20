import SwiftUI

struct GeneralSettingsView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Form {
            Section {
                Picker("Scroll Mode", selection: $appState.scrollModeRaw) {
                    ForEach(ScrollMode.allCases, id: \.self) { mode in
                        Text(mode.label).tag(mode.rawValue)
                    }
                }

                HStack {
                    Text("Scroll Speed")
                    Slider(value: $appState.scrollSpeed, in: 0.5...10.0, step: 0.5)
                    Text(String(format: "%.1fx", appState.scrollSpeed))
                        .monospacedDigit()
                        .frame(width: 40, alignment: .trailing)
                }

                Picker("Countdown", selection: $appState.countdownDuration) {
                    Text("None").tag(0)
                    Text("3 seconds").tag(3)
                    Text("5 seconds").tag(5)
                    Text("10 seconds").tag(10)
                }
            } header: {
                Text("Teleprompter")
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "waveform")
                            .foregroundStyle(.blue)
                        Text("Voice Tracking")
                            .font(.headline)
                    }
                    Text("When enabled, the teleprompter automatically adjusts scroll speed to match your speaking pace using on-device speech recognition.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Requires microphone access. All processing happens on-device — no data is sent to external servers.")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(.vertical, 4)
            } header: {
                Text("Voice Tracking Info")
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}
