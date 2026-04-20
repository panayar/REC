import SwiftUI

struct AppearanceSettingsView: View {
    @EnvironmentObject var appState: AppState

    private let fontFamilies = [
        "System", "SF Pro", "SF Mono", "Helvetica Neue",
        "Avenir Next", "Georgia", "Menlo"
    ]

    private let colorPresets: [(String, String)] = [
        ("White", "#FFFFFF"),
        ("Yellow", "#FFD60A"),
        ("Green", "#30D158"),
        ("Cyan", "#64D2FF"),
        ("Orange", "#FF9F0A"),
    ]

    var body: some View {
        Form {
            Section {
                Picker("Font", selection: $appState.fontFamily) {
                    ForEach(fontFamilies, id: \.self) { font in
                        Text(font).tag(font)
                    }
                }

                HStack {
                    Text("Font Size")
                    Slider(value: $appState.fontSize, in: 16...72, step: 2)
                    Text("\(Int(appState.fontSize)) pt")
                        .monospacedDigit()
                        .frame(width: 50, alignment: .trailing)
                }

                HStack {
                    Text("Line Spacing")
                    Slider(value: $appState.lineSpacing, in: 4...32, step: 2)
                    Text("\(Int(appState.lineSpacing)) pt")
                        .monospacedDigit()
                        .frame(width: 50, alignment: .trailing)
                }
            } header: {
                Text("Text")
            }

            Section {
                HStack {
                    Text("Text Color")
                    Spacer()
                    ForEach(colorPresets, id: \.0) { name, hex in
                        Button {
                            appState.textColorHex = hex
                        } label: {
                            Circle()
                                .fill(Color(hex: hex) ?? .white)
                                .frame(width: 24, height: 24)
                                .overlay {
                                    if appState.textColorHex == hex {
                                        Circle()
                                            .strokeBorder(.primary, lineWidth: 2)
                                    }
                                }
                        }
                        .buttonStyle(.plain)
                        .help(name)
                    }
                }

                HStack {
                    Text("Text Opacity")
                    Slider(value: $appState.textOpacity, in: 0.3...1.0, step: 0.05)
                    Text("\(Int(appState.textOpacity * 100))%")
                        .monospacedDigit()
                        .frame(width: 40, alignment: .trailing)
                }
            } header: {
                Text("Colors")
            }

            Section {
                HStack {
                    Text("Background Opacity")
                    Slider(value: $appState.backgroundOpacity, in: 0.3...1.0, step: 0.05)
                    Text("\(Int(appState.backgroundOpacity * 100))%")
                        .monospacedDigit()
                        .frame(width: 40, alignment: .trailing)
                }

                HStack {
                    Text("Width")
                    Slider(value: $appState.prompterWidth, in: 300...1200, step: 50)
                    Text("\(Int(appState.prompterWidth))")
                        .monospacedDigit()
                        .frame(width: 50, alignment: .trailing)
                }

                HStack {
                    Text("Height")
                    Slider(value: $appState.prompterHeight, in: 100...600, step: 25)
                    Text("\(Int(appState.prompterHeight))")
                        .monospacedDigit()
                        .frame(width: 50, alignment: .trailing)
                }
            } header: {
                Text("Window")
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}
