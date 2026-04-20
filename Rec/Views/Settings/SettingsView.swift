import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            AppearanceSettingsView()
                .tabItem {
                    Label("Appearance", systemImage: "paintbrush")
                }

            PositionSettingsView()
                .tabItem {
                    Label("Position", systemImage: "rectangle.center.inset.filled")
                }

            ControlsSettingsView()
                .tabItem {
                    Label("Controls", systemImage: "keyboard")
                }

            RemoteSettingsView()
                .tabItem {
                    Label("Remote", systemImage: "iphone")
                }
        }
        .frame(width: 480, height: 360)
    }
}
