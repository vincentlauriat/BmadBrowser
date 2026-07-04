import Foundation

/// Persiste l'accès au dernier dossier projet via un security-scoped bookmark.
enum BookmarkStore {
    private static let key = "lastProjectBookmark"

    /// URL dont l'accès security-scoped est actuellement démarré (une seule à la fois).
    private static var accessedURL: URL?

    /// Arrête l'accès scoped en cours, s'il y en a un.
    static func stopCurrentAccess() {
        accessedURL?.stopAccessingSecurityScopedResource()
        accessedURL = nil
    }

    static func save(_ url: URL) {
        guard let data = try? url.bookmarkData(
            options: .withSecurityScope,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        ) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    /// Restaure l'URL persistée et démarre l'accès security-scoped.
    /// L'appelant est responsable d'appeler `stopAccessingSecurityScopedResource()`.
    static func restore() -> URL? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        var isStale = false
        guard let url = try? URL(
            resolvingBookmarkData: data,
            options: .withSecurityScope,
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        ) else { return nil }
        // Libère l'accès précédent avant d'en démarrer un nouveau (évite la fuite).
        stopCurrentAccess()
        guard url.startAccessingSecurityScopedResource() else { return nil }
        accessedURL = url
        if isStale { save(url) }
        return url
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
