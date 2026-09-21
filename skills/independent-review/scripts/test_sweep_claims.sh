#!/usr/bin/env bash
#
# test_sweep_claims.sh — drives sweep_claims.sh the way an author does before round 1
# (--base on a branch, --file on a plan, --worktree on uncommitted edits) against a
# throwaway repo: a branch adds known text, then main moves on, as it does in real life.
#
# Why it exists: the sweep is only worth running if it sees what a per-line grep cannot.
# A per-line grep missed a phrase wrapped across a line break; an earlier sweep silently
# dropped every sentence ending in ".)" or ".*"; the one after it dropped the start of any
# sentence with a period inside a word ("Nothing in SKILL.md changes." came out as
# "md changes.").
# Each of those is a fixture here, and case H proves the wrapped one really is a miss for
# grep: a guard that cannot fire is worse than none.
#
# Usage: bash skills/independent-review/scripts/test_sweep_claims.sh
set -u
if ! command -v git >/dev/null 2>&1; then
  echo "SKIP: test_sweep_claims.sh needs git (it builds a throwaway repo)"
  exit 0
fi
HERE="$(cd "$(dirname "$0")" && pwd)"
SCRIPT="$HERE/sweep_claims.sh"
T="$(mktemp -d "${TMPDIR:-/tmp}/sweep-claims-test.XXXXXX")"
trap 'rm -rf "$T"' EXIT
# Hermetic: a developer's global hooks or signing must not decide whether this passes, and
# the "not a repository" case must not find a repo above $T.
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null GIT_CEILING_DIRECTORIES="$T"
git="git -c user.name=t -c user.email=t@t -c init.defaultBranch=main -c commit.gpgsign=false -c core.hooksPath=/dev/null"
R="$T/repo"
mkdir -p "$R/docs/reviews" "$T/notrepo" "$T/nopython"

# The base, on main.
printf '# Notes\n\nThe first release never shipped to users.\n\nEvery job ran on the old runner.\nThe new runner is ready.\n' >"$R/notes.md"
printf '# Wrapped\n' >"$R/docs/wrapped.md"
printf 'echo hello\n' >"$R/tool.sh"
$git init -q "$R"; $git -C "$R" add -A; $git -C "$R" commit -qm base
$git -C "$R" checkout -qb change

# The change branch adds the text. Line numbers in notes.md matter to the checks below.
#   3  C: "never" in a paragraph the change does not touch
#   5  D: first sentence of an old paragraph, untouched ("Every")
#   6  D: its second sentence, edited ("only")
#   8-9  B: wraps AND ends ".)*", then another sentence in the same paragraph
#   13 E: a table row
#   16 F: "never" inside a fenced code block (a "#" line there is not a heading)
#   19 J: a period inside a word before the sentence's end
#   21-22 K: two list items; a sentence must not run from one into the next
#   24-25 L: a heading with a paragraph straight under it
#   27-28 M: a quoted paragraph (its ">" markers must not reach the sentence)
cat >"$R/notes.md" <<'EOF'
# Notes

The first release never shipped to users.

Every job ran on the old runner.
The new runner is only ready for tests.

*(As of 2026-01-01, the check has not been
attempted; see Status, row 2.)* The next run is planned.

| # | Step | State | Evidence |
|---|---|---|---|
| 2 | Check | was not attempted | — |

```sh
# never run this twice
```

Nothing in SKILL.md changes.

- Alpha is fine
- Beta was not run

## Plan
Nothing is scheduled yet

> Nothing here
> is final.
EOF
# A: the phrase wraps across a line break.
printf '# Wrapped\n\nThe verification step has not\nbeen attempted on any device.\n' >"$R/docs/wrapped.md"
# G: the same phrase in a review trail.
printf 'The check has not been attempted.\n' >"$R/docs/reviews/x.md"
# Not prose: swept only when named.
printf 'echo hello\n\necho "it never runs twice"\n' >"$R/tool.sh"
$git -C "$R" add -A; $git -C "$R" commit -qm change
# Then main moves on and rewrites C's line. The change still has the old line, so a
# two-dot diff from main would list it as added; the three-dot diff must not.
$git -C "$R" checkout -q main
printf '# Notes\n\nThe first release shipped late.\n\nEvery job ran on the old runner.\nThe new runner is ready.\n' >"$R/notes.md"
$git -C "$R" commit -qam "main moves on"
$git -C "$R" checkout -q change

# run <name> <dir> <args...> — runs the sweep from <dir>; leaves $T/<name>.out, .err and .rc
run() {
  local name="$1" dir="$2"; shift 2
  (cd "$dir" && bash "$SCRIPT" "$@") >"$T/$name.out" 2>"$T/$name.err"
  echo $? >"$T/$name.rc"
}
fails=0
check() {   # check <description> <command ...>
  if "${@:2}"; then printf 'ok   %s\n' "$1"; else printf 'FAIL %s\n' "$1"; fails=$((fails+1)); fi
}
line()  { grep -qxF -- "$2" "$T/$1"; }   # the whole output line, exactly
has()   { grep -qF -- "$2" "$T/$1"; }
lacks() { ! grep -qF -- "$2" "$T/$1"; }
rc_is() { [ "$(cat "$T/$1.rc")" = "$2" ]; }
count_is() { [ "$(grep -c . "$T/$1")" = "$2" ]; }

# The branch sweep: added lines only, read at the head commit.
run diff "$R" --base main
check "A: a phrase wrapped across a line break is reported, with its line range" \
  line diff.out "docs/wrapped.md:3-4 [has not, any] The verification step has not been attempted on any device."
check "B: a wrapped sentence ending '.)*' is reported and ends there" \
  line diff.out "notes.md:8-9 [has not] *(As of 2026-01-01, the check has not been attempted; see Status, row 2.)*"
check "C: an untouched paragraph is not reported, although main has since changed it" lacks diff.out "never shipped"
check "D: the edited second sentence is reported alone" \
  line diff.out "notes.md:6 [only] The new runner is only ready for tests."
check "D: the untouched first sentence of the same paragraph is not" lacks diff.out "Every job"
check "E: a table cell is reported" line diff.out "notes.md:13 [was not] was not attempted"
check "F: a fenced code block is not reported" lacks diff.out "run this twice"
check "G: a review trail is not swept by default" lacks diff.out "docs/reviews/"
check "J: a period inside a word does not cut the sentence" \
  line diff.out "notes.md:19 [nothing] Nothing in SKILL.md changes."
check "K: a list item does not run into the next" line diff.out "notes.md:22 [was not] Beta was not run"
check "L: a heading does not run into its paragraph" line diff.out "notes.md:25 [nothing] Nothing is scheduled yet"
check "M: a quoted paragraph reads as one sentence, without its markers" \
  line diff.out "notes.md:27-28 [nothing] Nothing here is final."
check "a file that is not prose is not swept by default" lacks diff.out "tool.sh"
check "nothing else is reported" count_is diff.out 8
check "the count goes to stderr" has diff.err "8 sentences to check in 2 files"
check "advisory: exit 0 although it listed sentences" rc_is diff 0

# H: the per-line grep this replaces cannot see fixture A, so A really discriminates.
grep_misses() { ! grep -q -- "$1" "$2"; }
check "H: grep for 'has not been' finds nothing in fixture A" grep_misses 'has not been' "$R/docs/wrapped.md"

# PATH arguments replace the default set and are taken as given.
run named "$R" --base main tool.sh
check "a named file is swept whatever its type" line named.out 'tool.sh:3 [never] echo "it never runs twice"'
check "and only the named file" count_is named.out 1

# I: --file sweeps a whole document, touched or not.
run whole "$R" --file notes.md
check "I: --file reports the untouched paragraph" \
  line whole.out "notes.md:3 [first, never] The first release never shipped to users."
check "I: --file reports the untouched first sentence" line whole.out "notes.md:5 [every] Every job ran on the old runner."
check "I: --file still skips fenced code" lacks whole.out "run this twice"
check "I: --file reports every matching sentence" count_is whole.out 9

# Usage errors exit 2; nothing to sweep is not one.
run noargs "$R"
check "no --base and no --file: exit 2" rc_is noargs 2
run headwt "$R" --base main --head HEAD --worktree
check "--head with --worktree: exit 2" rc_is headwt 2
run badref "$R" --base no-such-ref
check "an unknown ref: exit 2" rc_is badref 2
check "an unknown ref: says which" has badref.err "no-such-ref"
run notrepo "$T/notrepo" --base main
check "outside a repository: exit 2" rc_is notrepo 2
run nofile "$R" --file missing.md
check "a missing --file: exit 2" rc_is nofile 2
run same "$R" --base HEAD
check "no changed prose: exit 0" rc_is same 0
check "no changed prose: says so" has same.err "no changed"

# Without python3 the skill must stay usable: one line, exit 0.
(cd "$R" && env PATH="$T/nopython" "$BASH" "$SCRIPT" --base main) >"$T/nopy.out" 2>"$T/nopy.err"
echo $? >"$T/nopy.rc"
check "no python3: exit 0" rc_is nopy 0
check "no python3: says so in one line" [ "$(grep -c python3 "$T/nopy.err")" = 1 ]
check "no python3: lists nothing" count_is nopy.out 0

# Uncommitted edits: the default reads the head commit; --worktree reads the files.
printf '\nThe rollout is never automatic.\n' >>"$R/notes.md"
printf '# Wrapped\n\nThe verification step has not\nbeen attempted on every device.\n' >"$R/docs/wrapped.md"
printf 'Only the owner can approve.\n' >"$R/draft.md"
printf 'It never ran.\n' >"$R/docs/reviews/y.md"
run committed "$R" --base main
check "default: an uncommitted edit is not read" lacks committed.out "rollout"
check "default: an added line is read at head, not from the edited file" \
  line committed.out "docs/wrapped.md:3-4 [has not, any] The verification step has not been attempted on any device."
check "default: an untracked file is not read" lacks committed.out "draft.md"
run wt "$R" --base main --worktree
check "--worktree: an uncommitted edit is reported" line wt.out "notes.md:30 [never] The rollout is never automatic."
check "--worktree: an untracked prose file is reported" line wt.out "draft.md:1 [only] Only the owner can approve."
check "--worktree: an added line is read from the edited file" \
  line wt.out "docs/wrapped.md:3-4 [has not, every] The verification step has not been attempted on every device."
check "--worktree: an untracked review trail is not" lacks wt.out "docs/reviews/"

if [ $fails -ne 0 ]; then echo "$fails check(s) FAILED"; exit 1; fi
echo "all checks passed"
