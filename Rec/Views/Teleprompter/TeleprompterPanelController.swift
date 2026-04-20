import AppKit
import SwiftUI

/// Custom NSPanel that passes through mouse events outside the notch area.
class NotchPanel: NSPanel {
    /// Check if a point (in window coordinates) is inside the visible notch
    func isPointInNotch(_ windowPoint: NSPoint) -> Bool {
        let appState = AppState.shared
        guard appState.panelVisible || appState.isPrompting else { return false }
        guard let screen = NSScreen.main else { return false }

        let screenPoint = convertPoint(toScreen: windowPoint)
        let notchW = appState.prompterWidth + 64
        let notchH = appState.prompterHeight
        let midX = screen.frame.midX

        let notchRect = NSRect(
            x: midX - notchW / 2,
            y: screen.frame.maxY - notchH,
            width: notchW,
            height: notchH
        )
        return notchRect.contains(screenPoint)
    }

    override func sendEvent(_ event: NSEvent) {
        switch event.type {
        case .leftMouseDown, .leftMouseUp, .rightMouseDown, .rightMouseUp,
             .leftMouseDragged, .rightMouseDragged, .scrollWheel:
            // Only handle mouse events inside the notch
            let point = event.locationInWindow
            if isPointInNotch(point) {
                super.sendEvent(event)
            }
            // Outside → don't handle, let it pass through
        default:
            super.sendEvent(event)
        }
    }
}

class TeleprompterPanelController: NSObject {
    private var panel: NotchPanel?
    private var screenObserver: Any?
    private var stealthObserver: Any?

    override init() {
        super.init()
        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.repositionPanel()
        }

        // Watch stealth mode changes and update panel in real-time
        stealthObserver = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateStealthMode()
        }
    }

    deinit {
        if let obs = screenObserver {
            NotificationCenter.default.removeObserver(obs)
        }
        if let obs = stealthObserver {
            NotificationCenter.default.removeObserver(obs)
        }
    }

    private func updateStealthMode() {
        guard let panel = panel else { return }
        panel.sharingType = AppState.shared.stealthMode ? .none : .readOnly
    }

    func show() {
        if panel != nil {
            repositionPanel()
        } else {
            createPanel()
        }
        guard let panel = panel else { return }
        panel.orderFrontRegardless()

        DispatchQueue.main.async {
            AppState.shared.panelVisible = true
        }
    }

    func hide() {
        AppState.shared.panelVisible = false

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            self?.panel?.orderOut(nil)
        }
    }

    private func repositionPanel() {
        guard let panel = panel, let screen = NSScreen.main else { return }
        let topHeight: CGFloat = 280
        let rect = NSRect(
            x: screen.frame.origin.x,
            y: screen.frame.maxY - topHeight,
            width: screen.frame.width,
            height: topHeight
        )
        panel.setFrame(rect, display: true)
    }

    private func createPanel() {
        guard let screen = NSScreen.main else { return }

        let appState = AppState.shared
        let rootView = AnyView(
            TeleprompterOverlayView().environmentObject(appState)
        )
        let hosting = NSHostingView(rootView: rootView)
        hosting.wantsLayer = true
        hosting.layer?.isOpaque = false
        hosting.layer?.backgroundColor = CGColor.clear

        let topHeight: CGFloat = 280
        let rect = NSRect(
            x: screen.frame.origin.x,
            y: screen.frame.maxY - topHeight,
            width: screen.frame.width,
            height: topHeight
        )

        let panel = NotchPanel(
            contentRect: rect,
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        panel.isFloatingPanel = true
        panel.level = NSWindow.Level(rawValue: NSWindow.Level.statusBar.rawValue + 8)
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isMovable = false
        panel.isMovableByWindowBackground = false
        panel.hidesOnDeactivate = false
        panel.ignoresMouseEvents = false
        panel.sharingType = appState.stealthMode ? .none : .readOnly
        panel.contentView = hosting

        self.panel = panel
    }

    func updateSize() { repositionPanel() }
    func updatePosition() { repositionPanel() }
}
