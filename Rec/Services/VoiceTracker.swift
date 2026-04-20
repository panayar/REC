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

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: hwFormat) { [weak self] buffer, _ in
            guard let self = self, self.shouldRun else { return }
            guard let data = buffer.floatChannelData?[0] else { return }
            let count = Int(buffer.frameLength)

            // Feed to Apple Speech
            self.recognitionRequest?.append(buffer)

            // Audio level
            self.levelUpdateCounter += 1
            if self.levelUpdateCounter % 3 == 0 {
                var rms: Float = 0
                vDSP_rmsqv(data, 1, &rms, vDSP_Length(count))
                let level = min(1.0, rms * 6.0)
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

        self.recognitionRequest = request
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

    private func handleAppleSpeechResult(wordCount: Int, text: String) {
        guard shouldRun else { return }

        // Normalize the full transcript into words
        let spokenWords = text
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .map { norm($0) }

        guard !spokenWords.isEmpty else { return }

        // Only process if transcript changed
        let currentLength = spokenWords.count
        guard currentLength != lastTranscriptLength else { return }
        lastTranscriptLength = currentLength

        debugInfo = String(text.suffix(25))

        // Match spoken words against script from confirmed position
        // Use the last N spoken words as an anchor to find position
        let anchorSize = min(6, spokenWords.count)
        let anchor = Array(spokenWords.suffix(anchorSize))

        // Search forward from current position
        let searchStart = max(0, confirmedIndex - 2)
        let searchEnd = min(scriptWords.count, confirmedIndex + 30)

        var bestPos = confirmedIndex
        var bestScore = 0

        for i in searchStart..<searchEnd {
            var score = 0
            for (j, word) in anchor.enumerated() {
                let idx = i + j
                guard idx < scriptWords.count else { break }
                if wordsMatch(word, scriptWords[idx]) {
                    score += 1
                }
            }
            if score > bestScore {
                bestScore = score
                bestPos = i + anchor.count
            }
        }

        // Also try simple sequential matching for single-word advances
        // This catches word-by-word progress even when anchor matching fails
        let lastSpoken = spokenWords.last ?? ""
        for offset in 0..<min(4, scriptWords.count - confirmedIndex) {
            if wordsMatch(lastSpoken, scriptWords[confirmedIndex + offset]) {
                let seqPos = confirmedIndex + offset + 1
                if seqPos > bestPos { bestPos = seqPos }
                break
            }
        }

        if bestPos > confirmedIndex {
            confirmedIndex = min(bestPos, scriptWords.count)
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

        self.recognitionRequest = request

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

    /// Use Whisper transcript to correct the position if Apple Speech got out of sync
    private func correctPositionWithWhisper(_ transcript: String) {
        let spoken = transcript
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .map { norm($0) }

        guard spoken.count >= 3 else { return }

        // Take last 5 words from Whisper and find where they are in the script
        let anchor = Array(spoken.suffix(min(5, spoken.count)))

        // Search in a window around current position
        let searchStart = max(0, confirmedIndex - 10)
        let searchEnd = min(scriptWords.count - 1, confirmedIndex + 20)
        guard searchStart <= searchEnd else { return }

        var bestScore = 0
        var bestPos = confirmedIndex

        for i in searchStart...searchEnd {
            var score = 0
            for (j, word) in anchor.enumerated() {
                let idx = i + j
                guard idx < scriptWords.count else { break }
                if wordsMatch(word, scriptWords[idx]) { score += 1 }
            }
            if score > bestScore {
                bestScore = score
                bestPos = i + anchor.count
            }
        }

        // Only correct if Whisper is confident (3+ matching words)
        // and the correction moves us forward
        if bestScore >= 3 && bestPos > confirmedIndex {
            let correction = bestPos - confirmedIndex
            if correction <= 10 { // don't jump too far
                confirmedIndex = bestPos
                currentWordIndex = bestPos
                onWordIndexChanged?(bestPos)
            }
        }
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
        let minLen = min(a.count, b.count)
        if minLen >= 3 {
            let pl = max(3, minLen - 2)
            if a.prefix(pl) == b.prefix(pl) { return true }
        }
        if minLen >= 3 && levenshtein(a, b) <= 1 { return true }
        if minLen >= 5 && levenshtein(a, b) <= 2 { return true }
        if a.count >= 4 && b.contains(a) { return true }
        if b.count >= 4 && a.contains(b) { return true }
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
