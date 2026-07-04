import SwiftUI

struct ContentView: View {
    @Bindable var state: AppState

    /// Sous-titre de la fenêtre : projet courant puis document sélectionné.
    private var navigationSubtitle: String {
        let parts = [state.project?.name, state.selection?.name].compactMap { $0 }
        return parts.joined(separator: " › ")
    }

    var body: some View {
        NavigationSplitView {
            ProjectListView(state: state)
                .navigationSplitViewColumnWidth(min: 180, ideal: 220)
        } content: {
            DocumentTreeView(state: state)
                .navigationSplitViewColumnWidth(min: 240, ideal: 300)
        } detail: {
            DocumentDetailView(state: state)
        }
        .navigationTitle(state.workspace?.name ?? "BmadBrowser")
        .navigationSubtitle(navigationSubtitle)
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Menu {
                    if state.recentProjects.isEmpty {
                        Text("No recent roots")
                    } else {
                        Section("Recent") {
                            ForEach(state.recentProjects) { recent in
                                Button(recent.name) { state.openRecent(recent) }
                            }
                        }
                        Divider()
                        Button("Clear Recents") { RecentsStore.clear() }
                    }
                } label: {
                    Label("Open a root", systemImage: "folder")
                } primaryAction: {
                    state.presentOpenPanel()
                }
            }
            ToolbarItem(placement: .navigation) {
                Button {
                    state.reload()
                } label: {
                    Label("Reload", systemImage: "arrow.clockwise")
                }
                .disabled(state.workspace == nil)
            }
        }
        .alert("Information", isPresented: Binding(
            get: { state.errorMessage != nil },
            set: { if !$0 { state.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { state.errorMessage = nil }
        } message: {
            Text(state.errorMessage ?? "")
        }
        .confirmationDialog(
            "You have unsaved changes.",
            isPresented: $state.showUnsavedDialog,
            titleVisibility: .visible
        ) {
            Button("Save") { state.saveAndProceed() }
            Button("Discard", role: .destructive) { state.discardAndProceed() }
            Button("Cancel", role: .cancel) { state.cancelPending() }
        }
        .onAppear { state.restoreLastProject() }
    }
}
