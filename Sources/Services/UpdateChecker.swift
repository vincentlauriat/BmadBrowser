import Foundation

/// Comparaison de versions sémantiques « x.y.z » (composants numériques).
enum SemVer {
    /// `true` si `a` est strictement plus récent que `b`.
    static func isNewer(_ a: String, than b: String) -> Bool {
        compare(a, b) == .orderedDescending
    }

    static func compare(_ a: String, _ b: String) -> ComparisonResult {
        let pa = parts(a), pb = parts(b)
        for i in 0..<max(pa.count, pb.count) {
            let x = i < pa.count ? pa[i] : 0
            let y = i < pb.count ? pb[i] : 0
            if x != y { return x < y ? .orderedAscending : .orderedDescending }
        }
        return .orderedSame
    }

    /// Découpe « v1.2.3-beta » → [1, 2, 3] (préfixe `v` et suffixes non numériques ignorés).
    private static func parts(_ version: String) -> [Int] {
        let trimmed = version.hasPrefix("v") ? String(version.dropFirst()) : version
        return trimmed.split(separator: ".").map { Int($0.prefix(while: \.isNumber)) ?? 0 }
    }
}

/// Une version publiée récupérée depuis GitHub Releases.
struct AppRelease: Equatable {
    let version: String
    let pageURL: URL
}

enum UpdateCheckResult: Equatable {
    case upToDate
    case updateAvailable(AppRelease)
    case failed
}

/// Vérifie la dernière release GitHub et la compare à la version installée.
/// Pas de dépendance externe ni de clé : compatible sandbox (entitlement `network.client`).
enum UpdateChecker {
    static let repo = "vincentlauriat/BmadBrowser"

    static var currentVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
    }

    static func check() async -> UpdateCheckResult {
        guard let api = URL(string: "https://api.github.com/repos/\(repo)/releases/latest") else {
            return .failed
        }
        var request = URLRequest(url: api)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")

        guard let (data, response) = try? await URLSession.shared.data(for: request),
              (response as? HTTPURLResponse)?.statusCode == 200,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let tag = json["tag_name"] as? String,
              let pageURL = (json["html_url"] as? String).flatMap(URL.init(string:)) else {
            return .failed
        }

        let latest = tag.hasPrefix("v") ? String(tag.dropFirst()) : tag
        if SemVer.isNewer(latest, than: currentVersion) {
            return .updateAvailable(AppRelease(version: latest, pageURL: pageURL))
        }
        return .upToDate
    }
}
