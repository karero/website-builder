#!/usr/bin/env bash
#
# test_whats_new_removed_skill.sh — drives scripts/whats-new.sh against throwaway sites, one
# of which bundles a skill the suite has since removed.
#
# Why it exists: for such a site the report listed the skill like any other update and told
# the reader to refresh. `--refresh` then stopped with "removed upstream" and left the stamp
# where it was, so the same report came back every time and only the error said how to end
# it (delete the copy, or list it in REFRESH-KEEP). These cases pin what the report says for
# a removed skill, that the two ways out still work, and that a site with only ordinary
# updates reads exactly as before.
#
# It enters the way a reader does: it runs whats-new.sh on a site folder, and judges what
# the report prints and what exit status and stamp come back.
#
# Usage: bash scripts/test_whats_new_removed_skill.sh
set -u
if ! command -v git >/dev/null 2>&1; then
  # A zip recipient without git should not fail `make check` over this test.
  echo "SKIP: test_whats_new_removed_skill.sh needs git (it builds a throwaway suite and sites)"
  exit 0
fi
HERE="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
T="$(mktemp -d "${TMPDIR:-/tmp}/whats-new-removed.XXXXXX")"
trap 'rm -rf "$T"' EXIT
# Hermetic: a developer's global commit.gpgsign, hooksPath or templateDir must not decide
# whether this test passes.
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null
git="git -c user.name=t -c user.email=t@t -c init.defaultBranch=main -c commit.gpgsign=false -c core.hooksPath=/dev/null"
fails=0
check() { if "${@:2}"; then printf 'ok   %s\n' "$1"; else printf 'FAIL %s\n' "$1"; fails=$((fails+1)); fi; }
has() { grep -Fq -- "$2" <<<"$1"; }          # has "$text" "needle"
lacks() { ! grep -Fq -- "$2" <<<"$1"; }

# A suite with three skills. Its second commit edits alpha and removes beta.
SUITE="$T/suite"
mkdir -p "$SUITE/scripts" "$SUITE/skills/alpha" "$SUITE/skills/beta" "$SUITE/skills/gamma"
cp "$HERE/whats-new.sh" "$SUITE/scripts/whats-new.sh"
for s in alpha beta gamma; do printf '# %s\n' "$s" > "$SUITE/skills/$s/SKILL.md"; done
$git -C "$SUITE" init -q && $git -C "$SUITE" add -A && $git -C "$SUITE" commit -q -m "three skills"
OLD="$($git -C "$SUITE" rev-parse HEAD)"
printf '# alpha, edited\n' > "$SUITE/skills/alpha/SKILL.md"
$git -C "$SUITE" rm -q -r skills/beta && $git -C "$SUITE" add -A && $git -C "$SUITE" commit -q -m "edit alpha, remove beta"
NEW="$($git -C "$SUITE" rev-parse HEAD)"
WN="$SUITE/scripts/whats-new.sh"

# make_site <name> <skill>... — a site repo that bundles those skills as the suite had them
# at OLD, stamped at OLD. Prints the site folder.
make_site() {
  local name="$1" d s; shift
  d="$T/$name"; mkdir -p "$d/.claude/skills"
  for s in "$@"; do
    mkdir -p "$d/.claude/skills/$s"
    $git -C "$SUITE" show "$OLD:skills/$s/SKILL.md" > "$d/.claude/skills/$s/SKILL.md"
  done
  printf 'suite_commit: %s\ncopied: 2026-10-01\n' "$OLD" > "$d/.claude/skills/SUITE-VERSION"
  $git -C "$d" init -q && $git -C "$d" add -A && $git -C "$d" commit -q -m site
  printf '%s' "$d"
}
stamp() { sed -n 's/^suite_commit: //p' "$1/.claude/skills/SUITE-VERSION"; }

# --- 1. only a removed skill: the report names it and both ways out, and no refresh to run
S1="$(make_site gone beta)"
out="$(bash "$WN" "$S1" 2>&1)"; rc=$?
check "report: exit status 0"                                  test "$rc" -eq 0
check "report: a removed skill is marked removed upstream"      has "$out" "beta   (removed upstream"
check "report: names REFRESH-KEEP as the way to keep it"        has "$out" "REFRESH-KEEP"
check "report: says its files stay in the site, unmaintained"   has "$out" "unmaintained"
check "report: does not tell the reader to refresh"             lacks "$out" "Refresh them"
check "report: prints no --refresh command to run"              lacks "$out" "scripts/whats-new.sh --refresh"

# --- 2. --refresh on that site still stops, keeps the stamp, and names the way out
out="$(bash "$WN" --refresh "$S1" 2>&1)"; rc=$?
check "refresh: stops with exit status 1"                       test "$rc" -eq 1
check "refresh: leaves the stamp where it was"                  test "$(stamp "$S1")" = "$OLD"
check "refresh: the error names REFRESH-KEEP"                   has "$out" "list it in"

# --- 3. a removed skill and an updated one: both said, and a refresh for the rest
S3="$(make_site mixed alpha beta)"
out="$(bash "$WN" "$S3" 2>&1)"; rc=$?
check "mixed: alpha is listed as an ordinary update"            has "$out" "  alpha"
check "mixed: beta is marked removed upstream"                  has "$out" "beta   (removed upstream"
check "mixed: refresh is offered for the rest"                  has "$out" "refresh the rest"
check "mixed: the --refresh command is printed"                 has "$out" "scripts/whats-new.sh --refresh"

# --- 4. only an updated skill: the report reads as it always did
S4="$(make_site updated alpha)"
out="$(bash "$WN" "$S4" 2>&1)"; rc=$?
check "updated: tells the reader to refresh"                    has "$out" "Refresh them"
check "updated: nothing is called removed"                      lacks "$out" "removed upstream"

# --- 5. a removed skill the site pinned: reported as pinned, and a refresh ends the repeat
S5="$(make_site pinned beta)"
printf 'beta # kept on purpose\n' > "$S5/.claude/skills/REFRESH-KEEP"
$git -C "$S5" add -A && $git -C "$S5" commit -q -m pin
out="$(bash "$WN" "$S5" 2>&1)"
check "pinned: marked as pinned"                                has "$out" "beta   (pinned in REFRESH-KEEP"
check "pinned: not marked removed"                              lacks "$out" "(removed upstream"
bash "$WN" --refresh "$S5" >/dev/null 2>&1; rc=$?
check "pinned: refresh exits 0"                                 test "$rc" -eq 0
check "pinned: refresh moves the stamp to the suite's head"     test "$(stamp "$S5")" = "$NEW"
out="$(bash "$WN" "$S5" 2>&1)"
check "pinned: the next report says up to date"                 has "$out" "Up to date"

# --- 6. a removed skill whose copy the site deleted: nothing to report
S6="$(make_site deleted beta gamma)"
rm -rf "$S6/.claude/skills/beta" && $git -C "$S6" add -A && $git -C "$S6" commit -q -m "delete the removed skill"
out="$(bash "$WN" "$S6" 2>&1)"
check "deleted: the next report says up to date"                has "$out" "Up to date"

if [ "$fails" -ne 0 ]; then echo "test_whats_new_removed_skill: $fails case(s) failed"; exit 1; fi
echo "test_whats_new_removed_skill: all cases passed"
