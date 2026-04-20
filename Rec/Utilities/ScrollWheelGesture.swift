import SwiftUI
import AppKit

/// Captures scroll wheel events only when the mouse is inside the notch area.
class ScrollWheelMonitor: ObservableObject {
    private var monitor: Any?
    var onScroll: ((CGFloat) -> Void)?

    func start() {
        guard monitor == nil else { return }
        monitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
            guard let self = self, let callback = self.onScroll else { return event }

            // Only handle scroll if mouse is inside the notch region
            guard self.isMouseOverNotch() else { return event }

            let delta = event.scrollingDeltaY
            if event.hasPreciseScrollingDeltas {
                callback(delta * 1.5)
            } else {
                callback(delta * 15)
            }

            return event
        }
    }

    func stop() {
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }

    /// Check if the mouse is currently over the expanded notch area
    private func isMouseOverNotch() -> Bool {
        let appState = AppState.shared
        guard appState.panelVisible, let screen = NSScreen.main else { return false }

        let mouse = NSEvent.mouseLocation
        let w = appState.prompterWidth
        let h = appState.prompterHeight
        let x = screen.frame.midX - w / 2
        let y = screen.frame.maxY - h

        let notchRect = NSRect(x: x, y: y, width: w, height: h)
        return notchRect.contains(mouse)
    }

    deinit { stop() }
}

/// View modifier that attaches a scroll wheel monitor while the view is visible.
struct ScrollWheelModifier: ViewModifier {
    let onScroll: (CGFloat) -> Void
    @StateObject private var monitor = ScrollWheelMonitor()

    func body(content: Content) -> some View {
        content
            .onAppear {
                monitor.onScroll = onScroll
                monitor.start()
            }
            .onDisappear {
                monitor.stop()
            }
    }
}

extension View {
    func onScrollWheelGesture(onScroll: @escaping (CGFloat) -> Void) -> some View {
        modifier(ScrollWheelModifier(onScroll: onScroll))
    }
}
