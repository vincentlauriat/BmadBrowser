import Foundation

/// Extrait le bloc YAML frontmatter (`--- ... ---`) en tête d'un document markdown.
/// Parser léger ligne-à-ligne suffisant pour les clés plates de BMad.
enum FrontmatterParser {

    /// Retourne (frontmatter, corps sans le bloc YAML).
    static func parse(_ text: String) -> (Frontmatter, String) {
        guard text.hasPrefix("---") else { return (Frontmatter(), text) }

        let lines = text.components(separatedBy: "\n")
        guard lines.first?.trimmingCharacters(in: .whitespaces) == "---" else {
            return (Frontmatter(), text)
        }

        var endIndex: Int?
        for i in 1..<lines.count where lines[i].trimmingCharacters(in: .whitespaces) == "---" {
            endIndex = i
            break
        }
        guard let end = endIndex else { return (Frontmatter(), text) }

        var fm = Frontmatter()
        // Bloc brut reconstructible tel quel (délimiteurs inclus) pour une sauvegarde fidèle.
        fm.rawBlock = lines[0...end].joined(separator: "\n")
        for i in 1..<end {
            let line = lines[i]
            guard let colon = line.firstIndex(of: ":") else { continue }
            let key = line[..<colon].trimmingCharacters(in: .whitespaces)
            var value = String(line[line.index(after: colon)...]).trimmingCharacters(in: .whitespaces)
            value = value.trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
            guard !key.isEmpty, !value.isEmpty else { continue }
            fm.raw[key] = value

            switch key {
            case "status": fm.status = value
            case "date", "completedAt": if fm.date == nil { fm.date = value }
            case "workflowType": fm.workflowType = value
            case "lastStep": fm.stepsCompleted = Int(value)
            default: break
            }
        }

        let body = lines[(end + 1)...].joined(separator: "\n")
        return (fm, body)
    }

    /// Champs scalaires éditables (`clé: valeur`) d'un bloc brut, dans l'ordre du fichier.
    /// Ignore les délimiteurs, les listes (valeur vide suivie de `-`) et les blocs `|`/`>`.
    static func scalarFields(from rawBlock: String) -> [FrontmatterField] {
        let lines = rawBlock.components(separatedBy: "\n")
        guard lines.count > 2 else { return [] }
        var fields: [FrontmatterField] = []
        for i in 1..<(lines.count - 1) {
            let line = lines[i]
            guard let colon = line.firstIndex(of: ":") else { continue }
            let rawKey = String(line[..<colon])
            let indent = String(rawKey.prefix(while: { $0 == " " || $0 == "\t" }))
            let key = rawKey.trimmingCharacters(in: .whitespaces)
            let value = String(line[line.index(after: colon)...]).trimmingCharacters(in: .whitespaces)
            // Clé plate uniquement, valeur scalaire non vide et non-bloc.
            guard !key.isEmpty, key.allSatisfy({ $0.isLetter || $0.isNumber || $0 == "_" || $0 == "-" }),
                  !value.isEmpty, !["|", ">", "|-", ">-"].contains(value) else { continue }
            fields.append(FrontmatterField(key: key, value: value, lineIndex: i, indent: indent))
        }
        return fields
    }

    /// Réécrit le bloc brut en remplaçant, à leur ligne d'origine, la valeur des champs édités.
    /// Toutes les autres lignes (listes, blocs, commentaires) sont conservées telles quelles.
    static func applying(_ fields: [FrontmatterField], to rawBlock: String) -> String {
        var lines = rawBlock.components(separatedBy: "\n")
        for field in fields where field.lineIndex < lines.count {
            lines[field.lineIndex] = "\(field.indent)\(field.key): \(field.value)"
        }
        return lines.joined(separator: "\n")
    }

    /// Lecture rapide du frontmatter seul (sans charger tout le corps en mémoire utile).
    static func parseFile(_ url: URL) -> Frontmatter? {
        guard let text = try? String(contentsOf: url, encoding: .utf8) else { return nil }
        let (fm, _) = parse(text)
        return fm.isEmpty ? nil : fm
    }
}
