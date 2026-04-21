import SwiftUI
import AVFoundation
import CoreImage.CIFilterBuiltins

struct OptionsPopover: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject private var remoteServer = AppState.shared.remoteServer
    @State private var micStatus: AVAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .audio)

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Scroll Mode
            VStack(alignment: .leading, spacing: 6) {
                sectionLabel("Scroll Mode")

                Picker("", selection: $appState.scrollModeRaw) {
                    ForEach(ScrollMode.allCases, id: \.self) { mode in
                        Text(mode.label).tag(mode.rawValue)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .onChange(of: appState.scrollModeRaw) {
                    micStatus = AVCaptureDevice.authorizationStatus(for: .audio)
                }

                // Mic permission warning — only when voice mode AND mic not authorized
                if appState.scrollMode == .voice && micStatus != .authorized {
                    micWarningView
                }

                // Voice mode tip — always show when voice is selected
                if appState.scrollMode == .voice {
                    HStack(spacing: 6) {
                        Image(systemName: "earbuds")
                            .font(.system(size: 10))
                            .foregroundStyle(.blue.opacity(0.7))
                        Text("Use earbuds in a quiet place for best results")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(8)
                    .background(.blue.opacity(0.04), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                    .padding(.top, 4)
                }
            }

            Divider().opacity(0.5)

            // Speed (only show in manual mode)
            if appState.scrollMode == .manual {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        sectionLabel("Speed")
                        Spacer()
                        Text(String(format: "%.1f×", appState.scrollSpeed))
                            .font(.system(size: 12, weight: .semibold, design: .rounded).monospacedDigit())
                            .foregroundStyle(.purple)
                    }

                    Slider(value: $appState.scrollSpeed, in: 0.5...5.0, step: 0.5)
                        .tint(.purple)
                }

                Divider().opacity(0.5)
            }

            // Mirror
            Toggle(isOn: $appState.isMirrored) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.left.and.right.righttriangle.left.righttriangle.right")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    Text("Mirror Mode")
                        .font(.system(size: 13))
                }
            }
            .toggleStyle(.switch)
            .tint(.purple)

            // Stealth mode
            Toggle(isOn: $appState.stealthMode) {
                HStack(spacing: 8) {
                    Image(systemName: "eye.slash.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Stealth Mode")
                            .font(.system(size: 13))
                        Text("Hide from screen sharing")
                            .font(.system(size: 10))
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .toggleStyle(.switch)
            .tint(.purple)

            Divider().opacity(0.5)

            // Remote control
            Toggle(isOn: $appState.remoteEnabled) {
                HStack(spacing: 8) {
                    Image(systemName: "iphone.radiowaves.left.and.right")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Remote Control")
                            .font(.system(size: 13))
                        Text("Scan QR to control from your phone")
                            .font(.system(size: 10))
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .toggleStyle(.switch)
            .tint(.purple)
            .onChange(of: appState.remoteEnabled) { _, enabled in
                if enabled {
                    appState.remoteServer.start(appState: appState)
                } else {
                    appState.remoteServer.stop()
                }
            }

            if appState.remoteEnabled && remoteServer.isRunning && !remoteServer.serverURL.isEmpty {
                remoteConnectionView
            }
        }
        .padding(16)
        .frame(width: 300)
        .onAppear {
            micStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        }
    }

    // MARK: - Remote Connection Info

    private var remoteConnectionView: some View {
        HStack(alignment: .center, spacing: 12) {
            if let qr = generateQR(remoteServer.serverURL) {
                Image(nsImage: qr)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .padding(4)
                    .background(.white, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Connected on Wi-Fi")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                Text(remoteServer.serverURL)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.primary)
                    .textSelection(.enabled)
                    .lineLimit(2)
                    .truncationMode(.middle)
                HStack(spacing: 4) {
                    Circle()
                        .fill(.green)
                        .frame(width: 5, height: 5)
                    Text("\(remoteServer.connectedClients) connected")
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .background(.purple.opacity(0.06), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func generateQR(_ text: String) -> NSImage? {
        guard !text.isEmpty else { return nil }
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(text.utf8)
        filter.correctionLevel = "M"
        guard let ciImage = filter.outputImage?.transformed(by: CGAffineTransform(scaleX: 8, y: 8)) else { return nil }
        let rep = NSCIImageRep(ciImage: ciImage)
        let image = NSImage(size: rep.size)
        image.addRepresentation(rep)
        return image
    }

    // MARK: - Mic Warning

    private var micWarningView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: micStatus == .denied ? "mic.slash.fill" : "mic.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(micStatus == .denied ? .red : .orange)

                Text(micStatus == .denied
                     ? "Microphone access denied"
                     : "Microphone access required")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(micStatus == .denied ? .red : .orange)
            }

            if micStatus == .denied {
                Text("Voice mode needs microphone access. Enable it in System Settings.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Button {
                    // Open System Settings > Privacy > Microphone
                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone") {
                        NSWorkspace.shared.open(url)
                    }
                } label: {
                    Text("Open Settings")
                        .font(.system(size: 11, weight: .medium))
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .tint(.orange)
            } else {
                Button {
                    AVCaptureDevice.requestAccess(for: .audio) { granted in
                        DispatchQueue.main.async {
                            micStatus = AVCaptureDevice.authorizationStatus(for: .audio)
                            if !granted {
                                appState.scrollMode = .manual
                            }
                        }
                    }
                } label: {
                    Text("Grant Access")
                        .font(.system(size: 11, weight: .medium))
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .tint(.green)
            }
        }
        .padding(10)
        .background(.orange.opacity(micStatus == .denied ? 0.06 : 0.04), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
    }
}
