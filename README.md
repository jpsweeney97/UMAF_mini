# UMAF Mini

A tiny, fast transformer that ingests **plain text**, **Markdown**, or **JSON** and emits a consistent, machine-friendly **UMAF Mini envelope**. The project ships as:

- a reusable Swift library (`UMAFCore`)
- a SwiftUI macOS app (`UMAF_mini`)
- a CLI (`umaf-mini`) for pipelines and CI

> Version: envelope schema `umaf-mini-0.4.1`

---

## What does it do?

Given an input file (`.txt`, `.md`, or `.json`), UMAF Mini computes a stable hash, normalizes newlines and whitespace, extracts structure (headings, bullets, tables, fenced code blocks, and optional front‑matter), and returns either:

- a JSON **envelope** with the normalized content and extracted metadata, or
- a normalized Markdown document

The envelope is designed to be lightweight but predictable, and is validated using a JSON Schema in this repo.

## Project layout

```
.
├─ Packages/
│  └─ UMAFCore/               # Swift package with the core transformer
├─ UMAF_mini/
│  ├─ UMAFMiniCLI/            # Xcode-friendly CLI entry point
│  └─ UMAF_mini/              # SwiftUI macOS app
├─ Sources/
│  └─ umaf-mini/              # SwiftPM CLI (ArgumentParser-powered)
├─ scripts/                   # Tooling (SwiftLint, envelope validation)
├─ spec/                      # JSON Schemas
└─ .github/workflows/         # CI for Swift + Node validation
```

## Quick start

### Build the CLI (SwiftPM)

```bash
# macOS 13+ with Xcode 15+ (Swift 5.9+) or Swift toolchain 5.9+
swift build -c release
./.build/release/umaf-mini --help
```

Transform a file:

```bash
./.build/release/umaf-mini --input path/to/input.md --json > out.envelope.json
./.build/release/umaf-mini --input path/to/input.md --markdown > normalized.md
```

### Run the macOS app

Open `UMAF_mini/UMAF_mini.xcodeproj` in Xcode and run the `UMAF_mini` scheme.

## macOS app (UMAF_mini) structure

The SwiftUI macOS app lives under `UMAF_mini/UMAF_mini`. It’s a separate target from the SwiftPM CLI and UMAFCore, but uses UMAFCore directly in-process instead of shelling out to the `umaf-mini` binary.

### Targets

- **UMAF_mini (SwiftUI app)**
  `UMAF_mini/UMAF_mini.xcodeproj` → target **UMAF_mini**

- **UMAFMiniCLI (Xcode-friendly CLI)**
  `UMAF_mini/UMAFMiniCLI/*`

- **umaf-mini (SwiftPM CLI)**
  `Sources/umaf-mini/*`

- **UMAFCore (library)**
  `Packages/UMAFCore/*`

The rest of this section is about the **UMAF_mini** app target only.

### App entry point and root layout

- `UMAF_mini/UMAF_mini/App/UMAF_miniApp.swift`
  SwiftUI entry point (`@main`). Creates the window and injects shared state:

  - Creates a single `AppState` (`@StateObject`)
  - Wraps `MainWindow()` in a `WindowGroup`
  - Attaches `.environmentObject(appState)` so all views can see it

- `UMAF_mini/UMAF_mini/App/MainWindow.swift`
  Root view and toolbar:
  - Hosts a `NavigationSplitView` with:
    - `SidebarView` (left)
    - `EditorView` (center)
    - `InspectorView` (right)
  - Adds a unified toolbar:
    - App title (“UMAF Mini”)
    - **Choose File…** button → `appState.pickFile()`
    - **Transform** button → `appState.runTransform()`

### Core state and models

All shared logic lives in `Core` and is wired into the app via `AppState`.

- `UMAF_mini/UMAF_mini/Core/AppState.swift`
  The single source of truth for the app (`ObservableObject`):

  - `@Published var selectedFile: URL?`
  - `@Published var sourceText: String` – raw file contents
  - `@Published var outputText: String` – UMAF envelope JSON (as text)
  - `@Published var envelope: UMAFEnvelope?` – decoded envelope model
  - `@Published var isRunning: Bool`, `errorMessage: String?`
  - Handles:

    - Showing an `NSOpenPanel` to pick files (`pickFile()`)
    - Loading file contents into `sourceText` (`loadFile(_:)`)
    - Watching the file for changes via `FileObserver`
    - Calling **UMAFCore** in-process:

      ```swift
      try UMAFMiniCore.processFile(at: url,
                                  assumedMediaType: nil,
                                  output: .json)
      ```

    - Decoding the JSON into `UMAFEnvelope` for the inspector

- `UMAF_mini/UMAF_mini/Core/FileObserver.swift`
  Watches the selected file on disk and auto-retransforms:

  - Wraps `DispatchSourceFileSystemObject` on the file descriptor
  - On `.write` events:
    - Reloads the file into `sourceText`
    - Calls `AppState.runTransform()` again

- `UMAF_mini/UMAF_mini/Core/UMAFEnvelope.swift`
  A minimal `Decodable` model for the UMAF Mini envelope:
  - Top-level fields like `version`, `docTitle`, `docId`, `createdAt`,
    `sourceHash`, `sourcePath`, `mediaType`, `encoding`, `sizeBytes`,
    `lineCount`, `normalized`
  - Structural collections:
    - `sections: [Section]?`
    - `bullets: [Bullet]?`
    - `frontMatter: [FrontMatterItem]?`
    - `tables: [Table]?`
    - `codeBlocks: [CodeBlock]?`
  - Each nested struct is also `Decodable` and intentionally loose/optional
    so envelopes from older/newer schema versions don’t crash decoding.

### Views

These files are the actual UI pieces used by `MainWindow`.

- `UMAF_mini/UMAF_mini/Views/SidebarView.swift`
  Left navigation column:

  - **Choose File…** button → `appState.pickFile()`
  - Shows the current file name if one is selected
  - Uses `@EnvironmentObject var appState: AppState`

- `UMAF_mini/UMAF_mini/Views/EditorView.swift`
  Center pane with tabs and a code editor:

  - Wrapped in `GlassPanel` (from `Theme.swift`)
  - Top row:
    - Segmented control: **Input** / **Envelope JSON**
    - **Transform** button (same behavior as toolbar; calls `runTransform()`)
  - **Input** tab:
    - Hosts `CodeEditor(text: $appState.sourceText)` – monospaced editor view
  - **Envelope JSON** tab:
    - Scrollable monospaced `Text` bound to `appState.outputText`

- `UMAF_mini/UMAF_mini/Views/InspectorView.swift`
  Right-hand inspector for envelope metadata:
  - Wrapped in `GlassPanel`
  - Uses `appState.envelope` and `appState.errorMessage`
  - Shows:
    - File name
    - `docTitle`, `mediaType`, `encoding`
    - `lineCount`, `sizeBytes`
    - Counts of `sections`, `bullets`, `tables`, `codeBlocks`
    - `sourceHash` in monospaced font, selectable
    - Last UMAFCore error, if present

### Components

Reusable lower-level views that sit under `Views`.

- `UMAF_mini/UMAF_mini/Components/CodeEditor.swift`
  A minimal `NSTextView` wrapper for use inside SwiftUI:
  - Implements `NSViewRepresentable`
  - Configures a plain, monospaced `NSTextView` (no rich text)
  - Syncs its string to a `@Binding var text: String`
  - All actual edits go through this binding (used by `EditorView`)

### Theme

Centralized styling / design tokens.

- `UMAF_mini/UMAF_mini/Theme/Theme.swift`
  App-wide theme helpers:

  - `UMAFTheme.accent` – accent color to use in buttons
  - `UMAFTheme.windowGradient` – background gradient for the main window
  - `UMAFTheme.panelBackground` / `panelBorder` – panel styling
  - `GlassPanel<Content>` – a reusable glassy card wrapper for content:
    - Uses `.ultraThinMaterial` + soft border + 14-pt rounded corners

  `MainWindow`, `EditorView`, and `InspectorView` all lean on this so any later
  design tweaks only need changes in one place.

### Sample data

- `UMAF_mini/UMAF_mini/Sample/SampeData.swift`
  Small static strings used for previews / initial prototyping:
  - `sampleMarkdown`
  - `normalizedOutput`
  - `sampleEnvelope`
    The live app no longer depends on these at runtime; they’re mostly useful
    for Xcode previews or quick experiments.

---

If you’re trying to understand “what code makes the UMAF_mini app actually run,” it’s everything under:

- `UMAF_mini/UMAF_mini/App`
- `UMAF_mini/UMAF_mini/Core`
- `UMAF_mini/UMAF_mini/Views`
- `UMAF_mini/UMAF_mini/Components`
- `UMAF_mini/UMAF_mini/Theme`

plus **UMAFCore** under `Packages/UMAFCore`, which the app calls directly instead of going through the `umaf-mini` CLI.

### Node-based validation (optional)

```bash
npm ci
npm run validate:schema         # validate the schema itself
npm run validate:envelopes      # build + run crucible inputs and validate outputs
```

> You can point the runner at a specific CLI by setting `UMAF_CLI=/path/to/umaf-mini`.

## Envelope format (summary)

The envelope is emitted as JSON with this top-level shape (see the [full schema](./spec/umaf-mini-envelope-v0.4.1.schema.json) for details):

```jsonc
{
  "version": "umaf-mini-0.4.1",
  "docTitle": "...",
  "docId": "...",            // stable identifier derived from source
  "createdAt": "2025-11-13T21:00:00Z",
  "sourceHash": "...",       // SHA-256 (hex)
  "sourcePath": "...",       // original path (or "-" for stdin)
  "mediaType": "text/markdown",
  "encoding": "utf-8",
  "sizeBytes": 12345,
  "lineCount": 420,
  "normalized": "...",       // normalized text/markdown
  "sections": [{ "heading": "...", "level": 2, "lines": [...], "paragraphs": [...] }],
  "bullets": [{ "text": "...", "lineIndex": 10, "sectionHeading": "..." }],
  "frontMatter": [{ "key": "title", "value": "..." }],
  "tables": [{ "startLineIndex": 12, "header": ["A", "B"], "rows": [["1","2"]] }],
  "codeBlocks": [{ "startLineIndex": 40, "language": "swift", "code": "..." }]
}
```

## Developing

- **Formatting**: `.swift-format` and `.swiftlint.yml` are configured; run `scripts/swiftlint.sh`.
- **Tests**: run `swift test --package-path Packages/UMAFCore` to exercise the library.
- **CI**: GitHub Actions builds the Swift package and validates envelopes.

### Common tasks

```bash
# Build CLI and run a sample transform
swift build
./.build/debug/umaf-mini --input README.md --json | jq .version

# Run UMAFCore tests
swift test --package-path Packages/UMAFCore

# Lint Swift
./scripts/swiftlint.sh
```

## Why two CLIs?

- `UMAF_mini/UMAFMiniCLI/main.swift` is kept for the Xcode project.
- `Sources/umaf-mini/main.swift` is a modern SwiftPM CLI built with ArgumentParser. Use this in CI.

## License

ISC © 2025 JP Sweeney


## Next-steps implemented

- **Error taxonomy** with stable CLI exit codes and actionable messages (`UMAFUserError`).
- **Structured logging** via `OSLog` (`UMAFLog.core/cli/app/parsing/io`).
- **SwiftUI refactor** with drag‑and‑drop, progress, toast notifications, and "Reveal in Finder."
- **Crucible inputs** under `crucible/min` for edge‑case testing.
- **Docs site** scaffolded with MkDocs Material (`mkdocs.yml`, `docs/**` + CI in `.github/workflows/docs.yml`).
- **Release automation** job to tag, build, sign, and attach CLI to GitHub Releases (`.github/workflows/release.yml`).

See the [docs](https://github.com/your-org/UMAF_mini) after GitHub Pages is enabled.
