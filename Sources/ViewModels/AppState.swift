import Foundation
import SwiftUI
import AppKit

@Observable
final class AppState {
    /// Niveau supérieur : racine regroupant un ou plusieurs projets.
    var workspace: Workspace?
    /// Projet actuellement sélectionné dans le workspace.
    var project: BmadProject?
    var tree: [DocumentNode] = []
    var selection: DocumentNode?

    /// Corps markdown (sans frontmatter) du document sélectionné.
    var documentBody: String = ""
    var currentFrontmatter: Frontmatter?

    var isEditing = false
    var isDirty = false
    var searchText = ""
    /// Filtre optionnel par statut de frontmatter (nil = tous).
    var statusFilter: String?
    var errorMessage: String?

    /// Cache du contenu des fichiers texte pour la recherche plein-texte (vidé au changement de projet).
    private var contentCache: [URL: String] = [:]

    /// Surveillance FSEvents de la racine pour le rafraîchissement automatique.
    private var watcher: FolderWatcher?

    /// Dialogue « modifications non enregistrées » affiché avant une navigation destructive.
    var showUnsavedDialog = false
    /// Action à exécuter une fois le sort des modifications en cours tranché.
    private var pendingAction: (() -> Void)?

    // MARK: - Ouverture de projet

    func presentOpenPanel() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = String(localized: "Open")
        panel.message = String(localized: "Choose a root containing one or more BMad projects")
        if panel.runModal() == .OK, let url = panel.url {
            // Nouvelle racine du panneau : libère l'accès scoped restauré précédent.
            BookmarkStore.stopCurrentAccess()
            open(rootURL: url, persist: true)
        }
    }

    /// Rouvre une racine récente (résout son bookmark scoped).
    func openRecent(_ recent: RecentProject) {
        guard let url = RecentsStore.resolve(recent) else {
            errorMessage = String(localized: "Couldn't reopen \(recent.name). The folder may have moved.")
            return
        }
        open(rootURL: url, persist: true)
    }

    /// Racines récemment ouvertes (pour le menu « Open Recent »).
    var recentProjects: [RecentProject] { RecentsStore.all() }

    /// Restaure le dernier workspace ouvert au démarrage (si bookmark disponible).
    func restoreLastProject() {
        if let url = BookmarkStore.restore() {
            open(rootURL: url, persist: false)
        }
    }

    /// Ouvre une racine : découvre les projets et sélectionne le premier.
    func open(rootURL: URL, persist: Bool) {
        let workspace = WorkspaceScanner.scan(rootURL: rootURL)
        self.workspace = workspace
        if persist {
            BookmarkStore.save(rootURL)
            RecentsStore.add(rootURL)
        }

        startWatching(rootURL)

        if let first = workspace.projects.first {
            selectProject(first)
        } else {
            clearProject()
            errorMessage = String(localized: "No BMad project found under this folder (no _bmad/, docs/, or _bmad-output/).")
        }
    }

    /// (Re)démarre la surveillance FSEvents de la racine du workspace.
    private func startWatching(_ url: URL) {
        watcher?.stop()
        watcher = FolderWatcher(url: url) { [weak self] in
            self?.autoReloadIfSafe()
        }
    }

    /// Recharge automatiquement, sauf si une édition est en cours (pour ne pas l'écraser).
    private func autoReloadIfSafe() {
        guard !isDirty, !isEditing else { return }
        reload()
    }

    /// Sélectionne un projet du workspace et charge son arbre de documents.
    func selectProject(_ project: BmadProject) {
        self.project = project
        self.tree = ProjectScanner.buildTree(at: project.outputURL)
        self.selection = nil
        self.documentBody = ""
        self.currentFrontmatter = nil
        self.isEditing = false
        self.isDirty = false
        self.statusFilter = nil
        self.contentCache.removeAll()
    }

    /// Réinitialise l'état lié au projet courant (workspace vide).
    private func clearProject() {
        project = nil
        tree = []
        selection = nil
        documentBody = ""
        currentFrontmatter = nil
        isEditing = false
        isDirty = false
    }

    func reload() {
        guard let workspace else { return }
        contentCache.removeAll()
        // Re-scanne la racine pour détecter les projets ajoutés/supprimés.
        let refreshed = WorkspaceScanner.scan(rootURL: workspace.rootURL)
        self.workspace = refreshed

        // Conserve le projet courant (identifié par sa racine) et sa sélection si possible.
        let current = project.flatMap { p in refreshed.projects.first { $0.rootURL == p.rootURL } }
        if let current {
            let previouslySelected = selection?.url
            self.project = current
            tree = ProjectScanner.buildTree(at: current.outputURL)
            if let url = previouslySelected, let node = firstNode(in: tree, where: { $0.url == url }) {
                select(node)
            }
        } else if let first = refreshed.projects.first {
            selectProject(first)
        } else {
            clearProject()
        }
    }

    // MARK: - Sélection / chargement

    /// Exécute `action` immédiatement, ou demande confirmation si des modifications
    /// non enregistrées seraient perdues.
    func guardUnsaved(_ action: @escaping () -> Void) {
        if isDirty {
            pendingAction = action
            showUnsavedDialog = true
        } else {
            action()
        }
    }

    /// L'utilisateur choisit d'ignorer les modifications en cours.
    func discardAndProceed() {
        isDirty = false
        showUnsavedDialog = false
        let action = pendingAction
        pendingAction = nil
        action?()
    }

    /// L'utilisateur choisit d'enregistrer avant de poursuivre.
    func saveAndProceed() {
        save()
        showUnsavedDialog = false
        let action = pendingAction
        pendingAction = nil
        action?()
    }

    /// L'utilisateur annule la navigation ; les modifications restent en cours.
    func cancelPending() {
        showUnsavedDialog = false
        pendingAction = nil
    }

    func select(_ node: DocumentNode) {
        guard !node.isDirectory else { return }
        selection = node
        isEditing = false
        isDirty = false

        guard node.isMarkdown else {
            // Fichiers texte (yaml, json, …) : on charge le contenu brut, sans frontmatter.
            if node.isText {
                if let text = try? String(contentsOf: node.url, encoding: .utf8) {
                    documentBody = text
                    currentFrontmatter = nil
                } else {
                    documentBody = ""
                    currentFrontmatter = nil
                    errorMessage = String(localized: "Couldn't read \(node.name).")
                }
            } else {
                documentBody = ""
                currentFrontmatter = node.frontmatter
            }
            return
        }
        if let text = try? String(contentsOf: node.url, encoding: .utf8) {
            let (fm, body) = FrontmatterParser.parse(text)
            currentFrontmatter = fm.isEmpty ? nil : fm
            documentBody = body
        } else {
            documentBody = ""
            currentFrontmatter = nil
            errorMessage = String(localized: "Couldn't read \(node.name).")
        }
    }

    // MARK: - Édition

    func markDirty() { isDirty = true }

    /// Champs scalaires éditables du frontmatter du document markdown courant.
    var frontmatterFields: [FrontmatterField] {
        guard let raw = currentFrontmatter?.rawBlock else { return [] }
        return FrontmatterParser.scalarFields(from: raw)
    }

    /// Applique les valeurs éditées au bloc frontmatter et marque le document modifié.
    func applyFrontmatterEdits(_ fields: [FrontmatterField]) {
        guard let raw = currentFrontmatter?.rawBlock else { return }
        let newRaw = FrontmatterParser.applying(fields, to: raw)
        guard newRaw != raw else { return }
        let (parsed, _) = FrontmatterParser.parse(newRaw + "\n")
        currentFrontmatter = parsed
        markDirty()
    }

    func save() {
        guard let node = selection else { return }

        let content: String
        if node.isMarkdown {
            // Réécrit le bloc frontmatter brut d'origine tel quel : préserve l'ordre des
            // clés, les listes YAML et les valeurs multi-lignes. Seul le corps est modifié.
            if let raw = currentFrontmatter?.rawBlock {
                content = raw + "\n" + documentBody
            } else {
                content = documentBody
            }
        } else if node.isText {
            content = documentBody
        } else {
            return
        }

        do {
            try content.write(to: node.url, atomically: true, encoding: .utf8)
            isDirty = false
            // Rafraîchit le badge de statut de l'arbre si le frontmatter a changé.
            if node.isMarkdown {
                node.frontmatter = (currentFrontmatter?.isEmpty == false) ? currentFrontmatter : nil
                tree = tree
            }
        } catch {
            errorMessage = String(localized: "Save failed: \(error.localizedDescription)")
        }
    }

    func openExternally() {
        guard let node = selection else { return }
        NSWorkspace.shared.open(node.url)
    }

    // MARK: - Recherche & filtres

    /// Statuts distincts présents dans l'arbre courant (pour le menu de filtre).
    var availableStatuses: [String] {
        var seen = Set<String>()
        var result: [String] = []
        func walk(_ nodes: [DocumentNode]) {
            for node in nodes {
                if let s = node.frontmatter?.status, seen.insert(s).inserted { result.append(s) }
                if let kids = node.children { walk(kids) }
            }
        }
        walk(tree)
        return result.sorted { $0.localizedStandardCompare($1) == .orderedAscending }
    }

    /// Arbre filtré par `searchText` (nom **et** contenu) et par `statusFilter`.
    var filteredTree: [DocumentNode] {
        let query = searchText.lowercased()
        let hasQuery = !query.isEmpty
        let hasStatus = statusFilter != nil
        guard hasQuery || hasStatus else { return tree }
        return filter(nodes: tree) { node in
            (!hasQuery || self.matches(node, query: query)) &&
            (!hasStatus || node.frontmatter?.status == self.statusFilter)
        }
    }

    /// Un fichier correspond si son nom ou son contenu texte contient la requête.
    private func matches(_ node: DocumentNode, query: String) -> Bool {
        if node.name.lowercased().contains(query) { return true }
        guard node.isEditable else { return false }
        return content(of: node.url).contains(query)
    }

    /// Contenu (minuscule) du fichier, mis en cache pour la recherche.
    private func content(of url: URL) -> String {
        if let cached = contentCache[url] { return cached }
        let text = (try? String(contentsOf: url, encoding: .utf8))?.lowercased() ?? ""
        contentCache[url] = text
        return text
    }

    private func filter(nodes: [DocumentNode], predicate: (DocumentNode) -> Bool) -> [DocumentNode] {
        var result: [DocumentNode] = []
        for node in nodes {
            if node.isDirectory {
                let kids = filter(nodes: node.children ?? [], predicate: predicate)
                if !kids.isEmpty {
                    result.append(DocumentNode(url: node.url, isDirectory: true, children: kids))
                }
            } else if predicate(node) {
                result.append(node)
            }
        }
        return result
    }

    /// Retrouve un nœud par son identifiant dans l'arbre complet.
    func node(withID id: DocumentNode.ID) -> DocumentNode? {
        firstNode(in: tree) { $0.id == id }
    }

    /// Premier nœud (en profondeur) satisfaisant `predicate`.
    private func firstNode(in nodes: [DocumentNode], where predicate: (DocumentNode) -> Bool) -> DocumentNode? {
        for node in nodes {
            if predicate(node) { return node }
            if let kids = node.children, let found = firstNode(in: kids, where: predicate) { return found }
        }
        return nil
    }
}
