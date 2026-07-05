import SwiftUI

struct ContentView: View {
    @Bindable var state: AppState

    /// Sous-titre de la fenêtre : projet courant puis document sélectionné.
    private var navigationSubtitle: String {
        let parts = [state.project?.name, state.selection?.name].compactMap { $0 }
        return parts.joined(separator: " › ")
    }

    private var updateTitle: String {
        switch state.updateResult {
        case .updateAvailable: return String(localized: "Update available")
        case .failed: return String(localized: "Update check failed")
        default: return String(localized: "You're up to date")
        }
    }

    private var updateMessage: String {
        switch state.updateResult {
        case .updateAvailable(let release):
            return String(localized: "BmadBrowser \(release.version) is available. You have \(UpdateChecker.currentVersion).")
        case .failed:
            return String(localized: "Couldn't reach GitHub. Please try again later.")
        default:
            return String(localized: "BmadBrowser \(UpdateChecker.currentVersion) is the latest version.")
        }
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
        .alert(updateTitle, isPresented: $state.showUpdateAlert) {
            if case .updateAvailable = state.updateResult {
                Button("Download") { state.openUpdatePage() }
                Button("Later", role: .cancel) {}
            } else {
                Button("OK", role: .cancel) {}
            }
        } message: {
            Text(updateMessage)
        }
        .onAppear {
            state.restoreLastProject()
            state.autoCheckForUpdatesOnce()
        }
    }
}
