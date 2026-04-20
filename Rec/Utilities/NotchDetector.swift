import AppKit

enum NotchDetector {
    /// Returns true if the main screen has a notch (camera housing area).
    static var hasNotch: Bool {
        guard let screen = NSScreen.main else { return false }
        // On notched MacBooks, the safe area insets top is > 0
        // The visible frame's maxY is less than the frame's maxY by more than the menu bar height
        let menuBarHeight = screen.frame.maxY - screen.visibleFrame.maxY
        // Notched Macs have a taller menu bar area (around 37-38pt vs 25pt on non-notch)
        return menuBarHeight > 30
    }

    /// Returns the center X position of the screen (where the notch is).
    static var notchCenterX: CGFloat {
        guard let screen = NSScreen.main else { return 0 }
        return screen.frame.midX
    }

    /// Returns the Y position just below the notch area.
    static var notchBottomY: CGFloat {
        guard let screen = NSScreen.main else { return 0 }
        return screen.frame.maxY - 4
    }
}
