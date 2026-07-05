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
- [x] **Sommaire / outline des titres markdown** — `MarkdownOutline` découpe le corps en sections
      (par titre, blocs de code ignorés) rendues dans un `ScrollViewReader` ; menu Outline avec
      scroll-to-heading.
- [x] **Coloration syntaxique** json / yaml / toml en lecture (`SyntaxHighlighter` → `AttributedString`).
- [x] **Export PDF** du markdown rendu (`MarkdownPDFExporter` via `ImageRenderer`, page continue).
- [x] **Réglages / Preferences** (⌘,) — thème markdown (GitHub/DocC), taille de police éditeur,
      affichage de la barre de stats.

## 🟢 Évolutions techniques / qualité
- [x] **Tests** — target `BmadBrowserTests` + scheme ; `FrontmatterParser` (round-trip, champs
      scalaires) et `ConfigResolver` (détection, fallbacks, `{project-root}`) couverts (9 tests verts).
- [x] **SwiftLint** — `.swiftlint.yml` + phase de build optionnelle (no-op si non installé).
- [x] **Refactor recherche d'arbre** — `node(withID:)` et l'ancienne `findNode(url:in:)`
      factorisées en `firstNode(in:where:)`.
- [x] **Vérification de mise à jour** in-app via l'API GitHub Releases (`UpdateChecker` + `SemVer`) :
      contrôle silencieux au lancement + commande « Check for Updates… », alerte avec téléchargement.
      Alternative sandbox-safe à Sparkle (pas de XPC/appcast/clé).
- [x] **Support multi-fenêtres** — état indépendant par fenêtre (`RootView` possède son `AppState`),
      accès security-scoped géré par instance ; « Open a Root… » cible la fenêtre active (`FocusedValue`).
- [ ] **Sparkle complet (deltas + auto-install)** — mise à jour silencieuse en arrière-plan avec
      installation automatique. Reporté : nécessite les services XPC Sparkle en sandbox, les
      entitlements d'exception mach-lookup, une clé EdDSA à préserver à vie, un appcast hébergé et
      une modification de `release.sh` (signature EdDSA). À traiter en passe distribution dédiée,
      testée sur l'app réelle. Le vérificateur GitHub ci-dessus couvre déjà le besoin « être prévenu ».

## Limitations connues
- **Export PDF** : `ImageRenderer` produit **une seule page continue** (pas de pagination A4/Lettre).
  Suffisant pour partage/archive ; une vraie pagination nécessiterait un moteur d'impression dédié.
- **Coloration syntaxique** : heuristique ligne/regex simple (pas un vrai parseur) ; un `#` dans une
  chaîne yaml/toml peut être vu comme un commentaire. Acceptable pour des fichiers de config BMad.

## Test manuel restant
- [ ] Lancer l'app et ouvrir un projet réel (ex: `~/Documents/GitHub/clarify`) pour valider l'UX
- [x] Round-trip d'un `.md` à frontmatter riche (liste `inputDocuments`) — validé par test unitaire
