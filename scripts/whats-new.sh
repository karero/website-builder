#!/usr/bin/env bash
# What changed in the suite's skills — overall, or since a project was scaffolded.
#
#   scripts/whats-new.sh                      # recent skill changes in the suite
#   scripts/whats-new.sh <project_dir>        # which of that project's bundled skills
#                                             # have upstream updates (reads the
#                                             # SUITE-VERSION stamp new-website wrote)
#   scripts/whats-new.sh --refresh <project_dir>   # re-copy the stale skills into the
#                                             # project and rewrite the stamp. Overwrites
#                                             # any local edits to those skill copies.
#
# Needs the git clone of the suite (a zip has no history to compare against).
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"

git -C "$REPO_DIR" rev-parse --git-dir >/dev/null 2>&1 || {
  echo "error: $REPO_DIR is not a git clone — whats-new compares git history," >&2
  echo "which a zip install doesn't carry. Clone the suite repo to use this." >&2
  exit 1
}

REFRESH=0
if [ "${1:-}" = "--refresh" ]; then REFRESH=1; shift; fi

if [ $# -eq 0 ]; then
  [ "$REFRESH" -eq 1 ] && { echo "error: --refresh needs a <project_dir>" >&2; exit 1; }
  echo "Recent skill changes in the suite (newest first):"
  git -C "$REPO_DIR" log --oneline -20 -- skills/
  echo
  echo "Tip: scripts/whats-new.sh <project_dir> shows what a scaffolded project is missing."
  exit 0
fi

PROJECT="${1%/}"
[ -d "$PROJECT" ] || { echo "error: no such directory: $PROJECT" >&2; exit 1; }

# The project's bundled-skills dir: .claude/skills (Claude Code) or .agents/skills
# (Codex / Antigravity) — same detection order new-website uses when copying.
SKILLS_DIR=""
for d in "$PROJECT/.claude/skills" "$PROJECT/.agents/skills"; do
  [ -d "$d" ] && SKILLS_DIR="$d" && break
done
[ -n "$SKILLS_DIR" ] || {
  echo "error: $PROJECT has no .claude/skills or .agents/skills dir — not a scaffolded site?" >&2
  exit 1
}

STAMP="$SKILLS_DIR/SUITE-VERSION"
[ -f "$STAMP" ] || {
  echo "error: $STAMP not found — the project predates stamping, so the baseline is unknown." >&2
  echo "Compare by hand (git -C $REPO_DIR log --oneline -- skills/), refresh the copies you" >&2
  echo "care about, then create the stamp with:" >&2
  echo "  printf 'suite_commit: %s\\ncopied: %s\\n' \"\$(git -C $REPO_DIR rev-parse HEAD)\" \"\$(date +%Y-%m-%d)\" > $STAMP" >&2
  exit 1
}

BASE="$(sed -n 's/^suite_commit: //p' "$STAMP")"
if [ -z "$BASE" ] || [ "$BASE" = "unknown" ]; then
  echo "error: the stamp has no usable commit (the suite was installed without git history" >&2
  echo "when this project was scaffolded). Baseline unknown — see the manual steps above." >&2
  exit 1
fi
git -C "$REPO_DIR" cat-file -e "$BASE^{commit}" 2>/dev/null || {
  echo "error: stamped commit $BASE is not in this clone — run 'git pull' first." >&2
  exit 1
}

# Which of THIS project's bundled skills changed upstream since the stamp?
CHANGED="$(git -C "$REPO_DIR" diff --name-only "$BASE" HEAD -- skills/ | cut -d/ -f2 | sort -u)"
STALE=""
for s in $CHANGED; do
  [ -d "$SKILLS_DIR/$s" ] && STALE="$STALE $s"
done

echo "Project:    $PROJECT"
echo "Scaffolded: $(sed -n 's/^copied: //p' "$STAMP") at suite commit $(git -C "$REPO_DIR" rev-parse --short "$BASE")"
echo

if [ -z "$STALE" ]; then
  echo "Up to date — none of this project's bundled skills changed upstream since then."
  exit 0
fi

echo "Bundled skills with upstream updates:"
for s in $STALE; do
  echo
  echo "  $s"
  git -C "$REPO_DIR" log --oneline "$BASE"..HEAD -- "skills/$s" | sed 's/^/    /'
done
echo

if [ "$REFRESH" -eq 0 ]; then
  echo "Refresh them (re-copies the skills above and updates the stamp) with:"
  echo "  scripts/whats-new.sh --refresh $PROJECT"
  exit 0
fi

for s in $STALE; do
  if [ -d "$REPO_DIR/skills/$s" ]; then
    rm -rf "$SKILLS_DIR/$s"
    cp -R "$REPO_DIR/skills/$s" "$SKILLS_DIR/"
    echo "refreshed $s"
  else
    echo "✗ $s was removed upstream — its copy in $SKILLS_DIR is now unmaintained;" >&2
    echo "  delete it yourself if the project no longer needs it." >&2
  fi
done
printf 'suite_commit: %s\ncopied: %s\n' \
  "$(git -C "$REPO_DIR" rev-parse HEAD)" "$(date +%Y-%m-%d)" > "$STAMP"
echo "stamp updated → $(git -C "$REPO_DIR" rev-parse --short HEAD)"
