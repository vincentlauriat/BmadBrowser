# BmadBrowser

Outil macOS natif (SwiftUI) pour **naviguer et éditer** les documents produits par la méthode [BMad](https://github.com/bmad-code-org/BMAD-METHOD) (v6) : les artefacts markdown rangés dans la sous-arborescence de sortie d'un projet.

## Fonctionnalités

| Statut | Fonctionnalité |
|--------|----------------|
| ✅ | **Niveau supérieur (workspace)** : ouverture d'une racine regroupant plusieurs projets BMad (UI 3 colonnes : Projets / Documents / Détail) |
| ✅ | Détection auto des projets : la racine elle-même (mono-projet) ou ses sous-dossiers contenant `_bmad/`, `docs/` ou `_bmad-output/` |
| ✅ | Détection auto du dossier de sortie BMad (`_bmad/config.toml` → `output_folder`, fallbacks `docs/`, `_bmad-output/`) |
| ✅ | Arbre des documents (markdown + artefacts xlsx/pptx/png…) |
| ✅ | Rendu markdown riche (MarkdownUI) + sélection de texte |
| ✅ | Frontmatter YAML affiché en badges (statut, type, date) |
| ✅ | Édition + sauvegarde (`⌘S`) avec indicateur « modifié » |
| ✅ | Filtre/recherche par nom dans la barre latérale |
| ✅ | Persistance du dernier projet ouvert (security-scoped bookmark) |
| ✅ | Ouverture externe des fichiers non-markdown |

## Prérequis

- macOS 14+
- Xcode 27 / Swift 6
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)

## Build & lancement

```bash
xcodegen generate
xcodebuild -project BmadBrowser.xcodeproj -scheme BmadBrowser -destination 'platform=macOS' build
open -a BmadBrowser   # ou lancer depuis Xcode
```

## Structure

```
project.yml              # définition XcodeGen (source de vérité du projet)
Sources/
  BmadBrowserApp.swift   # point d'entrée @main
  Models/                # Workspace, BmadProject, DocumentNode, Frontmatter
  Services/              # WorkspaceScanner, ConfigResolver, ProjectScanner, FrontmatterParser, BookmarkStore
  ViewModels/AppState.swift
  Views/                 # ContentView, ProjectListView, DocumentTreeView, DocumentDetailView, MediaViews
Resources/               # entitlements, assets
```

## Roadmap

- [x] Aperçu des images / PDF intégré
- [x] Niveau supérieur : workspace multi-projets
- [ ] Recherche plein-texte (dans le contenu, pas seulement les noms)
- [ ] Filtres par statut / type de workflow
- [ ] Édition du frontmatter en formulaire
- [ ] Workspaces / projets récents

> Voir `ARCHITECTURE.md` (FR) / `ARCHITECTURE_EN.md` (EN) pour la conception détaillée,
> `PLAN.md` pour le découpage des phases et `TODOS.md` pour l'avancement.
