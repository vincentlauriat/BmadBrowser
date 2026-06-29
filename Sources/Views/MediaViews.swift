import SwiftUI
import PDFKit
import MarkdownUI

// MARK: - Visionneuse d'image (fichier sélectionné dans l'arbre)

struct ImageViewer: View {
    let url: URL
    @State private var scale: CGFloat = 1.0

    var body: some View {
        if let image = NSImage(contentsOf: url) {
            VStack(spacing: 0) {
                ScrollView([.horizontal, .vertical]) {
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFit()
                        .scaleEffect(scale)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(20)
                }
                .gesture(
                    MagnifyGesture()
                        .onChanged { scale = max(0.2, min(6, $0.magnification)) }
                )
                Divider()
                zoomBar(pixelSize: image.pixelSize)
            }
        } else {
            ContentUnavailableView(
                "Image illisible",
                systemImage: "exclamationmark.triangle",
                description: Text(url.lastPathComponent)
            )
        }
    }

    private func zoomBar(pixelSize: CGSize?) -> some View {
        HStack(spacing: 12) {
            if let s = pixelSize {
                Text("\(Int(s.width)) × \(Int(s.height)) px")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Button { scale = max(0.2, scale - 0.25) } label: { Image(systemName: "minus.magnifyingglass") }
            Text("\(Int(scale * 100)) %").font(.caption.monospacedDigit()).frame(width: 48)
            Button { scale = min(6, scale + 0.25) } label: { Image(systemName: "plus.magnifyingglass") }
            Button("Ajuster") { scale = 1.0 }
        }
        .buttonStyle(.borderless)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.quaternary.opacity(0.4))
    }
}

extension NSImage {
    /// Taille en pixels réels (et non en points) de la représentation principale.
    var pixelSize: CGSize? {
        guard let rep = representations.first else { return nil }
        return CGSize(width: rep.pixelsWide, height: rep.pixelsHigh)
    }
}

// MARK: - Visionneuse PDF

struct PDFViewer: NSViewRepresentable {
    let url: URL

    func makeNSView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.document = PDFDocument(url: url)
        return view
    }

    func updateNSView(_ view: PDFView, context: Context) {
        if view.document?.documentURL != url {
            view.document = PDFDocument(url: url)
        }
    }
}

// MARK: - Fournisseur d'images pour le rendu markdown

/// Rend les images référencées dans le markdown.
/// Résout les chemins relatifs par rapport au dossier du document (`baseURL`)
/// et charge les fichiers locaux ; bascule sur le réseau pour les URLs http(s).
struct LocalImageProvider: ImageProvider {
    let baseURL: URL

    func makeImage(url: URL?) -> some View {
        Group {
            if let resolved = resolve(url), let image = NSImage(contentsOf: resolved) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
            } else if let url, let scheme = url.scheme, scheme.hasPrefix("http") {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let img): img.resizable().scaledToFit()
                    case .failure: brokenImage(url)
                    default: ProgressView()
                    }
                }
            } else {
                brokenImage(url)
            }
        }
    }

    private func brokenImage(_ url: URL?) -> some View {
        Label(url?.lastPathComponent ?? "image manquante", systemImage: "photo.badge.exclamationmark")
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 6))
    }

    /// Résout l'URL markdown en URL de fichier locale si possible.
    private func resolve(_ url: URL?) -> URL? {
        guard let url else { return nil }
        if url.isFileURL { return url }
        if url.scheme == nil {
            // Chemin relatif (ex: "images/diagram.png") ou absolu sur disque.
            let path = url.path(percentEncoded: false)
            if path.hasPrefix("/") { return URL(fileURLWithPath: path) }
            return baseURL.appendingPathComponent(path)
        }
        return nil
    }
}
