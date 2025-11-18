
# Envelope

The canonical JSON Schema lives at `spec/umaf-mini-envelope-v0.4.1.schema.json`.

Key fields:

| field       | type   | notes                         |
|-------------|--------|-------------------------------|
| `version`   | string | `"umaf-mini-0.4.1"`           |
| `encoding`  | string | `"utf-8"`                     |
| `mediaType` | string | `text/plain|text/markdown|application/json` |
| `title`     | string | derived from first heading or filename |
| `body`      | string | normalized content            |

Validation:
```bash
npm ci
npm run validate:schema
```
