<div align="center">

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="rec-logo.svg">
  <img src="rec-logo.svg" alt="Rec" width="200" style="background:#111; padding:24px; border-radius:16px;" />
</picture>

### A teleprompter that lives in your Mac's notch.
Invisible during screen sharing. Your voice sets the pace.

[Download for Mac](https://github.com/panayar/REC/releases) · [Website](https://rec.app) · [Report a bug](https://github.com/panayar/REC/issues)

</div>

## Features

* **Dynamic Island teleprompter.** Expands from your Mac's notch with a fluid spring animation, collapses back when you're done.
* **Voice tracking.** Your voice sets the scroll pace. Words turn green word by word, like Duolingo, as you speak them. Powered by Apple Speech and Whisper, all on device.
* **Stealth mode.** Hidden from screen recording and screen sharing. Your audience sees a blank notch.
* **Manual mode.** Adjustable speed, scroll nudging with the trackpad, and mirror mode for beam splitter teleprompter hardware.
* **Notes style editor.** The first line becomes the title. Paste plain text or drag and drop a file.
* **Phone remote.** Scan the QR code, control play, pause, and speed from your phone over Wi Fi.
* **Multi language.** Follows your system locale. English, Spanish, French, German, Portuguese, Chinese, Japanese, and more.

## Install

1. Download the latest `Rec.dmg` from [Releases](https://github.com/panayar/REC/releases).
2. Open the DMG and drag **Rec.app** to your Applications folder.
3. **First launch.** Because Rec is not yet notarized, macOS will show a "Not Opened" warning the first time:
   * **Right click** (or Control click) **Rec.app**, then **Open**
   * In the dialog, click **Open** again
   * macOS remembers your choice, future launches open normally

## Requirements

* macOS 14 (Sonoma) or later
* Apple Silicon or Intel Mac (a notch is not required, works on any Mac)
* Microphone permission (only for voice tracking mode)

## Usage

### Write or paste your script
The first line becomes the title, Notes style. Drag in a `.txt` file or paste text from anywhere.

### Start the teleprompter
Click the play button (or press ⌘↩). The notch expands into a Dynamic Island style panel.

### Pick a scroll mode
Click the gear icon for the Options popover:
* **Manual.** Adjustable speed slider, scroll on the trackpad to nudge up or down.
* **Voice.** Reads along with you, highlights words as you say them.

### Toggle Stealth mode
On by default. Hides the teleprompter from screen sharing and recording.

### Keyboard shortcuts
* ⌘↩ . Start or stop teleprompter
* ⌘N . New script
* ⌘⇧M . Toggle mirror mode
* ⌘, . Open Settings

## Tech stack

* **Swift and SwiftUI** for UI and app shell
* **SwiftData** for script persistence
* **AVFoundation** for audio capture
* **SFSpeechRecognizer** for real time streaming transcription
* **WhisperKit** for the on device Whisper model
* **Network.framework** for the local web server behind the phone remote
* **NSPanel** with a custom hosting view for the floating notch overlay

## Privacy

Everything runs on device. No accounts, no telemetry, no cloud. Audio never leaves your Mac.

## License

MIT

<div align="center">
<sub>Built with <a href="https://claude.com/claude-code">Claude Code</a></sub>
</div>
