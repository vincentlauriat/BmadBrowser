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

## Phase 5 — Confort (en cours)
- [x] Aperçu intégré images (zoom) / PDF + images inline du markdown
- [x] Niveau supérieur : workspace regroupant plusieurs projets (UI 3 colonnes)
- [x] Affichage/édition des fichiers texte (yaml, json, txt, csv, toml)
- [ ] Recherche plein-texte (contenu, pas seulement noms)
- [ ] Filtres statut/type de workflow
- [ ] Édition du frontmatter en formulaire
- [ ] Liste des workspaces/projets récents

## Phase 6 — Distribution & i18n ✅
- [x] i18n EN/FR (String Catalog `Resources/Localizable.xcstrings`, base anglaise + traductions FR + pluriels)
- [x] Bump version `1.0.0`
- [x] `Scripts/release.sh` (build Release + Developer ID + notarisation + DMG)
- [x] Landing page github.io (`docs/index.html`, GitHub Pages)
- [x] Dépôt rendu public
- [x] GitHub Release v1.0.0
- [x] Carte portfolio + lauriat.fr

## Test manuel restant
- [ ] Lancer l'app et ouvrir un projet réel (ex: `~/Documents/GitHub/clarify`) pour valider l'UX
