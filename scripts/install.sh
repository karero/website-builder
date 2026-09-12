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
[ "$#" -le 1 ] || { echo "usage: install.sh [--force]" >&2; exit 2; }

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DEST="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"
mkdir -p "$DEST"

# A pin is a link into a LINKED worktree of this repo, at the same skill. Every test
# below has to hold, because none of them alone means "pinned": worktrees of one repo
# share a git common dir, but so does this checkout itself (a link to the main checkout
# is what a previous install left, and must still refresh), and a link may point at a
# different skill entirely.
# `git rev-parse` echoes an option it does not understand and still exits 0, so a value
# counts only when it is a single absolute directory; otherwise the guard turns itself
# off and the old always-relink behaviour applies.
one_abs_dir() {
  case "$1" in
    /*) case "$1" in *"
"*) return 1 ;; esac; [ -d "$1" ] ;;
    *)  return 1 ;;
  esac
}
rp() { git -C "$1" rev-parse --path-format=absolute "$2" 2>/dev/null || true; }

repo_common="$(rp "$REPO_DIR" --git-common-dir)"
one_abs_dir "$repo_common" || repo_common=""

for src in "$REPO_DIR"/skills/*/; do
  name="$(basename "$src")"
  link="$DEST/$name"
  own="$(cd -P "$src" && pwd)"
  if [ -L "$link" ]; then
    # cd -P through the link resolves a relative target and fails on a dangling one.
    target="$(cd -P "$link" 2>/dev/null && pwd || true)"
    if [ "$FORCE" = 0 ] && [ -n "$repo_common" ] && [ -n "$target" ] && [ "$target" != "$own" ]; then
      link_common="$(rp "$target" --git-common-dir)"
      link_git="$(rp "$target" --git-dir)"
      link_top="$(rp "$target" --show-toplevel)"
      if one_abs_dir "$link_common" && one_abs_dir "$link_git" && one_abs_dir "$link_top" &&
         [ "$link_common" = "$repo_common" ] &&        # this repo
         [ "$link_git" != "$link_common" ] &&          # a linked worktree, not the checkout
         [ "$target" = "$link_top/skills/$name" ]; then # and the same skill
        echo "kept pinned $name → $target (linked worktree of this repo; --force relinks)"
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
