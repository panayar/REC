import SwiftUI

struct RemoteSettingsView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var remoteServer = RemoteServer()

    var body: some View {
        Form {
            Section {
                Toggle("Enable Remote Control", isOn: $appState.remoteEnabled)
                    .onChange(of: appState.remoteEnabled) { _, enabled in
                        if enabled {
                            remoteServer.start(appState: appState)
                        } else {
                            remoteServer.stop()
                        }
                    }

                if appState.remoteEnabled {
                    HStack {
                        Text("Port")
                        Spacer()
                        TextField("Port", value: $appState.remotePort, format: .number)
                            .frame(width: 80)
                            .textFieldStyle(.roundedBorder)
                    }
                }
            } header: {
                Text("Server")
            }

            if appState.remoteEnabled && remoteServer.isRunning {
                Section {
                    VStack(alignment: .center, spacing: 16) {
                        qrCodePlaceholder
                        Text(remoteServer.serverURL)
                            .font(.system(.body, design: .monospaced))
                            .textSelection(.enabled)
                        Text("Open this URL on your phone's browser to control the teleprompter.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                } header: {
                    Text("Connection")
                }

                Section {
                    HStack {
                        Image(systemName: "circle.fill")
                            .foregroundStyle(remoteServer.isRunning ? .green : .red)
                            .font(.caption2)
                        Text(remoteServer.isRunning ? "Server Running" : "Server Stopped")
                        Spacer()
                        Text("\(remoteServer.connectedClients) connected")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Status")
                }
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Label("How it works", systemImage: "info.circle")
                        .font(.headline)
                    Text("The remote control runs a local web server on your Mac. Your phone connects over the same Wi-Fi network — no internet required, no data leaves your network.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            } header: {
                Text("Info")
            }
        }
        .formStyle(.grouped)
        .padding()
        .onAppear {
            if appState.remoteEnabled {
                remoteServer.start(appState: appState)
            }
        }
        .onDisappear {
            remoteServer.stop()
        }
    }

    private var qrCodePlaceholder: some View {
        // Generate QR code from server URL
        ZStack {
            if let qrImage = generateQRCode(from: remoteServer.serverURL) {
                Image(nsImage: qrImage)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 150)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.quaternary)
                    .frame(width: 150, height: 150)
                    .overlay {
                        Image(systemName: "qrcode")
                            .font(.largeTitle)
                            .foregroundStyle(.tertiary)
                    }
            }
        }
    }

    private func generateQRCode(from string: String) -> NSImage? {
        guard !string.isEmpty else { return nil }
        let data = string.data(using: .ascii)
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")

        guard let ciImage = filter.outputImage else { return nil }
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let scaledImage = ciImage.transformed(by: transform)

        let rep = NSCIImageRep(ciImage: scaledImage)
        let nsImage = NSImage(size: rep.size)
        nsImage.addRepresentation(rep)
        return nsImage
    }
}
