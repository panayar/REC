import Foundation
import Combine
import SwiftUI

private func debugLog(_ msg: String) {
    let line = "[\(Date())] \(msg)\n"
    let path = "/tmp/rec_debug.log"
    if let handle = FileHandle(forWritingAtPath: path) {
        handle.seekToEndOfFile()
        handle.write(line.data(using: .utf8)!)
        handle.closeFile()
    } else {
        FileManager.default.createFile(atPath: path, contents: line.data(using: .utf8))
    }
}

class ScrollEngine: ObservableObject {
    @Published var scrollOffset: CGFloat = 0
    @Published var currentWordIndex: Int = 0
    @Published var isVoiceActive: Bool = false
    @Published var voiceDebugInfo: String = ""
    @Published var voiceAudioLevel: Float = 0.0
    @Published var voiceModelLoading: Bool = false
    @Published var voiceModelReady: Bool = false
    @Published var voiceMicDenied: Bool = false
    @Published var scriptFinished: Bool = false

    private var appState: AppState?
    private var cancellables = Set<AnyCancellable>()
    private var lastMode: String = ""
    private var lastTimestamp: TimeInterval = 0

    // Voice tracking
    private let voiceTracker = VoiceTracker()
    private var targetScrollOffset: CGFloat = 0
    private var totalScriptWords: Int = 0
    private var estimatedTotalHeight: CGFloat = 0
    private var wordOffsets: [CGFloat] = []  // Y offset for each word

    func bind(to appState: AppState) {
        self.appState = appState

        if appState.scrollMode == .voice {
            voiceTracker.loadModel()
        }

        appState.$isPrompting
            .sink { [weak self] isPrompting in
                if isPrompting {
                    self?.start()
                } else {
                    self?.stop()
                }
            }
            .store(in: &cancellables)

        appState.$isPaused
            .sink { [weak self] isPaused in
                if isPaused {
                    self?.pause()
                } else if appState.isPrompting {
                    self?.resume()
                }
            }
            .store(in: &cancellables)

        // Watch for mode changes while running — restart with new mode
        appState.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                // Check if mode actually changed
                let newMode = appState.scrollModeRaw
                if newMode != self.lastMode && appState.isPrompting {
                    self.lastMode = newMode
                    self.stop()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        if appState.isPrompting {
                            self.start()
                        }
                    }
                }
            }
            .store(in: &cancellables)
        lastMode = appState.scrollModeRaw
    }

    func start() {
        guard let appState = appState else { return }

        scrollOffset = 0
        currentWordIndex = 0
        targetScrollOffset = 0
        lastTimestamp = CACurrentMediaTime()

        // Calculate total words and build a word → Y offset lookup table
        let content = appState.currentScript?.content ?? ""
        let words = content.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        totalScriptWords = words.count

        // Measure where each word sits vertically using NSTextStorage
        let font = NSFont.systemFont(ofSize: appState.fontSize, weight: .medium)
        let textWidth = appState.prompterWidth - 56
        let ps = NSMutableParagraphStyle()
        ps.lineSpacing = appState.lineSpacing
        ps.alignment = .center

        let textStorage = NSTextStorage(string: content, attributes: [
            .font: font,
            .paragraphStyle: ps
        ])
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: NSSize(width: textWidth, height: .greatestFiniteMagnitude))
        textContainer.lineFragmentPadding = 0
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)

        // Force layout
        layoutManager.ensureLayout(for: textContainer)

        // Build word offset table: for each word, find its Y position
        var offsets: [CGFloat] = []
        var searchStart = content.startIndex
        for word in words {
            if let range = content.range(of: word, range: searchStart..<content.endIndex) {
                let nsRange = NSRange(range, in: content)
                let glyphRange = layoutManager.glyphRange(forCharacterRange: nsRange, actualCharacterRange: nil)
                let lineRect = layoutManager.lineFragmentRect(forGlyphAt: glyphRange.location, effectiveRange: nil)
                offsets.append(lineRect.origin.y)
                searchStart = range.upperBound
            } else {
                offsets.append(offsets.last ?? 0)
            }
        }
        wordOffsets = offsets

        let totalRect = layoutManager.usedRect(for: textContainer)
        estimatedTotalHeight = totalRect.height + appState.prompterHeight

        debugLog("start() — mode=\(appState.scrollModeRaw) words=\(totalScriptWords)")

        if appState.scrollMode == .voice {
            debugLog("→ VOICE mode")
            startVoiceMode()
        } else {
            debugLog("→ MANUAL mode")
        }

        startDisplayLink()
    }

    func stop() {
        stopDisplayLink()
        stopVoiceMode()
        scrollOffset = 0
        currentWordIndex = 0
        targetScrollOffset = 0
        scriptFinished = false
        voiceMicDenied = false
    }

    func pause() {
        stopDisplayLink()
        if appState?.scrollMode == .voice {
            stopVoiceMode()
        }
    }

    func resume() {
        lastTimestamp = CACurrentMediaTime()
        if appState?.scrollMode == .voice {
            startVoiceMode()
        }
        startDisplayLink()
    }

    /// Manual scroll adjustment
    func nudge(by delta: CGFloat) {
        scrollOffset = max(0, scrollOffset - delta)
        targetScrollOffset = scrollOffset
    }

    // MARK: - Voice Mode

    private func startVoiceMode() {
        guard let script = appState?.currentScript?.content else { return }

        // Forward voice tracker state to ScrollEngine
        voiceTracker.$debugInfo.receive(on: DispatchQueue.main).assign(to: &$voiceDebugInfo)
        voiceTracker.$audioLevel.receive(on: DispatchQueue.main).assign(to: &$voiceAudioLevel)
        voiceTracker.$isModelLoading.receive(on: DispatchQueue.main).assign(to: &$voiceModelLoading)
        voiceTracker.$isModelLoaded.receive(on: DispatchQueue.main).assign(to: &$voiceModelReady)
        voiceTracker.$micPermissionDenied.receive(on: DispatchQueue.main).assign(to: &$voiceMicDenied)
        voiceTracker.$isFinished.receive(on: DispatchQueue.main).assign(to: &$scriptFinished)

        voiceTracker.startTracking(script: script) { [weak self] wordIndex in
            guard let self = self else { return }
            self.currentWordIndex = wordIndex

            // Use exact word position from layout measurement
            guard !self.wordOffsets.isEmpty else { return }
            let idx = min(max(wordIndex - 1, 0), self.wordOffsets.count - 1)
            let wordY = self.wordOffsets[idx]

            // Check if the next word is on a different line (paragraph break)
            // If so, snap ahead to that line immediately instead of smooth scroll
            if idx + 1 < self.wordOffsets.count {
                let nextY = self.wordOffsets[idx + 1]
                let gap = nextY - wordY
                // A paragraph break creates a gap much larger than a normal line
                // (typically 2x+ the line height). Pre-scroll to close the gap.
                let lineHeight = self.appState?.fontSize ?? 15 + (self.appState?.lineSpacing ?? 6)
                if gap > lineHeight * 2.0 {
                    // Jump the scroll ahead to bridge the paragraph gap
                    self.targetScrollOffset = wordY + lineHeight
                    return
                }
            }

            self.targetScrollOffset = wordY
        }

        DispatchQueue.main.async {
            self.isVoiceActive = true
        }
    }

    private func stopVoiceMode() {
        voiceTracker.stopTracking()
        DispatchQueue.main.async {
            self.isVoiceActive = false
        }
    }

    // MARK: - Main Thread Timer (smooth scrolling)

    private var scrollTimer: Timer?

    private func startDisplayLink() {
        stopDisplayLink()
        lastTimestamp = CACurrentMediaTime()

        // Use a high-frequency main-thread timer for butter-smooth scrolling.
        // No cross-thread dispatch = no jitter.
        let timer = Timer(timeInterval: 1.0 / 120.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.main.add(timer, forMode: .common)
        scrollTimer = timer
    }

    private func stopDisplayLink() {
        scrollTimer?.invalidate()
        scrollTimer = nil
    }

    private func tick() {
        let now = CACurrentMediaTime()
        let delta = min(now - lastTimestamp, 0.05) // cap at 50ms to avoid jumps
        lastTimestamp = now

        guard let appState = appState, !appState.isPaused else { return }

        if appState.scrollMode == .voice {
            let diff = targetScrollOffset - scrollOffset
            let smoothFactor: CGFloat = 10.0
            let step = diff * min(CGFloat(delta) * smoothFactor, 1.0)

            if abs(diff) < 0.5 {
                scrollOffset = targetScrollOffset
            } else {
                scrollOffset += step
            }
            appState.scrollProgress = Double(scrollOffset)
        } else {
            let pixelsPerSecond = appState.scrollSpeed * 12.0
            scrollOffset += CGFloat(pixelsPerSecond * delta)
            appState.scrollProgress = Double(scrollOffset)

            if scrollOffset >= estimatedTotalHeight && !scriptFinished {
                scriptFinished = true
            }
        }
    }

    /// Reset to beginning for replay
    func restart() {
        scrollOffset = 0
        currentWordIndex = 0
        targetScrollOffset = 0
        scriptFinished = false
        lastTimestamp = CACurrentMediaTime()
    }

    deinit {
        scrollTimer?.invalidate()
        voiceTracker.stopTracking()
    }
}
