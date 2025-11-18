
# UMAF Mini

UMAF Mini turns plain text, Markdown, and JSON into a compact **envelope** that’s easy to consume, diff, and validate.

- **CLI:** `umaf-mini`
- **Schema:** `spec/umaf-mini-envelope-v0.4.1.schema.json`

## Quick start

```bash
swift build -c release
./.build/release/umaf-mini -i README.md --json > out.envelope.json
```
