import SwiftUI
import MarkdownUI
import AppKit
import UniformTypeIdentifiers

/// Colonne principale : rendu / édition du document sélectionné.
struct DocumentDetailView: View {
    @Bindable var state: AppState
    @State private var showFrontmatterSheet = false

    @State private var scrollTarget: String?

    @AppStorage(SettingsKeys.editorFontSize) private var editorFontSize: Double = 13
    @AppStorage(SettingsKeys.markdownTheme) private var markdownTheme: String = MarkdownThemeChoice.gitHub.rawValue
    @AppStorage(SettingsKeys.showDocumentStats) private var showDocumentStats: Bool = true

    private var selectedTheme: Theme {
        (MarkdownThemeChoice(rawValue: markdownTheme) ?? .gitHub).theme
    }

    private var editorFont: Font {
        .system(size: editorFontSize, design: .monospaced)
    }

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
                .font(editorFont)
                .padding(8)
            } else {
                markdownPreview(node)
                if showDocumentStats {
                    Divider()
                    statsBar
                }
            }
        }
    }

    /// Aperçu markdown découpé en sections (par titre) pour permettre le défilement vers un titre.
    private func markdownPreview(_ node: DocumentNode) -> some View {
        let sections = MarkdownOutline.split(state.documentBody).sections
        let baseURL = node.url.deletingLastPathComponent()
        return ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(sections) { section in
                        Markdown(section.text)
                            .markdownTheme(selectedTheme)
                            .markdownImageProvider(LocalImageProvider(baseURL: baseURL))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .id(section.id)
                    }
                }
                .padding(20)
            }
            .onChange(of: scrollTarget) { _, target in
                guard let target else { return }
                withAnimation { proxy.scrollTo(target, anchor: .top) }
                scrollTarget = nil
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
                .font(editorFont)
                .padding(8)
            } else {
                ScrollView([.vertical, .horizontal]) {
                    SyntaxHighlightedText(text: state.documentBody, ext: node.url.pathExtension, fontSize: editorFontSize)
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

    // MARK: - Export PDF

    private func exportPDF(_ node: DocumentNode) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.pdf]
        panel.nameFieldStringValue = node.url.deletingPathExtension().lastPathComponent + ".pdf"
        panel.canCreateDirectories = true
        guard panel.runModal() == .OK, let url = panel.url else { return }
        let ok = MarkdownPDFExporter.export(
            body: state.documentBody,
            theme: selectedTheme,
            baseURL: node.url.deletingLastPathComponent(),
            to: url
        )
        if !ok {
            state.errorMessage = String(localized: "PDF export failed.")
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup {
            if let node = state.selection, node.isMarkdown, !state.isEditing {
                let headings = MarkdownOutline.split(state.documentBody).headings
                if !headings.isEmpty {
                    Menu {
                        ForEach(headings) { heading in
                            Button {
                                scrollTarget = heading.id
                            } label: {
                                Text(String(repeating: "    ", count: max(0, heading.level - 1)) + heading.title)
                            }
                        }
                    } label: {
                        Label("Outline", systemImage: "list.bullet.indent")
                    }
                }
            }
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
                if node.isMarkdown {
                    Button {
                        exportPDF(node)
                    } label: {
                        Label("Export PDF", systemImage: "arrow.down.doc")
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
