import Foundation

/// Construit l'arbre de documents à partir du dossier de sortie d'un projet BMad.
enum ProjectScanner {

    /// Extensions de fichiers affichées (markdown + artefacts courants).
    private static let visibleExtensions: Set<String> = [
        "md", "markdown", "txt", "xlsx", "csv", "pptx", "key",
        "png", "jpg", "jpeg", "gif", "webp", "bmp", "tiff", "heic", "svg",
        "pdf", "json", "yaml", "yml"
    ]

    static func buildTree(at root: URL) -> [DocumentNode] {
        let fm = FileManager.default
        guard let entries = try? fm.contentsOfDirectory(
            at: root,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }

        var dirs: [DocumentNode] = []
        var files: [DocumentNode] = []

        for url in entries {
            let isDir = (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
            if isDir {
                let children = buildTree(at: url)
                // Ignore les dossiers sans contenu visible.
                guard !children.isEmpty else { continue }
                dirs.append(DocumentNode(url: url, isDirectory: true, children: children))
            } else {
                guard visibleExtensions.contains(url.pathExtension.lowercased()) else { continue }
                let node = DocumentNode(url: url, isDirectory: false)
                if node.isMarkdown {
                    node.frontmatter = FrontmatterParser.parseFile(url)
                }
                files.append(node)
            }
        }

        dirs.sort { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        files.sort { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        return dirs + files
    }
}
