#!/usr/bin/env bash
# SKILL.md quotes PROMPT_CORE for the fresh-eyes pass (tier 3), and the script's tier prompts embed
# it. This fails if the two copies drift, or if a tier prompt stops embedding PROMPT_CORE. It tests
# itself first on mutated copies, because a guard that cannot fire is worse than none.
# Run: bash skills/independent-review/scripts/check_prompt_sync.sh
set -u
here="$(cd "$(dirname "$0")" && pwd)"
SCRIPT="$here/independent_review.sh"; SKILL="$here/../SKILL.md"

norm() { tr -s ' \t\n' '   ' | sed -e 's/^ //' -e 's/ $//'; }
core_of() {  # PROMPT_CORE's text, with ${TYPE} as SKILL.md writes it
  awk '/^PROMPT_CORE="/{p=1; sub(/^PROMPT_CORE="/, "")} p{print} p && /"$/{exit}' "$1" \
    | sed -e 's/"$//' -e 's/\${TYPE}/{plan | diff}/g' | norm
}
quote_of() {  # the blockquote under SKILL.md's "The strict review prompt" heading
  awk '/^## The strict review prompt/{h=1; next} h && /^>/{q=1; sub(/^> ?/, ""); print; next} q{exit}' "$1" | norm
}
check() {  # $1 script, $2 SKILL.md; prints each problem, returns 1 if there is any
  local bad=0 core
  core="$(core_of "$1")"
  [ -n "$core" ] || { echo "PROMPT_CORE not found in $1"; bad=1; }
  [ "$core" = "$(quote_of "$2")" ] || { echo "SKILL.md's strict review prompt differs from PROMPT_CORE"; bad=1; }
  for v in PROMPT_TOOLED PROMPT_TEXTONLY PROMPT_PORTABLE; do
    grep -qF "$v=\"\${PROMPT_CORE}" "$1" || { echo "$v does not begin with \${PROMPT_CORE}"; bad=1; }
  done
  return $bad
}

t="$(mktemp -d)"; trap 'rm -rf "$t"' EXIT
sed 's/Return RANKED/Return RANKD/' "$SKILL" > "$t/SKILL.md"
cmp -s "$SKILL" "$t/SKILL.md" && { echo "FAIL: self-test mutation of SKILL.md did not apply"; exit 1; }
check "$SCRIPT" "$t/SKILL.md" >/dev/null && { echo "FAIL: self-test: a one-word drift in SKILL.md went unnoticed"; exit 1; }
sed 's/^PROMPT_TOOLED="\${PROMPT_CORE}/PROMPT_TOOLED="${OTHER}/' "$SCRIPT" > "$t/script.sh"
cmp -s "$SCRIPT" "$t/script.sh" && { echo "FAIL: self-test mutation of the script did not apply"; exit 1; }
check "$t/script.sh" "$SKILL" >/dev/null && { echo "FAIL: self-test: a tier prompt without PROMPT_CORE went unnoticed"; exit 1; }

if check "$SCRIPT" "$SKILL"; then echo "ok   SKILL.md's prompt matches PROMPT_CORE, and every tier prompt embeds it"; else exit 1; fi
