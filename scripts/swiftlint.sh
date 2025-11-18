#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if ! command -v swiftlint >/dev/null 2>&1; then
  echo "swiftlint not found. Install with: brew install swiftlint" >&2
  exit 1
fi

cd "$ROOT_DIR"
swiftlint
