# CHANGES — BmadBrowser

## v1.2.0 — 2026-07-05

> DMG signé/notarisé publié sur la GitHub Release `v1.2.0`.

### Fixed (packaging)
- **App réellement sandboxée** : `Scripts/release.sh` ne passait jamais `--entitlements` à la
  signature manuelle (le build utilise `CODE_SIGNING_ALLOWED=NO`), si bien que les DMG précédents
  (v1.0.0/v1.1.0) étaient signés **sans entitlements** — donc non sandboxés malgré la conception.
  Le script applique désormais `Resources/BmadBrowser.entitlements` à l'app (pas aux frameworks) et
  vérifie que l'entitlement `app-sandbox` est bien embarqué. v1.2.0 est le premier DMG réellement
  sandboxé (app-sandbox + bookmarks + user-selected + network.client).

### Added
- **Multi-fenêtres** : chaque fenêtre a son propre `AppState` (workspace/sélection indépendants),
  via `RootView` ; « New Window » (⌘N) restauré, « Open a Root… » cible la fenêtre active
  (`FocusedValue`).
- **Vérification de mise à jour** in-app via l'API GitHub Releases (`UpdateChecker` + `SemVer`) :
  contrôle silencieux au lancement (une fois par process), commande « Check for Updates… » dans le
  menu de l'app, alerte proposant le téléchargement quand une version plus récente existe.
  4 tests `SemVer` (total 18 tests).

### Changed
- **Accès security-scoped** déplacé d'un état statique global vers un cycle de vie **par `AppState`**
  (`adoptScopedAccess` + `deinit`) — indispensable pour que deux fenêtres ouvrent des racines
  différentes simultanément. `BookmarkStore`/`RecentsStore` redeviennent sans état.
- Entitlement `com.apple.security.network.client` ajouté (pour la vérification de MAJ).

### Notes
- **Sparkle complet** (deltas + auto-install silencieux) reporté : incompatible « clé en main » avec
  le sandbox sans XPC + entitlements d'exception + appcast hébergé + clé EdDSA à préserver. Le
  vérificateur GitHub couvre le besoin « être prévenu + télécharger ».

## v1.1.0 — 2026-07-05

> Première mise à jour après la 1.0.0. Regroupe l'audit code (corrections de données
> + confort) et la vague confort (préférences, coloration, export PDF, outline).
> DMG signé/notarisé publié sur la GitHub Release `v1.1.0`.

### Préférences, coloration, export, outline (2026-07-05)

### Added
- **Fenêtre Préférences** (⌘,) : thème de rendu markdown (GitHub / DocC), taille de police de
  l'éditeur, bascule de la barre de statistiques (`SettingsView` + `@AppStorage`).
- **Coloration syntaxique** en lecture pour `json` / `yaml` / `toml` (`SyntaxHighlighter` →
  `AttributedString`, couleurs système adaptées clair/sombre).
- **Export PDF** du markdown rendu (`MarkdownPDFExporter` via `ImageRenderer` — page continue) ;
  bouton « Export PDF » + `NSSavePanel`.
- **Sommaire (outline)** des titres markdown : `MarkdownOutline` découpe le corps en sections
  (par titre, blocs de code ignorés) rendues dans un `ScrollViewReader` ; menu Outline avec
  défilement vers le titre choisi.
- Tests : `MarkdownOutlineTests` (niveaux, blocs de code, préambule, round-trip) — total 14 tests verts.

### Changed
- L'aperçu markdown est désormais rendu **section par section** (au lieu d'un bloc unique) pour
  permettre le scroll-to-heading ; le thème et la police suivent les préférences.

### Limitations
- Export PDF en **une seule page continue** (pas de pagination). Coloration syntaxique heuristique
  (regex, pas un parseur).

### Audit code → corrections données & confort (2026-07-04)

### Fixed
- **Sauvegarde markdown non destructive** : `save()` réécrit le bloc frontmatter **brut d'origine**
  (`Frontmatter.rawBlock`) au lieu de le reconstruire depuis un dictionnaire non ordonné —
  l'ordre des clés YAML, les listes (`inputDocuments`) et les valeurs multi-lignes sont préservés.
- **Perte silencieuse des modifications** : dialogue de confirmation « Save / Discard / Cancel »
  (`AppState.guardUnsaved`) avant tout changement de document ou de projet en mode édition.
- **Message d'erreur** de lecture français codé en dur → `String(localized:)`.
- **Badge de statut de l'arbre** rafraîchi après édition/sauvegarde du frontmatter.
- **Fuite d'accès security-scoped** : `BookmarkStore` ne conserve qu'un seul accès actif
  (`beginAccess`/`stopCurrentAccess`), libéré avant d'en ouvrir un nouveau.

### Added
- **Recherche plein-texte** : la recherche filtre désormais sur le nom **et** le contenu des
  fichiers texte (mise en cache par projet).
- **Filtre par statut** de frontmatter (menu dans la colonne documents).
- **Édition du frontmatter en formulaire** (feuille « Edit metadata ») : les champs scalaires
  `clé: valeur` sont éditables ; seules leurs lignes sont réécrites (listes/blocs intacts).
- **Menu contextuel** sur les nœuds : Révéler dans le Finder, Copier le chemin, Ouvrir.
- **Compteur de mots + temps de lecture** sous l'aperçu markdown.
- **Projets récents** : le bouton « Open » devient un menu avec une section Recent
  (security-scoped bookmarks, 8 max, dédup par chemin) + Clear Recents.
- **Rendu SVG** inline dans la visionneuse d'image.
- **Rafraîchissement automatique** via FSEvents (`FolderWatcher`), sans écraser une édition en cours.
- **Tests unitaires** : target `BmadBrowserTests` + scheme ; `FrontmatterParser` (round-trip,
  champs scalaires) et `ConfigResolver` (détection, fallbacks, `{project-root}`) — 9 tests verts.
- **SwiftLint** : `.swiftlint.yml` + phase de build optionnelle (no-op si non installé).

### Changed
- Traversées d'arbre dupliquées (`node(withID:)`, `findNode(url:in:)`) factorisées en
  `firstNode(in:where:)`.

### Docs
- **Audit complet du code source** (17 fichiers Swift) consigné dans `TODOS.md` (backlog priorisé
  🔴/🟠/🟢) ; items traités cochés, reste (outline, coloration syntaxique, export, préférences,
  Sparkle, multi-fenêtres) marqué reporté avec justification.

## 2026-07-04 (i18n, v1.0.0, distribution & site)

### Added
- **Internationalisation EN/FR** via un String Catalog `Resources/Localizable.xcstrings` : base anglaise, traductions françaises fournies par le catalogue, pluriels gérés (ex. `%lld projects`).
- **`Scripts/release.sh <version>`** : build Release, signature Developer ID (Hardened Runtime), notarisation Apple (profil trousseau `AppliMacVincentGithub`), staple, packaging DMG (`release/BmadBrowser-<version>.dmg`).
- **Landing page** bilingue `docs/index.html` (GitHub Pages).
- **README** entièrement en anglais + `README.fr.md` (miroir français).

### Changed
- Tout le texte UI codé en dur est passé du français vers des **clés anglaises** ; le français est désormais fourni par le String Catalog.
- `MARKETING_VERSION` : `0.1.0` → **`1.0.0`** (première version publique).
- `project.yml` : ajout de `options.developmentLanguage: en` et de la source `Resources/Localizable.xcstrings`.

### Docs
- README bilingue (EN + FR), `ARCHITECTURE_EN.md`/`ARCHITECTURE.md` : nouvelles sections « 12. Localization (i18n) » et « 13. Distribution », section « 3. Project layout » mise à jour (`Localizable.xcstrings`, `Scripts/release.sh`, `docs/`).
- App ajoutée au portfolio github.io et à lauriat.fr.

### Chore
- Dépôt GitHub `vincentlauriat/BmadBrowser` rendu **public**.
- GitHub Release **v1.0.0** publiée avec le DMG notarisé.
- **GitHub Pages** activées sur `docs/`.

## 2026-06-29 (fichiers texte)

### Added
- Affichage et **édition des fichiers texte** non-markdown (`yaml`, `yml`, `json`, `txt`, `csv`, `toml`) : aperçu monospace scrollable (h/v) avec sélection, bascule édition + sauvegarde `⌘S` comme le markdown. En-tête indiquant le type de fichier.
- `toml` ajouté aux extensions scannées ; icônes dédiées (`curlybraces` pour yaml/json/toml, `doc.plaintext` pour txt).
- Helpers `DocumentNode.isText` / `isEditable`.

### Changed
- `AppState.select(_:)` charge le contenu brut des fichiers texte (sans parsing frontmatter) ; `save()` écrit le markdown (frontmatter reconstruit) ou le texte brut selon le type.
- Toolbar Éditer/Enregistrer affichée pour tout document éditable (`isEditable`), plus seulement le markdown.

### Docs
- Synchro complète de toute la documentation (MEMORY, PLAN, ARCHITECTURE EN+FR, README, TODOS, COMMANDS) : fichiers texte, AppIcon, workspace, piège XcodeGen `resources:`→`sources:`, statut GitHub/licence, workflow git feature branch → merge.

## 2026-06-29 (icône)

### Added
- **AppIcon** : icône macOS générée par un script Swift (AppKit/CoreGraphics, rendu vectoriel net à chaque taille 16→1024). Design : squircle dégradé bleu→indigo, carte document markdown (coin replié, ligne de titre accentuée + lignes de corps), pastille de statut verte. `AppIcon.appiconset` complet (mac idiom, @1x/@2x).
- `ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon` dans `project.yml`.

### Fixed
- `project.yml` : le catalogue d'assets était sous une clé `resources:` **inexistante** pour une target XcodeGen → silencieusement ignoré, `Assets.xcassets` jamais inclus, pas de `Assets.car` ni de `CFBundleIconName` (icône par défaut). Déplacé sous `sources:` ; `actool` compile désormais le catalogue et l'icône apparaît.

## 2026-06-29 (workspace)

### Docs
- `ARCHITECTURE_EN.md` (source de vérité) + `ARCHITECTURE.md` (miroir FR) : vue d'ensemble, stack, arborescence, diagramme mermaid des composants, modèles/services, flux d'état `AppState`, disposition 3 colonnes, persistance/sandbox, build.
- `LICENSE` (MIT, © 2026 Vincent Lauriat) + section Licence dans le README.

### Chore
- Repo GitHub privé `vincentlauriat/BmadBrowser` créé (remote `origin`), `main` + branche feature poussés, topics ajoutés.

### Added
- **Niveau supérieur (workspace)** : on ouvre désormais une racine pouvant contenir **plusieurs projets** BMad. Modèle `Workspace` + service `WorkspaceScanner`.
- Détection auto + fallback : si la racine est elle-même un projet → mode mono-projet ; sinon scan des sous-dossiers directs, retenant ceux contenant `_bmad/`, `docs/` ou `_bmad-output/`.
- UI **3 colonnes** : `ProjectListView` (projets) | `DocumentTreeView` (documents du projet sélectionné) | `DocumentDetailView`. En-tête de workspace avec nom + nombre de projets.

### Changed
- `AppState` : ajout de `workspace`, méthode `selectProject(_:)`, `open(rootURL:)` scanne désormais le workspace et sélectionne le premier projet ; `reload()` re-scanne la racine (détecte projets ajoutés/supprimés) en conservant projet + sélection courants.
- `ContentView` : `NavigationSplitView` à 3 colonnes ; titre = workspace, sous-titre = `projet › document`.
- Libellés « Ouvrir un projet » → « Ouvrir une racine » (menu + toolbar).

## 2026-06-29 (suite)

### Added
- Affichage des **images** sélectionnées dans l'arbre : `ImageViewer` (zoom molette/pincement + boutons %, ajuster, dimensions px).
- Affichage des **PDF** via PDFKit (`PDFViewer`, auto-scale).
- Rendu **inline des images du markdown** : `LocalImageProvider` résout les chemins relatifs par rapport au dossier du document et charge les fichiers locaux (fallback réseau pour les URLs http).
- Bouton « Ouvrir dans l'app par défaut » dans la toolbar pour image/PDF.
- Extensions image élargies au scan (bmp, tiff, heic, svg) et helpers `isImage`/`isPDF` sur `DocumentNode`.

## 2026-06-29

### Added
- Échafaudage initial du projet macOS SwiftUI (XcodeGen `project.yml`, entitlements sandbox + user-selected read-write + bookmarks).
- Modèles : `BmadProject`, `DocumentNode`, `Frontmatter`.
- Services : `ConfigResolver` (lecture `_bmad/config.toml` → `output_folder` + fallbacks `docs/`/`_bmad-output/`), `ProjectScanner` (arbre des artefacts), `FrontmatterParser` (YAML léger), `BookmarkStore` (security-scoped bookmark persistant).
- `AppState` (@Observable) : ouverture projet, sélection, chargement, édition, sauvegarde, filtre, recharge.
- Vues : `ContentView` (NavigationSplitView), `DocumentTreeView` (arbre + badges de statut), `DocumentDetailView` (rendu MarkdownUI / éditeur, barre frontmatter, toolbar Éditer/Enregistrer).
- Dépendance SPM : MarkdownUI (rendu markdown riche).

### Docs
- `PLAN.md`, `TODOS.md`, `README.md`, `.gitignore`.

### Fixed
- Erreur d'inférence `some View` due à une fonction de ligne récursive → remplacée par `List(children:)` natif + struct `NodeRow`.

### Changed
- UX : en-tête de projet permanent dans la barre latérale (icône + nom + chemin) et titre/sous-titre de fenêtre (`navigationTitle` projet, `navigationSubtitle` document courant) → on sait toujours dans quel projet on est.
- Distinction des états « aucun projet ouvert » vs « projet sans document ».

### Chore
- `git init` (branche `main`).
