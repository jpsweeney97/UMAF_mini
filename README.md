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
