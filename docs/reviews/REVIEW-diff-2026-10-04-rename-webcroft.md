# DIFF review — the rename from website-builder to Webcroft — 2026-10-04

Branch `chore/rename-webcroft`, from `origin/main` (`4bddcad`) to the PR head. The change
renames the product, its addresses and the handoff zip everywhere outside this folder, and
teaches the private-name check (`scripts/check_clean.sh`) the repository's new name. The
pull request stays a draft until the repository is renamed on GitHub: its links point at
the new address.

Depth: **Normal** (mostly prose and names, plus one line of a guard that decides whether
private names reach a public repo). Seats: Codex CLI (its default model, read-only) in
rounds 1 and 2; a fresh-context reviewer agent of the host, on a different model than the
authoring session, in round 1. ollama-cloud (`kimi-k3`) was started for round 1 and failed:
the account was at its weekly usage limit, and a second cloud tag gave the same answer, so
no review came from that tier. Consent: the owner, this session ("prepare the toolkit
rename PR as a draft").

| Round | Head reviewed | Seat | BUG / RISK / NIT | What it found, in short |
|---|---|---|---|---|
| 1 | `de7962a` | Codex | 1 / 2 / 0 | a longer name joined by two dots (`<owner>/webcroft..x`) blanked as a self-link (older than this branch); no test noticed a wrong back-reference in the replacement; the README names `webcroft.zip` before a release carries it |
| 1 | `de7962a` | fresh-context agent | 1 / 2 / 6 | the first commit's message said all four new cases failed against the old pattern (one did); the same back-reference and zip findings; the "formerly" note overstated what keeps working; any host or path accepted in front of the name; "the builder" in a worked example; "webcroft clone" in `whats-new.sh`; rename-only skill updates for earlier sites; unzipping over an older folder |
| 2 | `e42b14e` | Codex | 0 / 0 / 1 | a test comment still said "four cases" |

13 findings over 2 rounds, two of them reported by both seats, so 11 distinct.

## Dispositions

- **Fixed, each with a case in `scripts/test_clean_denylist.sh`:** the two-dot name (the
  pattern no longer accepts a second dot after the name); the back-reference (a listed name
  right after a self-link must still be reported). Each of the four new cases fails when the
  pattern is broken in the way it guards against: second dot allowed again, or the
  replacement keeping group 2 or 3 instead of 4.
- **Fixed in text:** the first commit's message (rewritten before the branch was pushed);
  the README note (it now says what GitHub redirects and how to point a clone at the new
  address); `whats-new.sh` says "suite clone", because a clone made before the rename sits
  in a folder with the old name; the stale test comment.
- **Comment only — any host or path in front of the name.** Older than this branch, and the
  README badge needs a path in front (`.../release/<this repo>`). Tightening it would need an
  exception for that URL. The comment in `check_clean.sh` now says what is not checked.
- **No code change — the zip name.** The pull request states the order: rename the
  repository, merge, cut 0.30 with `webcroft.zip` straight after, and update any release
  runbook that still names the old zip.
- **For the release notes — rename-only skill updates.** `whats-new` will list `copywriting`,
  `search-console-insights` and `website-review` for sites built earlier; the pull request
  carries the sentence.
- **Declined:** "the builder" in the `website-story` worked example (a generic noun, not the
  product name; changing a skill for it would flag one more skill in every built site);
  unzipping a newer zip over an older folder merges both (older than this branch, and the
  README already says to use a newer unzipped copy).

## Evidence

- `make check` passes in the worktree with the name list read (no "skipped" line), and
  inside the unzipped zip outside any git repository.
- `make smoke` builds `dist/webcroft.zip` (286 files) and its integrity check passes; the zip
  has no top-level folder, which is why the README now unzips into one.
- `make test`: 187 tests pass, none skipped.
- `scripts/test_clean_denylist.sh`: 21 cases pass with `/bin/bash` 3.2 and BSD `sed`, `grep`
  and `awk`. Run against the check as it was on `origin/main`, the case that expects a
  self-link under the new name to pass fails.
- Not run by any seat or locally: the GNU tools. CI on the pull request covers them.
- `git grep -n -i 'website-builder' -- ':!docs/reviews'` shows only the deliberate leftovers
  (the installers' backup suffix and its test, the template comment in `ship.sh`, a German
  example title), the README's "formerly" note, and the name check with its test.

**Verdict:** clean after round 2. The fix for round 2's nit was not sent for a third round.
