import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ScriptEditorView: View {
    @Bindable var script: Script
    @EnvironmentObject var appState: AppState
    @State private var isImporting = false
    @State private var showOptions = false

    private var wordCount: Int {
        script.content.split(separator: " ").count
    }

    private var estimatedDuration: String {
        let wordsPerMinute = 150.0
        let minutes = Double(wordCount) / wordsPerMinute
        if minutes < 1 {
            let secs = Int(minutes * 60)
            return secs == 0 ? "" : "\(secs)s"
        }
        return String(format: "%.1f min", minutes)
    }

    private var displayTitle: String {
        let firstLine = script.content
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .newlines)
            .first ?? ""
        let trimmed = String(firstLine.prefix(60)).trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? "Untitled Script" : trimmed
    }

    var body: some View {
        VStack(spacing: 0) {
            editor
            statusBar
        }
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.plainText, .text],
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result)
        }
    }

    // MARK: - Editor (Notion-style)

    private var editor: some View {
        TextEditor(text: $script.content)
            .font(.system(size: 15, weight: .regular, design: .default))
            .lineSpacing(6)
            .scrollContentBackground(.hidden)
            .padding(.horizontal, 32)
            .padding(.top, 24)
            .padding(.bottom, 12)
            .onChange(of: script.content) {
                script.updatedAt = Date()
                script.title = displayTitle
            }
            .overlay(alignment: .topLeading) {
                if script.content.isEmpty {
                    Text("Start writing, or paste your script here…")
                        .font(.system(size: 15))
                        .foregroundStyle(.quaternary)
                        .padding(.leading, 37)
                        .padding(.top, 24)
                        .allowsHitTesting(false)
                }
            }
            .onDrop(of: [.plainText, .fileURL], isTargeted: nil) { providers in
                handleDrop(providers)
            }
    }

    // MARK: - Status Bar

    private var statusBar: some View {
        HStack(spacing: 8) {
            Text("\(wordCount) words")
                .foregroundStyle(.quaternary)

            if !estimatedDuration.isEmpty {
                Text("~\(estimatedDuration)")
                    .foregroundStyle(.quaternary)
            }

            Spacer()

            HStack(spacing: 4) {
                StatusBarButton(icon: "gearshape", tooltip: "Options") {
                    showOptions.toggle()
                }
                .popover(isPresented: $showOptions, arrowEdge: .top) {
                    OptionsPopover()
                        .environmentObject(appState)
                }

                StatusBarButton(icon: "square.and.arrow.down", tooltip: "Import") {
                    isImporting = true
                }

                StatusBarButton(
                    icon: appState.isPrompting ? "stop.fill" : "play.fill",
                    tooltip: appState.isPrompting ? "Stop" : "Start",
                    accent: true
                ) {
                    if appState.isPrompting {
                        appState.stopPrompting()
                    } else {
                        appState.currentScript = ScriptData(title: script.title, content: script.content)
                        appState.startPrompting()
                    }
                }
                .disabled(script.content.isEmpty)
            }
        }
        .font(.caption)
        .padding(.horizontal, 32)
        .padding(.vertical, 10)
    }

    // MARK: - File Handling

    private func handleFileImport(_ result: Result<[URL], Error>) {
        guard case .success(let urls) = result,
              let url = urls.first else { return }
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }
        if let content = try? String(contentsOf: url, encoding: .utf8) {
            script.content = content
            if script.title == "Untitled Script" {
                script.title = url.deletingPathExtension().lastPathComponent
            }
        }
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.plainText.identifier) { data, _ in
                    if let data = data as? Data, let text = String(data: data, encoding: .utf8) {
                        DispatchQueue.main.async { script.content = text }
                    }
                }
                return true
            }
        }
        return false
    }
}

// MARK: - Status Bar Button

struct StatusBarButton: View {
    let icon: String
    let tooltip: String
    var accent: Bool = false
    let action: () -> Void
    @State private var isHovered = false
    @State private var showTooltip = false

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(isHovered ? .primary : .tertiary)
                .frame(width: 28, height: 28)
                .background(isHovered ? .white.opacity(0.06) : .clear, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .overlay(alignment: .top) {
            if showTooltip {
                Text(tooltip)
                    .font(.system(size: 11))
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                    .shadow(color: .black.opacity(0.12), radius: 4, y: 2)
                    .fixedSize()
                    .offset(y: -34)
                    .transition(.opacity.combined(with: .offset(y: 3)))
                    .allowsHitTesting(false)
            }
        }
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.15)) { isHovered = hovering }
            if hovering {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    if isHovered {
                        withAnimation(.easeIn(duration: 0.12)) { showTooltip = true }
                    }
                }
            } else {
                withAnimation(.easeOut(duration: 0.08)) { showTooltip = false }
            }
        }
    }
}
