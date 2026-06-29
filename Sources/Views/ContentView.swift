import SwiftUI

struct ContentView: View {
    @Bindable var state: AppState

    var body: some View {
        NavigationSplitView {
            DocumentTreeView(state: state)
                .navigationSplitViewColumnWidth(min: 240, ideal: 300)
        } detail: {
            DocumentDetailView(state: state)
        }
        .navigationTitle(state.project?.name ?? "BmadBrowser")
        .navigationSubtitle(state.selection?.name ?? "")
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button {
                    state.presentOpenPanel()
                } label: {
                    Label("Ouvrir un projet", systemImage: "folder")
                }
            }
            ToolbarItem(placement: .navigation) {
                Button {
                    state.reload()
                } label: {
                    Label("Recharger", systemImage: "arrow.clockwise")
                }
                .disabled(state.project == nil)
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
        .onAppear { state.restoreLastProject() }
    }
}
