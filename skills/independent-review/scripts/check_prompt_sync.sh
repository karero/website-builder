#!/usr/bin/env bash
# SKILL.md quotes PROMPT_CORE for the fresh-eyes pass (tier 3), and the script's tier prompts embed
# it. This fails if the two copies drift, if PROMPT_CORE or a tier prompt is assigned more than once
# or PROMPT_CORE comes after a tier prompt, or if a tier prompt's LIVE assignment does not begin
# with ${PROMPT_CORE} — a commented-out correct line does not satisfy it.
# It tests itself first on mutated copies, because a guard that cannot fire is worse than none.
# SKILL.md's copy is every blockquote line under its heading, up to the next heading.
# Run: bash skills/independent-review/scripts/check_prompt_sync.sh
set -u
here="$(cd "$(dirname "$0")" && pwd)"
SCRIPT="$here/independent_review.sh"; SKILL="$here/../SKILL.md"
TIERS="PROMPT_TOOLED PROMPT_TEXTONLY PROMPT_PORTABLE"

# Counting assignments by recognising shell syntax was an arms race and lost it twice: a
# declaring keyword with options (`declare -x X=`) and then a conditional (`if true; then X=`;
# round 2, Codex) each slipped past a pattern that had just been widened for the previous one.
# The rule is now conservative instead of clever: on any line that is not a whole-line comment,
# ANY textual occurrence of the name followed by `=` or `+=` counts. Every syntax that assigns
# contains one, whatever the surrounding shape, so nothing can hide behind `then`, `do`, `eval`
# or a keyword yet to be thought of. It over-counts a mention inside a string, which fails the
# check rather than passing it -- the safe direction for a guard.
uncommented() { grep -vE '^[[:space:]]*#' "$1"; }
assignments() { uncommented "$1" | grep -oE "$2\+?=" | wc -l | tr -d ' '; }
assign_line() {  # line number of the first occurrence of $2 being assigned, or empty
  uncommented "$1" | grep -nE "$2\+?=" | head -1 | cut -d: -f1
}

norm() { tr -s ' \t\n' '   ' | sed -e 's/^ //' -e 's/ $//'; }
core_of() {  # PROMPT_CORE's value as bash assigns it, with ${TYPE} as SKILL.md writes it.
  # Extracts the ONE assignment, not a range: lines are taken from `PROMPT_CORE="` until the
  # double quotes balance, so no code that happens to sit between the prompts is ever evaluated.
  # Balancing alone is NOT enough — `PROMPT_CORE="ok"; cmd` balances on its own line and used to
  # run cmd (Codex, round 13). So the block must be the assignment and NOTHING else, and must
  # carry no command substitution, before it is evaluated. Anything else yields no core, which
  # fails the check rather than passing it.
  local block
  block="$(awk '
    /^PROMPT_CORE="/ && !p { p = 1 }
    p {
      print
      line = $0
      gsub(/\\\\/, "", line); gsub(/\\"/, "", line)
      n = gsub(/"/, "\"", line); q += n
      if (q % 2 == 0) exit
    }' "$1")"
  [ -n "$block" ] || return 0
  printf '%s' "$block" | perl -0777 -ne '
    exit 1 unless /\APROMPT_CORE="((?:[^"\\]|\\.)*)"\s*\z/s;   # the assignment, and nothing after it
    exit 1 if $1 =~ /\$\(|`/;                                 # no command substitution to evaluate
    exit 0' || return 0
  ( TYPE='{plan | diff}'; eval "$block" 2>/dev/null && printf '%s' "${PROMPT_CORE:-}" ) | norm
}
quote_of() {  # every blockquote line under SKILL.md's "The strict review prompt" heading
  awk '/^## The strict review prompt/{h=1; next} h && /^#/{exit} h && /^>/{sub(/^> ?/, ""); print}' "$1" | norm
}
check() {  # $1 script, $2 SKILL.md; prints each problem, returns 1 if there is any
  local bad=0 core v n cl vl
  n=$(assignments "$1" PROMPT_CORE)
  [ "$n" = 1 ] || { echo "PROMPT_CORE is assigned $n times; expected once"; bad=1; }
  core="$(core_of "$1")"
  [ -n "$core" ] || { echo "PROMPT_CORE not found in $1"; bad=1; }
  [ -n "$core" ] && [ "$core" = "$(quote_of "$2")" ] || { echo "SKILL.md's strict review prompt differs from PROMPT_CORE"; bad=1; }
  cl=$(assign_line "$1" PROMPT_CORE)
  for v in $TIERS; do
    n=$(assignments "$1" "$v")
    [ "$n" = 1 ] || { echo "$v is assigned $n times; expected once"; bad=1; }
    uncommented "$1" | grep -qE "^[[:space:]]*$v=\"\\\$\{PROMPT_CORE\}" || { echo "$v does not begin with \${PROMPT_CORE}"; bad=1; }
    vl=$(assign_line "$1" "$v")
    [ -n "$cl" ] && [ -n "$vl" ] && [ "$cl" -lt "$vl" ] || { echo "PROMPT_CORE is not assigned before $v"; bad=1; }
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
# drift in a LATER blockquote line, which a first-blockquote-only comparison would miss
awk '/^## The strict review prompt/{h=1} h && /^> The \{plan/ && !d {print "> DRIFTED"; d=1; next} {print}' "$SKILL" > "$t/SKILL2.md"
cmp -s "$SKILL" "$t/SKILL2.md" && { echo "FAIL: self-test could not mutate SKILL.md's later paragraph"; exit 1; }
fires "a drift in SKILL.md's second paragraph" "$SCRIPT" "$t/SKILL2.md"
sed 's/^PROMPT_TOOLED="\${PROMPT_CORE}/PROMPT_TOOLED="${OTHER}/' "$SCRIPT" > "$t/a.sh"
cmp -s "$SCRIPT" "$t/a.sh" && { echo "FAIL: self-test could not mutate the tier prompt"; exit 1; }
fires "a tier prompt without PROMPT_CORE" "$t/a.sh" "$SKILL"
{ cat "$SCRIPT"; echo 'PROMPT_TOOLED="Review this diff."'; } > "$t/b.sh"
fires "a later assignment of a tier prompt" "$t/b.sh" "$SKILL"
{ cat "$SCRIPT"; echo 'PROMPT_CORE="something else"'; } > "$t/c.sh"
fires "a second PROMPT_CORE assignment" "$t/c.sh" "$SKILL"
# the hole this check was fooled by: a commented-out correct line above a live wrong one
sed 's/^PROMPT_TEXTONLY="\${PROMPT_CORE}/# PROMPT_TEXTONLY="${PROMPT_CORE}\
PROMPT_TEXTONLY="detached/' "$SCRIPT" > "$t/d.sh"
cmp -s "$SCRIPT" "$t/d.sh" && { echo "FAIL: self-test could not comment out the tier prompt"; exit 1; }
fires "a commented-out tier prompt above a live one that drops PROMPT_CORE" "$t/d.sh" "$SKILL"
# other assignment forms, which a line-start-only count misses
{ cat "$SCRIPT"; echo 'declare PROMPT_TOOLED="Review this diff."'; } > "$t/e.sh"
fires "a later 'declare' assignment of a tier prompt" "$t/e.sh" "$SKILL"
{ cat "$SCRIPT"; echo ':; PROMPT_TOOLED="Review this diff."'; } > "$t/f.sh"
fires "a later ';'-prefixed assignment of a tier prompt" "$t/f.sh" "$SKILL"
# a conditional, which no widening of a statement-shape pattern had caught (round 2, Codex)
{ cat "$SCRIPT"; echo 'if true; then PROMPT_TOOLED="detached"; fi'; } > "$t/m.sh"
fires "a later conditional assignment of a tier prompt" "$t/m.sh" "$SKILL"
{ cat "$SCRIPT"; printf '\tPROMPT_TOOLED="Review this diff."\n'; } > "$t/i.sh"
fires "a later indented assignment of a tier prompt" "$t/i.sh" "$SKILL"
# a declaring keyword carrying OPTIONS -- bash really does reassign here (round 13, Codex)
{ cat "$SCRIPT"; echo 'declare -x PROMPT_TOOLED="detached"'; } > "$t/j.sh"
fires "a later 'declare -x' assignment of a tier prompt" "$t/j.sh" "$SKILL"
# a command on the SAME line as the assignment: quote-balancing alone would evaluate it
{ echo 'PROMPT_CORE="ok"; printf "SIDE_EFFECT\n"'; cat "$SCRIPT"; } > "$t/k.sh"
fires "a command trailing PROMPT_CORE's own line" "$t/k.sh" "$SKILL"
# command substitution inside the prompt text, which eval would run
sed 's/^PROMPT_CORE="Adversarial/PROMPT_CORE="$(id) Adversarial/' "$SCRIPT" > "$t/l.sh"
cmp -s "$SCRIPT" "$t/l.sh" && { echo "FAIL: self-test could not inject a substitution"; exit 1; }
fires "command substitution inside PROMPT_CORE" "$t/l.sh" "$SKILL"
# PROMPT_CORE moved after the tier prompts: still assigned once, still quoted correctly,
# but every tier would expand it empty under `set -u`-free expansion
awk '/^PROMPT_CORE="/{p=1} p{core = core $0 "\n"; if ($0 ~ /not an attack\."$/) p=0; next} {print} END{printf "%s", core}' "$SCRIPT" > "$t/g.sh"
grep -q '^PROMPT_TOOLED=' "$t/g.sh" || { echo "FAIL: self-test could not move PROMPT_CORE"; exit 1; }
fires "PROMPT_CORE moved after the tier prompts" "$t/g.sh" "$SKILL"
# PROMPT_CORE deleted outright
awk '/^PROMPT_CORE="/{p=1} p{if ($0 ~ /not an attack\."$/) p=0; next} {print}' "$SCRIPT" > "$t/h.sh"
grep -q '^PROMPT_CORE=' "$t/h.sh" && { echo "FAIL: self-test could not delete PROMPT_CORE"; exit 1; }
fires "PROMPT_CORE deleted" "$t/h.sh" "$SKILL"

if check "$SCRIPT" "$SKILL"; then
  echo "ok   SKILL.md's prompt matches PROMPT_CORE; PROMPT_CORE and every tier prompt are assigned once, core first, and each tier embeds it"
else
  exit 1
fi
