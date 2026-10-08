# DIFF review — karero/website-builder#194 — pipefail guard: #131 review items P1 (path and backslash), P7, P8

Base `b8d7136` · depth: **Light gate** (a small fix to a lint over the suite's own scripts; no user
data, no production path; owner: "Gate: Light, per `skills/independent-review/SKILL.md`") ·
verdict: **CLEAN** · authority used: WORKTREE-WRITE, BRANCH-COMMIT — atom A (this session's
worktree and branch `claude/quizzical-carson-f202ec`). Light gates carry no cross-model seat and no
stamp marker.

Nothing left the machine: the one seat is the host's own `/code-review`.

| Round | Head | Artifact | Reviewer | seconds, tokens | BUG/RISK/NIT |
|---|---|---|---|---|---|
| 1 | `738daa5` | full, `b8d7136...738daa5` | `/code-review` at medium (Claude host) | 27, not captured | 0/0/0 |

No findings. Waivers and deferrals: none. Follow-ups: none.

## The #131 record (`REVIEW-diff-2026-10-06-pr131.md`)

| id | Was | Now | Evidence |
|---|---|---|---|
| P1 | open: `\| /usr/bin/head`, `\| \head`, `\| timeout 5 head` missed | **path and backslash forms fixed** in `738daa5`; the wrapper form (`timeout`, `xargs` …) stays open | `check()` drops a leading `\` and judges the consumer by its basename. New self-test cases `bad/head-by-path` and `bad/head-alias-bypass` each failed on `b8d7136`'s guard ("the known-bad case … is not flagged"), and pass now; `good/tail-by-path` (`\| /usr/bin/tail -1`) is not flagged |
| P7 | open: mode 100644 | **fixed** in `738daa5` | `git ls-files -s scripts/*.sh`: all 17 are 100755 |
| P8 | open: `git ls-files` runs twice | **fixed** in `738daa5`, in both guards | `discover()` captures the list once. One side effect: a `git ls-files` that exits non-zero now falls back to `find` even if it printed something; before, its output was used |

Still open in the #131 record: P1's wrapper forms, P2 (`tee >(head -1)`, `while … break`), P9 (one
shared `discover()`), P10 (an `EXEMPT` needle matches the whole line).

## Checks run at `738daa5`

- `make check`: exit 0, plainly and as `perl -e '$SIG{PIPE}="IGNORE"; exec @ARGV' make check`.
- The repo scan: "18 scripts (2 exempt)", the same two `EXEMPT` sites; neither entry is stale.
- Both guards under `/bin/bash` 3.2.57 with macOS awk (version 20200816): exit 0.
- Both guards in a git-less copy of the tracked files (the `find` branch): exit 0, 18 scripts.
- mawk and gawk are not installed here; CI's Linux jobs run them.

Notes: the round found no BUG, so Light ends after it.
