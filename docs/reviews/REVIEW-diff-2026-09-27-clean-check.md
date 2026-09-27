# DIFF review — the private-name check in worktrees, and `make check` from the zip — 2026-09-27

Branch `fix/clean-check-worktrees`, from `origin/main` (`bbe4432`) to the PR head. Found by the
final check before v0.28: `make check` in the main checkout failed on a client name in
`REVIEW-diff-2026-09-27-gsc-report.md`, which had passed every check in its worktree, because
`check_clean.sh` skipped the gitignored name list there and still printed OK. The same check
found `make check` failing in the unzipped handoff zip, already true of the v0.27 zip.

Depth: **Normal** (a guard that decides whether private names reach a public repo). Seat: Codex
CLI (`gpt-6-astra`, read-only) every round. ollama-cloud was out of credits, so every round had
one cross-model seat. Consent: the owner, this session ("do you want to do a final check and
review?").

| Round | Head reviewed | BUG / RISK / NIT | What it found, in short |
|---|---|---|---|
| 1 | `e6b40c7` | 1 / 1 / 0 | dropping every line with a self-reference hid a private name beside it and exempted a longer repo name (`<owner>/website-builder-x`); the main checkout assumed to be the folder above the shared `.git` |
| 2 | `cce44c7` | 3 / 1 / 0 | the new filter swallowed a scan error (a broken pattern read as clean); no left boundary (`other-<owner>/website-builder`); hits in a file name holding a colon dropped; the `--separate-git-dir` risk again |
| 3 | `2b67b32` | 2 / 1 / 0 | two references one character apart (fails safe: flagged, nothing hidden); `filter_ignored` cutting a file name at its first colon; the `--separate-git-dir` risk a third time |

9 findings over 3 rounds, two of them the same risk repeated. Round 3 found no bug that could
hide a name, so it did not earn a round 4 (SKILL.md's round budget).

## Dispositions

- **Fixed, each with a case in `scripts/test_clean_denylist.sh`:** the line-drop (the check now
  blanks exactly the lowercase reference, bounded on both sides, one at a time until none is
  left, and looks again); the scan error (passed to `report` before any filtering); the left
  boundary; the colon in a file name (the line-shape test no longer assumes a colon-free
  name); two references one character apart. The main checkout now comes from
  `git worktree list`.
- **Declined — the `--separate-git-dir` layout (rounds 1–3).** Checked on a fixture with git
  2.33: from a linked worktree, `git worktree list --porcelain` names the git folder, not the
  main checkout, so git records no path to it and no code can find the list there. Failing
  instead would turn `make check` red for every contributor and zip recipient, none of whom
  has a list. The check says it skipped the list there, and a test pins that. The owner's
  checkout uses the default layout, which is covered.
- **Left as is, and pre-existing — `filter_ignored` cuts at the first colon (round 3).** It
  predates this change and applies to every check in the script. It matters only for a file
  whose name holds a colon *and* whose name up to that colon is a gitignored path
  (`docs/.DS_Store:notes.md`). Fixing it means carrying file names NUL-separated through
  every check. Named to the owner.

## Evidence

- `make smoke` passes in the worktree, with the name list read (no "skipped" line).
- `make check` passes inside the unzipped zip with `/bin/bash` 3.2 and BSD `awk sed tr grep`
  first on PATH, outside any git repository; before this change it failed there, and so does
  the published v0.27 zip.
- `scripts/test_clean_denylist.sh`: 11 cases pass under bash 5 and under `/bin/bash` 3.2 with
  only `/usr/bin:/bin` on PATH. Run against `origin/main`'s `check_clean.sh` it fails the
  worktree cases, and against each earlier round's version it fails that round's finding.
- GNU sed is not installed locally; the Linux CI jobs are the GNU run.
