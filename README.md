# BmadBrowser

Native macOS (SwiftUI) app to **browse and edit** the documents produced by the [BMad](https://github.com/bmad-code-org/BMAD-METHOD) method (v6) — the markdown artifacts stored in a project's output folder.

[![Release](https://img.shields.io/github/v/release/vincentlauriat/BmadBrowser)](https://github.com/vincentlauriat/BmadBrowser/releases/latest)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
![macOS 14+](https://img.shields.io/badge/macOS-14%2B-lightgrey)

🇫🇷 Version française : [README.fr.md](README.fr.md)

## Download

- **[Download the DMG](https://github.com/vincentlauriat/BmadBrowser/releases/latest/download/BmadBrowser.dmg)** — macOS 14+, Apple Silicon & Intel, signed & notarized.
- Or visit the website: **[vincentlauriat.github.io/BmadBrowser](https://vincentlauriat.github.io/BmadBrowser/)**

## Features

| Status | Feature |
|--------|----------------|
| ✅ | **Top level (workspace)**: open a root folder grouping several BMad projects (3-column UI: Projects / Documents / Detail) |
| ✅ | Auto-detection of projects: the root itself (single-project mode) or its subfolders containing `_bmad/`, `docs/`, or `_bmad-output/` |
| ✅ | Auto-detection of the BMad output folder (`_bmad/config.toml` → `output_folder`, fallbacks `docs/`, `_bmad-output/`) |
| ✅ | Document tree (markdown + artifacts: xlsx/pptx/png…) |
| ✅ | Viewing and editing of text files (`yaml`, `json`, `txt`, `csv`, `toml`) in monospace |
| ✅ | Rich markdown rendering (MarkdownUI) + text selection |
| ✅ | YAML frontmatter shown as badges (status, type, date) |
| ✅ | Editing + saving (`⌘S`) with a "modified" indicator; unsaved-changes confirmation |
| ✅ | Frontmatter-safe saving: the original YAML block is preserved verbatim (key order & lists intact) |
| ✅ | Frontmatter editing as a form ("Edit metadata") |
| ✅ | Full-text search (name **and** content) + filter by status |
| ✅ | Context menu: reveal in Finder, copy path, open in default app |
| ✅ | Word count + reading time under the markdown preview |
| ✅ | Inline image (zoom), SVG and PDF preview |
| ✅ | Auto-refresh on external file changes (FSEvents) |
| ✅ | Recent roots menu |
| ✅ | Persistence of the last opened project (security-scoped bookmark) |
| ✅ | External opening of non-markdown files |
| ✅ | Bilingual UI (English / French), follows the system language |

## Requirements

- macOS 14+
- Xcode 27 / Swift 6
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)

## Build from source

```bash
xcodegen generate
xcodebuild -project BmadBrowser.xcodeproj -scheme BmadBrowser -destination 'platform=macOS' build
open -a BmadBrowser   # or run from Xcode
```

## Release

```bash
./Scripts/release.sh 1.0.0
```

Builds a Release `.app`, signs it with a Developer ID certificate (Hardened Runtime), submits it for Apple notarization, staples the ticket, and packages a notarized, ready-to-distribute `release/BmadBrowser-1.0.0.dmg`.

Prerequisites: XcodeGen, and the `Developer ID Application: Vincent LAURIAT (KFLACS69T9)` certificate in the login keychain (notarization credentials are stored under the shared keychain profile `AppliMacVincentGithub`).

## Project layout

```
project.yml              # XcodeGen definition (source of truth of the project)
Sources/
  BmadBrowserApp.swift   # @main entry point
  Models/                # Workspace, BmadProject, DocumentNode, Frontmatter
  Services/              # WorkspaceScanner, ConfigResolver, ProjectScanner, FrontmatterParser, BookmarkStore, RecentsStore, FolderWatcher
  ViewModels/AppState.swift
  Views/                 # ContentView, ProjectListView, DocumentTreeView, DocumentDetailView, MediaViews
Resources/               # entitlements, assets, Localizable.xcstrings (EN base + FR translations)
Tests/                   # FrontmatterParserTests, ConfigResolverTests
Scripts/
  release.sh             # Release build, Developer ID signing, notarization, DMG packaging
docs/
  index.html             # Bilingual landing page (GitHub Pages)
```

## Roadmap

- [x] Built-in image / PDF / SVG preview
- [x] Top level: multi-project workspace
- [x] Bilingual UI (English / French)
- [x] Full-text search (content, not just names)
- [x] Filters by status
- [x] Frontmatter editing as a form
- [x] Recent workspaces / projects
- [x] Auto-refresh on file changes (FSEvents)
- [ ] Markdown outline, syntax highlighting, PDF/HTML export, preferences
- [ ] Sparkle auto-update, multi-window

> See `ARCHITECTURE.md` (FR) / `ARCHITECTURE_EN.md` (EN) for the detailed design,
> `PLAN.md` for the phase breakdown and `TODOS.md` for progress.

## License

[MIT](LICENSE) © 2026 Vincent Lauriat
