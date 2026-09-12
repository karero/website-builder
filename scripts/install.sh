#!/usr/bin/env bash
# Symlink every suite skill into the Claude skills dir so Claude loads them.
# Idempotent: re-running just refreshes the links. An existing REAL directory with
# the same name is backed up to <name>.pre-website-builder.bak rather than clobbered.
# A symlink already pointing into ANOTHER WORKTREE of this repo is left alone: that is
# a deliberate pin to a vetted commit, and relinking it would silently undo someone's
# decision about which version of a skill runs. Pass --force to relink those too.
set -euo pipefail

FORCE=0
case "${1:-}" in
  --force) FORCE=1 ;;
  "")      ;;
  *)       echo "usage: install.sh [--force]" >&2; exit 2 ;;
esac

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DEST="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"
mkdir -p "$DEST"

# Every worktree of one repo shares a git common dir. That is what tells a pin (a skill
# checked out at a vetted commit in a sibling worktree) from a stale link to some other
# copy, which is still refreshed. An older git without --path-format leaves this empty,
# and the old always-relink behaviour applies.
repo_common="$(git -C "$REPO_DIR" rev-parse --path-format=absolute --git-common-dir 2>/dev/null || true)"

for src in "$REPO_DIR"/skills/*/; do
  name="$(basename "$src")"
  link="$DEST/$name"
  own="$(cd -P "$src" && pwd)"
  if [ -L "$link" ]; then
    # cd -P through the link resolves a relative target and fails on a dangling one.
    target="$(cd -P "$link" 2>/dev/null && pwd || true)"
    if [ "$FORCE" = 0 ] && [ -n "$repo_common" ] && [ -n "$target" ] && [ "$target" != "$own" ]; then
      link_common="$(git -C "$target" rev-parse --path-format=absolute --git-common-dir 2>/dev/null || true)"
      if [ -n "$link_common" ] && [ "$link_common" = "$repo_common" ]; then
        echo "kept pinned $name → $target (another worktree of this repo; --force relinks)"
        continue
      fi
    fi
    rm "$link"                                   # stale/our symlink → refresh
  elif [ -e "$link" ]; then
    mv "$link" "$link.pre-website-builder.bak"   # real dir → keep a backup
    echo "backed up existing $name → $name.pre-website-builder.bak"
  fi
  ln -s "$REPO_DIR/skills/$name" "$link"
  echo "linked $name"
done
echo "done → $DEST"
