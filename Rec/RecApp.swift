import SwiftUI
import SwiftData

@main
struct RecApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState.shared

    var body: some Scene {
        WindowGroup("") {
            MainWindow()
                .environmentObject(appState)
                .frame(minWidth: 500, minHeight: 380)
        }
        .modelContainer(for: Script.self)
        .defaultSize(width: 700, height: 500)
        .commands {
            CommandGroup(after: .newItem) {
                Button("New Script") {
                    NotificationCenter.default.post(name: .createNewScript, object: nil)
                }
                .keyboardShortcut("n", modifiers: [.command])
            }
            CommandGroup(after: .sidebar) {
                Button(appState.isPrompting ? "Stop Teleprompter" : "Start Teleprompter") {
                    appState.togglePrompting()
                }
                .keyboardShortcut(.return, modifiers: [.command])

                Button("Toggle Mirror Mode") {
                    appState.isMirrored.toggle()
                }
                .keyboardShortcut("m", modifiers: [.command, .shift])
            }
        }

        Settings {
            SettingsView()
                .environmentObject(appState)
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var teleprompterPanelController: TeleprompterPanelController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        teleprompterPanelController = TeleprompterPanelController()
        AppState.shared.panelController = teleprompterPanelController

        // Auto-start the remote server on launch if the user enabled it
        let enabled = AppState.shared.remoteEnabled
        NSLog("[Rec] Remote auto-start check: remoteEnabled=\(enabled), port=\(AppState.shared.remotePort)")
        if enabled {
            AppState.shared.remoteServer.start(appState: AppState.shared)
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}

extension Notification.Name {
    static let createNewScript = Notification.Name("createNewScript")
}
