#!/usr/bin/env bash
# Guard: independent-review is model-AGNOSTIC — the pipeline prescribes no specific LLM.
# The ollama tier auto-detects the owner's signed-in ':cloud' model, Codex and Antigravity
# use their own CLI-configured defaults, and the docs speak in families and generic tags.
# A hardcoded default is exactly how the ollama tier once drifted out of sync with the
# owner's real setup (the pre-2026-08-29 version of this check managed that drift; this
# version prevents the class). references/setup-guide.md is deliberately NOT scanned —
# it is the drift-prone helper that cites dated, concrete local-model examples for the
# RAM table, and says so inline.
set -uo pipefail
cd "$(dirname "$0")/.."

SKILL_DIR="skills/independent-review"
FILES=(
  "$SKILL_DIR/SKILL.md"
  "$SKILL_DIR/references/onboarding.md"
  "$SKILL_DIR/references/closeout.md"
  "$SKILL_DIR/scripts/independent_review.sh"
)

for f in "${FILES[@]}"; do
  if [ ! -f "$f" ]; then
    echo "FAIL — expected pipeline file missing: $f (update FILES in this check if it moved)."
    exit 1
  fi
done

# Named cloud tags (word:cloud — a bare ':cloud' convention mention is fine) and
# versioned family/model names. Family names WITHOUT a version (Gemini, GLM,
# gpt-class, Claude) stay allowed — the Independence rule classifies by family.
PATTERN='[A-Za-z0-9][A-Za-z0-9._-]*:cloud|[Gg][Ll][Mm]-[0-9]|gpt-[0-9]|[Gg]emini[- ][0-9]|[Cc]laude[- ][0-9]'
mismatches=$(grep -nE "$PATTERN" "${FILES[@]}")

if [ -n "$mismatches" ]; then
  echo "FAIL — a concrete model name/tag appears in independent-review's pipeline files."
  echo "The skill is model-agnostic: name model FAMILIES or generic tag shapes only, and"
  echo "let the owner's own CLI config/signin choose the actual model:"
  printf '%s\n' "$mismatches" | sed 's/^/    /'
  exit 1
fi

echo "OK — independent-review stays model-agnostic (no concrete model names/tags in its pipeline files)"
