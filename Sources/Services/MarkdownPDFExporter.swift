import SwiftUI
import MarkdownUI

/// Exporte le rendu markdown vers un fichier PDF (une page continue).
/// Utilise `ImageRenderer` pour rasteriser la même vue que l'aperçu.
@MainActor
enum MarkdownPDFExporter {

    /// Largeur de page type Lettre (points).
    private static let pageWidth: CGFloat = 612

    /// Rend `body` en PDF à l'emplacement `url`. Retourne `true` si l'écriture réussit.
    @discardableResult
    static func export(body: String, theme: Theme, baseURL: URL, to url: URL) -> Bool {
        let content = Markdown(body)
            .markdownTheme(theme)
            .markdownImageProvider(LocalImageProvider(baseURL: baseURL))
            .textSelection(.disabled)
            .padding(24)
            .frame(width: pageWidth, alignment: .leading)
            .background(Color.white)

        let renderer = ImageRenderer(content: content)
        renderer.proposedSize = ProposedViewSize(width: pageWidth, height: nil)

        var success = false
        renderer.render { size, renderInContext in
            var box = CGRect(x: 0, y: 0, width: size.width, height: size.height)
            guard let pdf = CGContext(url as CFURL, mediaBox: &box, nil) else { return }
            pdf.beginPDFPage(nil)
            renderInContext(pdf)
            pdf.endPDFPage()
            pdf.closePDF()
            success = true
        }
        return success
    }
}
