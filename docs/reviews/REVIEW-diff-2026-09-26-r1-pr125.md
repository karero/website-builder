# Independent review — DIFF gate — PR #125, rounds 1–3

**Change:** the site template's pre-push hook
(`skills/new-website/templates/astro/scripts/hooks/pre-push`) skips the build/test gate for a
push that only deletes refs. It reads git's ref lines once and replays them, so the optional
PR-only-main block still sees them.
**Artifact:** `git diff <base> <head> -- . ':(exclude)docs/reviews'`, per round. The exclusion
keeps reviewers on the change, not on this trail.
**Date:** 2026-09-26. **Base (merge-base with `main`), every round:** `8cfed4f`.

## Reviewer seats per round

| round | head reviewed | seat | version / model / sandbox | BUG | RISK | NIT |
|---|---|---|---|---|---|---|
| 1 | `8a40055` | codex | codex-cli 0.157.0, `gpt-6-astra`, read-only sandbox | 0 | 0 | 0 |
| 1 | `8a40055` | ollama-cloud | ollama 0.34.4, `kimi-k2.7-code:cloud`, text only | 0 | 3 | 2 |
| 1 | `8a40055` | fresh-eyes | Claude sub-agent, no shared context, read-only, experiments in temp dirs | 0 | 0 | 2 |
| 2 | `84ea3ee` | fresh-eyes | same | 0 | 1 | 2 |
| 3 | `7a7ed4e` | fresh-eyes | same | 0 | 0 | 3 |

Round 1's raw notes are the two PR comments headed "Independent review, round 1". Rounds 2 and 3
ran in a cloud session where neither the codex nor the ollama CLI is installed. Those rounds had
only the fresh-eyes seat, which is the same model family as the author and **does not count as
cross-model**.

## Findings and dispositions

| id | round | seat | sev | finding | disposition | status |
|---|---|---|---|---|---|---|
| R1-O1 | 1 | ollama | RISK | `exec <<PUSH_LINES` changes stdin for every later step | **REFUTED.** Before this PR, build and test inherited git's unread stdin pipe, which held the same ref lines. Only a hand-run from a terminal differs: later steps now get a blank line, not the tty. Round 2 confirmed this: `npm run build` gets the replayed lines, as it got git's before, and `npm test` gets EOF, as before. | `externally_reverified` (fresh-eyes) |
| R1-O3 | 1 | ollama | RISK | the PR-only block depends on that redirect | **REFUTED** together with R1-O1. It only matters if the redirect is removed. | same |
| R1-O2 | 1 | ollama | RISK | a future edit giving the skip line the `▶ pre-push gate` prefix would make `ship.sh:182` read a skip as a failed gate | **FIXED** (`6833cc5`): a comment above the skip echo forbids the prefix and says why. | `externally_reverified` (round 2) |
| R1-O4 | 1 | ollama | NIT | give the skip line a stable sentinel token | **REFUTED**: the R1-O2 comment covers it, and no consumer parses the skip line. | — |
| R1-O5 | 1 | ollama | NIT | the blank-line guard is clutter | **REFUTED**: an empty `$push_lines` replays as one blank line, which without the guard sets `saw_ref=1` and skips the gate. Round 2 confirmed. | `externally_reverified` |
| R1-F1 | 1 | fresh-eyes | NIT | `website-team-setup` §5-B still says a stock hook differs by two additions | **FIXED** (`84ea3ee`, reworded in `7a7ed4e`): it now names four additions and the reason for each position. The owner chose "fix" over "waive" in this session. | `externally_reverified` (round 3) |
| R1-F2 | 1 | fresh-eyes | NIT | with stdin closed, `$(cat)` hangs under bash and fails under dash | **FIXED** (`6833cc5`) with `[ -p /dev/stdin ] \|\| [ -f /dev/stdin ]`. **That fix was wrong; see R2-1.** | superseded |
| R2-1 | 2 | fresh-eyes | **RISK** | the R1-F2 guard fails open: without `/proc`, or with a socket on stdin, it reads nothing, and an enabled PR-only block lets a push to `main` through. The base hook refused it. | **FIXED** (`7a7ed4e`): `if [ -t 0 ] \|\| ! true 2>/dev/null 3<&0; then push_lines=""; else push_lines=$(cat); fi` reads anything except a terminal or a closed fd. The host reproduced the fail-open first (`unshare -rm` plus a tmpfs over `/proc`: base hook blocked, head passed). | `externally_reverified` (round 3) |
| R2-2 | 2 | fresh-eyes | NIT | the §5-B wording gave the wrong reason for the capture's position | **FIXED** (`7a7ed4e`). | `externally_reverified` (round 3) |
| R2-3 | 2 | fresh-eyes | NIT | no automated test runs the hook | **FIXED** (`e235c0f`): `scripts/test_pre_push_hook.sh`, wired into `make check` and `clean.yml`. The owner chose "add a test" over "waive" in this session. | `locally_verified` |
| R3-1 | 3 | fresh-eyes | NIT | a write-only stdin passes the probe, then `cat` fails; this fails closed, hand-run only | **FIXED** as a comment in the hook (`e235c0f`); no code change, since `$(cat) \|\| true` would fail open. | `locally_verified` |
| R3-2 | 3 | fresh-eyes | NIT | a hand-run from a pipe that never closes now waits with the block off too | **FIXED** as a comment in the hook (`e235c0f`); git's pipe cannot be told apart from any other. | `locally_verified` |

R2-1 is the finding that justified the extra rounds. It was **introduced by round 1's own fix**,
and only a verification round caught it: the round-1 stubbed-stdin matrix passed, because
`/proc` was present there.

## Convergence (step 7)

BUG/RISK per round: 3 → 1 → 0. The round-2 RISK was new ground: code written by the round-1
fix, not a re-raise. Nothing a round fixed was broken again later. Round 3 had zero BUG and
zero RISK, which is clean under step 6(a2), so iteration stopped. Its NITs were fixed without
another round.

## Verification status (step 6)

The code that round 3 saw (`7a7ed4e`) is `externally_reverified`, **by the fresh-eyes seat only**.
**The closing edits are `locally_verified`: they were not externally re-verified.** Those edits
are the R3 comments and `scripts/test_pre_push_hook.sh`.

**Last round not externally re-verified by a cross-model seat.** Codex and ollama saw only
`8a40055`. Every change after that has been seen by the same-family seat alone, or by nobody.
That includes the stdin guard (`7a7ed4e`) and the new test (`e235c0f`).

Local evidence for the closing edits:
- `scripts/test_pre_push_hook.sh`: 83 checks pass on Linux (bash, sh=dash, dash; block off and
  on; stdin from a pipe, a file, `/dev/null`, closed, a socket, and no `/proc`; real
  `git push` to a bare remote).
- Mutation check. With the `8a40055`→`84ea3ee` guard swapped in, it fails 6 checks: socket and
  no-`/proc`, block on, every shell. With `:` swapped in for `true`, it fails 4 checks: closed
  stdin under dash.
- `make check` passes.

## Consolidated marker

**Not stamped.** GATED-THIS-DIFF needs every seat in the verdict to have seen the pair being
certified (closeout, clerk item 2). The current pair is `8cfed4f` → `e235c0f`, plus this trail
commit, whose diff-scope is identical. Codex and ollama have not seen it, and the fresh-eyes
seat has not seen the closing edits. The owner cannot waive this. To stamp, a session with
the codex and ollama CLIs must re-gate the current pair with every seat.

## Gated actions and the authority relied on (audit duty)

- **Commits and pushes to the PR head** `claude/recursing-sammet-8abc54` (BRANCH-COMMIT): atom B.
  In this session the owner chose "PR #125's head branch" when asked where the fix commits
  should go.
- **This trail file** (WORKTREE-WRITE): atom A. The session works in its own clone, cloned at
  container start.
- **Raw round-1 comments on #125** (POST AUTHORITY): posted by the previous session, on the
  owner's "let's review it" for this PR.
- **The consolidated PR comment** (POST AUTHORITY): the same instruction; this close-out is
  part of that review.
- **Marker stamp** (GATED-THIS-DIFF): not taken; see above.

## CI flake: fixed on `main` first, so this PR carries `main`'s fix

`cdpath-safe` failed at random, on this PR and on `main`. The cause was two pipelines in
`skills/independent-review/scripts/check_prompt_sync.sh` whose last stage stops reading early
(`| head -1`, `| grep -q`). GitHub's runners start jobs with SIGPIPE ignored, so the upstream
`grep` printed `write error: Broken pipe`, and `check_cdpath_safe.sh` compared stderr.

At the owner's request this PR first carried its own fix (`a346e67`, and a SIGPIPE reset in the
harness). The first patch proposed on the PR, `grep -m1`, was wrong: it moves the early exit one
stage up, and measured 6/100 against 3/100.

Meanwhile `main` fixed the same thing at the root: #123 and #127 compare stdout and exit status
instead of stderr, and remove the race. Merging `main` (conflicts in both files) took **`main`'s
version of both files unchanged**. The only line this PR adds to `check_cdpath_safe.sh` is the
NOT_RUN entry for `scripts/test_pre_push_hook.sh`. None of this PR's own flake code remains.

## Round 4 — `/code-review` (fresh eyes, same family), pair `8cfed4f` → `a346e67`

7 findings, each checked against the code before acting:

| # | finding | disposition |
|---|---|---|
| 1–2 | `make check` in the handoff zip calls `test_pre_push_hook.sh`, which `package.sh` neither ships nor requires | **FIXED**: shipped and in `REQUIRED`. `make check` inside the unpacked zip passes. (It then also failed on the `whats-new` CDPATH case, because the branch was behind `main`'s #123 zip fix; the merge fixed that.) |
| 3 | the harness, not one subject, should stop a stray SIGPIPE message failing the check | **FIXED by `main`** (#123 compares stdout and status, not stderr), which superseded this PR's own harness change in the merge |
| 4 | the `exec <<` replay changes stdin for later steps on a hand-run from a tty | **REFUTED**, the R1-O1 re-raise. git always runs the hook with a pipe, and the tty case was already accepted in round 1. Keeping fd 0 for a tty would make an enabled block wait on the terminal. |
| 5 | README's exhaustive scripts list misses the new test | **FIXED** |
| 6 | the deletion test checks both `(delete)` and the all-zero sha, which is redundant | **REFUTED**: both must hold to skip, so a mismatch in either falls back to running the gate. The redundancy fails safe on purpose. |
| 7 | real-git cases ran only with the block on | **FIXED**: the same four pushes also run as shipped (block off). |

All `locally_verified`. `make check` passes in the checkout, and in the unpacked zip after the
`main` merge.

**The cross-model re-gate still owed** (Consolidated marker, above) now covers the pair
`<merge-base with main>` → the head after this merge.
