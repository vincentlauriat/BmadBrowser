---
project: BmadBrowser
last_updated: 2026-06-29
phase: "MVP + workspace multi-projets + icône + fichiers texte — build vert, publié sur GitHub (privé)"
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
- **Dépôt** : `github.com/vincentlauriat/BmadBrowser` (privé), licence MIT. Workflow git : feature branch → merge → suppression (jamais de push direct sur `main`).

## Modèle BMad v6 (observé sur la machine)
- Moteur dans `_bmad/` ; `config.toml` → `[core] output_folder = "{project-root}/docs"`.
- Artefacts dans `output_folder` (souvent `docs/`, parfois `_bmad-output/`), sous-dossiers : `planning-artifacts/`, `implementation-artifacts/`, `test-artifacts/`, `brainstorming/`, `superpowers/{specs,plans}/`, `research/`.
- Frontmatter YAML dans les `.md` : `status`, `date`/`completedAt`, `workflowType`, `lastStep`/`stepsCompleted`, `inputDocuments`.

## État actuel
- Build `xcodebuild` vert, 0 erreur.
- Implémenté : phases 1-4 + aperçu images/PDF + workspace multi-projets + AppIcon + affichage/édition fichiers texte (yaml/json/txt/csv/toml).
- Publié sur GitHub (privé, MIT). Reste : test manuel approfondi + suite phase 5 (recherche plein-texte, filtres, édition frontmatter en formulaire, récents).

## Pièges connus
- Récursion de vue + `some View` → utiliser `List(_:children:selection:)` natif, pas une fonction `@ViewBuilder` qui s'appelle elle-même.
- `config.toml` est en TOML : parsing ciblé sur la ligne `output_folder` (pas de lib TOML).
- **XcodeGen n'a pas de clé `resources:` au niveau d'une target** : tout (code + assets) va sous `sources:`. Mettre `Assets.xcassets` sous `resources:` le fait silencieusement ignorer → pas de `Assets.car`, pas de `CFBundleIconName`, icône par défaut. Corrigé en plaçant le catalogue sous `sources:`.
