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

---

# Améliorations, corrections & évolutions (audit code v1.0.0)

## 🔴 Bugs / corrections (risque de corruption de données — prioritaire)
- [ ] **Sauvegarde markdown destructive pour le frontmatter** — dans `AppState.save()`, le
      bloc YAML est reconstruit à partir de `currentFrontmatter.raw`, un `[String: String]`
      **non ordonné** (`Frontmatter.raw`). Conséquences à chaque `⌘S` d'un `.md` :
      - l'**ordre des clés** du frontmatter change de façon aléatoire (diffs git parasites) ;
      - les **valeurs non scalaires** (listes YAML `inputDocuments:` / `- item`, objets, multi-lignes)
        sont **aplaties ou perdues** car le parser ne gère que `key: value` plat.
      → Fix : préserver le bloc frontmatter **brut** d'origine (le réécrire tel quel, ne toucher
      qu'au corps), ou stocker les paires ordonnées (`[(String,String)]`) + gérer les listes.
      Fichiers : `Sources/ViewModels/AppState.swift:143`, `Sources/Models/Frontmatter.swift`,
      `Sources/Services/FrontmatterParser.swift`.
- [ ] **Perte silencieuse des modifications non sauvegardées** — `AppState.select()` contient
      un `if isDirty { /* … perdu si on change */ }` vide : changer de document (ou de projet)
      en mode édition **jette** les modifs sans prévenir. → Confirmation « Enregistrer / Ignorer /
      Annuler » avant de basculer. Fichier : `Sources/ViewModels/AppState.swift:106`.
- [ ] **Message d'erreur français codé en dur** — `AppState.select()` ligne 135 :
      `"Impossible de lire \(node.name)."` alors que la variante localisée existe déjà
      (ligne 120). Incohérence i18n → `String(localized:)`. Fichier : `Sources/ViewModels/AppState.swift:135`.
- [ ] **Badge de statut de l'arbre figé après édition** — `node.frontmatter` est capturé au scan
      initial ; après édition/sauvegarde du frontmatter d'un `.md`, la pastille dans l'arbre
      (`NodeRow`) n'est pas rafraîchie. → Recharger le frontmatter du nœud après `save()`.
- [ ] **Fuite d'accès security-scoped** — `BookmarkStore.restore()` appelle
      `startAccessingSecurityScopedResource()` mais rien n'appelle jamais
      `stopAccessingSecurityScopedResource()` (ni à `reload()`, ni à la réouverture d'une autre
      racine). Mineur en mono-fenêtre mais réel. Fichier : `Sources/Services/BookmarkStore.swift`.

## 🟠 Confort / UX
- [ ] **Rafraîchissement automatique** (FSEvents / `DispatchSource`) — BMad régénère les fichiers
      hors de l'app ; aujourd'hui il faut cliquer « Reload » manuellement. Watch de la racine +
      re-scan incrémental.
- [ ] **Menu contextuel sur les nœuds** — « Révéler dans le Finder », « Copier le chemin »,
      « Ouvrir dans l'app par défaut », « Copier le nom ».
- [ ] **Sommaire / outline des titres markdown** (H1–H3) pour naviguer dans les longs documents.
- [ ] **Coloration syntaxique** pour les fichiers texte (json / yaml / toml) en lecture.
- [ ] **Compteur de mots + temps de lecture** dans la barre du document markdown.
- [ ] **Export** du markdown rendu (PDF / HTML).
- [ ] **Rendu SVG** — `svg` est scanné (`visibleExtensions`) mais n'est ni `isImage` ni `isText`,
      donc il tombe en « ouverture externe ». L'afficher inline (WebKit / conversion).
- [ ] **Réglages / Preferences** — thème markdown, taille de police de l'éditeur, dossier par défaut.

## 🟢 Évolutions techniques / qualité
- [ ] **Aucun test** — pas de dossier `Tests/` ni de target de test. `FrontmatterParser` et
      `ConfigResolver` sont des fonctions pures faciles à couvrir (round-trip frontmatter,
      résolution `{project-root}`, fallbacks `docs/`/`_bmad-output/`). Ajouter une target
      `BmadBrowserTests` (XCTest/Swift Testing) dans `project.yml`.
- [ ] **SwiftLint / swift-format** — aucun linter configuré ; ajouter `.swiftlint.yml` + phase build.
- [ ] **Auto-update Sparkle** — cohérent avec les autres apps `~/DevApps` (voir `release.sh`
      de MarkdownViewer). Permet de livrer les correctifs sans re-télécharger le DMG.
- [ ] **Refactor recherche d'arbre** — `AppState.node(withID:)` et `AppState.findNode(url:in:)`
      dupliquent une traversée récursive ; factoriser en une seule fonction générique.
- [ ] **Support multi-fenêtres** (`WindowGroup` + état par fenêtre) pour comparer deux projets.

## Test manuel restant
- [ ] Lancer l'app et ouvrir un projet réel (ex: `~/Documents/GitHub/clarify`) pour valider l'UX
- [ ] Vérifier le round-trip d'un `.md` à frontmatter riche (liste `inputDocuments`) avant/après `⌘S`
