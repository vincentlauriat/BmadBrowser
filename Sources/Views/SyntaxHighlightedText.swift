import SwiftUI

/// Texte monospace avec coloration syntaxique légère pour json / yaml / toml.
/// En lecture seule (l'édition reste un `TextEditor` brut).
struct SyntaxHighlightedText: View {
    let text: String
    let ext: String
    let fontSize: Double

    var body: some View {
        Text(SyntaxHighlighter.highlight(text, ext: ext, fontSize: fontSize))
    }
}

/// Colorise un texte structuré en `AttributedString` via quelques passes regex.
/// Volontairement simple (fichiers de config BMad, pas un éditeur complet).
enum SyntaxHighlighter {
    private static let supported: Set<String> = ["json", "yaml", "yml", "toml"]

    // Couleurs système : s'adaptent au mode clair/sombre.
    private static let commentColor = Color.secondary
    private static let keyColor = Color(nsColor: .systemPurple)
    private static let stringColor = Color(nsColor: .systemGreen)
    private static let numberColor = Color(nsColor: .systemBlue)
    private static let keywordColor = Color(nsColor: .systemOrange)

    static func highlight(_ text: String, ext: String, fontSize: Double) -> AttributedString {
        let mono = Font.system(size: fontSize, design: .monospaced)
        let language = ext.lowercased()

        guard supported.contains(language) else {
            var plain = AttributedString(text)
            plain.font = mono
            return plain
        }

        let ns = text as NSString
        var colors = [Color?](repeating: nil, count: ns.length)

        func apply(_ pattern: String, _ color: Color, group: Int = 0) {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines]) else { return }
            let full = NSRange(location: 0, length: ns.length)
            for match in regex.matches(in: text, options: [], range: full) {
                let range = match.range(at: group)
                guard range.location != NSNotFound else { continue }
                for i in range.location..<(range.location + range.length) where colors[i] == nil {
                    colors[i] = color
                }
            }
        }

        // Ordre = priorité (première passe qui colore une position gagne).
        let isYamlLike = language != "json"
        if isYamlLike {
            apply("#[^\n]*", commentColor)                          // commentaires
        }
        if language == "json" {
            apply("\"(?:\\\\.|[^\"\\\\])*\"(?=\\s*:)", keyColor)     // clés json
        }
        apply("\"(?:\\\\.|[^\"\\\\])*\"", stringColor)              // chaînes doubles
        apply("'(?:\\\\.|[^'\\\\])*'", stringColor)                // chaînes simples (yaml)
        if language == "toml" {
            apply("^\\s*[\\w.-]+(?=\\s*=)", keyColor)               // clés toml
        } else if isYamlLike {
            apply("^\\s*-?\\s*[\\w.-]+(?=\\s*:)", keyColor)         // clés yaml
        }
        apply("\\b-?\\d+(?:\\.\\d+)?\\b", numberColor)             // nombres
        apply("\\b(?:true|false|null|yes|no)\\b", keywordColor)    // mots-clés

        // Reconstruit l'AttributedString en regroupant les positions de même couleur.
        var result = AttributedString()
        var i = 0
        while i < ns.length {
            let color = colors[i]
            var j = i + 1
            while j < ns.length && colors[j] == color { j += 1 }
            var piece = AttributedString(ns.substring(with: NSRange(location: i, length: j - i)))
            if let color { piece.foregroundColor = color }
            result += piece
            i = j
        }
        result.font = mono
        return result
    }
}
