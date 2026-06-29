# TODOS — BmadBrowser

## Phase 1 — Échafaudage ✅
- [x] `project.yml` XcodeGen (app macOS, MarkdownUI, entitlements)
- [x] App SwiftUI minimale (NavigationSplitView) qui compile
- [x] Build vert `xcodebuild`

## Phase 2 — Détection projet ✅
- [x] NSOpenPanel + sélection dossier
- [x] `ConfigResolver` : lire `_bmad/config.toml` → `output_folder` (+ fallbacks)
- [x] `ProjectScanner` : construire l'arbre des `.md`
- [x] `BookmarkStore` : bookmark security-scoped persistant

## Phase 3 — Navigation + preview ✅
- [x] Arbre latéral des documents (`List(children:)`)
- [x] Rendu MarkdownUI
- [x] `FrontmatterParser` + badges de statut

## Phase 4 — Édition ✅
- [x] Toggle preview / édition
- [x] Sauvegarde Cmd+S + indicateur modifié

## Phase 5 — Confort (à venir)
- [ ] Recherche plein-texte (contenu, pas seulement noms)
- [ ] Filtres statut/type de workflow
- [ ] Édition du frontmatter en formulaire
- [ ] Aperçu intégré images / PDF
- [ ] Liste des projets récents

## Test manuel restant
- [ ] Lancer l'app et ouvrir un projet réel (ex: `~/Documents/GitHub/clarify`) pour valider l'UX
