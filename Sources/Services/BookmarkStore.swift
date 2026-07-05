import Foundation

/// Persiste et restaure l'accès à la dernière racine ouverte via un security-scoped bookmark.
/// Sans état : le cycle de vie de l'accès scoped est géré par chaque `AppState` (une par fenêtre).
enum BookmarkStore {
    private static let key = "lastProjectBookmark"

    static func save(_ url: URL) {
        guard let data = try? url.bookmarkData(
            options: .withSecurityScope,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        ) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    /// Restaure l'URL persistée et démarre l'accès security-scoped.
    /// L'appelant (`AppState`) est responsable de le libérer via `adoptScopedAccess`.
    static func restore() -> URL? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        var isStale = false
        guard let url = try? URL(
            resolvingBookmarkData: data,
            options: .withSecurityScope,
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        ), url.startAccessingSecurityScopedResource() else { return nil }
        if isStale { save(url) }
        return url
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
