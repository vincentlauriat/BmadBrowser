import SwiftUI

/// Première colonne : liste des projets du workspace (niveau supérieur).
struct ProjectListView: View {
    @Bindable var state: AppState

    /// Sélection exprimée par identifiant (requis par `List(selection:)`).
    private var selectionBinding: Binding<BmadProject.ID?> {
        Binding(
            get: { state.project?.id },
            set: { newID in
                if let id = newID,
                   let project = state.workspace?.projects.first(where: { $0.id == id }) {
                    state.selectProject(project)
                }
            }
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            if let workspace = state.workspace {
                WorkspaceHeader(workspace: workspace)
                Divider()
                if workspace.projects.isEmpty {
                    ContentUnavailableView(
                        "Aucun projet",
                        systemImage: "square.stack.3d.up.slash",
                        description: Text("Aucun projet BMad trouvé sous cette racine.")
                    )
                } else {
                    List(workspace.projects, selection: selectionBinding) { project in
                        ProjectRow(project: project)
                            .tag(project.id)
                    }
                    .listStyle(.sidebar)
                }
            } else {
                ContentUnavailableView(
                    "Aucune racine ouverte",
                    systemImage: "folder.badge.questionmark",
                    description: Text("Ouvrez une racine de projets (⌘O).")
                )
            }
        }
    }
}

/// En-tête de la colonne projets : rappelle la racine (workspace) courante.
private struct WorkspaceHeader: View {
    let workspace: Workspace

    private var subtitle: String {
        if workspace.isSingleProject { return "Projet unique" }
        let count = workspace.projects.count
        return "\(count) projet\(count > 1 ? "s" : "")"
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "rectangle.3.group.fill")
                .font(.title2)
                .foregroundStyle(.tint)
            VStack(alignment: .leading, spacing: 2) {
                Text(workspace.name)
                    .font(.headline)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .help(workspace.rootURL.path(percentEncoded: false))
    }
}

/// Une ligne de projet dans la liste du workspace.
private struct ProjectRow: View {
    let project: BmadProject

    var body: some View {
        Label {
            Text(project.name)
                .lineLimit(1)
        } icon: {
            Image(systemName: "shippingbox")
        }
    }
}
