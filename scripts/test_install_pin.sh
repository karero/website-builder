#!/usr/bin/env bash
#
# test_install_pin.sh — drives scripts/install.sh and its Codex mirror against a
# throwaway repo, one of whose skills is symlinked into a SIBLING WORKTREE of the same
# repo (a pin: that skill runs at a vetted commit, not at whatever the checkout holds).
#
# Why it exists: both installers removed any existing symlink and re-pointed it at the
# checkout, so re-running one silently undid such a pin — the pinned skill quietly went
# back to following the checkout, with nothing said. A pin is now kept, and these cases
# pin both halves of that: what counts as a pin (a linked worktree of this repo, at the
# same skill) and what does not (the main checkout, another skill, another repo).
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
same_dir() { [ "$(cd -P "$1" 2>/dev/null && pwd)" = "$(cd -P "$2" 2>/dev/null && pwd)" ]; }

# one_installer <script name> <skills-dir env var> <case label>
one_installer() {
  local script="$1" var="$2" label="$3" R O DEST PIN out rc first
  R="$T/$label/repo"; O="$T/$label/other"; DEST="$T/$label/dest"; PIN="$T/$label/pin"
  mkdir -p "$R/scripts" "$R/skills/alpha" "$R/skills/beta" "$R/skills/gamma" "$R/skills/delta" \
           "$O/skills/beta" "$DEST"
  cp "$HERE/$script" "$R/scripts/$script"
  printf 'v2\n' >"$R/skills/alpha/SKILL.md"
  for s in beta gamma delta; do printf 'v2\n' >"$R/skills/$s/SKILL.md"; done
  $git init -q "$R"; $git -C "$R" add -A; $git -C "$R" commit -qm two
  first="$($git -C "$R" rev-parse HEAD)"
  printf 'v3\n' >"$R/skills/alpha/SKILL.md"; $git -C "$R" commit -qam three
  # The pin: a sibling LINKED worktree of the same repo, at the older commit.
  $git -C "$R" worktree add -q --detach "$PIN" "$first"
  # A stale link: an unrelated copy in a DIFFERENT repo.
  printf 'other\n' >"$O/skills/beta/SKILL.md"; $git init -q "$O"; $git -C "$O" add -A; $git -C "$O" commit -qm other

  ln -s "$PIN/skills/alpha" "$DEST/alpha"          # a pin (absolute)
  ln -s "$O/skills/beta" "$DEST/beta"              # stale: another repo
  ln -s "$PIN/skills/alpha" "$DEST/gamma"          # same repo, WRONG skill
  ln -s "$PIN/skills/nowhere" "$DEST/delta"        # dangling

  out="$(env "$var=$DEST" bash "$R/scripts/$script" 2>&1)"; rc=$?
  check "$label: install succeeds" [ "$rc" = 0 ]
  check "$label: the pin is kept" same_dir "$DEST/alpha" "$PIN/skills/alpha"
  check "$label: it says the pin was kept" grep -q "kept pinned alpha" <<<"$out"
  check "$label: the pinned skill still reads its own commit" [ "$(cat "$DEST/alpha/SKILL.md")" = v2 ]
  check "$label: a stale link to another repo is refreshed" same_dir "$DEST/beta" "$R/skills/beta"
  check "$label: a link to the WRONG skill is refreshed" same_dir "$DEST/gamma" "$R/skills/gamma"
  check "$label: a dangling link is refreshed" same_dir "$DEST/delta" "$R/skills/delta"

  out="$(env "$var=$DEST" bash "$R/scripts/$script" --force 2>&1)"; rc=$?
  check "$label: --force succeeds" [ "$rc" = 0 ]
  check "$label: --force relinks the pin" same_dir "$DEST/alpha" "$R/skills/alpha"
  check "$label: --force keeps nothing back" [ "$(grep -c 'kept pinned' <<<"$out")" = 0 ]

  # A RELATIVE link into the pin is a pin too (the installer resolves it).
  rm -f "$DEST/alpha"; ( cd "$DEST" && ln -s "../pin/skills/alpha" alpha )
  out="$(env "$var=$DEST" bash "$R/scripts/$script" 2>&1)"
  check "$label: a relative link into the pin is kept" same_dir "$DEST/alpha" "$PIN/skills/alpha"

  # Installing FROM the pin worktree, with links left by an install from the main
  # checkout: the main checkout is not a pin, so those links must refresh.
  local DEST2="$T/$label/dest2"; mkdir -p "$DEST2"; ln -s "$R/skills/alpha" "$DEST2/alpha"
  out="$(env "$var=$DEST2" bash "$PIN/scripts/$script" 2>&1)"
  check "$label: a link to the main checkout is refreshed" same_dir "$DEST2/alpha" "$PIN/skills/alpha"
  check "$label: and it is not called a pin" [ "$(grep -c 'kept pinned' <<<"$out")" = 0 ]

  # A real directory is still backed up, not clobbered (pre-existing behaviour).
  rm -f "$DEST/alpha"; mkdir -p "$DEST/alpha"; printf 'mine\n' >"$DEST/alpha/SKILL.md"
  env "$var=$DEST" bash "$R/scripts/$script" >/dev/null 2>&1
  check "$label: a real directory is backed up" [ "$(cat "$DEST/alpha.pre-website-builder.bak/SKILL.md")" = mine ]
  check "$label: and the skill is linked to the checkout" same_dir "$DEST/alpha" "$R/skills/alpha"

  env "$var=$DEST" bash "$R/scripts/$script" --nope >/dev/null 2>&1; rc=$?
  check "$label: an unknown flag exits 2" [ "$rc" = 2 ]
  env "$var=$DEST" bash "$R/scripts/$script" --force --nope >/dev/null 2>&1; rc=$?
  check "$label: a trailing argument exits 2" [ "$rc" = 2 ]
}

one_installer install.sh CLAUDE_SKILLS_DIR claude
one_installer install-codex.sh CODEX_SKILLS_DIR codex

# A git too old for `rev-parse --path-format` cannot tell a pin from a stale link, so the
# installer must fall back to always relinking rather than abort or trust junk. Old
# rev-parse does one of two things with an option it does not know: fail, or echo it back
# and still exit 0. Both must degrade the same way.
old_git() {
  local variant="$1" R DEST BIN first rc
  R="$T/oldgit-$variant/repo"; DEST="$T/oldgit-$variant/dest"; BIN="$T/oldgit-$variant/bin"
  mkdir -p "$R/scripts" "$R/skills/alpha" "$DEST" "$BIN"
  cp "$HERE/install.sh" "$R/scripts/install.sh"; printf 'v2\n' >"$R/skills/alpha/SKILL.md"
  $git init -q "$R"; $git -C "$R" add -A; $git -C "$R" commit -qm two
  first="$($git -C "$R" rev-parse HEAD)"
  printf 'v3\n' >"$R/skills/alpha/SKILL.md"; $git -C "$R" commit -qam three
  $git -C "$R" worktree add -q --detach "$T/oldgit-$variant/pin" "$first"
  ln -s "$T/oldgit-$variant/pin/skills/alpha" "$DEST/alpha"
  if [ "$variant" = fails ]; then
    printf '#!/bin/sh\nfor a in "$@"; do [ "$a" = "--path-format=absolute" ] && { echo "error: unknown option" >&2; exit 129; }; done\nexec %s "$@"\n' \
      "$(command -v git)" >"$BIN/git"
  else   # echoes the unknown option back on stdout, exit 0
    printf '#!/bin/sh\nfor a in "$@"; do if [ "$a" = "--path-format=absolute" ]; then echo "--path-format=absolute"; shift; exec %s "$@"; fi; done\nexec %s "$@"\n' \
      "$(command -v git)" "$(command -v git)" >"$BIN/git"
  fi
  chmod +x "$BIN/git"
  PATH="$BIN:$PATH" CLAUDE_SKILLS_DIR="$DEST" bash "$R/scripts/install.sh" >/dev/null 2>&1; rc=$?
  check "old git ($variant): install still succeeds" [ "$rc" = 0 ]
  check "old git ($variant): falls back to relinking" same_dir "$DEST/alpha" "$R/skills/alpha"
}
old_git fails
old_git echoes

if [ $fails -ne 0 ]; then echo "$fails check(s) FAILED"; exit 1; fi
echo "all checks passed"
