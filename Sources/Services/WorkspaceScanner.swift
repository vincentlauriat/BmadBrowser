import Foundation

/// Découvre les projets BMad situés sous une racine (workspace).
///
/// Logique : si la racine elle-même ressemble à un projet BMad, on retourne un
/// workspace mono-projet. Sinon, on scanne les sous-dossiers directs et on retient
/// ceux qui ressemblent à un projet BMad (présence de `_bmad/`, `docs/` ou `_bmad-output/`).
enum WorkspaceScanner {

    static func scan(rootURL: URL) -> Workspace {
        // Cas 1 : la racine est elle-même un projet -> mode mono-projet.
        if ConfigResolver.looksLikeBmadProject(rootURL) {
            let output = ConfigResolver.resolveOutputFolder(projectRoot: rootURL)
            let project = BmadProject(rootURL: rootURL, outputURL: output)
            return Workspace(rootURL: rootURL, projects: [project], isSingleProject: true)
        }

        // Cas 2 : la racine contient plusieurs projets.
        let fm = FileManager.default
        let entries = (try? fm.contentsOfDirectory(
            at: rootURL,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )) ?? []

        var projects: [BmadProject] = []
        for url in entries {
            let isDir = (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
            guard isDir, ConfigResolver.looksLikeBmadProject(url) else { continue }
            let output = ConfigResolver.resolveOutputFolder(projectRoot: url)
            projects.append(BmadProject(rootURL: url, outputURL: output))
        }
        projects.sort { $0.name.localizedStandardCompare($1.name) == .orderedAscending }

        return Workspace(rootURL: rootURL, projects: projects, isSingleProject: false)
    }
}
