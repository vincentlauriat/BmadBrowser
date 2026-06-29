import Foundation

/// Résout le dossier de sortie BMad d'un projet.
/// Lit `_bmad/config.toml` (clé `output_folder`) et résout `{project-root}`.
/// Fallbacks usuels si la config est absente : `docs/`, `_bmad-output/`.
enum ConfigResolver {

    static func resolveOutputFolder(projectRoot: URL) -> URL {
        if let fromConfig = readOutputFolderFromConfig(projectRoot: projectRoot) {
            return fromConfig
        }
        let fm = FileManager.default
        for candidate in ["docs", "_bmad-output"] {
            let url = projectRoot.appendingPathComponent(candidate, isDirectory: true)
            if fm.fileExistsDirectory(url) { return url }
        }
        // Dernier recours : la racine elle-même.
        return projectRoot
    }

    /// Indique si le dossier ressemble à un projet BMad.
    static func looksLikeBmadProject(_ root: URL) -> Bool {
        let fm = FileManager.default
        if fm.fileExistsDirectory(root.appendingPathComponent("_bmad", isDirectory: true)) { return true }
        if fm.fileExistsDirectory(root.appendingPathComponent("_bmad-output", isDirectory: true)) { return true }
        if fm.fileExistsDirectory(root.appendingPathComponent("docs", isDirectory: true)) { return true }
        return false
    }

    private static func readOutputFolderFromConfig(projectRoot: URL) -> URL? {
        let configURL = projectRoot
            .appendingPathComponent("_bmad", isDirectory: true)
            .appendingPathComponent("config.toml")
        guard let content = try? String(contentsOf: configURL, encoding: .utf8) else { return nil }

        // Cherche la première occurrence de: output_folder = "..."
        for line in content.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard trimmed.hasPrefix("output_folder"),
                  let eq = trimmed.firstIndex(of: "=") else { continue }
            var value = String(trimmed[trimmed.index(after: eq)...])
                .trimmingCharacters(in: .whitespaces)
            value = value.trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
            value = value.replacingOccurrences(of: "{project-root}", with: projectRoot.path)
            if value.isEmpty { continue }
            let url = URL(fileURLWithPath: value, isDirectory: true)
            if FileManager.default.fileExistsDirectory(url) { return url }
        }
        return nil
    }
}

extension FileManager {
    func fileExistsDirectory(_ url: URL) -> Bool {
        var isDir: ObjCBool = false
        return fileExists(atPath: url.path, isDirectory: &isDir) && isDir.boolValue
    }
}
