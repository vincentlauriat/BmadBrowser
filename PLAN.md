# PLAN — BmadBrowser

Outil macOS natif pour **naviguer et éditer** les documents produits par BMad (méthode BMad v6).

## Décisions de cadrage (validées)
- **Stack** : SwiftUI natif (macOS), build via XcodeGen + xcodebuild.
- **Périmètre** : Lecture/navigation **+ édition** des fichiers markdown.
- **Source** : Sélecteur de dossier (l'utilisateur ouvre un projet ; l'app détecte l'arborescence BMad).

## Contexte technique BMad v6 (observé sur la machine)
- Moteur dans `_bmad/` ; `config.toml` → `[core] output_folder = "{project-root}/docs"`.
- Documents dans `output_folder` (souvent `docs/`, parfois `_bmad-output/`), organisés en sous-dossiers :
  `planning-artifacts/`, `implementation-artifacts/`, `test-artifacts/`, `brainstorming/`, `superpowers/{specs,plans}/`, `research/`.
- Frontmatter YAML dans les `.md` : `status`, `completedAt`/`date`, `workflowType`, `stepsCompleted`, `inputDocuments`.
- Présence de fichiers non-md (xlsx, pptx, png) à gérer (ouverture externe).

## Architecture cible
```
BmadBrowser/
  project.yml                 # XcodeGen
  Sources/
    BmadBrowserApp.swift      # @main
    Models/
      Workspace.swift         # racine (niveau supérieur) + liste de projets
      BmadProject.swift       # racine projet + output folder résolu
      DocumentNode.swift      # arbre fichiers/dossiers
      Frontmatter.swift       # métadonnées parsées
    Services/
      WorkspaceScanner.swift  # scanne la racine → projets (mono ou multi)
      ProjectScanner.swift    # lit config.toml, résout output_folder, construit l'arbre
      ConfigResolver.swift    # mini-parser ciblé du config.toml (+ fallbacks docs/ , _bmad-output/)
      FrontmatterParser.swift # extrait le bloc YAML --- ... ---
      BookmarkStore.swift     # security-scoped bookmarks (accès persistant au dossier)
    ViewModels/
      AppState.swift          # @Observable : workspace, projet courant, sélection, contenu
    Views/
      ContentView.swift       # NavigationSplitView 3 colonnes
      ProjectListView.swift   # colonne 1 : projets du workspace
      DocumentTreeView.swift  # colonne 2 : arbre latéral + badges de statut
      DocumentDetailView.swift# colonne 3 : preview rendu / éditeur (toggle) + Cmd+S
      MediaViews.swift        # ImageViewer (zoom) + PDFViewer
  Resources/                  # entitlements, assets
```

## Dépendances
- **MarkdownUI** (gonzalezreal/swift-markdown-ui) via SPM pour un rendu markdown riche.
- Sandbox activé + entitlement `files.user-selected.read-write` + bookmarks pour la persistance.

## Phases
1. **Échafaudage** : project.yml + app SwiftUI minimale qui compile (NavigationSplitView vide). ✅ build vert.
2. **Détection projet** : NSOpenPanel → résolution `output_folder` → scan de l'arbre `.md`.
3. **Navigation + preview** : arbre latéral, rendu MarkdownUI, frontmatter en badges.
4. **Édition** : toggle preview/édition, TextEditor, sauvegarde Cmd+S, indicateur « modifié ».
5. **Confort** : recherche plein-texte, filtres par statut/dossier, ouverture externe des non-md, persistance du dernier projet.

## Vérification
`xcodebuild -scheme BmadBrowser build` vert à chaque phase. Test manuel sur un projet réel (ex: `clarify/docs`).
