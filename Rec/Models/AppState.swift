import SwiftUI
import Combine

final class AppState: ObservableObject {
    static let shared = AppState()

    // Teleprompter state
    @Published var isPrompting = false
    @Published var isPaused = false
    @Published var isMirrored = false
    @Published var panelVisible = false
    @Published var currentScript: ScriptData?
    @Published var scrollProgress: Double = 0.0

    // Scroll settings
    @AppStorage("scrollSpeed") var scrollSpeed: Double = 2.0
    @AppStorage("scrollMode") var scrollModeRaw: String = "manual"
    @AppStorage("countdownDuration") var countdownDuration: Int = 3

    // Appearance settings
    @AppStorage("fontSize") var fontSize: Double = 22.0
    @AppStorage("fontFamily") var fontFamily: String = "System"
    @AppStorage("textColor") var textColorHex: String = "#FFFFFF"
    @AppStorage("lineSpacing") var lineSpacing: Double = 8.0
    @AppStorage("textOpacity") var textOpacity: Double = 1.0
    @AppStorage("backgroundOpacity") var backgroundOpacity: Double = 0.85
    @AppStorage("prompterWidth") var prompterWidth: Double = 460.0
    @AppStorage("prompterHeight") var prompterHeight: Double = 200.0

    // Position settings
    @AppStorage("positionMode") var positionModeRaw: String = "notch"
    @AppStorage("customX") var customX: Double = 0
    @AppStorage("customY") var customY: Double = 0

    // Remote settings
    @AppStorage("remoteEnabled") var remoteEnabled: Bool = false
    @AppStorage("remotePort") var remotePort: Int = 8089

    // Stealth mode — hide teleprompter from screen sharing
    @AppStorage("stealthMode") var stealthMode: Bool = true

    // Onboarding — only shows on first launch
    @AppStorage("onboardingCompleted") var onboardingCompleted: Bool = false

    // Panel controller reference
    weak var panelController: TeleprompterPanelController?

    // Remote control server — lives for the lifetime of the app
    let remoteServer = RemoteServer()

    var scrollMode: ScrollMode {
        get { ScrollMode(rawValue: scrollModeRaw) ?? .manual }
        set { scrollModeRaw = newValue.rawValue }
    }

    var positionMode: PositionMode {
        get { PositionMode(rawValue: positionModeRaw) ?? .notch }
        set { positionModeRaw = newValue.rawValue }
    }

    var textColor: Color {
        Color(hex: textColorHex) ?? .white
    }

    func togglePrompting() {
        if isPrompting {
            stopPrompting()
        } else {
            startPrompting()
        }
    }

    func startPrompting() {
        guard currentScript != nil else { return }
        scrollProgress = 0.0
        isPaused = false
        isPrompting = true
        panelController?.show()
    }

    func stopPrompting() {
        isPrompting = false
        isPaused = false
        panelController?.hide()
    }

    func togglePause() {
        isPaused.toggle()
    }

    func adjustSpeed(by delta: Double) {
        scrollSpeed = max(0.5, min(10.0, scrollSpeed + delta))
    }
}

struct ScriptData: Equatable {
    let title: String
    let content: String
    let words: [String]

    init(title: String, content: String) {
        self.title = title
        self.content = content
        self.words = content.split(separator: " ").map(String.init)
    }

    static func == (lhs: ScriptData, rhs: ScriptData) -> Bool {
        lhs.title == rhs.title && lhs.content == rhs.content
    }
}

enum ScrollMode: String, CaseIterable {
    case manual = "manual"
    case voice = "voice"

    var label: String {
        switch self {
        case .manual: return "Manual"
        case .voice: return "Voice"
        }
    }
}

enum PositionMode: String, CaseIterable {
    case notch = "notch"
    case top = "top"
    case bottom = "bottom"
    case custom = "custom"

    var label: String {
        switch self {
        case .notch: return "Notch (Default)"
        case .top: return "Top Center"
        case .bottom: return "Bottom Center"
        case .custom: return "Custom Position"
        }
    }
}

extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        guard hexSanitized.count == 6,
              let hexNumber = UInt64(hexSanitized, radix: 16) else {
            return nil
        }

        let r = Double((hexNumber & 0xFF0000) >> 16) / 255.0
        let g = Double((hexNumber & 0x00FF00) >> 8) / 255.0
        let b = Double(hexNumber & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b)
    }
}
