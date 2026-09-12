#!/usr/bin/env bash
#
# test_install_pin.sh — drives scripts/install.sh and its Codex mirror against a
# throwaway repo, one of whose skills is symlinked into a SIBLING WORKTREE of the same
# repo (a pin: that skill runs at a vetted commit, not at whatever the checkout holds).
#
# Why it exists: both installers removed any existing symlink and re-pointed it at the
# checkout, so re-running one silently undid such a pin — the pinned skill quietly went
# back to following the checkout, with nothing said. These cases pin four outcomes, for
# each installer: a pin is kept, --force still relinks it, a stale link to an unrelated
# copy is still refreshed, and a real directory is still backed up.
#
# Usage: bash scripts/test_install_pin.sh
set -u
command -v git >/dev/null 2>&1 || { echo "test_install_pin.sh needs git (it builds a throwaway repo and worktree)" >&2; exit 2; }
HERE="$(cd "$(dirname "$0")" && pwd)"
T="$(mktemp -d "${TMPDIR:-/tmp}/install-pin-test.XXXXXX")"
trap 'rm -rf "$T"' EXIT
git="git -c user.name=t -c user.email=t@t -c init.defaultBranch=main"
fails=0
check() { if "${@:2}"; then printf 'ok   %s\n' "$1"; else printf 'FAIL %s\n' "$1"; fails=$((fails+1)); fi; }

# one_installer <script name> <skills-dir env var> <case label>
one_installer() {
  local script="$1" var="$2" label="$3" R O DEST out rc first
  R="$T/$label/repo"; O="$T/$label/other"; DEST="$T/$label/dest"
  mkdir -p "$R/scripts" "$R/skills/alpha" "$R/skills/beta" "$O/skills/beta" "$DEST"
  cp "$HERE/$script" "$R/scripts/$script"
  printf 'v2\n' >"$R/skills/alpha/SKILL.md"; printf 'v2\n' >"$R/skills/beta/SKILL.md"
  $git init -q "$R"; $git -C "$R" add -A; $git -C "$R" commit -qm two
  first="$($git -C "$R" rev-parse HEAD)"
  printf 'v3\n' >"$R/skills/alpha/SKILL.md"; $git -C "$R" commit -qam three
  # The pin: a sibling worktree of the SAME repo, at the older commit.
  $git -C "$R" worktree add -q --detach "$T/$label/pin" "$first"
  # A stale link: an unrelated copy in a DIFFERENT repo.
  printf 'other\n' >"$O/skills/beta/SKILL.md"; $git init -q "$O"; $git -C "$O" add -A; $git -C "$O" commit -qm other
  ln -s "$T/$label/pin/skills/alpha" "$DEST/alpha"
  ln -s "$O/skills/beta" "$DEST/beta"

  links_to() { [ "$(cd -P "$DEST/$1" 2>/dev/null && pwd)" = "$(cd -P "$2" && pwd)" ]; }

  out="$(env "$var=$DEST" bash "$R/scripts/$script" 2>&1)"; rc=$?
  check "$label: install succeeds" [ "$rc" = 0 ]
  check "$label: the pin is kept" links_to alpha "$T/$label/pin/skills/alpha"
  check "$label: it says the pin was kept" grep -q "kept pinned alpha" <<<"$out"
  check "$label: the pinned skill still reads its own commit" [ "$(cat "$DEST/alpha/SKILL.md")" = v2 ]
  check "$label: a stale link to another repo is refreshed" links_to beta "$R/skills/beta"

  out="$(env "$var=$DEST" bash "$R/scripts/$script" --force 2>&1)"; rc=$?
  check "$label: --force succeeds" [ "$rc" = 0 ]
  check "$label: --force relinks the pin" links_to alpha "$R/skills/alpha"
  check "$label: --force keeps nothing back" [ "$(grep -c 'kept pinned' <<<"$out")" = 0 ]

  # A real directory is still backed up, not clobbered (pre-existing behaviour).
  rm -f "$DEST/alpha"; mkdir -p "$DEST/alpha"; printf 'mine\n' >"$DEST/alpha/SKILL.md"
  env "$var=$DEST" bash "$R/scripts/$script" >/dev/null 2>&1
  check "$label: a real directory is backed up" [ "$(cat "$DEST/alpha.pre-website-builder.bak/SKILL.md")" = mine ]
  check "$label: and the skill is linked to the checkout" links_to alpha "$R/skills/alpha"

  env "$var=$DEST" bash "$R/scripts/$script" --nope >/dev/null 2>&1; rc=$?
  check "$label: an unknown flag exits 2" [ "$rc" = 2 ]
}

one_installer install.sh CLAUDE_SKILLS_DIR claude
one_installer install-codex.sh CODEX_SKILLS_DIR codex

# A git too old for `rev-parse --path-format` cannot tell a pin from a stale link. The
# installer must then fall back to the old always-relink behaviour, not abort under set -e.
old_git() {
  local R="$T/oldgit/repo" DEST="$T/oldgit/dest" BIN="$T/oldgit/bin" first rc
  mkdir -p "$R/scripts" "$R/skills/alpha" "$DEST" "$BIN"
  cp "$HERE/install.sh" "$R/scripts/install.sh"; printf 'v2\n' >"$R/skills/alpha/SKILL.md"
  $git init -q "$R"; $git -C "$R" add -A; $git -C "$R" commit -qm two
  first="$($git -C "$R" rev-parse HEAD)"
  printf 'v3\n' >"$R/skills/alpha/SKILL.md"; $git -C "$R" commit -qam three
  $git -C "$R" worktree add -q --detach "$T/oldgit/pin" "$first"
  ln -s "$T/oldgit/pin/skills/alpha" "$DEST/alpha"
  # Stub git: real git, except the option an old git does not know.
  printf '#!/bin/sh\nfor a in "$@"; do [ "$a" = "--path-format=absolute" ] && { echo "error: unknown option" >&2; exit 129; }; done\nexec %s "$@"\n' "$(command -v git)" >"$BIN/git"
  chmod +x "$BIN/git"
  PATH="$BIN:$PATH" CLAUDE_SKILLS_DIR="$DEST" bash "$R/scripts/install.sh" >/dev/null 2>&1; rc=$?
  check "old git: install still succeeds" [ "$rc" = 0 ]
  check "old git: falls back to relinking" [ "$(cd -P "$DEST/alpha" && pwd)" = "$(cd -P "$R/skills/alpha" && pwd)" ]
}
old_git

if [ $fails -ne 0 ]; then echo "$fails check(s) FAILED"; exit 1; fi
echo "all checks passed"
