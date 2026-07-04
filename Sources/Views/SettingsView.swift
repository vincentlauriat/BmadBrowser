import SwiftUI
import MarkdownUI

/// Clés de préférences partagées (via `@AppStorage`).
enum SettingsKeys {
    static let editorFontSize = "editorFontSize"
    static let markdownTheme = "markdownTheme"
    static let showDocumentStats = "showDocumentStats"
}

/// Thèmes de rendu markdown proposés dans les préférences.
enum MarkdownThemeChoice: String, CaseIterable, Identifiable {
    case gitHub
    case docC

    var id: String { rawValue }

    var label: String {
        switch self {
        case .gitHub: return "GitHub"
        case .docC: return "DocC"
        }
    }

    var theme: Theme {
        switch self {
        case .gitHub: return .gitHub
        case .docC: return .docC
        }
    }
}

/// Fenêtre Préférences (⌘,).
struct SettingsView: View {
    @AppStorage(SettingsKeys.editorFontSize) private var editorFontSize: Double = 13
    @AppStorage(SettingsKeys.markdownTheme) private var markdownTheme: String = MarkdownThemeChoice.gitHub.rawValue
    @AppStorage(SettingsKeys.showDocumentStats) private var showDocumentStats: Bool = true

    var body: some View {
        Form {
            Section("Markdown") {
                Picker("Rendering theme", selection: $markdownTheme) {
                    ForEach(MarkdownThemeChoice.allCases) { choice in
                        Text(choice.label).tag(choice.rawValue)
                    }
                }
                Toggle("Show word count & reading time", isOn: $showDocumentStats)
            }
            Section("Editor") {
                LabeledContent("Font size") {
                    HStack {
                        Slider(value: $editorFontSize, in: 10...22, step: 1)
                        Text("\(Int(editorFontSize)) pt")
                            .font(.caption.monospacedDigit())
                            .frame(width: 44, alignment: .trailing)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 420, height: 240)
    }
}
