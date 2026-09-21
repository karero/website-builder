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
# "md changes."). Its first review found more ways to lose a claim: a false split at "e.g."
# or at a wrapped "2024.", a fence opened on a list line, an rst "~~~" underline read as a
# fence, a deleted qualifier, and a user's diff settings. Each of those is a fixture here,
# and case H proves the wrapped one really is a miss for grep: a guard that cannot fire is
# worse than none.
#
# Usage: bash skills/independent-review/scripts/test_sweep_claims.sh
set -u
for tool in git python3; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    # A zip recipient without them should not fail `make check`; the sweep itself says so and
    # exits 0 without python3, and that case is tested below whenever python3 is present.
    echo "SKIP: test_sweep_claims.sh needs $tool"
    exit 0
  fi
done
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
printf '# History\n\nThe job never retries\nexcept on a timeout.\n\nThe old runner never ran before\n\nAll services, e.g.\nworkers.\n' >"$R/history.md"
printf '# Wrapped\n' >"$R/docs/wrapped.md"
printf 'Nothing here is kept.\n' >"$R/old.md"
printf 'echo hello\n' >"$R/tool.sh"
printf 'ignored/\n' >"$R/.gitignore"
$git init -q "$R"; $git -C "$R" add -A; $git -C "$R" commit -qm base
$git -C "$R" checkout -qb change

# The change branch adds the text. Line numbers matter to the checks below.
# notes.md:
#   1  a changed heading, so C sits between two hunks
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
# Notes on the rollout

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
# history.md: ways a claim was lost in the first review.
#   3  N: deleting "except on a timeout." widens the claim left on line 3
#   5-6 O: a wrapped line starting "2024." is not a list item; only line 6 is added
#   8-9 P: "e.g." does not end the sentence; only line 9 is edited
#   11-13 Q: a fence opened on a list line must close, or it swallows the rest
#   17 R: "will not" and "won't"
#   19 KNOWN WRONG: an indented code block is read as text (the reference doc says so)
cat >"$R/history.md" <<'EOF'
# History

The job never retries

The old runner never ran before
2024. It ran daily after that.

All services, e.g.
workers, use the new runner.

- ```sh
  make
  ```

Only the owner can approve.

The pin will not move, and the gate won't wait.

    echo "this never runs"
EOF
# A: the phrase wraps across a line break.
printf '# Wrapped\n\nThe verification step has not\nbeen attempted on any device.\n' >"$R/docs/wrapped.md"
# G: the same phrase in a review trail.
printf 'The check has not been attempted.\n' >"$R/docs/reviews/x.md"
# Not prose: swept only when named.
printf 'echo hello\n\necho "it never runs twice"\n' >"$R/tool.sh"
rm "$R/old.md"
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
check "N: a deleted qualifier reports the claim it widened" line diff.out "history.md:3 [never] The job never retries"
check "O: a wrapped '2024.' does not split the claim from its edit" \
  line diff.out "history.md:5-6 [never] The old runner never ran before 2024."
check "P: 'e.g.' does not split the claim from its edit" \
  line diff.out "history.md:8-9 [all] All services, e.g. workers, use the new runner."
check "Q: a fence opened on a list line closes, so what follows is swept" \
  line diff.out "history.md:15 [only] Only the owner can approve."
check "R: future and conditional negatives are listed" \
  line diff.out "history.md:17 [will not, won't] The pin will not move, and the gate won't wait."
check "KNOWN WRONG: an indented code block is read as text" \
  line diff.out 'history.md:19 [never] echo "this never runs"'
check "a file that is not prose is not swept by default" lacks diff.out "tool.sh"
check "a deleted file is left out, not reported as skipped" lacks diff.err "skipped"
check "nothing else is reported" count_is diff.out 14
check "the count goes to stderr" has diff.err "14 sentences to check in 3 files"
check "advisory: exit 0 although it listed sentences" rc_is diff 0

# H: the per-line grep this replaces cannot see fixture A, so A really discriminates.
grep_misses() { ! grep -q -- "$1" "$2"; }
check "H: grep for 'has not been' finds nothing in fixture A" grep_misses 'has not been' "$R/docs/wrapped.md"

# A user's diff settings must not change the list: run from a subdirectory, with settings that
# widen hunks (C would then sit inside one), colour the diff, make it relative to the
# subdirectory, and mark every file binary.
for kv in "color.diff always" "diff.interHunkContext 100" "diff.relative true"; do
  # shellcheck disable=SC2086
  $git -C "$R" config $kv
done
mkdir -p "$R/.git/info"; printf '* -diff\n' >"$R/.git/info/attributes"
run hostile "$R/docs" --base main
for k in color.diff diff.interHunkContext diff.relative; do $git -C "$R" config --unset "$k"; done
rm "$R/.git/info/attributes"
check "user diff settings, from a subdirectory: the same list" cmp -s "$T/diff.out" "$T/hostile.out"
check "user diff settings, from a subdirectory: the same count" has hostile.err "14 sentences to check in 3 files"

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
run both "$R" --base main --file notes.md
check "--base and --file on the same file: each sentence once" count_is both.out 16

# "~~~" is an rst underline, not a fence; a Markdown fence left open is reported, not silent.
printf 'Guide\n=====\n\nUpgrades\n~~~~~~~~\n\nUpgrades are always safe.\n\nData\n~~~~\n\nThe installer never touches your data.\n\nCleanup\n~~~~~~~\n\nNothing is left behind.\n' >"$T/guide.rst"
printf 'Only this is swept.\n\n```\nNothing here is.\n' >"$T/open.md"
# Each rule that keeps a sentence whole, on its own: "e.g." before a capital, and a stop
# before a lowercase word.
printf 'All services, e.g. Python and Go, use the new runner.\n\nEvery job ran, approx. twice a day.\n' >"$T/splits.md"
run files "$R" --file "$T/guide.rst" --file "$T/open.md" --file "$T/splits.md"
check "'e.g.' before a capital does not end the sentence" \
  line files.out "$T/splits.md:1 [all] All services, e.g. Python and Go, use the new runner."
check "a stop before a lowercase word does not end the sentence" \
  line files.out "$T/splits.md:3 [every] Every job ran, approx. twice a day."
check "rst: every section under a '~~~' underline is swept" count_is files.out 6
check "rst: the second section too" has files.out "The installer never touches your data."
check "an unclosed fence: says what was not swept" has files.err "open.md: the code fence opened at line 3 never closes"

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
run dirfile "$R" --file docs
check "an unreadable --file: exit 2" rc_is dirfile 2
check "an unreadable --file: no traceback" lacks dirfile.err "Traceback"
unrelated="$($git -C "$R" commit-tree "$($git -C "$R" mktree </dev/null)" -m unrelated)"
run unrelated "$R" --base "$unrelated"
check "a base with no common ancestor: exit 2" rc_is unrelated 2
check "a base with no common ancestor: says so" has unrelated.err "no common ancestor"
run same "$R" --base HEAD
check "no changed prose: exit 0" rc_is same 0
check "no changed prose: says so" has same.err "no changed"

# A reader that stops early (| head) is not an error, and leaves no traceback.
yes 'Nothing is final.' 2>/dev/null | head -n 3000 >"$T/big.md"
(cd "$R" && bash "$SCRIPT" --file "$T/big.md" 2>"$T/pipe.err" | head -n 1 >/dev/null
 echo "${PIPESTATUS[0]}" >"$T/pipe.rc")
check "a closed pipe: exit 0" rc_is pipe 0
check "a closed pipe: no traceback" lacks pipe.err "Traceback"

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
mkdir -p "$R/ignored"; printf 'It never ran.\n' >"$R/ignored/x.md"
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
check "--worktree: a gitignored file is not" lacks wt.out "ignored/"

if [ $fails -ne 0 ]; then echo "$fails check(s) FAILED"; exit 1; fi
echo "all checks passed"
