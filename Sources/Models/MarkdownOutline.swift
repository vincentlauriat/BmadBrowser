import Foundation

/// Une section du document : un bloc de texte markdown démarrant à un titre
/// (ou le préambule avant le premier titre). Rendue séparément pour permettre
/// le défilement vers un titre.
struct MarkdownSection: Identifiable {
    let id: String
    let text: String
}

/// Un titre pour le sommaire ; `id` désigne la section vers laquelle défiler.
struct MarkdownHeading: Identifiable {
    let id: String
    let level: Int
    let title: String
}

/// Découpe un corps markdown en sections (par titre ATX) et en extrait le sommaire.
/// Ignore les titres à l'intérieur des blocs de code délimités (``` ou ~~~).
enum MarkdownOutline {

    static func split(_ body: String) -> (sections: [MarkdownSection], headings: [MarkdownHeading]) {
        let lines = body.components(separatedBy: "\n")
        var sections: [MarkdownSection] = []
        var headings: [MarkdownHeading] = []

        var currentLines: [String] = []
        var inFence = false
        var fenceMarker = ""

        func flush() {
            guard !currentLines.isEmpty else { return }
            let id = "section-\(sections.count)"
            sections.append(MarkdownSection(id: id, text: currentLines.joined(separator: "\n")))
            currentLines = []
        }

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Bascule d'état des blocs de code délimités.
            if trimmed.hasPrefix("```") || trimmed.hasPrefix("~~~") {
                let marker = String(trimmed.prefix(3))
                if inFence {
                    if trimmed.hasPrefix(fenceMarker) { inFence = false }
                } else {
                    inFence = true
                    fenceMarker = marker
                }
                currentLines.append(line)
                continue
            }

            if !inFence, let heading = parseHeading(trimmed) {
                flush()
                let id = "section-\(sections.count)"
                headings.append(MarkdownHeading(id: id, level: heading.level, title: heading.title))
                currentLines.append(line)
            } else {
                currentLines.append(line)
            }
        }
        flush()

        return (sections, headings)
    }

    private static func parseHeading(_ trimmed: String) -> (level: Int, title: String)? {
        guard trimmed.hasPrefix("#") else { return nil }
        let hashes = trimmed.prefix(while: { $0 == "#" })
        let level = hashes.count
        guard (1...6).contains(level) else { return nil }
        let rest = trimmed.dropFirst(level)
        guard rest.first == " " else { return nil } // ATX exige une espace après les #
        let title = rest.trimmingCharacters(in: .whitespaces)
            .trimmingCharacters(in: CharacterSet(charactersIn: "#"))
            .trimmingCharacters(in: .whitespaces)
        guard !title.isEmpty else { return nil }
        return (level, title)
    }
}
