import Foundation

/// Métadonnées extraites du bloc YAML frontmatter d'un document BMad.
struct Frontmatter: Equatable {
    var status: String?
    var date: String?
    var workflowType: String?
    var stepsCompleted: Int?
    var raw: [String: String] = [:]

    var isEmpty: Bool {
        status == nil && date == nil && workflowType == nil && stepsCompleted == nil
    }
}
