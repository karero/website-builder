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
# docs/reviews/ holds internal review trails + plan artifacts — never handoff material.
zip -r -X "$OUT/website-builder.zip" \
  skills docs README.md LICENSE THIRD-PARTY-LICENSES.md Makefile \
  scripts/install.sh scripts/install-codex.sh scripts/check_clean.sh scripts/package.sh \
  scripts/whats-new.sh \
  -x '*.DS_Store' '*/dist/*' 'docs/reviews/*' >/dev/null

echo "built $OUT/website-builder.zip"
unzip -l "$OUT/website-builder.zip" | tail -1

# Integrity check: a handoff zip missing any of these is broken (legal notices, install
# path, the orchestrator, or the architecture doc it points at). Fail loud if so.
REQUIRED=(
  README.md
  LICENSE
  THIRD-PARTY-LICENSES.md
  Makefile
  scripts/install.sh
  scripts/install-codex.sh
  scripts/check_clean.sh
  scripts/package.sh
  scripts/whats-new.sh
  docs/ANTIGRAVITY.md
  docs/ANTIGRAVITY-TEST.md
  docs/CODEX.md
  docs/CODEX-TEST.md
  skills/new-website/SKILL.md
  skills/new-website/references/WEBSITE_ARCHITECTURE.md
)
zipfiles="$(unzip -Z1 "$OUT/website-builder.zip")"
missing=0
for f in "${REQUIRED[@]}"; do
  grep -Fxq "$f" <<<"$zipfiles" || { echo "✗ MISSING from zip: $f"; missing=1; }
done
if [ "$missing" -ne 0 ]; then
  echo "FAIL — handoff zip is incomplete (see ✗ above)."
  exit 1
fi

# Internal artifacts must never ship: fail loud if any slip past the exclusions.
if grep -E '^docs/reviews/|^REVIEW-|^SKILL-PLAN-' <<<"$zipfiles" | head -5 | grep .; then
  echo "FAIL — internal review/plan artifacts leaked into the handoff zip (see above)."
  exit 1
fi
echo "zip integrity OK — all critical files present, no internal artifacts"
