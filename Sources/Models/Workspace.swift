import Foundation

/// Niveau supérieur : une racine (workspace) qui regroupe plusieurs projets BMad.
struct Workspace: Identifiable {
    let id = UUID()
    /// Dossier racine choisi par l'utilisateur.
    let rootURL: URL
    /// Projets BMad découverts sous la racine, triés par nom.
    let projects: [BmadProject]
    /// `true` si la racine elle-même est un projet (mode mono-projet, pas de niveau supérieur réel).
    let isSingleProject: Bool

    var name: String { rootURL.lastPathComponent }
}
