#!/usr/bin/env bash
# Guard: independent-review is model-AGNOSTIC — the pipeline prescribes no specific LLM.
# The ollama tier auto-detects the owner's signed-in ':cloud' model, Codex and Antigravity
# use their own CLI-configured defaults, and the docs speak in families and generic tags.
# A hardcoded default is exactly how the ollama tier once drifted out of sync with the
# owner's real setup (this script's pre-2026-08-29 ancestor, check_model_defaults.sh,
# managed that drift; this version prevents the class).
set -uo pipefail
cd "$(dirname "$0")/.."

SKILL_DIR="skills/independent-review"

# Scan every doc and script in the skill EXCEPT references/setup-guide.md — the
# drift-prone helper that cites dated, concrete local-model examples for the RAM
# table, and says so inline. Files are discovered, not listed, so a new reference
# or script is scanned by default instead of silently skipped.
FILES=()
while IFS= read -r f; do FILES+=("$f"); done < <(
  find "$SKILL_DIR" -type f \( -name '*.md' -o -name '*.sh' \) ! -name 'setup-guide.md' | sort
)
if [ "${#FILES[@]}" -lt 4 ]; then
  echo "FAIL — expected at least 4 pipeline files under $SKILL_DIR, found ${#FILES[@]}."
  echo "If the skill moved or was restructured, update this check."
  exit 1
fi

# Tripwire for the common shapes of concrete model names: named ollama tags
# (word:cloud, word:<size>b) and versioned family names, any case. Family names
# WITHOUT a version (Gemini, GLM, gpt-class, Claude) stay allowed — the
# Independence rule classifies by family. A regex cannot catch every conceivable
# model name; this bounds the common drift, it is not an exhaustive parser.
PATTERN='[a-z0-9][a-z0-9._-]*:(cloud|[0-9]+b)\b|\bglm-[0-9]|\bgpt-[0-9]|\bgemini[- ][0-9]|\bclaude[- ][0-9]|\b(opus|sonnet|haiku|fable)[- ][0-9]'

# Self-test: the pattern must actually catch the shapes it claims to — a guard
# that cannot fire is worse than none.
for bad in 'glm-9.9-flash:cloud' 'somemodel:120b' 'GPT-5' 'gpt-5.6-sol' \
           'Gemini 3.1 Pro' 'Claude Opus 4.6' 'claude-3' 'a Sonnet 4 pass'; do
  printf '%s\n' "$bad" | grep -qiE "$PATTERN" || {
    echo "FAIL — self-test: PATTERN misses '$bad'. Fix the pattern before trusting the scan."
    exit 1
  }
done

mismatches=$(grep -niE "$PATTERN" "${FILES[@]}")

if [ -n "$mismatches" ]; then
  echo "FAIL — a concrete model name/tag appears in independent-review's pipeline files."
  echo "The skill is model-agnostic: name model FAMILIES or generic tag shapes only, and"
  echo "let the owner's own CLI config/signin choose the actual model:"
  printf '%s\n' "$mismatches" | sed 's/^/    /'
  exit 1
fi

echo "OK — independent-review stays model-agnostic (no concrete model names/tags in its ${#FILES[@]} pipeline files)"
