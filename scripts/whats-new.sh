#!/usr/bin/env bash
# What changed in the suite's skills — overall, or since a project was scaffolded.
#
#   scripts/whats-new.sh                          # recent skill changes in the suite
#   scripts/whats-new.sh <project_dir>            # which of that project's bundled skills
#                                                 # have upstream updates (reads the
#                                                 # SUITE-VERSION stamp new-website wrote)
#   scripts/whats-new.sh --refresh <project_dir>  # re-copy the stale skills and re-stamp.
#                                                 # Overwrites local edits to those copies;
#                                                 # refuses while either the suite clone or
#                                                 # the site has uncommitted skill changes.
#   scripts/whats-new.sh --stamp <skills_dir>     # write the SUITE-VERSION stamp. This is
#                                                 # the ONLY writer of the stamp format —
#                                                 # new-website's scaffold step calls it too.
#
# Needs the git clone of the suite (a zip has no history to compare against).
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd -P)"

# The suite must be a git clone, and REPO_DIR must be that repo's own toplevel —
# not a zip extraction sitting inside some unrelated enclosing repository, whose
# history would silently answer every query below.
TOPLEVEL="$(git -C "$REPO_DIR" rev-parse --show-toplevel 2>/dev/null || true)"
if [ "$TOPLEVEL" != "$REPO_DIR" ]; then
  echo "error: $REPO_DIR is not a git clone of the suite — whats-new compares git" >&2
  echo "history, which a zip install doesn't carry. Clone the suite repo to use this." >&2
  exit 1
fi

suite_dirty() {  # tracked, uncommitted changes under skills/
  [ -n "$(git -C "$REPO_DIR" status --porcelain -uno -- skills/)" ]
}

write_stamp() {  # $1 = skills dir
  printf 'suite_commit: %s\ncopied: %s\n' \
    "$(git -C "$REPO_DIR" rev-parse HEAD)" "$(date +%Y-%m-%d)" > "$1/SUITE-VERSION"
}

MODE=report
TARGET=""
for arg in "$@"; do
  case "$arg" in
    --refresh|--stamp)
      [ "$MODE" = report ] || { echo "error: conflicting flags: --refresh/--stamp" >&2; exit 2; }
      MODE="${arg#--}" ;;
    -*)
      echo "error: unknown flag: $arg" >&2; exit 2 ;;
    *)
      [ -z "$TARGET" ] || { echo "error: unexpected extra argument: $arg" >&2; exit 2; }
      TARGET="$arg" ;;
  esac
done

if [ "$MODE" = stamp ]; then
  [ -n "$TARGET" ] || { echo "error: --stamp needs a <skills_dir> (e.g. <site>/.claude/skills)" >&2; exit 2; }
  [ -d "$TARGET" ] || { echo "error: no such directory: $TARGET" >&2; exit 1; }
  if suite_dirty; then
    echo "warning: the suite clone has uncommitted skill edits — the stamp records HEAD," >&2
    echo "which may not match copies made from the working tree. Commit the suite first" >&2
    echo "for a clean baseline." >&2
  fi
  write_stamp "$TARGET"
  echo "stamped $TARGET/SUITE-VERSION → $(git -C "$REPO_DIR" rev-parse --short HEAD)"
  exit 0
fi

if [ -z "$TARGET" ]; then
  [ "$MODE" = report ] || { echo "error: --refresh needs a <project_dir>" >&2; exit 2; }
  echo "Recent skill changes in the suite (newest first):"
  git -C "$REPO_DIR" log --oneline -20 -- skills/
  echo
  echo "Tip: scripts/whats-new.sh <project_dir> shows what a scaffolded project is missing."
  exit 0
fi

PROJECT="${TARGET%/}"
[ -d "$PROJECT" ] || { echo "error: no such directory: $PROJECT" >&2; exit 1; }
# Absolute physical path: `git -C` re-anchors relative pathspecs to the repo dir,
# which would silently defeat the dirty guards below for a relative <project_dir>.
PROJECT="$(cd "$PROJECT" && pwd -P)"

process_dir() {  # $1 = path to a SUITE-VERSION stamp
  local stamp="$1" skills_dir base short_base copied changed stale s missing
  skills_dir="$(dirname "$stamp")"
  base="$(sed -n 's/^suite_commit: //p' "$stamp")"
  copied="$(sed -n 's/^copied: //p' "$stamp")"

  echo "Skills dir: $skills_dir"

  if [ -z "$base" ] || [ "$base" = "unknown" ]; then
    echo "error: this stamp has no usable commit (the suite had no git history when the" >&2
    echo "project was scaffolded, e.g. a zip install). Refresh the copies by hand if" >&2
    echo "needed, then set a fresh baseline with:" >&2
    echo "  scripts/whats-new.sh --stamp $skills_dir" >&2
    return 1
  fi
  if ! git -C "$REPO_DIR" cat-file -e "$base^{commit}" 2>/dev/null; then
    echo "error: stamped commit $base is not in this clone — run 'git pull' first." >&2
    echo "If it still fails, the stamp was written against a different repository;" >&2
    echo "reset the baseline with:  scripts/whats-new.sh --stamp $skills_dir" >&2
    return 1
  fi
  short_base="$(git -C "$REPO_DIR" rev-parse --short "$base")"
  echo "Scaffolded: $copied at suite commit $short_base"
  echo

  changed="$(git -C "$REPO_DIR" diff --name-only "$base" HEAD -- skills/ | cut -d/ -f2 | sort -u)"
  stale=""
  for s in $changed; do
    [ -d "$skills_dir/$s" ] && stale="$stale $s"
  done

  if [ -z "$stale" ]; then
    echo "Up to date — none of this dir's bundled skills changed upstream since then."
    return 0
  fi

  echo "Bundled skills with upstream updates:"
  for s in $stale; do
    echo
    echo "  $s"
    git -C "$REPO_DIR" log --oneline "$base"..HEAD -- "skills/$s" | sed 's/^/    /'
  done
  echo

  if [ "$MODE" != refresh ]; then
    echo "Refresh them (re-copies the skills above and re-stamps; OVERWRITES any local"
    echo "edits to those copies) with:"
    echo "  scripts/whats-new.sh --refresh $PROJECT"
    return 0
  fi

  # Refresh guards — refuse when either side would lose or skew content.
  if suite_dirty; then
    echo "error: the suite clone has uncommitted changes under skills/ — a refresh would" >&2
    echo "copy content matching no commit while stamping HEAD. Commit or stash first." >&2
    return 1
  fi
  if git -C "$PROJECT" rev-parse --show-toplevel >/dev/null 2>&1; then
    if [ -n "$(git -C "$skills_dir" status --porcelain . 2>/dev/null)" ]; then
      echo "error: the site has uncommitted changes under $skills_dir — a refresh would" >&2
      echo "overwrite them irrecoverably. Commit them in the site repo first; then any" >&2
      echo "overwrite stays recoverable via the site's git history." >&2
      return 1
    fi
    echo "note: refresh overwrites these skill copies; local edits stay recoverable via"
    echo "the site repo's git history."
  else
    echo "warning: $PROJECT is not a git repo — refresh OVERWRITES local edits to these" >&2
    echo "skill copies with no way back." >&2
  fi

  missing=0
  for s in $stale; do
    if [ -d "$REPO_DIR/skills/$s" ]; then
      rm -rf "${skills_dir:?}/$s"
      cp -R "$REPO_DIR/skills/$s" "$skills_dir/"
      find "$skills_dir/$s" -name .DS_Store -delete 2>/dev/null || true
      echo "refreshed $s"
    else
      echo "✗ $s was removed upstream — its copy in $skills_dir is now unmaintained;" >&2
      echo "  delete it (or keep it knowingly), then re-run --refresh to advance the stamp." >&2
      missing=1
    fi
  done
  if [ "$missing" -ne 0 ]; then
    echo "stamp NOT advanced (still $short_base) so the removed-upstream warning keeps firing." >&2
    return 1
  fi
  write_stamp "$skills_dir"
  echo "stamp updated → $(git -C "$REPO_DIR" rev-parse --short HEAD)"
}

# Locate every bundled-skills dir by its stamp — covers .claude/skills,
# .agents/skills, and any custom $PROJECT_SKILLS_DIR new-website was run with.
STAMPS="$(find "$PROJECT" -maxdepth 4 -name SUITE-VERSION -not -path '*/node_modules/*' 2>/dev/null | sort)"
if [ -z "$STAMPS" ]; then
  for d in "$PROJECT/.claude/skills" "$PROJECT/.agents/skills"; do
    [ -d "$d" ] || continue
    echo "error: $d exists but has no SUITE-VERSION stamp — the project predates stamping." >&2
    echo "Baseline unknown; compare by hand (git -C $REPO_DIR log --oneline -- skills/)," >&2
    echo "refresh the copies you care about, then create the stamp with:" >&2
    echo "  scripts/whats-new.sh --stamp $d" >&2
    exit 1
  done
  echo "error: no SUITE-VERSION stamp (and no .claude/skills or .agents/skills dir)" >&2
  echo "found under $PROJECT — not a site scaffolded by new-website?" >&2
  exit 1
fi

echo "Project:    $PROJECT"
FAIL=0
while IFS= read -r STAMP; do
  [ -n "$STAMP" ] || continue
  process_dir "$STAMP" || FAIL=1
  echo
done <<EOF
$STAMPS
EOF
exit $FAIL
