#!/usr/bin/env bash
# Guard: the skill suite is a handoff artifact — no personal names, contact info, or
# credentials may enter it. Scans skills/ + root docs and exits 1 (with file:line) on
# any hit. Wired into `make check` and CI (.github/workflows/clean.yml).
#
# Two kinds of check:
#   • DENYLIST — specific known-private identifiers, read from an OPTIONAL gitignored
#     file (scripts/.clean-denylist) so the public suite never enumerates private names.
#     Catches our own info regressing back in; skipped if the file is absent.
#   • GENERIC  — any real email, plus credential/secret formats and secret-looking
#     assignments. Catches things no denylist could enumerate.
# A real false positive should be fixed by narrowing the pattern here, never by
# loosening it to "match nothing".
set -uo pipefail
export LC_ALL=C   # unlocalized grep output — filter_ignored parses "Binary file … matches"
cd "$(dirname "$0")/.."
SCAN="skills"   # the arch doc now lives in skills/new-website/references/, so skills/ covers it
# Generic checks (email / home-path / secret) also cover the root docs that ship in the
# handoff, including LICENSE. NOT the scripts (they DEFINE the secret regexes — would
# self-match). The name denylist covers the same docs EXCEPT LICENSE, which legitimately
# carries the owner's real name + clone URLs (2026-07-17: widened from skills/-only after
# docs/reviews/*.md review artifacts slipped a client name past a skills/-only scan).
SCAN_NAMES_ALL="$SCAN README.md THIRD-PARTY-LICENSES.md SECURITY.md Makefile docs"
SCAN_DOCS_ALL="$SCAN_NAMES_ALL LICENSE"
# Every target must be here. A missing path makes grep print a diagnostic and exit 2,
# which this script used to send to /dev/null and read as "no hits" — so the final OK line
# named files nobody had looked at, an OK that could not fail (found in the handoff zip,
# which shipped no SECURITY.md while this check claimed to scan it). The zip now ships
# every target, so a missing one means something is broken, not a legitimate subset.
# The lists stay space-separated and unquoted on purpose — every entry is a fixed,
# space-free path in this repo.
SCAN_NAMES="$SCAN_NAMES_ALL"
SCAN_DOCS="$SCAN_DOCS_ALL"
# `set -f` so a target is never pathname-expanded — the loop wants the literal list.
missing() { local t out=""; set -f; for t in $1; do [ -e "$t" ] || out="${out:+$out }$t"; done; set +f; printf '%s' "$out"; }
MISSING="$(missing "$SCAN_DOCS_ALL")"
if [ -n "$MISSING" ]; then
  echo "FAIL — these scan targets are missing, so nothing checked them: $MISSING"
  echo "All of them ship in the handoff zip and exist in a checkout. If a copy should"
  echo "legitimately lack one, drop it from SCAN_NAMES_ALL/SCAN_DOCS_ALL deliberately."
  exit 1
fi
fail=0
# Hits in gitignored files (__pycache__, local caches…) never ship in the handoff —
# drop them. Outside a git checkout (e.g. a tarball) check-ignore fails → keep the hit.
filter_ignored() { # stdin: grep output → stdout minus gitignored files
  while IFS= read -r line; do
    case "$line" in
      "Binary file "*" matches") f="${line#Binary file }"; f="${f% matches}" ;;
      *) f="${line%%:*}" ;;
    esac
    git check-ignore -q -- "$f" 2>/dev/null || printf '%s\n' "$line"
  done
}
# grep wrapper: existence filtering says the paths are there, not that they were read.
# grep exits 1 for "no hits" but >1 for a real failure (unreadable file, bad regex), and
# discarding that difference is how an unscanned tree still prints OK.
g() { # <grep args…> → matches on stdout; a scan ERROR fails the run instead of reading as clean
  local out rc err
  err="$(mktemp)"; out="$(command grep "$@" 2>"$err")"; rc=$?
  if [ "$rc" -gt 1 ]; then
    fail=1
    echo "✗ scan error (grep exit $rc) — this check did NOT run:"
    sed 's/^/    /' "$err"
  fi
  rm -f "$err"
  printf '%s' "$out"
}
report() { # <label> <grep-output>
  [ -z "$2" ] && return 0
  local hits
  hits="$(printf '%s\n' "$2" | filter_ignored)"
  [ -z "$hits" ] && return 0
  fail=1
  echo "✗ $1:"
  printf '%s\n' "$hits" | sed 's/^/    /'
}

# 1. Personal / site / org identifiers (denylist, word-boundaried). Patterns live in a
#    gitignored local file — one extended-regex pattern per line, '#' comments allowed —
#    so private names never ship in the repo. Absent (e.g. a fresh clone / CI) → skipped;
#    the generic checks below still run.
DENYLIST_FILE="scripts/.clean-denylist"
if [ -f "$DENYLIST_FILE" ]; then
  NAMES="$(grep -vE '^[[:space:]]*(#|$)' "$DENYLIST_FILE" | paste -sd'|' -)"
  # karero/website-builder is this project's OWN public repo — self-links to it (README
  # badges, clone instructions, the security policy) are the point, not a leak.
  [ -n "$NAMES" ] && report "personal/site identifier" "$(g -rinE "\\b(${NAMES})\\b" $SCAN_NAMES \
    | grep -viE 'github\.com/karero/website-builder')"
else
  echo "· personal-name denylist skipped (no $DENYLIST_FILE) — generic checks still run"
fi

# 2. Personal home paths (non-portable + identifying).
report "home path" "$(g -rnE '/(Users|home)/[A-Za-z0-9._-]+' $SCAN_DOCS)"

# 3. Real email addresses (anything that is not an obvious placeholder/markup token).
EMAIL='[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}'
report "email address" "$(g -rinE "$EMAIL" $SCAN_DOCS \
  | grep -viE '@(example|test|domain|yoursite|site|company)\b|example\.(com|org)|@(type|id|context|media|import|2x|3x|font-face|keyframes)|(you|user|name|email|first\.last|hello|info|team)@|git@(github|gitlab)\.com')"

# 4. Credential / secret formats + private keys + JWTs.
SECRETS='(AKIA[0-9A-Z]{16}|gh[pousr]_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|glpat-[A-Za-z0-9_-]{20,}|xox[baprs]-[A-Za-z0-9-]{10,}|sk-[A-Za-z0-9]{20,}|AIza[0-9A-Za-z_-]{30,}|-----BEGIN [A-Z ]*PRIVATE KEY-----|eyJ[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,})'
report "credential/secret" "$(g -rnE "$SECRETS" $SCAN_DOCS)"

# 5. Secret-looking assignments:  (api_key|secret|token|password|...) = "longish-literal"
ASSIGN='(api[_-]?key|secret|client[_-]?secret|access[_-]?token|auth[_-]?token|password|passwd|bearer)["'"'"' ]*[:=]["'"'"' ]*["'"'"'][^"'"'"' ]{8,}'
report "secret-looking assignment" "$(g -rinE "$ASSIGN" $SCAN_DOCS \
  | grep -viE 'placeholder|example|your[_-]|<[a-z]|x{4,}|\.\.\.|process\.env|import\.meta\.env|REPLACE|TODO|\[bracket\]')"

if [ "$fail" -ne 0 ]; then
  echo ""
  echo "FAIL — personal info or credentials found in the skill suite. Skills are handoff"
  echo "artifacts: keep them generic. Remove the content, or (if a genuine false positive)"
  echo "tighten the pattern in scripts/check_clean.sh."
  exit 1
fi
echo "OK — no personal names, contact info, or credentials in: $SCAN_DOCS"
