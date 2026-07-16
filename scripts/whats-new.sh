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
#                                                 # Skills listed in <skills_dir>/REFRESH-KEEP
#                                                 # (one name per line, # comments) are
#                                                 # deliberate local forks: never overwritten,
#                                                 # reported as "(pinned)".
#   scripts/whats-new.sh --stamp <skills_dir>     # write the SUITE-VERSION stamp. This is
#                                                 # the ONLY writer of the stamp format —
#                                                 # new-website's scaffold step calls it too.
#   scripts/whats-new.sh --stamp-tests <tests_dir> # write the TESTS-VERSION stamp next to a
#                                                 # site's tests/ copies. The report uses it
#                                                 # to flag upstream changes to the template
#                                                 # test suite + CONTENT_GUIDE — files that
#                                                 # are FROZEN one-time copies, which
#                                                 # --refresh deliberately never touches
#                                                 # (a blind overwrite would clobber the
#                                                 # site's own PAGES list / exemptions).
#                                                 # Merge those by hand, then re-stamp.
#
# The report also flags a stale Astro MAJOR version (site's package.json vs. the suite's
# current template pin) and points at docs/UPGRADING.md — deliberately a pointer, not an
# auto-refresh: unlike a skill copy, a dependency bump needs a real build + verification
# pass, which is left to the AI assistant reading that doc, not a blind file overwrite here.
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

# Upstream template files that scaffolded sites carry as FROZEN copies (tests/*,
# CONTENT_GUIDE.md). Tracked via TESTS-VERSION; never auto-refreshed.
TEMPLATE_TRACKED='skills/new-website/templates/astro/tests skills/new-website/templates/content-guide.md'

write_tests_stamp() {  # $1 = tests dir
  printf 'suite_commit: %s\ncopied: %s\n' \
    "$(git -C "$REPO_DIR" rev-parse HEAD)" "$(date +%Y-%m-%d)" > "$1/TESTS-VERSION"
}

is_int() { case "$1" in ''|*[!0-9]*) return 1 ;; *) return 0 ;; esac; }

astro_major() {  # $1 = path to a package.json; prints its "astro" dependency's major version
  sed -n 's/.*"astro"[[:space:]]*:[[:space:]]*"[^0-9]*\([0-9][0-9]*\)\..*/\1/p' "$1" | head -1
}

check_astro_version() {  # $1 = project dir; report-only, never mutates
  local pkg="$1/package.json" ref="$REPO_DIR/skills/new-website/templates/astro/package.json"
  [ -f "$pkg" ] && [ -f "$ref" ] || return 0
  local site_major suite_major
  site_major="$(astro_major "$pkg")"
  suite_major="$(astro_major "$ref")"
  is_int "$site_major" && is_int "$suite_major" || return 0
  if [ "$site_major" -lt "$suite_major" ]; then
    echo "Astro version: this site pins astro major $site_major; the suite's current template"
    echo "pins major $suite_major. Ask your AI assistant to follow docs/UPGRADING.md (in the"
    echo "website-builder clone) to upgrade — it walks through the version bump, the known"
    echo "gotchas, and what to verify, so nothing gets silently skipped."
    echo
  fi
}

MODE=report
TARGET=""
for arg in "$@"; do
  case "$arg" in
    --refresh|--stamp|--stamp-tests)
      [ "$MODE" = report ] || { echo "error: conflicting flags: --refresh/--stamp/--stamp-tests" >&2; exit 2; }
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

if [ "$MODE" = stamp-tests ]; then
  [ -n "$TARGET" ] || { echo "error: --stamp-tests needs a <tests_dir> (e.g. <site>/tests)" >&2; exit 2; }
  [ -d "$TARGET" ] || { echo "error: no such directory: $TARGET" >&2; exit 1; }
  if suite_dirty; then
    echo "warning: the suite clone has uncommitted skill edits — the stamp records HEAD," >&2
    echo "which may not match copies made from the working tree. Commit the suite first" >&2
    echo "for a clean baseline." >&2
  fi
  write_tests_stamp "$TARGET"
  echo "stamped $TARGET/TESTS-VERSION → $(git -C "$REPO_DIR" rev-parse --short HEAD)"
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
  local stamp="$1" skills_dir base short_base copied changed stale s missing keep
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

  # Skills pinned by the site (deliberate local forks): REFRESH-KEEP next to the
  # stamp, one skill name per line, '#' comments allowed. --refresh leaves them
  # untouched; the report shows their upstream changes SINCE THE STAMP, marked
  # (pinned). Note a refresh advances the stamp past skipped changes too — each
  # pinned change is reported until the next refresh, not forever.
  keep=""
  [ -f "$skills_dir/REFRESH-KEEP" ] && keep="$(sed 's/#.*//' "$skills_dir/REFRESH-KEEP")"

  if [ -z "$stale" ]; then
    echo "Up to date — none of this dir's bundled skills changed upstream since then."
    return 0
  fi

  echo "Bundled skills with upstream updates:"
  for s in $stale; do
    echo
    if [ -n "$keep" ] && printf '%s\n' $keep | grep -Fxq -- "$s"; then
      echo "  $s   (pinned in REFRESH-KEEP — --refresh will skip it)"
    else
      echo "  $s"
    fi
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
    if [ -n "$keep" ] && printf '%s\n' $keep | grep -Fxq -- "$s"; then
      echo "pinned    $s — in REFRESH-KEEP; local copy left as-is despite upstream changes"
      continue
    fi
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

process_tests_stamp() {  # $1 = tests dir, $2 = baseline commit, $3 = baseline source label
  local tests_dir="$1" base="$2" src="$3" short_base changed f
  if [ -z "$base" ] || [ "$base" = "unknown" ]; then
    echo "error: the tests baseline ($src) has no usable commit (zip install?). Compare by" >&2
    echo "hand, then set a fresh baseline with:  scripts/whats-new.sh --stamp-tests $tests_dir" >&2
    return 1
  fi
  if ! git -C "$REPO_DIR" cat-file -e "$base^{commit}" 2>/dev/null; then
    echo "error: tests baseline $base is not in this clone — run 'git pull' first, or" >&2
    echo "reset it with:  scripts/whats-new.sh --stamp-tests $tests_dir" >&2
    return 1
  fi
  short_base="$(git -C "$REPO_DIR" rev-parse --short "$base")"
  echo "Template tests: $tests_dir (baseline $short_base, from $src)"

  # shellcheck disable=SC2086
  changed="$(git -C "$REPO_DIR" diff --name-only "$base" HEAD -- $TEMPLATE_TRACKED)"
  if [ -z "$changed" ]; then
    echo "Up to date — no upstream changes to the template test suite / CONTENT_GUIDE."
    if [ "${src#SUITE-VERSION}" != "$src" ]; then
      echo "Pin the tests baseline off the fallback (it moves when skills refresh):"
      echo "  scripts/whats-new.sh --stamp-tests $tests_dir"
    fi
    return 0
  fi

  echo
  echo "Template test files changed upstream — your site's copies are NOT auto-refreshed"
  echo "(they are frozen one-time copies that may carry site-specific edits like the"
  echo "PAGES list; --refresh deliberately never touches them):"
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    case "$f" in
      skills/new-website/templates/astro/tests/*)
        echo "  ${f#skills/new-website/templates/astro/} (site copy: tests/$(basename "$f"))" ;;
      skills/new-website/templates/content-guide.md)
        echo "  templates/content-guide.md (site copy: CONTENT_GUIDE.md)" ;;
      *)
        echo "  $f" ;;
    esac
    git -C "$REPO_DIR" log --oneline "$base"..HEAD -- "$f" | sed 's/^/    /'
  done <<CHANGED
$changed
CHANGED
  echo
  echo "Review + merge each by hand, e.g.:"
  echo "  git -C $REPO_DIR diff $short_base HEAD -- $(printf '%s\n' "$changed" | head -1)"
  if printf '%s\n' "$changed" | grep -q '_helpers\.ts$'; then
    echo "NOTE: tests/_helpers.ts changed — specs import it (tone.spec.ts, and i18n.spec.ts"
    echo "on multilingual sites), so merge the helpers together with any spec that uses the"
    echo "new exports, or the import breaks loudly."
  fi
  echo "When the site's copies are current again, advance the baseline:"
  echo "  scripts/whats-new.sh --stamp-tests $tests_dir"
  return 2
}

# Locate every bundled-skills dir by its stamp — covers .claude/skills,
# .agents/skills, and any custom $PROJECT_SKILLS_DIR new-website was run with.
STAMPS="$(find "$PROJECT" -maxdepth 4 -name SUITE-VERSION -not -path '*/node_modules/*' 2>/dev/null | sort)"
if [ -z "$STAMPS" ]; then
  # Even without a skills stamp, a present tests/TESTS-VERSION is actionable —
  # report the tests channel before erroring on the skills side.
  if [ -f "$PROJECT/tests/TESTS-VERSION" ]; then
    TB="$(sed -n 's/^suite_commit: //p' "$PROJECT/tests/TESTS-VERSION")"
    process_tests_stamp "$PROJECT/tests" "$TB" "tests/TESTS-VERSION" || true
    echo
  fi
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

# Capture the tests-channel FALLBACK baseline NOW — before process_dir, whose
# --refresh rewrites the SUITE-VERSION stamps to HEAD; reading it afterwards
# would silently destroy the pre-refresh baseline (and with it all reported
# template-test drift) for every site that predates TESTS-VERSION. With
# multiple stamps (.claude/skills AND .agents/skills), take the OLDEST commit —
# under-reporting is the dangerous direction for a staleness channel.
FALLBACK_BASE=""
while IFS= read -r STAMP; do
  [ -n "$STAMP" ] || continue
  SB="$(sed -n 's/^suite_commit: //p' "$STAMP")"
  [ -n "$SB" ] && [ "$SB" != "unknown" ] || continue
  git -C "$REPO_DIR" cat-file -e "$SB^{commit}" 2>/dev/null || continue
  if [ -z "$FALLBACK_BASE" ]; then
    FALLBACK_BASE="$SB"
  else
    # older = ancestor of the current pick (linear history), else compare dates
    if git -C "$REPO_DIR" merge-base --is-ancestor "$SB" "$FALLBACK_BASE" 2>/dev/null; then
      FALLBACK_BASE="$SB"
    elif [ "$(git -C "$REPO_DIR" show -s --format=%ct "$SB")" -lt "$(git -C "$REPO_DIR" show -s --format=%ct "$FALLBACK_BASE")" ]; then
      FALLBACK_BASE="$SB"
    fi
  fi
done <<EOF
$STAMPS
EOF

FAIL=0
while IFS= read -r STAMP; do
  [ -n "$STAMP" ] || continue
  process_dir "$STAMP" || FAIL=1
  echo
done <<EOF
$STAMPS
EOF

# Template-tests staleness (frozen copies, tracked separately from skill dirs).
# Baseline: tests/TESTS-VERSION when present; pre-existing sites (scaffolded
# before TESTS-VERSION existed) fall back to the first SUITE-VERSION stamp's
# commit — the closest recorded scaffold point — and the report says so.
TESTS_DIR="$PROJECT/tests"
TESTS_STATUS=0
if [ -d "$TESTS_DIR" ]; then
  if [ -f "$TESTS_DIR/TESTS-VERSION" ]; then
    TB="$(sed -n 's/^suite_commit: //p' "$TESTS_DIR/TESTS-VERSION")"
    process_tests_stamp "$TESTS_DIR" "$TB" "tests/TESTS-VERSION" || TESTS_STATUS=$?
  elif [ -n "$FALLBACK_BASE" ]; then
    process_tests_stamp "$TESTS_DIR" "$FALLBACK_BASE" "SUITE-VERSION fallback (oldest stamp, captured pre-refresh) — no tests/TESTS-VERSION yet" || TESTS_STATUS=$?
  else
    echo "note: $TESTS_DIR has no TESTS-VERSION and no skills stamp is usable as a" >&2
    echo "fallback — template-test drift can't be reported. Set a baseline with:" >&2
    echo "  scripts/whats-new.sh --stamp-tests $TESTS_DIR" >&2
  fi
  echo
fi
# Stale template tests (status 2) are a report, not a failure; real errors (1) fail.
[ "$TESTS_STATUS" = 1 ] && FAIL=1

check_astro_version "$PROJECT"

exit $FAIL
