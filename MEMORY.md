---
project: BmadBrowser
last_updated: 2026-07-04
phase: "post-v1.0.0 : audit code → corrections données + confort (recherche plein-texte, filtres, frontmatter en formulaire, récents, FSEvents, SVG) + tests + SwiftLint — build vert, 9 tests verts"
---

# MEMORY — BmadBrowser

## Objectif
Outil macOS natif (SwiftUI) pour naviguer **et éditer** les documents markdown produits par la méthode BMad (v6).

## Décisions structurantes
- **Stack** : SwiftUI natif macOS 14+, projet géré par **XcodeGen** (`project.yml` = source de vérité ; le `.xcodeproj` est gitignored et régénéré).
- **Rendu markdown** : dépendance SPM **MarkdownUI**.
- **Périmètre v1** : lecture + édition + sauvegarde.
- **Source des docs** : sélecteur de dossier (NSOpenPanel) ; accès persistant via **security-scoped bookmark** (sandbox activé).
- **Niveau supérieur (workspace)** : la racine ouverte peut regrouper plusieurs projets. `WorkspaceScanner` scanne les sous-dossiers directs ; un dossier est un projet s'il contient `_bmad/`, `docs/` ou `_bmad-output/`. Si la racine est elle-même un projet → mode mono-projet. UI 3 colonnes (Projets | Documents | Détail). Le bookmark persiste la racine du workspace, pas un projet isolé.
- **Fichiers texte** : les non-markdown texte (`yaml`, `yml`, `json`, `txt`, `csv`, `toml`) sont affichés/édités en monospace (`DocumentNode.isText`/`isEditable`), chargement/écriture brute (pas de frontmatter). Les autres binaires → ouverture externe.
- **AppIcon** : générée par un script Swift (AppKit/CoreGraphics), `Resources/Assets.xcassets/AppIcon.appiconset`. Script source : `scratchpad/gen_icon.swift` (hors repo) — à regénérer si le design change.
- **Internationalisation (i18n)** : app bilingue EN/FR suivant la langue système. Langue de base = **anglais** (clés littérales dans le code UI) ; traductions françaises fournies par le String Catalog `Resources/Localizable.xcstrings` (compilé en `en.lproj`/`fr.lproj`, pluriels gérés). `project.yml` : `options.developmentLanguage: en` + catalogue sous `sources:`. Les strings non-SwiftUI (erreurs `AppState`, `NSOpenPanel`) utilisent `String(localized:)`.
- **Sauvegarde frontmatter (invariant anti-corruption)** : `Frontmatter.rawBlock` conserve le bloc YAML **brut d'origine** (délimiteurs `---` inclus). `save()` d'un markdown écrit `rawBlock + "\n" + body` — jamais une reconstruction depuis `raw` (dictionnaire non ordonné, qui réordonnait les clés et aplatissait les listes). L'édition en formulaire (`FrontmatterParser.scalarFields`/`applying`) ne réécrit **que** les lignes scalaires éditées, laissant listes/blocs intacts. Ne jamais revenir à une reconstruction depuis un dictionnaire.
- **Accès security-scoped** : `BookmarkStore` maintient **un seul** accès actif à la fois (`beginAccess`/`stopCurrentAccess`) ; `RecentsStore` (bookmarks scoped par récent) passe par `beginAccess`. Chemin panneau : `stopCurrentAccess()` avant `open()`. Ne pas rappeler `stopCurrentAccess` dans `open()` (casserait le flux « récent »).
- **Rafraîchissement auto** : `FolderWatcher` (FSEvents, débounce 0.5 s) sur la racine ; `autoReloadIfSafe()` saute le reload si `isDirty`/`isEditing` pour ne pas écraser une édition.
- **Distribution** : `Scripts/release.sh <version>` automatise build Release + signature Developer ID (Hardened Runtime) + notarisation Apple (profil trousseau partagé `AppliMacVincentGithub`) + staple + packaging DMG (`release/BmadBrowser-<version>.dmg`). `MARKETING_VERSION` bumpé à **`1.0.0`** (première version publique).
- **Dépôt** : `github.com/vincentlauriat/BmadBrowser`, désormais **public**, licence MIT. Workflow git : feature branch → merge → suppression (jamais de push direct sur `main`). GitHub Release v1.0.0 avec DMG notarisé.
- **Site** : landing page bilingue `docs/index.html` servie via **GitHub Pages** (`vincentlauriat.github.io/BmadBrowser`) ; app référencée sur le portfolio github.io et sur lauriat.fr.

## Modèle BMad v6 (observé sur la machine)
- Moteur dans `_bmad/` ; `config.toml` → `[core] output_folder = "{project-root}/docs"`.
- Artefacts dans `output_folder` (souvent `docs/`, parfois `_bmad-output/`), sous-dossiers : `planning-artifacts/`, `implementation-artifacts/`, `test-artifacts/`, `brainstorming/`, `superpowers/{specs,plans}/`, `research/`.
- Frontmatter YAML dans les `.md` : `status`, `date`/`completedAt`, `workflowType`, `lastStep`/`stepsCompleted`, `inputDocuments`.

## État actuel
- Build `xcodebuild` vert, 0 erreur ; suite de tests verte (9 tests).
- Implémenté : phases 1-4 + aperçu images/PDF/SVG + workspace multi-projets + AppIcon + affichage/édition fichiers texte (yaml/json/txt/csv/toml) + i18n EN/FR + distribution notarisée.
- **v1.0.0 publiée** : dépôt GitHub public (MIT), GitHub Release v1.0.0 avec DMG signé/notarisé, landing page GitHub Pages, portfolio github.io + lauriat.fr.
- **Post-v1.0.0 (branche `feat/audit-fixes-v1.1`, non mergée)** : audit code → 🔴 corrections données (round-trip frontmatter fidèle via `rawBlock`, confirmation modifs non sauvegardées, fuite scoped-access, badge rafraîchi) + 🟠 confort (recherche plein-texte, filtre statut, frontmatter en formulaire, menu contextuel, compteur mots/lecture, projets récents, FSEvents auto-reload) + 🟢 tests + SwiftLint + refactor. Reste reporté : outline markdown, coloration syntaxique, export PDF/HTML, préférences, Sparkle, multi-fenêtres.

## Pièges connus
- Récursion de vue + `some View` → utiliser `List(_:children:selection:)` natif, pas une fonction `@ViewBuilder` qui s'appelle elle-même.
- `config.toml` est en TOML : parsing ciblé sur la ligne `output_folder` (pas de lib TOML).
- **XcodeGen n'a pas de clé `resources:` au niveau d'une target** : tout (code + assets) va sous `sources:`. Mettre `Assets.xcassets` sous `resources:` le fait silencieusement ignorer → pas de `Assets.car`, pas de `CFBundleIconName`, icône par défaut. Corrigé en plaçant le catalogue sous `sources:`.
