#!/usr/bin/env bash
set -euo pipefail

SCHEMA="schemas/umaf-mini-envelope-v0.4.1.schema.json"

if [ $# -lt 1 ]; then
  echo "Usage: $0 path/to/envelope.json" >&2
  exit 1
fi

ENVELOPE="$1"

npx ajv validate \
  -s "$SCHEMA" \
  -d "$ENVELOPE"
