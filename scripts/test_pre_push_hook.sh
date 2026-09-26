#!/usr/bin/env bash
#
# test_pre_push_hook.sh — drives the site template's git pre-push hook
# (skills/new-website/templates/astro/scripts/hooks/pre-push) with a stubbed `npm`, both as
# shipped and with its optional PR-only-main block uncommented.
#
# Why it exists: the hook reads git's ref lines from stdin once and replays them, so the
# block can refuse a push to main and a push that only deletes refs can skip the gate. Every
# check of that was by hand, and one round of hand checks let through a stdin guard that read
# nothing without /proc, so an enabled block waved a push to main through (PR #125). These
# cases pin what the gate does per push shape, per stdin kind and per shell, and that the
# block refuses main whatever stdin git's pipe looks like.
#
# Usage: bash scripts/test_pre_push_hook.sh
set -u
if ! command -v git >/dev/null 2>&1; then
  echo "SKIP: test_pre_push_hook.sh needs git (it pushes to a throwaway bare repo)"
  exit 0
fi
HERE="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
HOOK="$HERE/../skills/new-website/templates/astro/scripts/hooks/pre-push"
T="$(mktemp -d "${TMPDIR:-/tmp}/pre-push-test.XXXXXX")"
trap 'rm -rf "$T"' EXIT
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null
unset ALLOW_MAIN_PUSH
git="git -c user.name=t -c user.email=t@t -c init.defaultBranch=main -c commit.gpgsign=false"
fails=0
check() { if [ "$2" = "$3" ]; then printf 'ok   %s\n' "$1"; else printf 'FAIL %s (expected %s, got %s)\n' "$1" "$2" "$3"; fails=$((fails+1)); fi; }

# The hook as shipped, and with the block's six commented lines uncommented — the edit
# website-team-setup §5-B makes. If that edit stops changing exactly six lines, the "on"
# cases would silently test the shipped hook, so fail loudly instead.
cp "$HOOK" "$T/off"
sed '/^# while read -r _lref/,/^# done$/s/^# //' "$HOOK" >"$T/on"
changed="$(diff "$T/off" "$T/on" | grep -c '^>')"
check "the block uncomments as six lines" 6 "$changed"

# A stub npm, so "the gate ran" is cheap and visible. No tests/ dir, so the hook's optional
# classifier and SEO steps stay off.
mkdir -p "$T/bin" "$T/site"
printf '#!/bin/sh\necho "npm $*"\n' >"$T/bin/npm"; chmod +x "$T/bin/npm"
export PATH="$T/bin:$PATH"
TO=""; command -v timeout >/dev/null 2>&1 && TO="timeout 20"

# outcome <output> — SKIP (gate skipped), BLOCK (block refused), GATE (gate ran and passed),
# or what went wrong. A hang shows as a timeout, not a stuck `make check`.
outcome() {
  case "$1" in
    *"pre-push gate: skipped"*) echo SKIP ;;
    *"Direct push to 'main' blocked"*) echo BLOCK ;;
    *"✓ pre-push gate passed"*) echo GATE ;;
    *) echo "other:$(printf '%s' "$1" | tr '\n' ' ' | cut -c1-80)" ;;
  esac
}
# run <shell> <hook> <stdin-setup...> — runs the hook in the stub site with the given stdin.
run() { local sh="$1" hook="$2"; shift 2; (cd "$T/site" && $TO "$@" "$sh" "$hook") 2>&1; }

Z=0000000000000000000000000000000000000000; A=1111111111111111111111111111111111111111
DEL="(delete) $Z refs/heads/feat $A"
DEL2="(delete) $Z refs/tags/v1 $A"
UPD="HEAD $A refs/heads/feat $Z"
DELMAIN="(delete) $Z refs/heads/main $A"
PUSHMAIN="HEAD $A refs/heads/main $Z"
printf '%s\n' "$DEL" >"$T/del.txt"
printf '%s\n' "$PUSHMAIN" >"$T/pushmain.txt"

piped() { local sh="$1" hook="$2"; shift 2; printf '%s\n' "$@" | run "$sh" "$hook" env; }

shells="bash"
for s in sh dash; do command -v "$s" >/dev/null 2>&1 && shells="$shells $s"; done
for sh in $shells; do
  for v in off on; do
    h="$T/$v"
    if [ "$v" = on ]; then main_del=BLOCK main_push=BLOCK; else main_del=SKIP main_push=GATE; fi
    p="$sh, block $v:"
    check "$p deleting one ref skips the gate"   SKIP "$(outcome "$(piped "$sh" "$h" "$DEL")")"
    check "$p deleting two refs skips the gate"  SKIP "$(outcome "$(piped "$sh" "$h" "$DEL" "$DEL2")")"
    check "$p a normal push runs the gate"       GATE "$(outcome "$(piped "$sh" "$h" "$UPD")")"
    check "$p a mixed push runs the gate"        GATE "$(outcome "$(piped "$sh" "$h" "$DEL" "$UPD")")"
    check "$p deleting main"                     "$main_del" "$(outcome "$(piped "$sh" "$h" "$DELMAIN")")"
    check "$p pushing main"                      "$main_push" "$(outcome "$(piped "$sh" "$h" "$PUSHMAIN")")"
    check "$p ALLOW_MAIN_PUSH=1 lets main through" GATE \
      "$(outcome "$(printf '%s\n' "$PUSHMAIN" | ALLOW_MAIN_PUSH=1 run "$sh" "$h" env)")"
    check "$p empty stdin runs the gate"         GATE "$(outcome "$(printf '' | run "$sh" "$h" env)")"
    check "$p /dev/null runs the gate"           GATE "$(outcome "$(run "$sh" "$h" env </dev/null)")"
    check "$p closed stdin runs the gate, no hang" GATE "$(outcome "$(run "$sh" "$h" env <&-)")"
    check "$p refs from a file are read"         SKIP "$(outcome "$(run "$sh" "$h" env <"$T/del.txt")")"
    # A socket is neither a pipe nor a file; a guard testing for those read nothing here.
    if command -v python3 >/dev/null 2>&1; then
      out="$(cd "$T/site" && $TO python3 -c '
import socket, subprocess, sys
a, b = socket.socketpair(); a.sendall(open(sys.argv[3], "rb").read()); a.shutdown(socket.SHUT_WR)
r = subprocess.run([sys.argv[1], sys.argv[2]], stdin=b, capture_output=True, text=True)
print(r.stdout + r.stderr)' "$sh" "$h" "$T/pushmain.txt" 2>&1)"
      check "$p refs from a socket are read" "$main_push" "$(outcome "$out")"
    fi
    # Without /proc, /dev/stdin does not resolve — the case that let main through in PR #125.
    # Needs unprivileged user namespaces; where they are off, say so rather than fail.
    if command -v unshare >/dev/null 2>&1 && unshare -rm true 2>/dev/null; then
      out="$(printf '%s\n' "$PUSHMAIN" | (cd "$T/site" && $TO unshare -rm "$sh" -c \
        'mount -t tmpfs none /proc 2>/dev/null || exit 97; exec "$0" "$1"' "$sh" "$h") 2>&1)"
      case "$out" in
        '') printf 'skip %s without /proc (could not hide /proc)\n' "$p" ;;
        *) check "$p refs are read without /proc" "$main_push" "$(outcome "$out")" ;;
      esac
    else
      printf 'skip %s without /proc (no unprivileged unshare here)\n' "$p"
    fi
  done
done

# Real git: what it actually hands the hook, end to end, as shipped and with the block on.
# Each pass gets a fresh remote, so every push below has a ref to change.
for v in off on; do
  R="$T/remote-$v.git"; W="$T/work-$v"
  $git init -q --bare "$R"
  $git init -q "$W"
  $git -C "$W" commit -q --allow-empty -m one
  $git -C "$W" push -q "$R" HEAD:refs/heads/main HEAD:refs/heads/feat HEAD:refs/heads/feat2 2>/dev/null
  mkdir -p "$W/.hooks"; cp "$T/$v" "$W/.hooks/pre-push"; chmod +x "$W/.hooks/pre-push"
  gpush() { (cd "$W" && $TO $git -c core.hooksPath="$W/.hooks" push "$R" "$@") 2>&1; }
  $git -C "$W" commit -q --allow-empty -m two
  if [ "$v" = on ]; then main_push=BLOCK main_del=BLOCK; else main_push=GATE main_del=SKIP; fi
  check "git, block $v: --delete of a branch skips the gate" SKIP "$(outcome "$(gpush --delete feat)")"
  check "git, block $v: a mixed push runs the gate"          GATE "$(outcome "$(gpush HEAD:refs/heads/feat2 :refs/heads/feat3)")"
  check "git, block $v: pushing main"                        "$main_push" "$(outcome "$(gpush HEAD:refs/heads/main)")"
  check "git, block $v: deleting main"                       "$main_del" "$(outcome "$(gpush --delete main)")"
done

if [ $fails -ne 0 ]; then echo "$fails check(s) FAILED"; exit 1; fi
echo "all checks passed"
