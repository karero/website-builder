#!/usr/bin/env bash
# Guard: scripts locate themselves CDPATH-safely.
#
# `cd "$(dirname "$0")"` is wrong when CDPATH is exported: cd searches CDPATH before
# the current directory for a relative operand, so it can land somewhere else entirely
# — and it prints where it went, which corrupts any $(...) capturing it. Both modes were
# live here until 2026-09-26; `CDPATH=/tmp/cdp make check` failed with exit 2 on the
# commit before this guard, and whats-new.sh resolved a relative <project_dir> to a
# same-named decoy that --refresh would then have written into.
#
# Why a guard and not just the fix: nothing in this repo ever sets CDPATH, so a green
# `make check` looks identical whether the scripts are safe or not — the same reason
# check_template_coverage.sh exists. Without this, the next script silently reintroduces
# the class with CI green.
#
# Scope: the SELF-LOCATION idiom only. A cd to an operand that is absolute by
# construction (mktemp -d, git rev-parse --show-toplevel, an already-absolute REPO_DIR)
# is safe — CDPATH is not consulted for an absolute operand — and is not flagged.
set -uo pipefail
CDPATH= cd -- "$(dirname -- "$0")/.." || { echo "FAIL — cannot cd to the repo root from $0."; exit 1; }

rc=0

# --- negative case: no tracked script may use the unsafe idiom -----------------------
# Files are discovered, not listed, so a new script is scanned by default. Excluded:
# docs/reviews/ (historical review transcripts quote the unsafe form as evidence —
# rewriting them would falsify the record), and this file, which DEFINES the pattern
# and would otherwise match itself (same reason check_clean.sh skips scripts/).
# find, not `git ls-files`: this ships in the handoff zip, where there is no git — the
# same reason test_install_pin.sh gates itself on git. Every sibling guard uses find too.
self="./scripts/$(basename -- "$0")"
hits="$(
  find . -name '*.sh' -type f \
      ! -path './.git/*' ! -path './docs/reviews/*' ! -path './dist/*' \
      ! -path '*/node_modules/*' -print0 \
    | xargs -0 grep -nE '(^|[^[:alnum:]_])cd([[:space:]]|[[:space:]]+--[[:space:]]+)[^;&|]*\$\(dirname' 2>/dev/null \
    | grep -vE ':[0-9]+:.*CDPATH=[[:space:]]+cd[[:space:]]+--[[:space:]]+"\$\(dirname[[:space:]]+--' \
    | grep -v "^${self}:" \
    || true
)"
# A broken enumeration must not read as a pass: an empty `hits` is only meaningful if the
# scan actually looked at files. (Caught by a malformed no-git test that removed `find` and
# `grep` from PATH — the scan silently reported OK.)
scanned="$(
  find . -name '*.sh' -type f \
      ! -path './.git/*' ! -path './docs/reviews/*' ! -path './dist/*' \
      ! -path '*/node_modules/*' 2>/dev/null | wc -l | tr -d ' '
)"
if [ "${scanned:-0}" -lt 10 ]; then
  echo "FAIL — the scan found only ${scanned:-0} shell scripts; it cannot have run correctly."
  echo "Run this from a checkout or an unpacked handoff zip, with find and grep on PATH."
  exit 1
fi

if [ -n "$hits" ]; then
  echo "FAIL — these lines locate the script with a CDPATH-unsafe cd:"
  printf '%s\n' "$hits" | sed 's/^/  /'
  echo "Use: CDPATH= cd -- \"\$(dirname -- \"\$0\")\"   (the assignment is scoped to that one cd)"
  rc=1
else
  echo "OK — all $scanned shell scripts locate themselves with CDPATH= cd -- \"\$(dirname -- \"\$0\")\"."
fi

# --- positive case: a real script, invoked relatively, under a hostile CDPATH ---------
# The scan above is textual; this proves the idiom actually works on this platform's
# shell and dirname, which is the half a regex cannot check.
decoy="$(mktemp -d)"
trap 'rm -rf "$decoy"' EXIT
mkdir -p "$decoy/scripts" "$decoy/skills"
expected="$(bash scripts/check_model_agnostic.sh 2>&1)"; exp_rc=$?
actual="$(CDPATH="$decoy" bash scripts/check_model_agnostic.sh 2>&1)"; act_rc=$?
if [ "$exp_rc" -ne 0 ]; then
  echo "FAIL — the positive case needs check_model_agnostic.sh green to mean anything; it exited $exp_rc."
  rc=1
elif [ "$act_rc" -ne 0 ] || [ "$actual" != "$expected" ]; then
  echo "FAIL — check_model_agnostic.sh behaves differently under an exported CDPATH (exit $act_rc):"
  diff <(printf '%s\n' "$expected") <(printf '%s\n' "$actual") | sed 's/^/  /'
  rc=1
else
  echo "OK — a relatively-invoked script is byte-identical with and without a hostile CDPATH."
fi

exit $rc
