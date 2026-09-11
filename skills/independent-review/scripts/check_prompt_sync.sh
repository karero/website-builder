#!/usr/bin/env bash
# SKILL.md quotes PROMPT_CORE for the fresh-eyes pass (tier 3), and the script's tier prompts embed
# it. This fails if the two copies drift, if PROMPT_CORE or a tier prompt is assigned more than once
# or PROMPT_CORE comes after PROMPT_TOOLED, or if a tier prompt does not begin with ${PROMPT_CORE}.
# It tests itself first on mutated copies, because a guard that cannot fire is worse than none.
# SKILL.md's copy must stay one contiguous blockquote under its heading.
# Run: bash skills/independent-review/scripts/check_prompt_sync.sh
set -u
here="$(cd "$(dirname "$0")" && pwd)"
SCRIPT="$here/independent_review.sh"; SKILL="$here/../SKILL.md"
TIERS="PROMPT_TOOLED PROMPT_TEXTONLY PROMPT_PORTABLE"

norm() { tr -s ' \t\n' '   ' | sed -e 's/^ //' -e 's/ $//'; }
core_of() {  # PROMPT_CORE's value as bash assigns it, with ${TYPE} as SKILL.md writes it
  local block
  block="$(awk '/^PROMPT_TOOLED=/{exit} /^PROMPT_CORE="/{p=1} p{print}' "$1")"
  [ -n "$block" ] || return 0
  ( TYPE='{plan | diff}'; eval "$block" 2>/dev/null && printf '%s' "${PROMPT_CORE:-}" ) | norm
}
quote_of() {  # the blockquote under SKILL.md's "The strict review prompt" heading
  awk '/^## The strict review prompt/{h=1; next} h && /^>/{q=1; sub(/^> ?/, ""); print; next} q{exit}' "$1" | norm
}
assignments() { grep -cE "^[[:space:]]*(export[[:space:]]+)?$2\+?=" "$1"; }
check() {  # $1 script, $2 SKILL.md; prints each problem, returns 1 if there is any
  local bad=0 core v n
  n=$(assignments "$1" PROMPT_CORE)
  [ "$n" = 1 ] || { echo "PROMPT_CORE is assigned $n times; expected once"; bad=1; }
  core="$(core_of "$1")"
  [ -n "$core" ] || { echo "PROMPT_CORE not found before PROMPT_TOOLED in $1"; bad=1; }
  [ "$core" = "$(quote_of "$2")" ] || { echo "SKILL.md's strict review prompt differs from PROMPT_CORE"; bad=1; }
  for v in $TIERS; do
    n=$(assignments "$1" "$v")
    [ "$n" = 1 ] || { echo "$v is assigned $n times; expected once"; bad=1; }
    grep -qF "$v=\"\${PROMPT_CORE}" "$1" || { echo "$v does not begin with \${PROMPT_CORE}"; bad=1; }
  done
  return $bad
}

t="$(mktemp -d)"; trap 'rm -rf "$t"' EXIT
fires() {  # $1 what was changed, $2 script, $3 SKILL.md: the check must fail on them
  check "$2" "$3" >/dev/null && { echo "FAIL: self-test: $1 went unnoticed"; exit 1; }
  return 0
}
awk '/^## The strict review prompt/{h=1} h && /^> [^ ]/ && !d {sub(/^> [^ ]+/, "> DRIFTED"); d=1} {print}' "$SKILL" > "$t/SKILL.md"
cmp -s "$SKILL" "$t/SKILL.md" && { echo "FAIL: self-test could not mutate SKILL.md"; exit 1; }
fires "a one-word drift in SKILL.md's copy" "$SCRIPT" "$t/SKILL.md"
sed 's/^PROMPT_TOOLED="\${PROMPT_CORE}/PROMPT_TOOLED="${OTHER}/' "$SCRIPT" > "$t/a.sh"
cmp -s "$SCRIPT" "$t/a.sh" && { echo "FAIL: self-test could not mutate the tier prompt"; exit 1; }
fires "a tier prompt without PROMPT_CORE" "$t/a.sh" "$SKILL"
{ cat "$SCRIPT"; echo 'PROMPT_TOOLED="Review this diff."'; } > "$t/b.sh"
fires "a later assignment of a tier prompt" "$t/b.sh" "$SKILL"
{ cat "$SCRIPT"; echo 'PROMPT_CORE="something else"'; } > "$t/c.sh"
fires "a second PROMPT_CORE assignment" "$t/c.sh" "$SKILL"

if check "$SCRIPT" "$SKILL"; then
  echo "ok   SKILL.md's prompt matches PROMPT_CORE; PROMPT_CORE and every tier prompt are assigned once, and each tier embeds it"
else
  exit 1
fi
