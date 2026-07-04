import SwiftUI

/// Colonne latérale : arbre des documents avec badges de statut.
struct DocumentTreeView: View {
    @Bindable var state: AppState

    /// Sélection exprimée par identifiant (requis par `List(children:selection:)`).
    private var selectionBinding: Binding<DocumentNode.ID?> {
        Binding(
            get: { state.selection?.id },
            set: { newID in
                if let id = newID, let node = state.node(withID: id) {
                    state.guardUnsaved { state.select(node) }
                }
            }
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            if let project = state.project {
                ProjectHeader(project: project)
                Divider()
            }
            Group {
                if state.project == nil {
                    ContentUnavailableView(
                        "No project open",
                        systemImage: "folder.badge.questionmark",
                        description: Text("Open a BMad project (⌘O) to see its documents.")
                    )
                } else if state.tree.isEmpty {
                    ContentUnavailableView(
                        "No document",
                        systemImage: "tray",
                        description: Text("This project has no readable BMad artifact.")
                    )
                } else {
                    List(state.filteredTree, children: \.children, selection: selectionBinding) { node in
                        NodeRow(node: node)
                            .tag(node.id)
                    }
                    .listStyle(.sidebar)
                }
            }
        }
        .searchable(text: $state.searchText, placement: .sidebar, prompt: "Filter documents")
    }
}

/// En-tête de la barre latérale : rappelle en permanence le projet courant.
private struct ProjectHeader: View {
    let project: BmadProject

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "shippingbox.fill")
                .font(.title2)
                .foregroundStyle(.tint)
            VStack(alignment: .leading, spacing: 2) {
                Text(project.name)
                    .font(.headline)
                    .lineLimit(1)
                Text(project.rootURL.path(percentEncoded: false))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .help(project.rootURL.path(percentEncoded: false))
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}

/// Une ligne de l'arbre (fichier ou dossier).
private struct NodeRow: View {
    let node: DocumentNode

    var body: some View {
        Label {
            HStack(spacing: 6) {
                Text(node.name)
                    .foregroundStyle(node.isDirectory ? .secondary : .primary)
                Spacer()
                if let status = node.frontmatter?.status {
                    StatusBadge(status: status)
                }
            }
        } icon: {
            Image(systemName: node.systemImage)
        }
    }
}

/// Petite pastille colorée pour le statut du frontmatter.
struct StatusBadge: View {
    let status: String

    private var color: Color {
        switch status.lowercased() {
        case "complete", "done", "approved": return .green
        case "in-progress", "in_progress", "draft", "wip": return .orange
        case "blocked", "failed": return .red
        default: return .secondary
        }
    }

    var body: some View {
        Text(status)
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.18), in: Capsule())
            .foregroundStyle(color)
    }
}
