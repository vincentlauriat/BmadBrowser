import Foundation

/// Une racine récemment ouverte (nom + chemin affichable + bookmark scoped réutilisable).
struct RecentProject: Identifiable, Codable, Equatable {
    var id: String { path }
    let name: String
    let path: String
    let bookmark: Data
}

/// Persiste la liste des racines récemment ouvertes via des security-scoped bookmarks.
enum RecentsStore {
    private static let key = "recentRoots"
    private static let maxCount = 8

    /// Liste des récents, la plus récente en tête.
    static func all() -> [RecentProject] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let list = try? JSONDecoder().decode([RecentProject].self, from: data) else { return [] }
        return list
    }

    /// Ajoute (ou remonte en tête) une racine ouverte par l'utilisateur.
    static func add(_ url: URL) {
        guard let bookmark = try? url.bookmarkData(
            options: .withSecurityScope,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        ) else { return }

        let entry = RecentProject(
            name: url.lastPathComponent,
            path: url.path(percentEncoded: false),
            bookmark: bookmark
        )
        var list = all().filter { $0.path != entry.path }
        list.insert(entry, at: 0)
        if list.count > maxCount { list = Array(list.prefix(maxCount)) }
        if let data = try? JSONEncoder().encode(list) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    /// Résout un récent en URL et démarre son accès scoped (via `BookmarkStore`).
    static func resolve(_ recent: RecentProject) -> URL? {
        var isStale = false
        guard let url = try? URL(
            resolvingBookmarkData: recent.bookmark,
            options: .withSecurityScope,
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        ), BookmarkStore.beginAccess(url) else { return nil }
        return url
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
