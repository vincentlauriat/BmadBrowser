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
