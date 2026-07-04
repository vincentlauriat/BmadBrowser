import SwiftUI
import MarkdownUI

/// Colonne principale : rendu / édition du document sélectionné.
struct DocumentDetailView: View {
    @Bindable var state: AppState
    @State private var showFrontmatterSheet = false

    var body: some View {
        Group {
            if let node = state.selection {
                if node.isMarkdown {
                    markdownView(node)
                } else if node.isImage {
                    ImageViewer(url: node.url)
                } else if node.isPDF {
                    PDFViewer(url: node.url)
                } else if node.isText {
                    textView(node)
                } else {
                    nonMarkdownView(node)
                }
            } else {
                ContentUnavailableView(
                    "No document selected",
                    systemImage: "doc.text",
                    description: Text("Pick a document from the list.")
                )
            }
        }
        .toolbar { toolbarContent }
        .sheet(isPresented: $showFrontmatterSheet) {
            FrontmatterEditorView(fields: state.frontmatterFields) { edited in
                state.applyFrontmatterEdits(edited)
            }
        }
    }

    // MARK: - Markdown

    private func markdownView(_ node: DocumentNode) -> some View {
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
                        .markdownImageProvider(LocalImageProvider(baseURL: node.url.deletingLastPathComponent()))
                        .textSelection(.enabled)
                        .padding(20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                Divider()
                statsBar
            }
        }
    }

    /// Barre de statistiques du document markdown : nombre de mots + temps de lecture.
    private var statsBar: some View {
        let words = state.documentBody.split { $0.isWhitespace || $0.isNewline }.count
        let minutes = max(1, Int((Double(words) / 200.0).rounded()))
        return HStack(spacing: 12) {
            Label("\(words) words", systemImage: "text.word.spacing")
            Label("\(minutes) min read", systemImage: "clock")
            Spacer()
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(.quaternary.opacity(0.4))
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

    // MARK: - Texte brut (yaml, json, …)

    private func textView(_ node: DocumentNode) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: node.systemImage)
                Text(node.url.pathExtension.uppercased())
                Spacer()
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.quaternary.opacity(0.4))
            Divider()

            if state.isEditing {
                TextEditor(text: Binding(
                    get: { state.documentBody },
                    set: { state.documentBody = $0; state.markDirty() }
                ))
                .font(.system(.body, design: .monospaced))
                .padding(8)
            } else {
                ScrollView([.vertical, .horizontal]) {
                    Text(state.documentBody)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    // MARK: - Non markdown (placeholder, défini plus bas)

    private func nonMarkdownView(_ node: DocumentNode) -> some View {
        ContentUnavailableView {
            Label(node.name, systemImage: node.systemImage)
        } description: {
            Text("This file type can't be displayed here.")
        } actions: {
            Button("Open in default app") { state.openExternally() }
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup {
            if let node = state.selection, node.isEditable {
                if state.isDirty {
                    Text("• edited").font(.caption).foregroundStyle(.orange)
                }
                if node.isMarkdown, !state.frontmatterFields.isEmpty {
                    Button {
                        showFrontmatterSheet = true
                    } label: {
                        Label("Edit metadata", systemImage: "list.bullet.rectangle")
                    }
                }
                Button {
                    if state.isEditing && state.isDirty { state.save() }
                    state.isEditing.toggle()
                } label: {
                    Label(state.isEditing ? "Preview" : "Edit",
                          systemImage: state.isEditing ? "eye" : "pencil")
                }
                Button {
                    state.save()
                } label: {
                    Label("Save", systemImage: "square.and.arrow.down")
                }
                .keyboardShortcut("s", modifiers: .command)
                .disabled(!state.isDirty)
            } else if let node = state.selection, node.isImage || node.isPDF {
                Button {
                    state.openExternally()
                } label: {
                    Label("Open in default app", systemImage: "arrow.up.forward.app")
                }
            }
        }
    }
}

// MARK: - Éditeur de frontmatter (formulaire)

/// Feuille d'édition des champs scalaires du frontmatter. Les valeurs éditées sont
/// renvoyées via `onApply` ; les lignes non-scalaires du bloc restent intactes.
struct FrontmatterEditorView: View {
    let onApply: ([FrontmatterField]) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var fields: [FrontmatterField]

    init(fields: [FrontmatterField], onApply: @escaping ([FrontmatterField]) -> Void) {
        self.onApply = onApply
        _fields = State(initialValue: fields)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Edit frontmatter")
                .font(.headline)
                .padding()
            Divider()
            if fields.isEmpty {
                ContentUnavailableView(
                    "No editable field",
                    systemImage: "list.bullet.rectangle",
                    description: Text("This document has no scalar frontmatter key.")
                )
                .frame(minHeight: 120)
            } else {
                Form {
                    ForEach($fields) { $field in
                        LabeledContent(field.key) {
                            TextField("", text: $field.value)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                }
                .formStyle(.grouped)
            }
            Divider()
            HStack {
                Spacer()
                Button("Cancel", role: .cancel) { dismiss() }
                Button("Apply") {
                    onApply(fields)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
        .frame(width: 420, height: 360)
    }
}
