import SwiftUI
import SwiftData

struct MainWindow: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Script.updatedAt, order: .reverse) private var scripts: [Script]
    @State private var selectedScript: Script?
    @State private var searchText = ""

    var filteredScripts: [Script] {
        if searchText.isEmpty { return scripts }
        return scripts.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.content.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationSplitView {
            ScriptListView(
                scripts: filteredScripts,
                selectedScript: $selectedScript,
                onDelete: deleteScripts,
                onCreate: createScript
            )
            .searchable(text: $searchText, prompt: "Search scripts")
            .navigationSplitViewColumnWidth(min: 200, ideal: 240)
        } detail: {
            if let script = selectedScript {
                ScriptEditorView(script: script)
                    .id(script.persistentModelID)
            } else {
                emptyState
            }
        }
        .navigationTitle("")
        .onReceive(NotificationCenter.default.publisher(for: .createNewScript)) { _ in
            createScript()
        }
        .globalKeyboardShortcuts()
        .onAppear {
            if scripts.isEmpty {
                createScript()
            } else {
                selectedScript = scripts.first
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "text.below.photo")
                .font(.system(size: 44, weight: .thin))
                .foregroundStyle(.quaternary)
            VStack(spacing: 4) {
                Text("No Script Selected")
                    .font(.title3.weight(.medium))
                    .foregroundStyle(.secondary)
                Text("Select or create a script to start")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
            }
            Button {
                createScript()
            } label: {
                Text("New Script")
                    .font(.subheadline.weight(.medium))
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func createScript() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            let script = Script(title: "Untitled Script", content: "")
            modelContext.insert(script)
            selectedScript = script
        }
    }

    private func deleteScripts(_ scripts: [Script]) {
        withAnimation(.easeOut(duration: 0.2)) {
            for script in scripts {
                if selectedScript == script {
                    selectedScript = nil
                }
                modelContext.delete(script)
            }
        }
    }
}
