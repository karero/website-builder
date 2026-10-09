#!/usr/bin/env bash
#
# test_mktemp_guard.sh — runs each script that builds itself a throwaway folder with mktemp
# failing, from a folder holding a sentinel file, and checks that it stops with an error and
# leaves that folder as it found it.
#
# Why it exists: these scripts made their folder with
#     T="$(mktemp -d …)"; trap 'rm -rf "$T"' EXIT; T="$(CDPATH= cd -- "$T" && pwd -P)"
# and never looked at mktemp's status. When mktemp failed (TMPDIR naming a folder that is
# missing or read-only, a full disk), T was empty and bash's `cd ""` stayed where it was. T
# became the folder the script was started in, the whole suite ran there and printed "all
# checks passed", and the EXIT trap deleted the folder. Under `make check` that folder is the
# repo. The scripts that did not reassign T ran on with it empty, so every "$T/…" path pointed
# at the filesystem root. These cases pin the repair: a failed mktemp stops the script before
# it does anything else, with a non-zero status and a message that says why.
#
# mktemp fails through a stub first on PATH, not through a bad TMPDIR alone: macOS's mktemp
# with no template falls back to the user's temp folder when TMPDIR is bad, so the scripts
# that call it bare would only fail on Linux. TMPDIR names a missing folder as well, as in the
# incident. HOME moves too, so a script whose guard has broken cannot touch the real one.
#
# Usage: bash scripts/test_mktemp_guard.sh
set -u

# Scripts that build a throwaway folder and remove it on exit. A script under `set -e` stops on
# a failed mktemp by itself, and is not listed.
SCRIPTS=(
  scripts/test_whats_new.sh
  scripts/test_verify.sh
)

HERE="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
ROOT="$(dirname -- "$HERE")"
T="$(mktemp -d "${TMPDIR:-/tmp}/mktemp-guard-test.XXXXXX")" \
  || { echo "FAIL — could not create a temp dir."; exit 1; }
trap 'rm -rf "$T"' EXIT
mkdir "$T/stub" \
  && printf '#!/bin/sh\necho "mktemp: stub: cannot create a temp file or folder" >&2\nexit 1\n' >"$T/stub/mktemp" \
  && chmod +x "$T/stub/mktemp" \
  || { echo "FAIL — could not build the failing mktemp."; exit 1; }
# A script whose guard has broken runs on unguarded: stop it if it runs away (no timeout on a
# stock Mac, so no limit there).
TO=""; command -v timeout >/dev/null 2>&1 && TO="timeout 120"
fails=0; n=0
fail() { printf 'FAIL %s\n' "$1"; fails=$((fails+1)); }

# probe <script> — runs it from a folder holding one file, "sentinel", with mktemp failing.
# Sets p_rc (its exit status), p_out (what it printed) and p_left (the names the folder holds
# afterwards; empty if the folder is gone).
probe() {
  local d="$T/run.$n"; n=$((n+1))
  mkdir "$d" && : >"$d/sentinel" || { echo "FAIL — could not set up $d."; exit 1; }
  p_out="$(cd "$d" && HOME="$T/home" PATH="$T/stub:$PATH" TMPDIR="$T/missing" $TO bash "$1" 2>&1 </dev/null)"; p_rc=$?
  p_left="$(ls -A "$d" 2>/dev/null)"
}

# why_wrong — empty when the last probe went right, otherwise what went wrong.
why_wrong() {
  if [ -z "$p_left" ]; then
    echo "it deleted the folder it ran from, sentinel and all"
  elif [ "$p_left" != sentinel ]; then
    echo "it left [$(printf '%s' "$p_left" | tr '\n' ' ')] in the folder it ran from, not just the sentinel"
  elif [ "$p_rc" -eq 0 ]; then
    echo "exited 0"
  else
    case "$p_out" in
      *"could not create a temp dir"*) ;;
      *) echo "exited $p_rc without saying 'could not create a temp dir'" ;;
    esac
  fi
}

# Self-test: the old three lines must be caught, or nothing below could fail.
cat >"$T/old.sh" <<'OLD'
T="$(mktemp -d "${TMPDIR:-/tmp}/old.XXXXXX")"
trap 'rm -rf "$T"' EXIT
T="$(CDPATH= cd -- "$T" && pwd -P)"
echo "all checks passed"
OLD
probe "$T/old.sh"
why="$(why_wrong)"
if [ -n "$why" ]; then
  echo "ok   self-test: the old three lines are caught ($why)"
else
  fail "self-test: the old three lines passed, so this test cannot fire"
fi

for s in "${SCRIPTS[@]}"; do
  [ -f "$ROOT/$s" ] || { fail "$s: no such script (is this list stale?)"; continue; }
  probe "$ROOT/$s"
  case "$p_out" in
    SKIP*) if [ "$p_rc" -eq 0 ]; then printf 'skip %s: %s\n' "$s" "$(printf '%s\n' "$p_out" | sed -n 1p)"; continue; fi ;;
  esac
  why="$(why_wrong)"
  if [ -z "$why" ]; then
    printf 'ok   %s: stops with an error and leaves its folder alone\n' "$s"
  else
    fail "$s: $why"
  fi
done

if [ $fails -ne 0 ]; then echo "$fails check(s) FAILED"; exit 1; fi
echo "all checks passed"
