#!/usr/bin/env bash
# Guard: per-skill size budgets. Two budgets per skills/*/SKILL.md:
#   - frontmatter `description` ≤ 1024 CHARACTERS — the skill-spec HARD limit
#     (tooling that indexes skills truncates or rejects longer ones). FAIL when
#     over; warn from 900 so a skill nearing the ceiling is visible before it
#     turns the gate red.
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

# Descriptions allowed over DESC_HARD, each pinned at its measured length so it
# can only shrink. Format "skill-name=maxchars". An entry whose skill drops back
# to ≤ DESC_HARD (or no longer exists) FAILS the check until the entry is
# removed — so the allowlist cleans itself up in the same PR that fixes the
# skill. Never add an entry to turn the gate green; shorten the description.
# All four entries predate this check (2026-08-29) — the debt was found by the
# check, not created by it. A skill-debloat thread trimming descriptions was
# already in flight when the check landed; the trims belong to that thread (or,
# if it never merges, to whoever picks the debt up). Each entry is removed in
# the same PR that lands its skill's trim — the stale-entry FAIL below enforces
# that.
ALLOW_OVER=(
  "search-console-insights=1602"
  "website-review=1312"
  "new-website=1203"
  "internal-link-audit=1031"
)

# The limit counts characters, not bytes — the descriptions are full of
# multi-byte punctuation (em-dashes), so `wc -m` needs a UTF-8 locale. No UTF-8
# locale would mean silently counting bytes; fail instead.
UTF8_LOCALE=""
for loc in C.UTF-8 en_US.UTF-8; do
  if locale -a 2>/dev/null | grep -qixF "$loc"; then UTF8_LOCALE="$loc"; break; fi
done
if [ -z "$UTF8_LOCALE" ]; then
  UTF8_LOCALE=$(locale -a 2>/dev/null | grep -iE '\.utf-?8$' | head -1 || true)
fi
if [ -z "$UTF8_LOCALE" ]; then
  echo "FAIL — no UTF-8 locale on this system; wc -m would count bytes, not characters,"
  echo "and the ${DESC_HARD}-char limit check would over-count. Install/enable one."
  exit 1
fi

chars() { printf '%s' "$1" | LC_ALL="$UTF8_LOCALE" wc -m | tr -d '[:space:]'; }

# Print the YAML-parsed frontmatter description of a SKILL.md. Handles the two
# styles this suite uses: a single-line plain/quoted scalar, and a folded block
# (`>` and friends: lines joined with spaces, blank lines become newlines —
# within ±1 char of a real YAML parser, which may add a trailing newline).
# Anything else (e.g. an unindicated multi-line plain scalar) comes back empty
# and the caller fails loud rather than measuring a truncated string.
desc_of() {
  awk '
    BEGIN { sq=sprintf("%c",39); dq=sprintf("%c",34) }
    NR==1 { if ($0 ~ /^---[ \t]*$/) infm=1; next }
    infm==0 { exit }
    /^---[ \t]*$/ { exit }
    mode=="block" {
      if ($0 ~ /^[ \t]*$/) { blanks++; next }
      if ($0 !~ /^[ \t]/) { exit }
      line=$0; sub(/^[ \t]+/,"",line); sub(/[ \t]+$/,"",line)
      if (desc!="") {
        if (blanks>0) { while (blanks-- > 0) desc=desc "\n" } else desc=desc " "
      }
      desc=desc line; blanks=0
      next
    }
    /^description:/ {
      val=$0; sub(/^description:[ \t]*/,"",val); sub(/[ \t]+$/,"",val)
      if (val==">"||val==">-"||val==">+"||val=="|"||val=="|-"||val=="|+") { mode="block"; next }
      if (length(val)>=2) {
        a=substr(val,1,1); z=substr(val,length(val),1)
        if ((a==sq && z==sq) || (a==dq && z==dq)) val=substr(val,2,length(val)-2)
      }
      desc=val; exit
    }
    END { printf "%s", desc }
  ' "$1"
}

# Self-test on known fixtures before trusting the scan — a guard that miscounts
# is worse than none. Exact-equality assertions catch both under- and
# over-extraction; the em-dash fixture catches byte-instead-of-char counting.
TMP=$(mktemp -d "${TMPDIR:-/tmp}/skill-budgets-selftest.XXXXXX") || {
  echo "FAIL — self-test: could not create a temp dir."; exit 1; }
trap 'rm -rf "$TMP"' EXIT
st_fail() { echo "FAIL — self-test: $1. Fix the parser before trusting the scan."; exit 1; }

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
cat > "$TMP/folded.md" <<'EOF'
---
name: t
description: >
  one two
  three
metadata: x
---
description: not this one
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

n=$(chars "$(desc_of "$TMP/plain.md")")
[ "$n" -eq 5 ] || st_fail "plain description counted $n chars, expected 5"
n=$(chars "$(desc_of "$TMP/quoted.md")")
[ "$n" -eq 7 ] || st_fail "quoted description counted $n chars, expected 7 (quotes stripped)"
[ "$(desc_of "$TMP/folded.md")" = "one two three" ] || \
  st_fail "folded description parsed as '$(desc_of "$TMP/folded.md")', expected 'one two three'"
n=$(chars "$(desc_of "$TMP/folded-utf8.md")")
[ "$n" -eq 7 ] || st_fail "em-dash description counted $n chars, expected 7 — counting bytes, not characters?"
[ -z "$(desc_of "$TMP/nodesc.md")" ] || st_fail "missing description did not come back empty"

# Scan every skill. Glob, not a maintained list, so a new skill is covered by
# default; the floor catches path breakage masquerading as a clean run.
shopt -s nullglob
FILES=(skills/*/SKILL.md)
if [ "${#FILES[@]}" -lt 10 ]; then
  echo "FAIL — only ${#FILES[@]} skills/*/SKILL.md found; path breakage or a moved suite."
  exit 1
fi

fails=0 warns=0 allow_seen=" "
for f in "${FILES[@]}"; do
  skill=${f#skills/}; skill=${skill%/SKILL.md}
  desc=$(desc_of "$f")
  if [ -z "$desc" ]; then
    echo "FAIL — $skill: no frontmatter description found (missing, or a YAML style this parser doesn't know — extend desc_of)."
    fails=1; continue
  fi
  len=$(chars "$desc")
  lines=$(wc -l < "$f" | tr -d '[:space:]')

  cap=""
  for entry in ${ALLOW_OVER[@]+"${ALLOW_OVER[@]}"}; do
    if [ "${entry%%=*}" = "$skill" ]; then cap=${entry#*=}; allow_seen="$allow_seen$skill "; fi
  done

  if [ -n "$cap" ]; then
    if [ "$len" -le "$DESC_HARD" ]; then
      echo "FAIL — $skill: description is ${len} chars, back under the ${DESC_HARD} hard limit — remove its now-stale ALLOW_OVER entry from this script."
      fails=1
    elif [ "$len" -gt "$cap" ]; then
      echo "FAIL — $skill: description grew to ${len} chars, past its pinned ALLOW_OVER cap of ${cap} — allowlisted descriptions may only shrink."
      fails=1
    else
      echo "warn — $skill: description ${len} chars, over the ${DESC_HARD} hard limit but allowlisted (pinned ≤ ${cap}; see the tracking note in this script)."
      warns=1
    fi
  elif [ "$len" -gt "$DESC_HARD" ]; then
    echo "FAIL — $skill: description is ${len} chars — over the ${DESC_HARD}-char skill-spec hard limit. Shorten it (aim under ${DESC_WARN})."
    fails=1
  elif [ "$len" -ge "$DESC_WARN" ]; then
    echo "warn — $skill: description ${len} chars — nearing the ${DESC_HARD}-char hard limit (warning starts at ${DESC_WARN})."
    warns=1
  fi

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
if [ "$warns" -ne 0 ]; then
  echo "OK (with warnings) — no skill over a hard budget, but see the warn lines above (${#FILES[@]} skills checked)."
else
  echo "OK — all ${#FILES[@]} skills within budget (description ≤ ${DESC_HARD} chars, SKILL.md ≤ ${LINES_SOFT} lines)."
fi
