import SwiftUI
import MarkdownUI

/// Colonne principale : rendu / édition du document sélectionné.
struct DocumentDetailView: View {
    @Bindable var state: AppState

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

    // MARK: - Non markdown

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
