#!/usr/bin/env bash
#
# merge_link.sh — the artifact of a MERGE LINK (SKILL.md step 6): after the base was merged into a
# change, or the change rebased, what changed in the change's own files since the last reviewed
# head, merge effects included — reviewed instead of a full round.
#
#   merge_link.sh <old-merge-base> <last-reviewed-head> <new-merge-base> [-- <extra path>...]
#
# Run inside the repository; the new head is HEAD. Prints the diff on stdout (empty: nothing of the
# change moved). Extra paths — files the merge changed that the change's code calls — are added.
#
# The change's own files are taken from BOTH pairs, the old (old-merge-base...last-reviewed-head)
# and the new (new-merge-base...HEAD): a file whose merge resolution threw the change's edit away
# matches the new base again, drops out of the new pair's list, and would otherwise never show
# (final full read, 2026-09-26). Both lists are built with --no-renames: a rename is listed by its
# new name alone, so a merge that brought the old name back left it out (Codex, round 4). The lists
# are NUL-separated and the paths passed literally
# (--literal-pathspecs), so a space, '*', '?', '[' or a leading ':' in a name is just a character;
# docs/reviews/ is dropped from the list itself, since a literal pathspec cannot carry :(exclude).
set -euo pipefail
usage() { echo "usage: merge_link.sh <old-merge-base> <last-reviewed-head> <new-merge-base> [-- <extra path>...]" >&2; exit 2; }
[ $# -ge 3 ] || usage
old_base="$1" reviewed="$2" new_base="$3"; shift 3
if [ $# -gt 0 ]; then [ "$1" = -- ] || usage; shift; fi
for rev in "$old_base" "$reviewed" "$new_base" HEAD; do
  git rev-parse --verify --quiet "$rev^{commit}" >/dev/null || { echo "merge_link.sh: not a commit: $rev" >&2; exit 2; }
done
list="$(mktemp "${TMPDIR:-/tmp}/merge_link.XXXXXX")"; trap 'rm -f "$list"' EXIT
{ git diff -z --no-renames --name-only "$old_base...$reviewed"
  git diff -z --no-renames --name-only "$new_base...HEAD"
  for p in "$@"; do printf '%s\0' "$p"; done
} | perl -0 -ne 'print unless m{^docs/reviews/} or $seen{$_}++' >"$list"
# An empty list must print nothing: xargs with no input runs git diff unfiltered on GNU (the whole
# tree) and not at all on BSD — neither is the merge link.
[ -s "$list" ] || exit 0
xargs -0 git --literal-pathspecs diff "$reviewed" HEAD -- <"$list"
