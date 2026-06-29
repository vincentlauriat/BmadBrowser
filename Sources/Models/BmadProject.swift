import Foundation

/// Un projet BMad ouvert : racine sélectionnée + dossier de sortie résolu.
struct BmadProject: Identifiable {
    let id = UUID()
    /// Racine du projet (dossier choisi par l'utilisateur).
    let rootURL: URL
    /// Dossier contenant les artefacts (résolu depuis `_bmad/config.toml`, sinon fallback).
    let outputURL: URL

    var name: String { rootURL.lastPathComponent }
}
