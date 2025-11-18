# Changelog

All notable changes to this project will be documented here.

## [0.4.1] - 2025-11-18

### Added
- SwiftPM CLI (`Sources/umaf-mini`) using ArgumentParser.
- JSON Schema for the UMAF Mini envelope (`spec/umaf-mini-envelope-v0.4.1.schema.json`).
- GitHub Actions workflows for Swift and Node validation.
- SwiftLint configuration and EditorConfig.
- Contributor docs: README, CONTRIBUTING, CODE_OF_CONDUCT, SECURITY, LICENSE.

### Changed
- `scripts/run-envelopes.mjs` can locate either the Xcode-built CLI (`UMAFMiniCLI`) or the SwiftPM CLI (`umaf-mini`).

### Fixed
- Minor UX nits in docs and error messages.
