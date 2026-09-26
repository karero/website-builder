#!/usr/bin/env bash
# Guard: an exported CDPATH must not change what any script does.
#
# `cd "$(dirname "$0")"` is wrong when CDPATH is exported: cd searches CDPATH before the
# current directory for a relative operand, so it can land elsewhere — and it prints where it
# went, corrupting any $(...) capturing it. Both modes were live here until 2026-09-26:
# `CDPATH=/tmp/cdp make check` exited 2, and whats-new.sh resolved a relative <project_dir>
# to a same-named decoy that --refresh would then have written into.
#
# Why a guard: nothing else in this repo sets CDPATH, so a green `make check` looks identical
# whether the scripts are safe or not — the same reason check_template_coverage.sh exists.
#
# Why BEHAVIOURAL, not a grep. The first version of this guard scanned for the textual idiom.
# A review round drove a truck through it: pushd, `SELF=$(dirname "$0"); cd "$SELF"`,
# `cd "${0%/*}"`, backticks, a space after `$(`, a backslash continuation and a second cd on
# the same line all evaded it; `CDPATH=""` and `unset CDPATH` produced false FAILs; it never
# covered the caller-supplied `cd "$PROJECT"` that was the original bug; and a *.sh glob could
# not see extensionless scripts. Running each subject twice and comparing has none of those
# holes, because it tests behaviour instead of spelling.
#
# The comparison is between the two RUNS, deliberately not against a known-good result: a
# subject that fails for its own unrelated reason fails identically both times and is not this
# guard's business. That keeps a leaked model name (say) from also turning this job red.
set -uo pipefail
CDPATH= cd -- "$(dirname -- "$0")/.." || { echo "FAIL — cannot cd to the repo root from $0."; exit 1; }

# Subjects: run twice and diff. Every one is read-only and quick. Invoked by a RELATIVE path,
# which is what makes CDPATH reachable at all.
SUBJECTS=(
  scripts/check_clean.sh
  scripts/check_model_agnostic.sh
  scripts/check_template_coverage.sh
  scripts/check_skill_budgets.sh
  scripts/whats-new.sh
  skills/independent-review/scripts/check_prompt_sync.sh
)
# Not run here, each for a reason — not because nobody got to them. The completeness check
# below forces a new script into one list or the other, the same way check_template_coverage.sh
# forces a new template file into a bucket.
NOT_RUN=(
  scripts/install.sh                                            # writes symlinks into ~/.claude/skills
  scripts/install-codex.sh                                      # writes symlinks into ~/.agents/skills
  scripts/package.sh                                            # builds dist/, and runs check itself
  scripts/test_install_pin.sh                                   # builds throwaway repos; needs git
  scripts/test_pre_push_hook.sh                                 # builds a throwaway repo; needs git
  scripts/check_cdpath_safe.sh                                  # this file
  skills/independent-review/scripts/independent_review.sh       # calls external reviewers, costs money
  skills/independent-review/scripts/test_failed_tier_report.sh  # slow; stubs a whole CLI
  skills/independent-review/scripts/test_looks_like_review.sh   # slow; stubs a whole CLI
  skills/new-website/templates/astro/tests/check_ship_push.sh   # template test; needs a built site
  skills/new-website/templates/astro/scripts/hooks/pre-push     # git hook; expects a push context
  skills/new-website/templates/astro/scripts/ship.sh            # template: pushes a site live
  skills/new-website/templates/astro/scripts/check_external_links.sh # template: needs a built site + network
  skills/new-website/templates/astro/scripts/check_internal_links.sh # template: needs a built site
  skills/search-console-insights/scripts/track.sh               # network + OAuth
  skills/search-console-insights/scripts/schedule_tracking.sh   # writes a launchd job
)

rc=0

# Completeness: every shell script must sit in exactly one list, so a new one forces a
# deliberate choice instead of being silently uncovered. Discovery is by SHEBANG, not a *.sh
# glob — templates/astro/scripts/hooks/pre-push is a tracked, shipped, extensionless #!/bin/sh
# script, and self-location is most idiomatic in exactly that file class.
discover() {
  find . -type f ! -path './.git/*' ! -path './dist/*' ! -path '*/node_modules/*' \
       ! -path './docs/reviews/*' -print 2>/dev/null |
  while IFS= read -r f; do
    case "$(head -n 1 -- "$f" 2>/dev/null)" in
      '#!'*sh|'#!'*sh' '*) printf '%s\n' "${f#./}" ;;
    esac
  done | sort
}
all_scripts="$(discover)"
if [ "$(printf '%s\n' "$all_scripts" | grep -c .)" -lt 10 ]; then
  echo "FAIL — discovery found fewer than 10 shell scripts; it cannot have run correctly."
  echo "Run this from a checkout or an unpacked handoff zip, with find and head on PATH."
  exit 1
fi
listed="$(printf '%s\n' "${SUBJECTS[@]}" "${NOT_RUN[@]}" | sort)"
unlisted="$(comm -23 <(printf '%s\n' "$all_scripts") <(printf '%s\n' "$listed"))"
stale="$(comm -13 <(printf '%s\n' "$all_scripts") <(printf '%s\n' "$listed"))"
if [ -n "$unlisted" ]; then
  echo "FAIL — these shell scripts are in neither SUBJECTS nor NOT_RUN in $0:"
  printf '%s\n' "$unlisted" | sed 's/^/    /'
  echo "Add each to SUBJECTS (run twice, compare) or to NOT_RUN with the reason it cannot be run."
  rc=1
fi
if [ -n "$stale" ]; then
  echo "FAIL — these are listed in $0 but no longer exist (or lost their shebang):"
  printf '%s\n' "$stale" | sed 's/^/    /'
  rc=1
fi

# --- behavioural case: CDPATH must change nothing --------------------------------------------
decoy="$(mktemp -d)"
proj="$(mktemp -d)"
trap 'rm -rf "$decoy" "$proj"' EXIT
# The decoy must contain the first path segment of each subject, or cd never resolves into it.
mkdir -p "$decoy/scripts" "$decoy/skills/independent-review/scripts"

# GitHub's runners start jobs with SIGPIPE ignored, and a shell cannot un-ignore a signal it
# inherited that way. A `producer | head` in a subject then prints "write error: Broken pipe"
# at random, and the two runs differ for a reason unrelated to CDPATH (PR #125). Run each
# subject with SIGPIPE at its default, as on a laptop, when perl is there to reset it.
default_sigpipe() {
  if command -v perl >/dev/null 2>&1; then
    perl -e '$SIG{PIPE} = "DEFAULT"; exec @ARGV or die "exec $ARGV[0]: $!\n"' -- "$@"
  else
    "$@"
  fi
}

diffs=0
for s in "${SUBJECTS[@]}"; do
  [ -f "$s" ] || { echo "FAIL — subject $s does not exist."; rc=1; continue; }
  a_out="$(default_sigpipe bash "$s" 2>&1)"; a_rc=$?
  b_out="$(CDPATH="$decoy" default_sigpipe bash "$s" 2>&1)"; b_rc=$?
  if [ "$a_rc" != "$b_rc" ] || [ "$a_out" != "$b_out" ]; then
    echo "FAIL — $s behaves differently under an exported CDPATH (exit $a_rc vs $b_rc):"
    diff <(printf '%s\n' "$a_out") <(printf '%s\n' "$b_out") | head -20 | sed 's/^/    /'
    diffs=$((diffs + 1)); rc=1
  fi
done
[ "$diffs" = 0 ] && echo "OK — all ${#SUBJECTS[@]} subjects behave identically with and without an exported CDPATH."

# --- regression case for the original bug -----------------------------------------------------
# The loop above cannot catch it: <project_dir> comes from the CALLER, so it needs a real
# project and a same-named decoy to resolve away to.
mkdir -p "$proj/real/myproj/.claude/skills" "$proj/decoy/myproj/.claude/skills"
printf 'suite_commit: %s\n' "$(git rev-parse HEAD 2>/dev/null || echo unknown)" \
  > "$proj/real/myproj/.claude/skills/SUITE-VERSION"
printf 'suite_commit: 0000000\n' > "$proj/decoy/myproj/.claude/skills/SUITE-VERSION"
here="$PWD"
got="$(cd "$proj/real" && CDPATH="$proj/decoy" bash "$here/scripts/whats-new.sh" myproj 2>&1 |
        sed -n 's/^Project: *//p')"
case "$got" in
  *"/real/myproj")
    echo "OK — whats-new.sh resolves a relative <project_dir> to the real one, not a CDPATH decoy." ;;
  *)
    echo "FAIL — whats-new.sh did not resolve a relative <project_dir> to the real directory."
    echo "    got: [${got:-<nothing>}]"
    echo "    --refresh writes into that path, so this is the wrong-project case, not a bad report."
    rc=1 ;;
esac

exit $rc
