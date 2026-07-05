# BmadBrowser

Outil macOS natif (SwiftUI) pour **naviguer et éditer** les documents produits par la méthode [BMad](https://github.com/bmad-code-org/BMAD-METHOD) (v6) : les artefacts markdown rangés dans la sous-arborescence de sortie d'un projet.

[![Release](https://img.shields.io/github/v/release/vincentlauriat/BmadBrowser)](https://github.com/vincentlauriat/BmadBrowser/releases/latest)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
![macOS 14+](https://img.shields.io/badge/macOS-14%2B-lightgrey)

🇬🇧 English version: [README.md](README.md)

## Téléchargement

- **[Télécharger le DMG](https://github.com/vincentlauriat/BmadBrowser/releases/latest/download/BmadBrowser.dmg)** — macOS 14+, Apple Silicon & Intel, signé & notarisé.
- Ou visitez le site : **[vincentlauriat.github.io/BmadBrowser](https://vincentlauriat.github.io/BmadBrowser/)**

## Fonctionnalités

| Statut | Fonctionnalité |
|--------|----------------|
| ✅ | **Niveau supérieur (workspace)** : ouverture d'une racine regroupant plusieurs projets BMad (UI 3 colonnes : Projets / Documents / Détail) |
| ✅ | Détection auto des projets : la racine elle-même (mono-projet) ou ses sous-dossiers contenant `_bmad/`, `docs/` ou `_bmad-output/` |
| ✅ | Détection auto du dossier de sortie BMad (`_bmad/config.toml` → `output_folder`, fallbacks `docs/`, `_bmad-output/`) |
| ✅ | Arbre des documents (markdown + artefacts xlsx/pptx/png…) |
| ✅ | Affichage et édition des fichiers texte (`yaml`, `json`, `txt`, `csv`, `toml`) en monospace |
| ✅ | Rendu markdown riche (MarkdownUI) + sélection de texte |
| ✅ | Frontmatter YAML affiché en badges (statut, type, date) |
| ✅ | Édition + sauvegarde (`⌘S`) avec indicateur « modifié » ; confirmation avant perte de modifs |
| ✅ | Sauvegarde préservant le frontmatter : le bloc YAML d'origine est réécrit tel quel (ordre des clés & listes intacts) |
| ✅ | Édition du frontmatter en formulaire (« Edit metadata ») |
| ✅ | Recherche plein-texte (nom **et** contenu) + filtre par statut |
| ✅ | Menu contextuel : révéler dans le Finder, copier le chemin, ouvrir |
| ✅ | Sommaire markdown avec saut vers un titre + compteur de mots / temps de lecture |
| ✅ | Coloration syntaxique json / yaml / toml (en lecture) |
| ✅ | Export du markdown rendu en PDF |
| ✅ | Préférences (⌘,) : thème markdown, taille de police éditeur, bascule stats |
| ✅ | Aperçu inline images (zoom), SVG et PDF |
| ✅ | Rafraîchissement auto sur changement de fichiers (FSEvents) |
| ✅ | Menu des racines récentes |
| ✅ | Persistance du dernier projet ouvert (security-scoped bookmark) |
| ✅ | Ouverture externe des fichiers non-markdown |
| ✅ | Interface bilingue (anglais / français), suit la langue du système |

## Prérequis

- macOS 14+
- Xcode 27 / Swift 6
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)

## Build depuis les sources

```bash
xcodegen generate
xcodebuild -project BmadBrowser.xcodeproj -scheme BmadBrowser -destination 'platform=macOS' build
open -a BmadBrowser   # ou lancer depuis Xcode
```

## Release

```bash
./Scripts/release.sh 1.0.0
```

Build une `.app` Release, la signe avec un certificat Developer ID (Hardened Runtime), la soumet à la notarisation Apple, agrafe (staple) le ticket, et produit un `release/BmadBrowser-1.0.0.dmg` notarisé, prêt à distribuer.

Prérequis : XcodeGen, et le certificat `Developer ID Application: Vincent LAURIAT (KFLACS69T9)` dans le trousseau de connexion (les identifiants de notarisation sont stockés dans le profil trousseau partagé `AppliMacVincentGithub`).

## Structure

```
project.yml              # définition XcodeGen (source de vérité du projet)
Sources/
  BmadBrowserApp.swift   # point d'entrée @main
  Models/                # Workspace, BmadProject, DocumentNode, Frontmatter
  Services/              # WorkspaceScanner, ConfigResolver, ProjectScanner, FrontmatterParser, BookmarkStore, RecentsStore, FolderWatcher
  ViewModels/AppState.swift
  Views/                 # ContentView, ProjectListView, DocumentTreeView, DocumentDetailView, MediaViews
Resources/               # entitlements, assets, Localizable.xcstrings (base EN + traductions FR)
Tests/                   # FrontmatterParserTests, ConfigResolverTests
Scripts/
  release.sh             # build Release, signature Developer ID, notarisation, packaging DMG
docs/
  index.html             # landing page bilingue (GitHub Pages)
```

## Roadmap

- [x] Aperçu des images / PDF / SVG intégré
- [x] Niveau supérieur : workspace multi-projets
- [x] Interface bilingue (anglais / français)
- [x] Recherche plein-texte (dans le contenu, pas seulement les noms)
- [x] Filtres par statut
- [x] Édition du frontmatter en formulaire
- [x] Workspaces / projets récents
- [x] Rafraîchissement auto sur changement de fichiers (FSEvents)
- [x] Outline markdown, coloration syntaxique, export PDF, préférences
- [ ] Auto-update Sparkle, multi-fenêtres

> Voir `ARCHITECTURE.md` (FR) / `ARCHITECTURE_EN.md` (EN) pour la conception détaillée,
> `PLAN.md` pour le découpage des phases et `TODOS.md` pour l'avancement.

## Licence

[MIT](LICENSE) © 2026 Vincent Lauriat
