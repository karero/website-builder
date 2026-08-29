#!/usr/bin/env bash
# Guard: per-skill size budgets. Two budgets per skills/*/SKILL.md:
#   - frontmatter `description` ≤ 1024 CHARACTERS — the skill-spec HARD limit
#     (tooling that indexes skills truncates or rejects longer ones). FAIL when
#     over; warn from 900 so a skill nearing the ceiling is visible before it
#     turns the gate red. Pre-existing overages are allowlisted below,
#     shrink-only, so the gate can land without blocking unrelated work while
#     still refusing NEW violations and any growth of the old ones.
#   - SKILL.md ≤ 500 lines — the skill-authoring guideline. SOFT budget: warn
#     only, never fail — an over-long body degrades quality, not loading, and
#     two shipped skills already sit over it while being slimmed down.
# Added 2026-08-29 after the skill-debloat review (finding D15): one description
# had silently grown ~60% past the hard limit with nothing in place to catch it.
set -uo pipefail
cd "$(dirname "$0")/.."

DESC_HARD=1024
DESC_WARN=900
LINES_SOFT=500
MIN_SKILLS=10

# All four entries predate this check (2026-08-29) — the debt was found by the
# check, not created by it. A skill-debloat thread trimming descriptions was
# already in flight when the check landed; the trims belong to that thread (or,
# if it never merges, to whoever picks the debt up). Each entry is removed in
# the same PR that lands its skill's trim — the stale-entry FAIL below enforces
# that. Caps are the YAML-parsed value lengths (see desc_of), verified against
# a real YAML parser on 2026-08-29.
ALLOW_OVER=(
  "search-console-insights=1603"
  "website-review=1313"
  "new-website=1204"
  "internal-link-audit=1032"
)

# The limit counts characters, not bytes — the descriptions are full of
# multi-byte punctuation (em-dashes), so `wc -m` needs a UTF-8 locale. No UTF-8
# locale would mean silently counting bytes; fail instead. The list is captured
# once and matched via herestrings so pipefail can never eat a genuine match.
LOCALES=$(locale -a 2>/dev/null || true)
UTF8_LOCALE=""
for loc in C.UTF-8 C.utf8 en_US.UTF-8 en_US.utf8; do
  if grep -qixF "$loc" <<<"$LOCALES"; then UTF8_LOCALE="$loc"; break; fi
done
if [ -z "$UTF8_LOCALE" ]; then
  UTF8_LOCALE=$(grep -iE '\.utf-?8$' <<<"$LOCALES" | head -1 || true)
fi
if [ -z "$UTF8_LOCALE" ]; then
  echo "FAIL — no UTF-8 locale on this system; wc -m would count bytes, not characters,"
  echo "and the ${DESC_HARD}-char limit check would over-count. Install/enable one."
  exit 1
fi

chars() { printf '%s' "$1" | LC_ALL="$UTF8_LOCALE" wc -m | tr -d '[:space:]'; }

# Print the YAML-parsed frontmatter description of a SKILL.md, exactly as a
# real YAML parser would return it: single-line plain/quoted scalars verbatim
# (quotes stripped), folded blocks (`>`/`>-`) with lines joined by spaces and
# blank lines as newlines, literal blocks (`|`/`|-`) likewise — the space-vs-
# newline difference is one character either way, so counts are unaffected —
# and clip chomping (`>`/`|`) contributes its trailing newline. Anything else
# comes back EMPTY so the caller fails loud instead of measuring a truncated
# string: a continuation line after a single-line scalar (multi-line
# plain/quoted style), keep chomping (`>+`/`|+`), or a block header beyond the
# four bare forms (indentation indicators like `>2`, trailing comments).
# Quoted-scalar escapes and trailing `#` comments on plain scalars are counted
# as content — an over-count only, so the error direction is conservative (can
# false-FAIL near the boundary, never false-pass).
#
# The output can END IN A NEWLINE (clip chomping), which $(...) strips — every
# caller must capture with the x-sentinel idiom:
#   d=$(desc_of "$f"; printf x); d=${d%x}
desc_of() {
  awk '
    BEGIN { sq=sprintf("%c",39); dq=sprintf("%c",34) }
    NR==1 { if ($0 ~ /^---[ \t\r]*$/) infm=1; next }
    infm==0 { exit }
    captured==1 {
      if ($0 ~ /^[ \t]+[^ \t]/) desc=""
      exit
    }
    /^---[ \t\r]*$/ { exit }
    mode=="block" {
      if ($0 ~ /^[ \t\r]*$/) { blanks++; next }
      if ($0 !~ /^[ \t]/) { exit }
      line=$0; sub(/^[ \t]+/,"",line); sub(/[ \t\r]+$/,"",line)
      if (desc!="") {
        if (blanks>0) { while (blanks-- > 0) desc=desc "\n" } else desc=desc " "
      }
      desc=desc line; blanks=0
      next
    }
    /^description:/ {
      val=$0; sub(/^description:[ \t]*/,"",val); sub(/[ \t\r]+$/,"",val)
      if (val==">"  || val=="|")  { mode="block"; clip=1; next }
      if (val==">-" || val=="|-") { mode="block"; clip=0; next }
      a=substr(val,1,1)
      if (a==">" || a=="|") { desc=""; exit }
      if (length(val)>=2) {
        z=substr(val,length(val),1)
        if ((a==sq && z==sq) || (a==dq && z==dq)) val=substr(val,2,length(val)-2)
      }
      desc=val; captured=1; next
    }
    END {
      if (mode=="block" && clip==1 && desc!="") desc=desc "\n"
      printf "%s", desc
    }
  ' "$1"
}

# Verdict for one skill description against the budgets and its optional
# allowlist entry. Prints findings; bumps the fails/warns/allowed_over globals.
# Kept as a function so the self-test below can drive the enforcement logic
# directly.
judge_desc() { # <skill> <len> <allowed:yes|no> <cap>
  local skill=$1 len=$2 allowed=$3 cap=$4
  if [ "$allowed" = yes ]; then
    case "$cap" in
      ''|*[!0-9]*)
        echo "FAIL — $skill: malformed ALLOW_OVER cap '$cap' — the entry must be \"skill-name=<number>\"; fix it."
        fails=1; return ;;
    esac
    if [ "$cap" -le "$DESC_HARD" ]; then
      echo "FAIL — $skill: ALLOW_OVER cap ${cap} is not above the ${DESC_HARD} hard limit — a pin at or under the limit is meaningless; remove the entry."
      fails=1
    elif [ "$len" -le "$DESC_HARD" ]; then
      echo "FAIL — $skill: description is ${len} chars, back under the ${DESC_HARD} hard limit — remove its now-stale ALLOW_OVER entry from this script."
      fails=1
    elif [ "$len" -gt "$cap" ]; then
      echo "FAIL — $skill: description grew to ${len} chars, past its pinned ALLOW_OVER cap of ${cap} — allowlisted descriptions may only shrink."
      fails=1
    else
      echo "warn — $skill: description ${len} chars, over the ${DESC_HARD} hard limit but allowlisted (pinned ≤ ${cap}; see the tracking note in this script)."
      warns=1; allowed_over=$((allowed_over+1))
    fi
  elif [ "$len" -gt "$DESC_HARD" ]; then
    echo "FAIL — $skill: description is ${len} chars — over the ${DESC_HARD}-char skill-spec hard limit. Shorten it (aim under ${DESC_WARN})."
    fails=1
  elif [ "$len" -ge "$DESC_WARN" ]; then
    echo "warn — $skill: description ${len} chars — nearing the ${DESC_HARD}-char hard limit (warning starts at ${DESC_WARN})."
    warns=1
  fi
}

# Self-test on known fixtures before trusting the scan — a guard that miscounts
# is worse than none. Exact-equality assertions catch both under- and
# over-extraction; the em-dash fixture catches byte-instead-of-char counting;
# the judge_desc calls catch enforcement regressions (dead pins, inverted
# comparisons, boundary drift). Only the stale/unknown-entry loop at the bottom
# is not driven here — it was hand-verified and is plain set logic.
TMP=$(mktemp -d "${TMPDIR:-/tmp}/skill-budgets-selftest.XXXXXX") || {
  echo "FAIL — self-test: could not create a temp dir."; exit 1; }
trap 'rm -rf "$TMP"' EXIT
st_fail() { echo "FAIL — self-test: $1. Fix the script before trusting the scan."; exit 1; }
# Character count of a fixture's description. Counts are computed HERE, inside
# one function, because a nested $(...) around the description itself would
# strip the clip-chomp trailing newline the sentinel just preserved.
st_len() { local out; out=$(desc_of "$1"; printf x); out=${out%x}; chars "$out"; }

cat > "$TMP/plain.md" <<'EOF'
---
name: t
description: abcde
---
body
EOF
cat > "$TMP/quoted.md" <<'EOF'
---
name: t
description: "abc def"
---
EOF
cat > "$TMP/folded-clip.md" <<'EOF'
---
name: t
description: >
  one two
  three
metadata: x
---
description: not this one
EOF
cat > "$TMP/folded-strip.md" <<'EOF'
---
name: t
description: >-
  one two
  three
---
EOF
cat > "$TMP/literal-clip.md" <<'EOF'
---
name: t
description: |
  one two
  three
---
EOF
cat > "$TMP/folded-utf8.md" <<'EOF'
---
name: t
description: >
  a — b

  c
---
EOF
cat > "$TMP/nodesc.md" <<'EOF'
---
name: t
---
EOF
cat > "$TMP/multiline-plain.md" <<'EOF'
---
name: t
description: first line
  silently-truncated continuation
---
EOF
cat > "$TMP/block-indicator.md" <<'EOF'
---
name: t
description: >2
  never measured
---
EOF
cat > "$TMP/keep-chomp.md" <<'EOF'
---
name: t
description: >+
  never measured
---
EOF
printf -- '---\r\nname: t\r\ndescription: abc\r\n---\r\n' > "$TMP/crlf.md"

n=$(st_len "$TMP/plain.md")
[ "$n" -eq 5 ] || st_fail "plain description counted $n chars, expected 5"
n=$(st_len "$TMP/quoted.md")
[ "$n" -eq 7 ] || st_fail "quoted description counted $n chars, expected 7 (quotes stripped)"
[ "$(desc_of "$TMP/folded-strip.md")" = "one two three" ] || \
  st_fail "strip-chomped folded description parsed wrong, expected exactly 'one two three'"
n=$(st_len "$TMP/folded-clip.md")
[ "$n" -eq 14 ] || st_fail "clip-chomped folded description counted $n chars, expected 14 (13 + trailing newline)"
n=$(st_len "$TMP/literal-clip.md")
[ "$n" -eq 14 ] || st_fail "literal block counted $n chars, expected 14 — space-vs-newline join must be count-neutral"
n=$(st_len "$TMP/folded-utf8.md")
[ "$n" -eq 8 ] || st_fail "em-dash description counted $n chars, expected 8 — counting bytes, not characters?"
n=$(st_len "$TMP/crlf.md")
[ "$n" -eq 3 ] || st_fail "CRLF file counted $n chars, expected 3 — CR handling broke"
[ -z "$(desc_of "$TMP/nodesc.md")" ] || st_fail "missing description did not come back empty"
[ -z "$(desc_of "$TMP/multiline-plain.md")" ] || \
  st_fail "multi-line plain description was silently truncated instead of coming back empty"
[ -z "$(desc_of "$TMP/block-indicator.md")" ] || \
  st_fail "unrecognized block header (>2) was measured as a scalar instead of coming back empty"
[ -z "$(desc_of "$TMP/keep-chomp.md")" ] || \
  st_fail "keep chomping (>+) was measured instead of refused"

fails=0 warns=0 allowed_over=0
judge_desc t 899  no  ""     >/dev/null
[ "$fails" -eq 0 ] && [ "$warns" -eq 0 ] || st_fail "in-budget description tripped judge_desc"
judge_desc t 900  no  ""     >/dev/null
[ "$warns" -eq 1 ] || st_fail "description at DESC_WARN did not warn"
fails=0 warns=0
judge_desc t 1024 no  ""     >/dev/null
[ "$fails" -eq 0 ] && [ "$warns" -eq 1 ] || st_fail "description at exactly DESC_HARD must warn, not fail"
fails=0 warns=0
judge_desc t 1025 no  ""     >/dev/null
[ "$fails" -eq 1 ] || st_fail "over-limit description did not fail"
fails=0 warns=0 allowed_over=0
judge_desc t 1500 yes 1600   >/dev/null
[ "$fails" -eq 0 ] && [ "$warns" -eq 1 ] && [ "$allowed_over" -eq 1 ] || \
  st_fail "allowlisted under-cap description did not warn cleanly"
fails=0 warns=0
judge_desc t 1700 yes 1600   >/dev/null
[ "$fails" -eq 1 ] || st_fail "description grown past its pin did not fail"
fails=0 warns=0
judge_desc t 1000 yes 1600   >/dev/null
[ "$fails" -eq 1 ] || st_fail "stale (back-under-limit) allowlist entry did not fail"
fails=0 warns=0
judge_desc t 1500 yes "13l2" >/dev/null
[ "$fails" -eq 1 ] || st_fail "malformed allowlist cap did not fail (pin would be silently dead)"
fails=0 warns=0
judge_desc t 1500 yes 1000   >/dev/null
[ "$fails" -eq 1 ] || st_fail "allowlist cap at/under DESC_HARD did not fail"

# Scan every skill. Glob, not a maintained list, so a new skill is covered by
# default; the floor catches path breakage masquerading as a clean run, and the
# directory sweep catches a skill directory whose SKILL.md is missing (which
# the glob alone would silently skip).
shopt -s nullglob
FILES=(skills/*/SKILL.md)
if [ "${#FILES[@]}" -lt "$MIN_SKILLS" ]; then
  echo "FAIL — only ${#FILES[@]} skills/*/SKILL.md found (floor ${MIN_SKILLS}); path breakage or a moved suite."
  echo "If the suite was deliberately reduced below ${MIN_SKILLS} skills, lower MIN_SKILLS in the same PR."
  exit 1
fi

fails=0 warns=0 allowed_over=0 allow_seen=" "
for d in skills/*/; do
  if [ ! -f "${d}SKILL.md" ]; then
    echo "FAIL — ${d%/}: no SKILL.md — the budget scan cannot see this skill at all."
    fails=1
  fi
done

for f in "${FILES[@]}"; do
  skill=${f#skills/}; skill=${skill%/SKILL.md}

  allowed=no cap=""
  for entry in ${ALLOW_OVER[@]+"${ALLOW_OVER[@]}"}; do
    if [ "${entry%%=*}" = "$skill" ]; then
      allowed=yes; cap=${entry#*=}
      [ "$cap" = "$entry" ] && cap=""   # entry has no '=' at all
      allow_seen="$allow_seen$skill "
    fi
  done

  desc=$(desc_of "$f"; printf x); desc=${desc%x}
  if [ -z "$desc" ]; then
    echo "FAIL — $skill: no measurable frontmatter description (missing, or a YAML style this parser refuses — see desc_of)."
    fails=1; continue
  fi
  judge_desc "$skill" "$(chars "$desc")" "$allowed" "$cap"

  lines=$(awk 'END{print NR}' "$f")
  if [ "$lines" -gt "$LINES_SOFT" ]; then
    echo "warn — $skill: SKILL.md is ${lines} lines — over the ${LINES_SOFT}-line soft budget; move detail to references/."
    warns=1
  fi
done

for entry in ${ALLOW_OVER[@]+"${ALLOW_OVER[@]}"}; do
  name=${entry%%=*}
  case "$allow_seen" in *" $name "*) ;; *)
    echo "FAIL — ALLOW_OVER entry '$name' matches no skill — remove or fix the entry."
    fails=1 ;;
  esac
done

if [ "$fails" -ne 0 ]; then
  exit 1
fi
if [ "$allowed_over" -ne 0 ]; then
  echo "OK (gate passes) — no new violations; ${allowed_over} pre-existing over-limit description(s) remain allowlisted, shrink-only (${#FILES[@]} skills checked, see warn lines above)."
elif [ "$warns" -ne 0 ]; then
  echo "OK (with warnings) — no skill over a hard budget; see the warn lines above (${#FILES[@]} skills checked)."
else
  echo "OK — all ${#FILES[@]} skills within budget (description ≤ ${DESC_HARD} chars, SKILL.md ≤ ${LINES_SOFT} lines)."
fi
