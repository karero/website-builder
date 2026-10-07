#!/usr/bin/env bash
# Lists the suite's shell scripts, one repo-relative path per line, sorted. Shared by
# check_cdpath_safe.sh and check_pipefail_pipes.sh, which each need every shell script there is.
#
# Discovery is by SHEBANG, not a *.sh glob — templates/astro/scripts/hooks/pre-push is a tracked,
# shipped, extensionless #!/bin/sh script, and self-location is most idiomatic in exactly that
# file class. Prefer git's own file list where there is one: it excludes NESTED CHECKOUTS for
# free, and a primary checkout routinely has them — .claude/worktrees/<name>/ per parallel
# session, each a full copy of this tree. A plain find walks straight into those and demands
# every script in every one of them be listed, which is how the CDPATH guard broke `make check`
# in the primary checkout while passing in CI and in a linked worktree, neither of which has
# any. The find branch is not dead code: the handoff zip has no git at all, and it is the zip
# recipients that `make check` most needs to work for.
#
# Fails, with the reason on stdout, if it finds fewer than 10: a listing that small cannot be
# right, and a guard that checked it would pass on nothing.
set -uo pipefail
CDPATH= cd -- "$(dirname -- "$0")/.." || { echo "FAIL — cannot cd to the repo root from $0."; exit 1; }

discover() {
  # Only when the suite root IS the toplevel: a zip unpacked inside some other repository would
  # otherwise get that repository's index, which may track none, some or all of these files.
  # git ls-files runs once; its listing is kept for the output.
  if [ "$(git rev-parse --is-inside-work-tree 2>/dev/null)" = true ] &&
     [ -z "$(git rev-parse --show-prefix 2>/dev/null)" ] &&
     tracked="$(git ls-files 2>/dev/null)" && [ -n "$tracked" ]; then
    printf '%s\n' "$tracked"
  else
    find . -type f ! -path './.git/*' ! -path './dist/*' ! -path '*/node_modules/*' \
         ! -path './docs/reviews/*' ! -path './.claude/worktrees/*' -print 2>/dev/null |
      sed 's|^\./||'
  fi |
  while IFS= read -r f; do
    [ -f "$f" ] || continue
    # tr: a tracked binary file's first "line" can hold NUL bytes. bash drops them from a command
    # substitution anyway, and >= 4.4 warns on stderr as it does; dropping them first is silent
    # and leaves the same string to match. LC_ALL=C: under a UTF-8 locale macOS tr stops on the
    # first invalid byte with "Illegal byte sequence".
    case "$(head -n 1 -- "$f" 2>/dev/null | LC_ALL=C tr -d '\0')" in
      '#!'*sh|'#!'*sh' '*) printf '%s\n' "$f" ;;
    esac
  done | sort
}

all="$(discover)"
if [ "$(grep -c . <<<"$all")" -lt 10 ]; then
  echo "FAIL — discovery found fewer than 10 shell scripts; it cannot have run correctly."
  echo "Run this from a checkout or an unpacked handoff zip, with find and head on PATH."
  exit 1
fi
printf '%s\n' "$all"
