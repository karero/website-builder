#!/usr/bin/env bash
#
# test_whats_new.sh — runs scripts/whats-new.sh <site> against a throwaway suite repo and a
# throwaway site, and checks which frozen template files it reports as MISSING.
#
# Why it exists: the report listed every frozen file that changed upstream the same way,
# whether the site had a copy or not. A site made before scripts/verify.mjs existed read
# "verify.mjs changed upstream" as one more file to merge some day, and so ran with no local
# `astro check` gate until a broken page reached main. A file the site lacks is now marked
# MISSING and listed again at the end. These cases pin what counts: a file the site has is
# not missing, and neither is one deleted upstream.
#
# Usage: bash scripts/test_whats_new.sh
set -u
if ! command -v git >/dev/null 2>&1; then
  echo "SKIP: test_whats_new.sh needs git (whats-new.sh compares a clone's history)"
  exit 0
fi
HERE="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
T="$(mktemp -d "${TMPDIR:-/tmp}/whats-new-test.XXXXXX")"
trap 'rm -rf "$T"' EXIT
T="$(CDPATH= cd -- "$T" && pwd -P)"
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null
git="git -c user.name=t -c user.email=t@t -c init.defaultBranch=main -c commit.gpgsign=false -c core.hooksPath=/dev/null"
fails=0
has()    { if grep -qxF -- "$2" "$T/out"; then printf 'ok   %s\n' "$1"; else printf 'FAIL %s (no line: %s)\n' "$1" "$2"; fails=$((fails+1)); fi; }
hasnt()  { if grep -qF -- "$2" "$T/out"; then printf 'FAIL %s (found: %s)\n' "$1" "$2"; fails=$((fails+1)); else printf 'ok   %s\n' "$1"; fi; }

# The suite: whats-new.sh plus template files, at a baseline commit and one later commit.
S="$T/suite" A="skills/new-website/templates/astro" C="skills/new-website/templates/claude"
# put <file> <version>: each file gets its own content, or git would pair a deletion with an
# addition as a rename and the deleted-upstream case would never be exercised.
put() { mkdir -p "$(dirname "$1")" && printf '%s %s\n' "$2" "$(printf '%s' "$1" | cksum)" > "$1"; }
mkdir -p "$S/scripts"
cp "$HERE/whats-new.sh" "$S/scripts/"
put "$S/$A/scripts/hooks/pre-push" v1
put "$S/$A/scripts/set_pdf_title.py" v1
put "$S/$A/tests/a.spec.ts" v1
$git -C "$S" init -q && $git -C "$S" add -A && $git -C "$S" commit -qm base
BASE="$($git -C "$S" rev-parse HEAD)"
put "$S/$A/scripts/hooks/pre-push" v2               # changed, the site has it
put "$S/$A/scripts/verify.mjs" v1                   # added, the site lacks it
$git -C "$S" rm -q "$A/scripts/set_pdf_title.py"    # deleted upstream, the site lacks it
put "$S/$A/tests/a.spec.ts" v2                      # changed, the site has it
put "$S/$A/tests/b.spec.ts" v1                      # added, the site lacks it
put "$S/$C/hooks/git-stand.mjs" v1                  # added, the site lacks it
$git -C "$S" add -A && $git -C "$S" commit -qm later

# The site, stamped at the baseline and holding only the files it had then.
P="$T/site"
mkdir -p "$P/.claude/skills" "$P/tests" "$P/scripts/hooks"
printf 'suite_commit: %s\ncopied: 2026-01-01\n' "$BASE" > "$P/.claude/skills/SUITE-VERSION"
printf 'suite_commit: %s\ncopied: 2026-01-01\n' "$BASE" > "$P/tests/TESTS-VERSION"
echo v1 > "$P/scripts/hooks/pre-push"
echo v1 > "$P/tests/a.spec.ts"

bash "$S/scripts/whats-new.sh" "$P" > "$T/out" 2>&1
has   "a file added upstream that the site lacks is MISSING" "    MISSING: the site has no scripts/verify.mjs"
has   "a template test the site lacks maps to tests/"         "    MISSING: the site has no tests/b.spec.ts"
has   "a claude template the site lacks maps to .claude/"     "    MISSING: the site has no .claude/hooks/git-stand.mjs"
has   "the closing summary lists the missing files"           "  scripts/verify.mjs"
hasnt "a changed file the site has is not MISSING"            "no scripts/hooks/pre-push"
hasnt "a changed test the site has is not MISSING"            "no tests/a.spec.ts"
has   "a file deleted upstream is still listed as drift"      "  templates/astro/scripts/set_pdf_title.py (site copy: scripts/set_pdf_title.py)"
hasnt "a file deleted upstream is not MISSING"                "no scripts/set_pdf_title.py"

# Once the site has every file, nothing is MISSING, though the drift report still runs.
echo v1 > "$P/scripts/verify.mjs"; echo v1 > "$P/tests/b.spec.ts"
mkdir -p "$P/.claude/hooks" && echo v1 > "$P/.claude/hooks/git-stand.mjs"
bash "$S/scripts/whats-new.sh" "$P" > "$T/out" 2>&1
has   "drift is still reported when nothing is missing"       "  templates/astro/scripts/verify.mjs (site copy: scripts/verify.mjs — the pre-push hook runs it once it is there; \`npm run verify\` also needs \"verify\": \"node scripts/verify.mjs\" in the site's package.json)"
hasnt "a site with every file shows no MISSING"               "MISSING"

[ "$fails" -eq 0 ] || { echo "$fails test(s) failed" >&2; exit 1; }
echo "all whats-new missing-file tests passed"
