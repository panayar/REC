import SwiftUI
import Carbon.HIToolbox

struct GlobalKeyboardShortcuts: ViewModifier {
    @EnvironmentObject var appState: AppState

    func body(content: Content) -> some View {
        content
            .onAppear {
                NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                    handleKeyEvent(event)
                }
            }
    }

    /// Check if the user is currently typing in a text field/editor
    private func isEditingText() -> Bool {
        guard let firstResponder = NSApp.keyWindow?.firstResponder else { return false }
        return firstResponder is NSTextView || firstResponder is NSTextField
    }

    private func handleKeyEvent(_ event: NSEvent) -> NSEvent? {
        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

        // If user is typing in a text field, don't intercept unmodified keys
        if isEditingText() && modifiers.isEmpty {
            return event
        }

        // Cmd + Return: Toggle teleprompter
        if event.keyCode == kVK_Return && modifiers == .command {
            appState.togglePrompting()
            return nil
        }

        // Space: Pause/Resume (only when teleprompter is active AND not editing text)
        if event.keyCode == kVK_Space && modifiers.isEmpty && appState.isPrompting && !isEditingText() {
            appState.togglePause()
            return nil
        }

        // Cmd + ]: Speed up
        if event.keyCode == kVK_ANSI_RightBracket && modifiers == .command {
            appState.adjustSpeed(by: 0.5)
            return nil
        }

        // Cmd + [: Speed down
        if event.keyCode == kVK_ANSI_LeftBracket && modifiers == .command {
            appState.adjustSpeed(by: -0.5)
            return nil
        }

        // Cmd + Shift + M: Toggle mirror
        if event.keyCode == kVK_ANSI_M && modifiers == [.command, .shift] {
            appState.isMirrored.toggle()
            return nil
        }

        return event
    }
}

extension View {
    func globalKeyboardShortcuts() -> some View {
        modifier(GlobalKeyboardShortcuts())
    }
}
