# Code review — DIFF — round 1 — 2026-09-26 — PR #130

Artifact: branch `claude/compassionate-gates-02gt12`, reviewed at `cff8a60` against `origin/main`
(`c2d8f21`), i.e. `git diff origin/main...cff8a60`. The follow-up that
`REVIEW-diff-2026-09-26-r1-pr129.md` carried as F1–F4: pipelines into an early-exit consumer
(`head -N`, `grep -q`) under `set -o pipefail`, whose status flips once the producer's output
passes the pipe buffer (~64 KiB).

## Gate used, and why not independent-review

The owner asked for "/double-knuth it or run through /code-review". No `/double-knuth` skill was
available in the session, so `/code-review` ran. `independent-review` was not run: no Codex or
ollama in the cloud container, as for #129. **This round is same-family only**, not a
cross-model review.

| Seat | Tool | Outcome |
|---|---|---|
| host | `/code-review` on `origin/main...HEAD` | no correctness bugs; 8 findings (1 fail-open edge, 1 pre-existing glob, 1 design, 5 cleanup) |

## What the PR fixed (reproduced before the fix)

Each site was driven with a >64 KiB input, with SIGPIPE at its default and ignored
(`perl -e '$SIG{PIPE}="IGNORE"; exec @ARGV' bash …`, which is how GitHub runners start jobs).

| #129 finding | Site | Before | After |
|---|---|---|---|
| F1 | `package.sh` leak checks | 20,000 leaked paths **missed** (status `141 0 0`); 50 caught | caught, counted, first 5 shown |
| F2 | `looks_like_review`, clean-verdict match | 140 KB clean review rejected 20/20 | accepted |
| F2 | `looks_like_review`, refusal match | refusal with a late "No findings." accepted 20/20 | rejected |
| F3 | quota classifier in `attempt()` | quota misreported on ~15–45% of runs (~120 KB error lines) | classified every run |
| F4 | `check_model_agnostic.sh`, `whats-new.sh` | inputs ≤ 15 KB, no live race | herestrings; no producer left to race |

Regression tests: new `scripts/test_package_leak.sh`, large-reply cases in
`test_looks_like_review.sh`, and a large quota case in `test_failed_tier_report.sh`. The quota
case is a race even at its maximum size (the quote caps each file at 64 KiB), so it runs 6 times
per mode; against `main` it failed 10/10. All new cases fail against `main` and pass on the PR.

## Findings and dispositions

| # | Sev | Location | Finding | Status |
|---|---|---|---|---|
| R1 | RISK | `package.sh` leak checks | `\|\| [ $? -eq 1 ]` read any status 1 as "no match", including a failed herestring redirection, so the guard could fail open | **fixed** (`bf6a7e9`): one `leak_check` helper scans with awk, which exits 0 whether or not anything matched; any non-zero status fails. `locally_verified`: an awk stub that exits 2 now fails the build (new test case) |
| R2 | RISK (pre-existing) | `whats-new.sh` REFRESH-KEEP | `$keep` expanded unquoted, so an entry like `seo-*` globbed against the cwd | **fixed** (`bf6a7e9`): split once with `set -f`. `locally_verified`: `seo-*` stays pinned with a `seo-audit` file in the cwd |
| R3 | design | all pipefail scripts | nothing stops the pattern returning | **out of scope — follow-up**: lint in karero/website-builder#131 |
| R4 | NIT | `test_looks_like_review.sh` | pipefail on only for the large cases, not as in production | **fixed** (`bf6a7e9`): on for every case |
| R5 | NIT | `test_package_leak.sh` | `check`/`rc_is`/`has` repeat `test_failed_tier_report.sh`'s helpers | **declined**: every test here is self-contained and defines its own `check`; a shared helper would be a new convention |
| R6 | NIT | three test files | the perl SIGPIPE-ignored wrapper and its SKIP are copied three times | **declined**, same reason as R5 |
| R7 | NIT | `package.sh` | node_modules leak block duplicates the docs/reviews block | **fixed** with R1 (`leak_check`) |
| R8 | NIT | `whats-new.sh` | `$keep` re-split in a subshell per stale skill, in two places | **fixed** with R2 |

Tally: 6 fixed, 2 declined, 1 out of scope (R3). None open in this PR.

## After the review

- **Not re-reviewed:** `bf6a7e9`. Verified instead: `make check` green plainly and with SIGPIPE
  ignored, `make smoke` green (real zip built), all new cases fail against `main`.
- `origin/main` moved to `2697b74` (#129) before merge. `make check` was re-run on a local merge
  (the `check_cdpath_safe.sh` change auto-merged) and passed. CI green on the head, 22/22.
  Merged as `03e32a0`.
- Not changed: the remaining `$(… | head -1)` sites, whose status nobody reads; and running CI
  jobs with default SIGPIPE, not needed once the call sites are fixed.

## Follow-up

R3: karero/website-builder#131, "Add a guard against early-exit pipes under pipefail".
