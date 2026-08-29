#!/usr/bin/env bash
# Guard: independent-review's OLLAMA_MODEL default is hand-maintained across nine prose
# references (SKILL.md x4, the script itself x5) instead of read from one place — exactly
# how the ollama-cloud default drifted out of sync during the claude-skills migration.
# This derives the canonical value from the script's own default assignment (the only
# line that actually governs runtime behavior) and fails if any other mention disagrees.
set -uo pipefail
cd "$(dirname "$0")/.."

SKILL_DIR="skills/independent-review"
SCRIPT="$SKILL_DIR/scripts/independent_review.sh"
DOC="$SKILL_DIR/SKILL.md"

canonical=$(grep -oE 'OLLAMA_MODEL="\$\{OLLAMA_MODEL:-[^}]+\}"' "$SCRIPT" \
  | sed -E 's/.*:-(.*)\}"/\1/')

if [ -z "$canonical" ]; then
  echo "FAIL — could not find the OLLAMA_MODEL default assignment in $SCRIPT."
  echo "The line this check expects looks like: OLLAMA_MODEL=\"\${OLLAMA_MODEL:-<tag>}\""
  exit 1
fi

# Every mention of a glm-*:cloud-shaped tag, anywhere in the doc or the script, must
# contain the canonical value above — a line that already contains it passes trivially,
# including the assignment line itself. A line legitimately discussing a DIFFERENT,
# non-default tag (e.g. "the old tag still works as an override") is excluded via an
# explicit inline marker rather than guessed at — see the marker text below.
MARKER='non-default mention'
PATTERN='glm-[A-Za-z0-9.-]+:cloud'
mismatches=$(grep -nE "$PATTERN" "$DOC" "$SCRIPT" | grep -vF "$canonical" | grep -vF "$MARKER")

if [ -n "$mismatches" ]; then
  echo "FAIL — a reference to the ollama-cloud default disagrees with the canonical value"
  echo "($canonical, from $SCRIPT's own default assignment):"
  printf '%s\n' "$mismatches" | sed 's/^/    /'
  echo ""
  echo "Update the mismatched reference(s) to $canonical, or update the assignment in"
  echo "$SCRIPT if the default itself is meant to change."
  exit 1
fi

echo "OK — every OLLAMA_MODEL reference in $SKILL_DIR matches the canonical default ($canonical)"
