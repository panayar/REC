import Foundation
import WhisperKit
import Speech
import AVFoundation
import Accelerate
import Combine

/// Hybrid voice tracker:
/// - Apple Speech: real-time streaming for instant word-by-word tracking
/// - Whisper: periodic accuracy correction every few seconds
/// This gives low latency (Apple) + high accuracy (Whisper).
class VoiceTracker: ObservableObject {
    @Published var isTracking = false
    @Published var currentWordIndex = 0
    @Published var debugInfo = ""
    @Published var isModelLoaded = false
    @Published var isModelLoading = false
    @Published var audioLevel: Float = 0.0
    @Published var micPermissionDenied = false
    @Published var isFinished = false

    // Apple Speech — real-time streaming
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    // Whisper — accuracy correction
    private var whisperKit: WhisperKit?
    private var whisperTimer: Timer?
    private var isWhisperProcessing = false

    // Audio
    private let audioEngine = AVAudioEngine()
    private let bufferLock = NSLock()
    private var whisperSamples: [Float] = []
    private var levelUpdateCounter = 0

    // Audio activity gate — prevents advancing the cursor on hallucinated words
    // that Apple Speech sometimes produces during silence.
    private var lastLoudAudioTime: CFTimeInterval = 0
    private let audioActivityThreshold: Float = 0.05
    private let silenceGracePeriod: CFTimeInterval = 0.5

    // Script
    private var scriptWords: [String] = []
    private var onWordIndexChanged: ((Int) -> Void)?
    private var confirmedIndex = 0
    private var shouldRun = false
    private var lastAppleWordCount = 0
    private var sessionWordOffset = 0 // cumulative offset across Apple Speech restarts
    private var restartTimer: Timer?

    // MARK: - Model

    func loadModel() {
        guard whisperKit == nil, !isModelLoading else { return }
        DispatchQueue.main.async {
            self.isModelLoading = true
            self.debugInfo = "Loading model..."
        }

        // Init Apple Speech with system locale — supports all languages the user has installed
        speechRecognizer = SFSpeechRecognizer(locale: Locale.current)
        if speechRecognizer == nil || !speechRecognizer!.isAvailable {
            speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        }

        Task {
            do {
                let kit = try await WhisperKit(
                    model: "openai_whisper-base",
                    verbose: false,
                    logLevel: .none
                )
                await MainActor.run {
                    self.whisperKit = kit
                    self.isModelLoaded = true
                    self.isModelLoading = false
                    self.debugInfo = "Ready"
                }
            } catch {
                await MainActor.run {
                    // Whisper failed but Apple Speech still works
                    self.isModelLoaded = true
                    self.isModelLoading = false
                    self.debugInfo = "Ready"
                }
            }
        }
    }

    // MARK: - Start / Stop

    func startTracking(script: String, onWordIndexChanged: @escaping (Int) -> Void) {
        // Step 1: Request MICROPHONE access first
        let micStatus = AVCaptureDevice.authorizationStatus(for: .audio)

        if micStatus == .notDetermined {
            // Show the system mic permission dialog
            DispatchQueue.main.async { self.debugInfo = "Requesting mic access..." }
            AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.micPermissionDenied = false
                        self?.requestSpeechThenStart(script: script, cb: onWordIndexChanged)
                    } else {
                        self?.micPermissionDenied = true
                        self?.debugInfo = "Mic denied"
                    }
                }
            }
            return
        } else if micStatus == .denied || micStatus == .restricted {
            DispatchQueue.main.async {
                self.micPermissionDenied = true
                self.debugInfo = "Mic denied"
            }
            return
        }

        // Mic already authorized
        requestSpeechThenStart(script: script, cb: onWordIndexChanged)
    }

    /// Step 2: Request Speech recognition access
    private func requestSpeechThenStart(script: String, cb: @escaping (Int) -> Void) {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                guard let self = self else { return }

                if status != .authorized {
                    self.debugInfo = "Speech recognition denied"
                    return
                }

                self.beginTracking(script: script, cb: cb)
            }
        }
    }

    private func beginTracking(script: String, cb: @escaping (Int) -> Void) {
        scriptWords = script
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .map { norm($0) }

        onWordIndexChanged = cb
        currentWordIndex = 0
        confirmedIndex = 0
        lastAppleWordCount = 0
        sessionWordOffset = 0
        lastTranscriptLength = 0
        previousLastWord = ""
        isFinished = false
        shouldRun = true

        if whisperKit == nil && !isModelLoading {
            loadModel()
        }
        startAudioAndSpeech()
    }

    func stopTracking() {
        shouldRun = false
        restartTimer?.invalidate()
        restartTimer = nil
        whisperTimer?.invalidate()
        whisperTimer = nil
        tearDownSpeech()
        stopAudio()
        DispatchQueue.main.async {
            self.isTracking = false
            self.debugInfo = ""
            self.audioLevel = 0
        }
    }

    // MARK: - Audio + Apple Speech (real-time)

    private func startAudioAndSpeech() {
        stopAudio()
        tearDownSpeech()

        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            debugInfo = "Speech unavailable"
            return
        }

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.requiresOnDeviceRecognition = false

        let inputNode = audioEngine.inputNode
        let hwFormat = inputNode.outputFormat(forBus: 0)
        guard hwFormat.sampleRate > 0 else {
            debugInfo = "No mic"
            return
        }

        let targetRate: Double = 16000
        let ratio = hwFormat.sampleRate / targetRate

        bufferLock.lock()
        whisperSamples = []
        whisperSamples.reserveCapacity(16000 * 15)
        bufferLock.unlock()

        lastAppleWordCount = 0

        // IMPORTANT: assign request BEFORE installing tap, so no audio is dropped
        self.recognitionRequest = request

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: hwFormat) { [weak self] buffer, _ in
            guard let self = self, self.shouldRun else { return }
            guard let data = buffer.floatChannelData?[0] else { return }
            let count = Int(buffer.frameLength)

            // Feed to Apple Speech
            self.recognitionRequest?.append(buffer)

            // Audio level + activity gate
            self.levelUpdateCounter += 1
            if self.levelUpdateCounter % 3 == 0 {
                var rms: Float = 0
                vDSP_rmsqv(data, 1, &rms, vDSP_Length(count))
                let level = min(1.0, rms * 6.0)
                if level > self.audioActivityThreshold {
                    self.lastLoudAudioTime = CACurrentMediaTime()
                }
                DispatchQueue.main.async { self.audioLevel = level }
            }

            // Downsample for Whisper buffer
            let outputCount = Int(Double(count) / ratio)
            guard outputCount > 0 else { return }
            var samples = [Float](repeating: 0, count: outputCount)
            for i in 0..<outputCount {
                samples[i] = data[min(Int(Double(i) * ratio), count - 1)]
            }
            self.bufferLock.lock()
            self.whisperSamples.append(contentsOf: samples)
            if self.whisperSamples.count > 16000 * 15 {
                self.whisperSamples.removeFirst(self.whisperSamples.count - 16000 * 15)
            }
            self.bufferLock.unlock()
        }

        audioEngine.prepare()
        do { try audioEngine.start() } catch {
            debugInfo = "Mic error"
            return
        }

        // Start Apple Speech recognition
        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self = self else { return }

            if let result = result {
                let segments = result.bestTranscription.segments
                let wordCount = segments.count

                DispatchQueue.main.async {
                    self.handleAppleSpeechResult(wordCount: wordCount, text: result.bestTranscription.formattedString)
                }
            }

            // Session ended (1-min limit or error) — auto-restart
            if error != nil || (result?.isFinal ?? false) {
                DispatchQueue.main.async {
                    self.handleSpeechSessionEnd()
                }
            }
        }

        isTracking = true
        debugInfo = "Listening..."

        // Start Whisper correction timer (every 3 seconds)
        whisperTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            self?.runWhisperCorrection()
        }
    }

    // MARK: - Apple Speech: Real-time word tracking

    /// Previous transcript length — to detect only NEW words
    private var lastTranscriptLength = 0

    /// Last `last word` we saw — detects in-place revisions of the final token
    private var previousLastWord: String = ""

    private func handleAppleSpeechResult(wordCount: Int, text: String) {
        guard shouldRun else { return }

        // Normalize the full transcript into words
        let spokenWords = text
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .map { norm($0) }

        guard !spokenWords.isEmpty else { return }

        // Show what the model actually heard — last ~6 words
        let tail = spokenWords.suffix(6).joined(separator: " ")
        debugInfo = tail

        // Determine which words are NEW since last update.
        // Case 1: transcript grew → last `delta` words are new.
        // Case 2: transcript same length but last word changed → Apple revised it.
        let previousLength = lastTranscriptLength
        let currentLastWord = spokenWords.last ?? ""
        lastTranscriptLength = spokenWords.count

        let wordsToCheck: [String]
        if spokenWords.count > previousLength {
            wordsToCheck = Array(spokenWords.suffix(spokenWords.count - previousLength))
        } else if currentLastWord != previousLastWord && !currentLastWord.isEmpty {
            // In-place revision — re-check only the last word
            wordsToCheck = [currentLastWord]
        } else {
            return
        }
        previousLastWord = currentLastWord

        // Duolingo-style: each spoken word advances the cursor by one step
        // OR catches up past words Apple missed. The lookahead window scales
        // with word length: longer words are distinctive enough to jump farther
        // safely, while short words stay conservative (they're often ambiguous).
        var advanced = false
        for word in wordsToCheck {
            guard confirmedIndex < scriptWords.count else { break }

            // How far ahead we'll scan for this word.
            // Wider windows recover from mis-heard words without stranding the cursor.
            let maxSkip: Int
            if word.count >= 5 {
                maxSkip = 7      // distinctive word → safe to jump past several missed ones
            } else if word.count >= 4 {
                maxSkip = 3
            } else {
                maxSkip = 1      // short words too ambiguous for wide skip
            }

            let limit = min(maxSkip, scriptWords.count - confirmedIndex - 1)
            guard limit >= 0 else { continue }
            for offset in 0...limit {
                if wordsMatch(word, scriptWords[confirmedIndex + offset]) {
                    confirmedIndex += offset + 1
                    advanced = true
                    break
                }
            }
            // No match within window → Apple mis-recognized / filler word.
            // Keep cursor, try the next spoken word.
        }

        if advanced {
            currentWordIndex = confirmedIndex
            onWordIndexChanged?(confirmedIndex)
        }

        // Check if done
        if confirmedIndex >= scriptWords.count {
            isFinished = true
            debugInfo = "Done"
            stopTracking()
        }
    }

    // MARK: - Apple Speech: Session restart

    private func handleSpeechSessionEnd() {
        sessionWordOffset += lastAppleWordCount
        lastTranscriptLength = 0
        previousLastWord = ""
        tearDownSpeech()

        guard shouldRun else { return }

        // Brief pause then restart — seamless
        restartTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: false) { [weak self] _ in
            guard let self = self, self.shouldRun else { return }
            self.restartSpeechSession()
        }
    }

    private func restartSpeechSession() {
        guard let recognizer = speechRecognizer, recognizer.isAvailable else { return }

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.requiresOnDeviceRecognition = false

        lastAppleWordCount = 0

        // Re-tap the audio into the new request
        // (the audio engine is still running from startAudioAndSpeech)

        // Assign request BEFORE installing tap (no dropped audio)
        self.recognitionRequest = request

        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self = self else { return }

            if let result = result {
                let segments = result.bestTranscription.segments
                DispatchQueue.main.async {
                    self.handleAppleSpeechResult(wordCount: segments.count, text: result.bestTranscription.formattedString)
                }
            }

            if error != nil || (result?.isFinal ?? false) {
                DispatchQueue.main.async {
                    self.handleSpeechSessionEnd()
                }
            }
        }

        // Re-install tap to feed new request
        // Need to remove old tap first, then add new one
        let inputNode = audioEngine.inputNode
        inputNode.removeTap(onBus: 0)

        let hwFormat = inputNode.outputFormat(forBus: 0)
        let ratio = hwFormat.sampleRate / 16000.0

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: hwFormat) { [weak self] buffer, _ in
            guard let self = self, self.shouldRun else { return }
            guard let data = buffer.floatChannelData?[0] else { return }
            let count = Int(buffer.frameLength)

            self.recognitionRequest?.append(buffer)

            self.levelUpdateCounter += 1
            if self.levelUpdateCounter % 3 == 0 {
                var rms: Float = 0
                vDSP_rmsqv(data, 1, &rms, vDSP_Length(count))
                let level = min(1.0, rms * 6.0)
                DispatchQueue.main.async { self.audioLevel = level }
            }

            let outputCount = Int(Double(count) / ratio)
            guard outputCount > 0 else { return }
            var samples = [Float](repeating: 0, count: outputCount)
            for i in 0..<outputCount {
                samples[i] = data[min(Int(Double(i) * ratio), count - 1)]
            }
            self.bufferLock.lock()
            self.whisperSamples.append(contentsOf: samples)
            if self.whisperSamples.count > 16000 * 15 {
                self.whisperSamples.removeFirst(self.whisperSamples.count - 16000 * 15)
            }
            self.bufferLock.unlock()
        }
    }

    // MARK: - Whisper: Periodic accuracy correction

    private func runWhisperCorrection() {
        guard !isWhisperProcessing, shouldRun, let kit = whisperKit else { return }

        bufferLock.lock()
        let count = whisperSamples.count
        bufferLock.unlock()
        guard count > 16000 else { return } // need 1+ second

        isWhisperProcessing = true

        bufferLock.lock()
        let chunk = Array(whisperSamples.suffix(min(count, 16000 * 6)))
        bufferLock.unlock()

        Task {
            do {
                let results = try await kit.transcribe(audioArray: chunk)
                let text = results.map { $0.text }.joined(separator: " ")
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                await MainActor.run {
                    self.isWhisperProcessing = false
                    guard !text.isEmpty && text != "[BLANK_AUDIO]" else { return }

                    // Use Whisper to correct position if Apple Speech drifted
                    self.correctPositionWithWhisper(text)
                }
            } catch {
                await MainActor.run { self.isWhisperProcessing = false }
            }
        }
    }

    /// Whisper correction disabled — it can push the cursor ahead of what the
    /// user has actually spoken. Duolingo-style tracking follows the user's voice,
    /// it doesn't try to catch up to a transcript. Apple Speech's real-time stream
    /// is our single source of truth.
    private func correctPositionWithWhisper(_ transcript: String) {
        // intentionally no-op
    }

    // MARK: - Cleanup

    private func tearDownSpeech() {
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
    }

    private func stopAudio() {
        if audioEngine.isRunning { audioEngine.stop() }
        audioEngine.inputNode.removeTap(onBus: 0)
    }

    // MARK: - Helpers

    private func wordsMatch(_ a: String, _ b: String) -> Bool {
        if a == b { return true }
        if a.isEmpty || b.isEmpty { return false }
        // Short words ("the", "a", "is", "it") must match exactly.
        // Otherwise every filler word fuzzy-matches a word ahead in the script.
        if a.count < 4 || b.count < 4 { return false }
        // Words ≥ 4 chars: allow 1 edit (plural/typo tolerance)
        if levenshtein(a, b) <= 1 { return true }
        // Words with both ≥ 6 chars: allow 2 edits (verb forms, mishearings)
        if min(a.count, b.count) >= 6 && levenshtein(a, b) <= 2 { return true }
        // Long stem match: one word is a prefix of the other, ≥ 5 chars
        // Catches "running"/"runs", "excited"/"excite", "focks"/"fox" fails safely
        // because short `b` prevents above rules from matching.
        let minLen = min(a.count, b.count)
        if minLen >= 5 && (a.hasPrefix(b.prefix(minLen)) || b.hasPrefix(a.prefix(minLen))) {
            return true
        }
        return false
    }

    private func norm(_ s: String) -> String {
        s.lowercased()
            .trimmingCharacters(in: .punctuationCharacters)
            .trimmingCharacters(in: .symbols)
            .replacingOccurrences(of: "'", with: "")
            .replacingOccurrences(of: "'", with: "")
    }

    private func levenshtein(_ a: String, _ b: String) -> Int {
        let a = Array(a), b = Array(b)
        let m = a.count, n = b.count
        if m == 0 { return n }; if n == 0 { return m }
        var prev = Array(0...n), curr = Array(repeating: 0, count: n + 1)
        for i in 1...m {
            curr[0] = i
            for j in 1...n {
                curr[j] = min(prev[j] + 1, curr[j-1] + 1, prev[j-1] + (a[i-1] == b[j-1] ? 0 : 1))
            }
            prev = curr
        }
        return prev[n]
    }
}
