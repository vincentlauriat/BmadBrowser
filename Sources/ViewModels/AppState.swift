import Foundation
import SwiftUI
import AppKit

@Observable
final class AppState {
    var project: BmadProject?
    var tree: [DocumentNode] = []
    var selection: DocumentNode?

    /// Corps markdown (sans frontmatter) du document sélectionné.
    var documentBody: String = ""
    var currentFrontmatter: Frontmatter?

    var isEditing = false
    var isDirty = false
    var searchText = ""
    var errorMessage: String?

    // MARK: - Ouverture de projet

    func presentOpenPanel() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Ouvrir le projet"
        panel.message = "Choisissez la racine d'un projet BMad"
        if panel.runModal() == .OK, let url = panel.url {
            open(rootURL: url, persist: true)
        }
    }

    /// Restaure le dernier projet ouvert au démarrage (si bookmark disponible).
    func restoreLastProject() {
        if let url = BookmarkStore.restore() {
            open(rootURL: url, persist: false)
        }
    }

    func open(rootURL: URL, persist: Bool) {
        let output = ConfigResolver.resolveOutputFolder(projectRoot: rootURL)
        let project = BmadProject(rootURL: rootURL, outputURL: output)
        self.project = project
        self.tree = ProjectScanner.buildTree(at: output)
        self.selection = nil
        self.documentBody = ""
        self.currentFrontmatter = nil
        self.isEditing = false
        self.isDirty = false
        if persist { BookmarkStore.save(rootURL) }
        if !ConfigResolver.looksLikeBmadProject(rootURL) {
            errorMessage = "Ce dossier ne ressemble pas à un projet BMad (ni _bmad/, ni docs/). Les fichiers visibles ont quand même été listés."
        }
    }

    func reload() {
        guard let project else { return }
        let previouslySelected = selection?.url
        tree = ProjectScanner.buildTree(at: project.outputURL)
        if let url = previouslySelected, let node = findNode(url: url, in: tree) {
            select(node)
        }
    }

    // MARK: - Sélection / chargement

    func select(_ node: DocumentNode) {
        guard !node.isDirectory else { return }
        if isDirty { /* on garde simple : le contenu non sauvegardé est perdu si on change */ }
        selection = node
        isEditing = false
        isDirty = false

        guard node.isMarkdown else {
            documentBody = ""
            currentFrontmatter = node.frontmatter
            return
        }
        if let text = try? String(contentsOf: node.url, encoding: .utf8) {
            let (fm, body) = FrontmatterParser.parse(text)
            currentFrontmatter = fm.isEmpty ? nil : fm
            documentBody = body
        } else {
            documentBody = ""
            currentFrontmatter = nil
            errorMessage = "Impossible de lire \(node.name)."
        }
    }

    // MARK: - Édition

    func markDirty() { isDirty = true }

    func save() {
        guard let node = selection, node.isMarkdown else { return }
        var full = ""
        if let fm = currentFrontmatter, !fm.raw.isEmpty {
            full += "---\n"
            for (k, v) in fm.raw { full += "\(k): \(v)\n" }
            full += "---\n"
        }
        full += documentBody
        do {
            try full.write(to: node.url, atomically: true, encoding: .utf8)
            isDirty = false
        } catch {
            errorMessage = "Échec de la sauvegarde : \(error.localizedDescription)"
        }
    }

    func openExternally() {
        guard let node = selection else { return }
        NSWorkspace.shared.open(node.url)
    }

    // MARK: - Recherche

    /// Arbre filtré par `searchText` (sur les noms de fichiers).
    var filteredTree: [DocumentNode] {
        guard !searchText.isEmpty else { return tree }
        return filter(nodes: tree, query: searchText.lowercased())
    }

    private func filter(nodes: [DocumentNode], query: String) -> [DocumentNode] {
        var result: [DocumentNode] = []
        for node in nodes {
            if node.isDirectory {
                let kids = filter(nodes: node.children ?? [], query: query)
                if !kids.isEmpty {
                    let copy = DocumentNode(url: node.url, isDirectory: true, children: kids)
                    result.append(copy)
                }
            } else if node.name.lowercased().contains(query) {
                result.append(node)
            }
        }
        return result
    }

    /// Retrouve un nœud par son identifiant dans l'arbre complet.
    func node(withID id: DocumentNode.ID) -> DocumentNode? {
        func search(_ nodes: [DocumentNode]) -> DocumentNode? {
            for node in nodes {
                if node.id == id { return node }
                if let kids = node.children, let found = search(kids) { return found }
            }
            return nil
        }
        return search(tree)
    }

    private func findNode(url: URL, in nodes: [DocumentNode]) -> DocumentNode? {
        for node in nodes {
            if node.url == url { return node }
            if let kids = node.children, let found = findNode(url: url, in: kids) {
                return found
            }
        }
        return nil
    }
}
