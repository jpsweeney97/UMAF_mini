# Contributing

Thanks for thinking about contributing—tiny tools get mighty with friendly hands.

## Development environment

- macOS 13+ with Xcode 15 (Swift 5.9+) recommended
- Node.js 20+ for schema validation tooling
- SwiftLint (optional): `brew install swiftlint`

## Workflow

1. Fork + clone the repo.
2. Create a feature branch: `git switch -c feat/your-thing`.
3. Run the checks below and commit with conventional messages.
4. Open a PR—describe the problem, your approach, and trade‑offs.

### Checks

```bash
# Build CLI
swift build -c debug

# Unit tests (UMAFCore)
swift test --package-path Packages/UMAFCore

# Lint Swift
./scripts/swiftlint.sh

# Validate envelopes (optional)
npm ci
npm run validate:envelopes
```

### Style

- Swift formatting via `.swift-format`; lint via `.swiftlint.yml`.
- Prefer small, pure functions in `UMAFCore`.
- No force unwraps; bubble errors explicitly.

### Commit messages

Use the conventional commits style (e.g., `feat:`, `fix:`, `docs:`, `refactor:`). It keeps the history navigable and helps auto‑generate changelogs.

### Security

Please **do not** file security issues publicly. See `SECURITY.md` for private reporting instructions.
