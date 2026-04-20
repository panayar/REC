import SwiftUI

// MARK: - Teleprompter Overlay (fills the transparent top-of-screen window)

import AVFoundation

struct TeleprompterOverlayView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var scrollEngine = ScrollEngine()
    @State private var isHovering = false
    @State private var micDenied = false

    // Spacing used for padding and ear sizing (same as MacIsland)
    private let spacing: CGFloat = 16

    // Detect the real hardware notch size
    private var deviceNotchSize: CGSize {
        guard let screen = NSScreen.main else { return CGSize(width: 150, height: 28) }
        let ns = screen.notchSize
        if ns == .zero { return CGSize(width: 150, height: 28) }
        return ns
    }

    // Sizes per state
    private var notchSize: CGSize {
        if appState.panelVisible {
            // Opened
            return CGSize(width: appState.prompterWidth, height: appState.prompterHeight)
        } else {
            // Closed — slightly smaller than device notch
            return CGSize(
                width: max(deviceNotchSize.width - 4, 0),
                height: max(deviceNotchSize.height - 4, 0)
            )
        }
    }

    // Corner radius per state
    private var notchCornerRadius: CGFloat {
        appState.panelVisible ? 32 : 8
    }

    // Animations matching MacIsland exactly
    private var openAnimation: Animation {
        .interactiveSpring(duration: 0.5, extraBounce: 0.25, blendDuration: 0.125)
    }

    private var closeAnimation: Animation {
        .interactiveSpring(duration: 0.5, extraBounce: 0.01, blendDuration: 0.125)
    }

    private var currentAnimation: Animation {
        appState.panelVisible ? openAnimation : closeAnimation
    }

    var body: some View {
        ZStack(alignment: .top) {
            // The notch shape — black body with concave ear corners
            notch
                .zIndex(0)

            // Opened content — clipped to the notch container bounds
            if appState.panelVisible {
                ZStack {
                    // Check states: mic denied → finished → script content
                    if appState.scrollMode == .voice && (micDenied || scrollEngine.voiceMicDenied) {
                        micPermissionView
                    } else if scrollEngine.scriptFinished {
                        finishedView
                    } else {
                        scriptContent
                            .padding(.horizontal, spacing)
                            .padding(.top, spacing)
                            .padding(.bottom, 10)
                    }

                    // Voice indicator — top left
                    // Top bar: voice status left, close button right
                    VStack {
                        HStack(spacing: 0) {
                            // Voice status chip — left (hide when mic denied)
                            if !micDenied && !scrollEngine.voiceMicDenied && (scrollEngine.isVoiceActive || scrollEngine.voiceModelLoading) {
                                voiceStatusPill
                            }

                            Spacer()

                            // "Speak now" — only before user starts speaking
                            if !micDenied && !scrollEngine.voiceMicDenied && scrollEngine.isVoiceActive && scrollEngine.voiceModelReady && scrollEngine.currentWordIndex == 0 {
                                Text("Speak now")
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundStyle(.green.opacity(0.5))
                                    .transition(.opacity)
                            }

                            // Close button
                            Button {
                                appState.stopPrompting()
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundStyle(.white.opacity(0.5))
                                    .frame(width: 18, height: 18)
                                    .background(.white.opacity(0.08), in: Circle())
                            }
                            .buttonStyle(.plain)
                            .padding(.leading, 8)
                        }
                        .padding(.top, 8)
                        .padding(.horizontal, 10)
                        Spacer()
                    }

                    // Controls — hidden until hover, only in manual mode
                    if isHovering && appState.scrollMode != .voice {

                        // Bottom controls bar with gradient backdrop
                        VStack {
                            Spacer()
                            VStack(spacing: 0) {
                                LinearGradient(
                                    colors: [.clear, .black.opacity(0.9), .black],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                                .frame(height: 24)

                                controlsBar
                                    .padding(.horizontal, spacing)
                                    .padding(.bottom, 10)
                                    .background(.black)
                            }
                        }
                        .transition(.opacity)
                    }
                }
                .frame(
                    width: appState.prompterWidth,
                    height: appState.prompterHeight
                )
                .clipShape(.rect(
                    bottomLeadingRadius: notchCornerRadius,
                    bottomTrailingRadius: notchCornerRadius
                ))
                .onScrollWheelGesture { delta in
                    scrollEngine.nudge(by: delta)
                }
                .onHover { hovering in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isHovering = hovering
                    }
                }
                .zIndex(2)
                .transition(
                    .scale
                    .combined(with: .opacity)
                    .combined(with: .offset(y: -appState.prompterHeight / 2))
                    .animation(openAnimation)
                )
            }
        }
        .animation(currentAnimation, value: appState.panelVisible)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onAppear {
            scrollEngine.bind(to: appState)
            checkMicPermission()
        }
        .onDisappear { scrollEngine.stop() }
        .onChange(of: appState.panelVisible) {
            if appState.panelVisible { checkMicPermission() }
        }
    }

    // MARK: - Notch Shape (exact MacIsland approach)

    private var notch: some View {
        Rectangle()
            .foregroundStyle(.black)
            .mask(notchMask)
            .frame(
                width: notchSize.width + notchCornerRadius * 2,
                height: notchSize.height
            )
            .shadow(
                color: .black.opacity(appState.panelVisible ? 1 : 0),
                radius: 16
            )
    }

    private var notchMask: some View {
        Rectangle()
            .foregroundStyle(.black)
            .frame(width: notchSize.width, height: notchSize.height)
            .clipShape(.rect(
                bottomLeadingRadius: notchCornerRadius,
                bottomTrailingRadius: notchCornerRadius
            ))
            // Right ear
            .overlay {
                ZStack(alignment: .topLeading) {
                    Rectangle()
                        .frame(width: notchCornerRadius, height: notchCornerRadius)
                        .foregroundStyle(.black)
                    Rectangle()
                        .clipShape(.rect(topLeadingRadius: notchCornerRadius))
                        .foregroundStyle(.white)
                        .frame(
                            width: notchCornerRadius + spacing,
                            height: notchCornerRadius + spacing
                        )
                        .blendMode(.destinationOut)
                }
                .compositingGroup()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .offset(x: notchCornerRadius + spacing - 0.5, y: -0.5)
            }
            // Left ear
            .overlay {
                ZStack(alignment: .topTrailing) {
                    Rectangle()
                        .frame(width: notchCornerRadius, height: notchCornerRadius)
                        .foregroundStyle(.black)
                    Rectangle()
                        .clipShape(.rect(topTrailingRadius: notchCornerRadius))
                        .foregroundStyle(.white)
                        .frame(
                            width: notchCornerRadius + spacing,
                            height: notchCornerRadius + spacing
                        )
                        .blendMode(.destinationOut)
                }
                .compositingGroup()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .offset(x: -notchCornerRadius - spacing + 0.5, y: -0.5)
            }
    }

    // MARK: - Script Content

    /// Build an AttributedString that highlights spoken words in green
    private func highlightedScript(wordIndex: Int) -> AttributedString {
        let content = appState.currentScript?.content ?? ""
        guard !content.isEmpty else { return AttributedString() }

        // Split into words preserving the original text structure
        let words = content.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        var result = AttributedString()
        var wordCount = 0

        // Walk through the original string character by character
        var i = content.startIndex
        while i < content.endIndex {
            let char = content[i]

            if char.isWhitespace || char.isNewline {
                // Preserve whitespace/newlines as-is
                var ws = AttributedString(String(char))
                ws.foregroundColor = .white.withAlphaComponent(0.4)
                result += ws
                i = content.index(after: i)
            } else {
                // Extract a word
                var wordEnd = i
                while wordEnd < content.endIndex && !content[wordEnd].isWhitespace && !content[wordEnd].isNewline {
                    wordEnd = content.index(after: wordEnd)
                }
                let word = String(content[i..<wordEnd])
                var attrWord = AttributedString(word)

                if wordCount < wordIndex {
                    // Spoken — green
                    attrWord.foregroundColor = NSColor(red: 0.35, green: 0.85, blue: 0.45, alpha: 1.0)
                } else if wordCount == wordIndex {
                    // Current word — bright white, bold emphasis
                    attrWord.foregroundColor = .white
                } else if wordCount <= wordIndex + 3 {
                    // Next few words — slightly visible so reader can anticipate
                    attrWord.foregroundColor = .white.withAlphaComponent(0.55)
                } else {
                    // Upcoming — dimmed
                    attrWord.foregroundColor = .white.withAlphaComponent(0.3)
                }

                result += attrWord
                wordCount += 1
                i = wordEnd
            }
        }

        return result
    }

    private var scriptContent: some View {
        GeometryReader { geometry in
            TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { timeline in
                let _ = timeline.date
                let offset = scrollEngine.scrollOffset
                let wordIndex = scrollEngine.currentWordIndex
                let isVoice = appState.scrollMode == .voice

                // Voice mode: start from middle. Manual: start from bottom.
                let startY = isVoice
                    ? geometry.size.height * 0.45
                    : geometry.size.height - 30

                Text(isVoice ? highlightedScript(wordIndex: wordIndex) : plainScript)
                    .font(prompterFont)
                    .lineSpacing(appState.lineSpacing)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.horizontal, 8)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .offset(y: startY - offset)
                    .scaleEffect(x: appState.isMirrored ? -1 : 1, y: 1)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
            .mask(
                VStack(spacing: 0) {
                    LinearGradient(colors: [.clear, .white], startPoint: .top, endPoint: .bottom)
                        .frame(height: 8)
                    Color.white
                    LinearGradient(colors: [.white, .clear], startPoint: .top, endPoint: .bottom)
                        .frame(height: 14)
                }
            )
        }
    }

    /// Plain white text for manual mode
    private var plainScript: AttributedString {
        let content = appState.currentScript?.content ?? ""
        var attr = AttributedString(content)
        attr.foregroundColor = .white.withAlphaComponent(0.9)
        return attr
    }

    // MARK: - Mic Permission

    private func checkMicPermission() {
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        micDenied = (status == .denied || status == .restricted)

        // If not determined yet and voice mode, request now
        if status == .notDetermined && appState.scrollMode == .voice {
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                DispatchQueue.main.async {
                    micDenied = !granted
                }
            }
        }
    }

    private var micPermissionView: some View {
        VStack(spacing: 12) {
            Spacer()

            Image(systemName: "mic.slash.fill")
                .font(.system(size: 24))
                .foregroundStyle(.red.opacity(0.7))

            VStack(spacing: 4) {
                Text("Microphone Required")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)

                Text("Enable microphone access\nto use voice mode.")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button {
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone") {
                    NSWorkspace.shared.open(url)
                }
            } label: {
                Text("Open System Settings")
                    .font(.system(size: 12, weight: .medium))
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
            .tint(.blue)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(spacing)
    }

    // MARK: - Finished / Credits View

    private var finishedView: some View {
        VStack(spacing: 16) {
            Spacer()

            Image("RecTextLogo")
                .resizable()
                .scaledToFit()
                .frame(height: 44)
                .opacity(0.8)

            Button {
                scrollEngine.restart()
                // Re-start voice tracking if in voice mode
                if appState.scrollMode == .voice, let script = appState.currentScript {
                    scrollEngine.currentWordIndex = 0
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 11, weight: .semibold))
                    Text("Read Again")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundStyle(.white.opacity(0.8))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(.white.opacity(0.1), in: Capsule())
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .transition(.opacity)
    }

    // MARK: - Voice Status Pill

    @ViewBuilder
    private var voiceStatusPill: some View {
        if scrollEngine.voiceModelLoading {
            chipView(
                icon: AnyView(ProgressView().controlSize(.mini).scaleEffect(0.55)),
                text: "Loading model...",
                color: .orange
            )
        } else if scrollEngine.isVoiceActive && !scrollEngine.voiceModelReady {
            chipView(
                icon: AnyView(ProgressView().controlSize(.mini).scaleEffect(0.55)),
                text: "Preparing...",
                color: .yellow
            )
        } else {
            // Always show waveform once model is ready — never switch back to "Ready"
            HStack(spacing: 4) {
                // Live waveform — bars stay at minimum height during silence
                HStack(spacing: 1.5) {
                    ForEach(0..<5, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(.green)
                            .frame(width: 2, height: barH(i, max(0.08, CGFloat(scrollEngine.voiceAudioLevel))))
                            .animation(.interpolatingSpring(stiffness: 350, damping: 10), value: scrollEngine.voiceAudioLevel)
                    }
                }
                .frame(height: 14)

                // Green dot — always on, pulses gently to show it's live
                Circle()
                    .fill(.green)
                    .frame(width: 4, height: 4)
                    .opacity(0.8)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.green.opacity(0.08), in: Capsule())
        }
    }

    private func chipView(icon: AnyView, text: String, color: Color) -> some View {
        HStack(spacing: 5) {
            icon
            Text(text)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(color.opacity(0.7))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.08), in: Capsule())
    }

    private func barH(_ i: Int, _ level: CGFloat) -> CGFloat {
        let patterns: [CGFloat] = [0.3, 0.7, 1.0, 0.8, 0.45]
        return 2.5 + 11 * level * patterns[i]
    }

    private var prompterFont: Font {
        let size = appState.fontSize
        switch appState.fontFamily {
        case "SF Mono", "Menlo":
            return .system(size: size, weight: .medium, design: .monospaced)
        case "System", "SF Pro":
            return .system(size: size, weight: .medium, design: .default)
        default:
            return .custom(appState.fontFamily, size: size).weight(.medium)
        }
    }

    // MARK: - Controls

    private var controlsBar: some View {
        HStack(spacing: 16) {
            // Slow down
            Button { appState.adjustSpeed(by: -0.5) } label: {
                Image(systemName: "gobackward.5")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.cyan)
                    .frame(width: 28, height: 28)
                    .background(.cyan.opacity(0.12), in: Circle())
            }
            .buttonStyle(.plain)

            // Play / Pause
            Button { appState.togglePause() } label: {
                Image(systemName: appState.isPaused ? "play.fill" : "pause.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(.white.opacity(0.15), in: Circle())
            }
            .buttonStyle(.plain)

            // Speed up
            Button { appState.adjustSpeed(by: 0.5) } label: {
                Image(systemName: "goforward.5")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.cyan)
                    .frame(width: 28, height: 28)
                    .background(.cyan.opacity(0.12), in: Circle())
            }
            .buttonStyle(.plain)

            Spacer()

            // Mirror toggle
            Button { appState.isMirrored.toggle() } label: {
                Image(systemName: "arrow.left.and.right.righttriangle.left.righttriangle.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(appState.isMirrored ? .orange : .white.opacity(0.4))
                    .frame(width: 28, height: 28)
                    .background(
                        (appState.isMirrored ? Color.orange.opacity(0.12) : .white.opacity(0.06)),
                        in: Circle()
                    )
            }
            .buttonStyle(.plain)

            // Clickable speed pill — cycles through speeds
            Button {
                let speeds: [Double] = [0.5, 1.0, 1.5, 2.0, 3.0, 4.0, 5.0]
                if let idx = speeds.firstIndex(where: { $0 >= appState.scrollSpeed + 0.01 }) {
                    appState.scrollSpeed = speeds[idx]
                } else {
                    appState.scrollSpeed = speeds[0]
                }
            } label: {
                Text(String(format: "%.1f×", appState.scrollSpeed))
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(.green)
                    .monospacedDigit()
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.green.opacity(0.12), in: Capsule())
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - NSScreen notch detection (same as MacIsland)

extension NSScreen {
    var notchSize: CGSize {
        guard safeAreaInsets.top > 0 else { return .zero }
        let notchHeight = safeAreaInsets.top
        let fullWidth = frame.width
        let leftPadding = auxiliaryTopLeftArea?.width ?? 0
        let rightPadding = auxiliaryTopRightArea?.width ?? 0
        guard leftPadding > 0, rightPadding > 0 else { return .zero }
        let notchWidth = fullWidth - leftPadding - rightPadding
        return CGSize(width: notchWidth, height: notchHeight)
    }
}
