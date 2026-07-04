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

## Phase 5 — Confort ✅
- [x] Aperçu intégré images (zoom) / PDF + images inline du markdown
- [x] Niveau supérieur : workspace regroupant plusieurs projets (UI 3 colonnes)
- [x] Affichage/édition des fichiers texte (yaml, json, txt, csv, toml)
- [x] Recherche plein-texte (contenu, pas seulement noms)
- [x] Filtres statut/type de workflow
- [x] Édition du frontmatter en formulaire
- [x] Liste des workspaces/projets récents

## Phase 6 — Distribution & i18n ✅
- [x] i18n EN/FR (String Catalog `Resources/Localizable.xcstrings`, base anglaise + traductions FR + pluriels)
- [x] Bump version `1.0.0`
- [x] `Scripts/release.sh` (build Release + Developer ID + notarisation + DMG)
- [x] Landing page github.io (`docs/index.html`, GitHub Pages)
- [x] Dépôt rendu public
- [x] GitHub Release v1.0.0
- [x] Carte portfolio + lauriat.fr

---

# Améliorations, corrections & évolutions (audit code v1.0.0)

## 🔴 Bugs / corrections (risque de corruption de données) ✅
- [x] **Sauvegarde markdown destructive pour le frontmatter** — `save()` réécrit désormais le
      bloc YAML **brut d'origine** (`Frontmatter.rawBlock`) au lieu de le reconstruire depuis un
      dictionnaire non ordonné : l'ordre des clés, les listes et les valeurs multi-lignes sont
      préservés. Couvert par un test de round-trip.
- [x] **Perte silencieuse des modifications non sauvegardées** — dialogue de confirmation
      « Save / Discard / Cancel » (`guardUnsaved`) avant tout changement de document/projet.
- [x] **Message d'erreur français codé en dur** — remplacé par `String(localized:)`.
- [x] **Badge de statut de l'arbre figé après édition** — le nœud est re-frontmatté et l'arbre
      rafraîchi après `save()`.
- [x] **Fuite d'accès security-scoped** — `BookmarkStore` ne garde qu'un seul accès actif
      (`beginAccess`/`stopCurrentAccess`), libéré avant d'en démarrer un nouveau.

## 🟠 Confort / UX
- [x] **Rafraîchissement automatique** (FSEvents) — `FolderWatcher` surveille la racine ;
      auto-reload sauf pendant une édition en cours.
- [x] **Menu contextuel sur les nœuds** — Révéler dans le Finder, Copier le chemin, Ouvrir.
- [x] **Compteur de mots + temps de lecture** sous l'aperçu markdown.
- [x] **Rendu SVG** inline dans la visionneuse d'image.
- [ ] **Sommaire / outline des titres markdown** (H1–H3) — nécessite un rendu par section pour
      le scroll-to-heading (MarkdownUI rend un bloc unique) ; reporté.
- [ ] **Coloration syntaxique** pour les fichiers texte (json / yaml / toml) en lecture.
- [ ] **Export** du markdown rendu (PDF / HTML).
- [ ] **Réglages / Preferences** — thème markdown, taille de police de l'éditeur, dossier par défaut.

## 🟢 Évolutions techniques / qualité
- [x] **Tests** — target `BmadBrowserTests` + scheme ; `FrontmatterParser` (round-trip, champs
      scalaires) et `ConfigResolver` (détection, fallbacks, `{project-root}`) couverts (9 tests verts).
- [x] **SwiftLint** — `.swiftlint.yml` + phase de build optionnelle (no-op si non installé).
- [x] **Refactor recherche d'arbre** — `node(withID:)` et l'ancienne `findNode(url:in:)`
      factorisées en `firstNode(in:where:)`.
- [ ] **Auto-update Sparkle** — cohérent avec les autres apps `~/DevApps` ; reporté (touche la
      release + clé EdDSA à ne jamais régénérer). À faire dans une passe distribution dédiée.
- [ ] **Support multi-fenêtres** (`WindowGroup` + état par fenêtre) pour comparer deux projets.

## Test manuel restant
- [ ] Lancer l'app et ouvrir un projet réel (ex: `~/Documents/GitHub/clarify`) pour valider l'UX
- [x] Round-trip d'un `.md` à frontmatter riche (liste `inputDocuments`) — validé par test unitaire
