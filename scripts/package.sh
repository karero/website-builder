#!/usr/bin/env bash
# Build the handoff zip from the canonical skills/. Replaces the old hand-rebuilt
# zip — run this instead of editing a separate package copy.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$REPO_DIR/dist"
mkdir -p "$OUT"
rm -f "$OUT/website-builder.zip"

find "$REPO_DIR" -name .DS_Store -delete 2>/dev/null || true
cd "$REPO_DIR"
zip -r -X "$OUT/website-builder.zip" skills reference README.md scripts/install.sh \
  -x '*.DS_Store' '*/dist/*' >/dev/null

echo "built $OUT/website-builder.zip"
unzip -l "$OUT/website-builder.zip" | tail -1
