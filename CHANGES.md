# CHANGES — BmadBrowser

## 2026-06-29 (suite)

### Added
- Affichage des **images** sélectionnées dans l'arbre : `ImageViewer` (zoom molette/pincement + boutons %, ajuster, dimensions px).
- Affichage des **PDF** via PDFKit (`PDFViewer`, auto-scale).
- Rendu **inline des images du markdown** : `LocalImageProvider` résout les chemins relatifs par rapport au dossier du document et charge les fichiers locaux (fallback réseau pour les URLs http).
- Bouton « Ouvrir dans l'app par défaut » dans la toolbar pour image/PDF.
- Extensions image élargies au scan (bmp, tiff, heic, svg) et helpers `isImage`/`isPDF` sur `DocumentNode`.

## 2026-06-29

### Added
- Échafaudage initial du projet macOS SwiftUI (XcodeGen `project.yml`, entitlements sandbox + user-selected read-write + bookmarks).
- Modèles : `BmadProject`, `DocumentNode`, `Frontmatter`.
- Services : `ConfigResolver` (lecture `_bmad/config.toml` → `output_folder` + fallbacks `docs/`/`_bmad-output/`), `ProjectScanner` (arbre des artefacts), `FrontmatterParser` (YAML léger), `BookmarkStore` (security-scoped bookmark persistant).
- `AppState` (@Observable) : ouverture projet, sélection, chargement, édition, sauvegarde, filtre, recharge.
- Vues : `ContentView` (NavigationSplitView), `DocumentTreeView` (arbre + badges de statut), `DocumentDetailView` (rendu MarkdownUI / éditeur, barre frontmatter, toolbar Éditer/Enregistrer).
- Dépendance SPM : MarkdownUI (rendu markdown riche).

### Docs
- `PLAN.md`, `TODOS.md`, `README.md`, `.gitignore`.

### Fixed
- Erreur d'inférence `some View` due à une fonction de ligne récursive → remplacée par `List(children:)` natif + struct `NodeRow`.

### Changed
- UX : en-tête de projet permanent dans la barre latérale (icône + nom + chemin) et titre/sous-titre de fenêtre (`navigationTitle` projet, `navigationSubtitle` document courant) → on sait toujours dans quel projet on est.
- Distinction des états « aucun projet ouvert » vs « projet sans document ».

### Chore
- `git init` (branche `main`).
