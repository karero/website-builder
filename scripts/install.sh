#!/usr/bin/env bash
# Symlink every suite skill into the Claude skills dir so Claude loads them.
# Idempotent: re-running just refreshes the links. An existing REAL directory with
# the same name is backed up to <name>.pre-website-builder.bak rather than clobbered.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DEST="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"
mkdir -p "$DEST"

for src in "$REPO_DIR"/skills/*/; do
  name="$(basename "$src")"
  link="$DEST/$name"
  if [ -L "$link" ]; then
    rm "$link"                                   # stale/our symlink → refresh
  elif [ -e "$link" ]; then
    mv "$link" "$link.pre-website-builder.bak"   # real dir → keep a backup
    echo "backed up existing $name → $name.pre-website-builder.bak"
  fi
  ln -s "$REPO_DIR/skills/$name" "$link"
  echo "linked $name"
done
echo "done → $DEST"
