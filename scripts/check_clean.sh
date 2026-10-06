#!/usr/bin/env bash
# Guard: the skill suite is a handoff artifact — no personal names, contact info, or
# credentials may enter it. Scans skills/ + root docs (and scripts/, for names only) and
# exits 1 (with file:line) on any hit. Wired into `make check` and CI (.github/workflows/clean.yml).
#
# Two kinds of check:
#   • DENYLIST — specific known-private identifiers, read from an OPTIONAL gitignored
#     file (scripts/.clean-denylist) so the public suite never enumerates private names.
#     Catches our own info regressing back in; skipped if the file is absent. CI writes
#     the file from the CLEAN_DENYLIST repo secret (`make push-denylist` sets it) and runs
#     with CLEAN_MASK_NAMES=1, which blanks every listed name out of everything this
#     script prints, since a public repo's CI logs are public (section 0 below).
#   • GENERIC  — any real email, plus credential/secret formats and secret-looking
#     assignments. Catches things no denylist could enumerate.
# A real false positive should be fixed by narrowing the pattern here, never by
# loosening it to "match nothing".
set -uo pipefail
export LC_ALL=C   # unlocalized grep output — filter_ignored parses "Binary file … matches"
CDPATH= cd -- "$(dirname -- "$0")/.."

# The private-name list (section 1 uses it; section 0 needs it first).
DENYLIST_FILE="scripts/.clean-denylist"
# A linked worktree has no copy of the gitignored list, so the check used to skip itself in
# exactly the checkouts where commits are made (2026-09-27: a client name reached main that
# way). Use the main checkout's list then, asking git where that is: the first entry of
# `git worktree list`. For a main checkout made with --separate-git-dir, git records no such
# path (it names the git folder), so the list is not found there and the skip below says so.
# No git (the handoff zip) or no list anywhere → skip, loudly. A list saved with Windows line
# endings would end every name in a carriage return that never matches; drop them.
if [ ! -f "$DENYLIST_FILE" ]; then
  main="$(git worktree list --porcelain 2>/dev/null | sed -n '1s/^worktree //p')"
  [ -n "$main" ] && [ -f "$main/$DENYLIST_FILE" ] && DENYLIST_FILE="$main/$DENYLIST_FILE"
fi
NAMES=""
[ -f "$DENYLIST_FILE" ] && NAMES="$(tr -d '\r' <"$DENYLIST_FILE" | grep -vE '^[[:space:]]*(#|$)' | paste -sd'|' -)"

# 0. CI's logs are public. With CLEAN_MASK_NAMES=1 this script runs itself again, unmasked,
#    and prints what that run printed with every listed name blanked out: anywhere in a
#    line, file names and error messages included, not only whole words. Then grep, the
#    engine that found the names, looks for them in the result. If one is left (perl reads
#    a pattern differently), or perl failed (its errors quote the whole list), nothing is
#    printed and the run fails. Masking one report at a time missed names in the other
#    reports, in scan errors and next to `_`, and could turn a hit into a pass (#189 review).
if [ -n "${CLEAN_MASK_NAMES:-}" ] && [ -n "$NAMES" ]; then
  out="$(CLEAN_MASK_NAMES= bash scripts/check_clean.sh 2>&1)"; rc=$?
  masked="$(printf '%s\n' "$out" | NAMES="$NAMES" perl -pe 's/(?:$ENV{NAMES})/[private name]/gi' 2>/dev/null)"; prc=$?
  grep -iqE -- "(${NAMES})" <<<"$masked" 2>/dev/null; grc=$?
  if [ "$prc" -ne 0 ] || [ "$grc" -ne 1 ]; then
    echo "FAIL — this run's output is withheld: a listed name could not be blanked out of it."
    echo "Run the check where the logs are private to see it: bash scripts/check_clean.sh"
    exit 1
  fi
  printf '%s\n' "$masked"
  exit "$rc"
fi
SCAN="skills"   # the arch doc now lives in skills/new-website/references/, so skills/ covers it
# Generic checks (email / home-path / secret) also cover the root docs that ship in the
# handoff, including LICENSE. NOT the scripts (they DEFINE the secret regexes — would
# self-match). The name denylist covers the same docs EXCEPT LICENSE, which legitimately
# carries the owner's real name + clone URLs (2026-07-17: widened from skills/-only after
# docs/reviews/*.md review artifacts slipped a client name past a skills/-only scan).
# It DOES cover scripts/: the names live in the gitignored list, not in any script, so
# nothing there can match itself; the list's own lines are dropped below. (2026-10-06: a
# client site's name sat in a comment in a script that ships in the handoff zip.)
SCAN_BASE="$SCAN README.md THIRD-PARTY-LICENSES.md SECURITY.md Makefile docs"
SCAN_NAMES_ALL="$SCAN_BASE scripts"
SCAN_DOCS_ALL="$SCAN_BASE LICENSE"
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
MISSING="$(missing "$SCAN_DOCS_ALL $SCAN_NAMES_ALL")"
if [ -n "$MISSING" ]; then
  echo "FAIL — these scan targets are missing, so nothing checked them: $MISSING"
  echo "All of them ship in the handoff zip and exist in a checkout. If a copy should"
  echo "legitimately lack one, drop it from SCAN_NAMES_ALL/SCAN_DOCS_ALL deliberately."
  exit 1
fi
fail=0
names_checked=0 names_skipped=""
# Hits in gitignored files (__pycache__, local caches…) never ship in the handoff —
# drop them. Outside a git checkout (e.g. a tarball) check-ignore fails → keep the hit.
filter_ignored() { # stdin: grep output → stdout minus gitignored files
  local line f rest keep
  while IFS= read -r line; do
    case "$line" in
      "Binary file "*" matches") f="${line#Binary file }"; f="${f% matches}"
        git check-ignore -q -- "$f" 2>/dev/null || printf '%s\n' "$line"; continue ;;
    esac
    # A file name may hold a colon, so the name is not simply the text before the first
    # one: try each prefix that ends at a colon, and drop the line only when every prefix
    # naming an existing file is gitignored. In doubt, the hit is reported.
    keep=1 f="" rest="$line"
    while [ "${rest#*:}" != "$rest" ]; do
      f="${f:+$f:}${rest%%:*}"; rest="${rest#*:}"
      [ -e "$f" ] || continue
      if git check-ignore -q -- "$f" 2>/dev/null; then keep=0; else keep=1; break; fi
    done
    if [ "$keep" = 1 ]; then printf '%s\n' "$line"; fi
  done
}
# grep wrapper: existence filtering says the paths are there, not that they were read.
# grep exits 1 for "no hits" but >1 for a real failure (unreadable file, bad regex), and
# discarding that difference is how an unscanned tree still prints OK.
g() { # <grep args…> → matches on stdout; a scan ERROR fails the run instead of reading as clean
  local out rc err
  err="$(mktemp)"; out="$(command grep "$@" 2>"$err")"; rc=$?
  # GNU grep 3.5+ (CI's) reports a matching binary file on stderr with exit 0, where BSD grep
  # prints "Binary file X matches" on stdout. Turn the GNU form into the BSD one, or the hit
  # would be thrown away with the rest of stderr and a binary file holding a name would pass.
  local bin; bin="$(sed -n 's/^grep: \(.*\): binary file matches$/Binary file \1 matches/p' "$err")"
  [ -n "$bin" ] && out="${out:+$out$'\n'}$bin"
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
#    so private names never ship in the repo. Absent (e.g. a fresh clone) → skipped;
#    the generic checks below still run.
if [ -f "$DENYLIST_FILE" ]; then
  # karero/website-builder is this project's OWN public repo — self-links to it (README
  # badges, clone instructions, the security policy) and its short form in issue and PR
  # references (karero/website-builder#131) are the point, not a leak. Blank out exactly that
  # reference, in lowercase, and not inside a longer name (one with an extra prefix like
  # `other-` or suffix like `-x`), then look again: dropping every line that held one also hid
  # any private name beside it. One reference at a time, until none is left: a global
  # replace consumes the character after one reference that the next needs before it
  # (karero/website-builder,karero/website-builder). Binary-file lines pass through for
  # filter_ignored. A scan error (g's "✗ scan error" block, first in its output) goes to
  # report whole: the filter would compile the same broken pattern, fail too, and turn the
  # error into a clean pass. The list itself sits in the scanned scripts/ and holds every
  # name, so its own lines are dropped, by exact path: a file of that name anywhere else
  # (docs/ ships whole in the zip) is scanned like any other. A line from a file named
  # like the list plus a colon (scripts/.clean-denylist:1:x) starts the same way, so with
  # such a file present nothing is dropped: the list then reports itself, loudly.
  if [ -n "$NAMES" ]; then
    self='^scripts/\.clean-denylist:[0-9]+:'
    compgen -G 'scripts/.clean-denylist:*' >/dev/null && self='^$'
    hits="$(g -rinE "\\b(${NAMES})\\b" $SCAN_NAMES)"
    case "$hits" in
      "✗ scan error"*) ;;
      *) hits="$(printf '%s\n' "$hits" \
           | grep -vE "$self" \
           | sed -E -e ':a' -e 's#(^|[^A-Za-z0-9_.-])karero/website-builder(\.git)?([^A-Za-z0-9_.-]|\.[^A-Za-z0-9_-]|\.?$)#\1SELF-REPO\3#' -e 'ta' \
           | grep -iE "^Binary file |:[0-9]+:.*\\b(${NAMES})\\b")" ;;
    esac
    report "personal/site identifier" "$hits"
    names_checked=1
  else
    names_skipped="$DENYLIST_FILE lists no names"
    echo "· personal-name denylist skipped ($names_skipped) — generic checks still run"
  fi
else
  names_skipped="no $DENYLIST_FILE"
  echo "· personal-name denylist skipped ($names_skipped) — generic checks still run"
fi

# 2. Personal home paths (non-portable + identifying).
report "home path" "$(g -rnE '/(Users|home)/[A-Za-z0-9._-]+' $SCAN_DOCS)"

# 3. Real email addresses (anything that is not an obvious placeholder/markup token).
EMAIL='[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}'
report "email address" "$(g -rinE "$EMAIL" $SCAN_DOCS \
  | grep -viE '@(example|test|domain|yoursite|site|company)\b|example\.(com|org)|@(type|id|context|media|import|2x|3x|font-face|keyframes)|(you|user|name|email|first\.last|hello|info|team)@|git@(github|gitlab)\.com')"

# 4. Credential / secret formats + private keys + JWTs.
# sk-/pplx- cover OpenAI (incl. sk-proj-), Anthropic (sk-ant-) and Perplexity keys for the
# AI check; they must start a word, or hyphenated prose ("risk-free-and-...") would match.
SECRETS='(AKIA[0-9A-Z]{16}|gh[pousr]_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|glpat-[A-Za-z0-9_-]{20,}|xox[baprs]-[A-Za-z0-9-]{10,}|(^|[^A-Za-z0-9_-])sk-[A-Za-z0-9_-]{20,}|(^|[^A-Za-z0-9_-])pplx-[A-Za-z0-9]{20,}|AIza[0-9A-Za-z_-]{30,}|-----BEGIN [A-Z ]*PRIVATE KEY-----|eyJ[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,})'
# Self-test, both directions: a pattern that stops matching real key shapes passes silently, and
# one that starts matching prose fails every docs change. The samples are built at run time so
# this file never holds a key-shaped literal of its own.
x20=aaaaaaaaaaaaaaaaaaaa; x36="${x20}aaaaaaaaaaaaaaaa"
for k in "AKIA""ABCDEFGHIJKLMNOP" "ghp_$x36" "github_pat_$x20" "glpat-$x20" "xoxb-$x20" \
         "sk-""proj-$x20" "sk-""ant-api03-$x20" "key: sk-$x20" "pplx-$x20" "AIza$x36" \
         "-----BEGIN RSA PRIVATE KEY-----"; do
  grep -qE -- "$SECRETS" <<<"$k" || { echo "FAIL — the secret pattern no longer matches a key shaped like: ${k:0:12}…"; exit 1; }
done
for k in "a risk-free-and-clear-guarantee-for-everyone" "ask-me-anything-about-your-website-today" \
         "task-sk-$x20" "the pplx-style answer"; do
  if grep -qE -- "$SECRETS" <<<"$k"; then echo "FAIL — the secret pattern matches plain prose: $k"; exit 1; fi
done
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
# The OK line says itself whether names were checked: CI once had no list, and a bare OK there
# read as "no private names" while the same tree failed `make check` locally.
if [ "$names_checked" -eq 1 ]; then
  echo "OK — no private names in: $SCAN_NAMES; no contact info or credentials in: $SCAN_DOCS"
else
  echo "OK — no contact info or credentials in: $SCAN_DOCS (private-name check SKIPPED: $names_skipped)"
fi
