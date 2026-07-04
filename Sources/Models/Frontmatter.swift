import Foundation

/// Métadonnées extraites du bloc YAML frontmatter d'un document BMad.
struct Frontmatter: Equatable {
    var status: String?
    var date: String?
    var workflowType: String?
    var stepsCompleted: Int?
    var raw: [String: String] = [:]

    /// Bloc YAML brut d'origine (délimiteurs `---` inclus, sans le saut de ligne final).
    /// Réécrit tel quel à la sauvegarde pour préserver l'ordre des clés, les listes
    /// et les valeurs multi-lignes que le parser plat ne modélise pas.
    var rawBlock: String?

    var isEmpty: Bool {
        status == nil && date == nil && workflowType == nil && stepsCompleted == nil
    }
}

/// Un champ scalaire éditable du frontmatter (`clé: valeur`), repéré par sa ligne
/// dans le bloc brut. Les lignes non-scalaires (listes, blocs `|`/`>`) ne sont pas
/// exposées ici et restent inchangées à la réécriture.
struct FrontmatterField: Identifiable, Equatable {
    let id = UUID()
    let key: String
    var value: String
    let lineIndex: Int
    let indent: String
}
