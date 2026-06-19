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
# Explicit file list (not the scripts/ dir) so the gitignored scripts/.clean-denylist
# can never leak into the handoff. LICENSE + THIRD-PARTY-LICENSES.md ship the notices the
# README points to; Makefile makes `make install` work for a zip recipient.
zip -r -X "$OUT/website-builder.zip" \
  skills reference README.md LICENSE THIRD-PARTY-LICENSES.md Makefile \
  scripts/install.sh scripts/check_clean.sh scripts/package.sh \
  -x '*.DS_Store' '*/dist/*' >/dev/null

echo "built $OUT/website-builder.zip"
unzip -l "$OUT/website-builder.zip" | tail -1
