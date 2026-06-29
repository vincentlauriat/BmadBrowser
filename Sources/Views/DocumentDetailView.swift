import SwiftUI
import MarkdownUI

/// Colonne principale : rendu / édition du document sélectionné.
struct DocumentDetailView: View {
    @Bindable var state: AppState

    var body: some View {
        Group {
            if let node = state.selection {
                if node.isMarkdown {
                    markdownView
                } else {
                    nonMarkdownView(node)
                }
            } else {
                ContentUnavailableView(
                    "Aucun document sélectionné",
                    systemImage: "doc.text",
                    description: Text("Choisissez un document dans la liste.")
                )
            }
        }
        .toolbar { toolbarContent }
    }

    // MARK: - Markdown

    private var markdownView: some View {
        VStack(spacing: 0) {
            frontmatterBar
            Divider()
            if state.isEditing {
                TextEditor(text: Binding(
                    get: { state.documentBody },
                    set: { state.documentBody = $0; state.markDirty() }
                ))
                .font(.system(.body, design: .monospaced))
                .padding(8)
            } else {
                ScrollView {
                    Markdown(state.documentBody)
                        .markdownTheme(.gitHub)
                        .textSelection(.enabled)
                        .padding(20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    @ViewBuilder
    private var frontmatterBar: some View {
        if let fm = state.currentFrontmatter, !fm.isEmpty {
            HStack(spacing: 12) {
                if let status = fm.status { StatusBadge(status: status) }
                if let type = fm.workflowType {
                    Label(type, systemImage: "flowchart").font(.caption)
                }
                if let date = fm.date {
                    Label(date, systemImage: "calendar").font(.caption)
                }
                Spacer()
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.quaternary.opacity(0.4))
        }
    }

    // MARK: - Non markdown

    private func nonMarkdownView(_ node: DocumentNode) -> some View {
        ContentUnavailableView {
            Label(node.name, systemImage: node.systemImage)
        } description: {
            Text("Ce type de fichier ne peut pas être affiché ici.")
        } actions: {
            Button("Ouvrir dans l'app par défaut") { state.openExternally() }
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup {
            if let node = state.selection, node.isMarkdown {
                if state.isDirty {
                    Text("• modifié").font(.caption).foregroundStyle(.orange)
                }
                Button {
                    if state.isEditing && state.isDirty { state.save() }
                    state.isEditing.toggle()
                } label: {
                    Label(state.isEditing ? "Aperçu" : "Éditer",
                          systemImage: state.isEditing ? "eye" : "pencil")
                }
                Button {
                    state.save()
                } label: {
                    Label("Enregistrer", systemImage: "square.and.arrow.down")
                }
                .keyboardShortcut("s", modifiers: .command)
                .disabled(!state.isDirty)
            }
        }
    }
}
