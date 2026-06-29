import Foundation

/// Nœud de l'arbre de documents : fichier markdown, autre fichier, ou dossier.
final class DocumentNode: Identifiable, Hashable {
    let id = UUID()
    let url: URL
    let name: String
    let isDirectory: Bool
    var children: [DocumentNode]?
    var frontmatter: Frontmatter?

    init(url: URL, isDirectory: Bool, children: [DocumentNode]? = nil) {
        self.url = url
        self.name = url.lastPathComponent
        self.isDirectory = isDirectory
        self.children = children
    }

    var isMarkdown: Bool {
        ["md", "markdown"].contains(url.pathExtension.lowercased())
    }

    var isImage: Bool {
        ["png", "jpg", "jpeg", "gif", "webp", "bmp", "tiff", "heic"].contains(url.pathExtension.lowercased())
    }

    var isPDF: Bool {
        url.pathExtension.lowercased() == "pdf"
    }

    /// Icône SF Symbol selon le type de nœud.
    var systemImage: String {
        if isDirectory { return "folder" }
        switch url.pathExtension.lowercased() {
        case "md", "markdown": return "doc.text"
        case "xlsx", "csv": return "tablecells"
        case "pptx", "key": return "rectangle.on.rectangle"
        case "png", "jpg", "jpeg", "gif", "webp", "pdf": return "photo"
        default: return "doc"
        }
    }

    static func == (lhs: DocumentNode, rhs: DocumentNode) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
