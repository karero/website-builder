# DIFF review — chore/rename-croftweaver — website-builder becomes Croftweaver

Base `f812647` · depth: Normal (mostly names and prose, plus the self-link rule of the
private-name check, which decides what may reach a public repo; mutation-tested) · verdict:
CLEAN in code; F2 open on a missing prerequisite (the GitHub rename) · authority used: the
owner in this session — "bring #147 up to date with main, review that update again ... do it
now" (2026-10-06) and "yes" to sending the diff to Melious (2026-10-08).

This carries over the reviewed Webcroft version of the rename (#147; its rounds are in
`REVIEW-diff-2026-10-04-rename-webcroft.md`) with the name changed to Croftweaver, onto a main
whose private-name check had been rewritten since. That part was redone by hand.

| Round | Head | Artifact | Reviewers | seconds, tokens | BUG/RISK/NIT |
|---|---|---|---|---|---|
| 1 | `514d292` | full, 34 KB | Codex CLI (gpt-6.1-sol, config effort, read-only) | 536 s, 84k | 0 / 2 / 0 |
| 1 | `514d292` | full | fresh-eyes agent (sonnet, read-only, ran the leak-check tests) | 149 s, 108k | 0 / 2 / 4 |
| 1 | `bf76317` | full, + F1's comment | Melious (glm-5.3, HTTP API, text only) | 128 s, 29k | 0 / 1 / 2 |
| 2 | `608f85e` | delta since `514d292`, `--verify` | Codex (medium) · Melious (glm-5.3) | 90 s, 29k · 31 s, 7k | 0 / 1 / 1 (same RISK from both) |
| prose re-gate | `9de3b79` | delta since `608f85e` (two comments) | Codex (medium) | — | 0 / 0 / 0 |
| extra, owner-requested | `d067172` | full, 34 KB | Antigravity (`agy`, CLI default model unconfirmed, plan mode, no tools) | 399 s | 0 / 0 / 0 |

| id | Sev | Source | Round | Finding — one line | Status | Evidence |
|---|---|---|---|---|---|---|
| F1 | RISK | fresh-eyes | 1 | the old-name allowance goes by name, not by what the link leads to | kept by design; comment states it (locally_verified) | `bf76317`, reworded in `608f85e` and the closing commit |
| F2 | RISK | all three | 1 | badge, clone, security-report and zip links and the redirect claim hold only after the rename and the next release | open on a missing prerequisite: checked live right after the rename | order: rename → merge → v0.31 |
| F3 | NIT | Melious | 1 | `make package` left a pre-rename `dist/website-builder.zip` | fixed (locally_verified, externally_reverified r2 by both) | `3773743`; an empty old zip is gone after `make smoke` |
| F4 | RISK | Codex | 1 | "100% compatible" in `docs/ANTIGRAVITY.md` | follow-up: older than this change | — |
| F5 | NIT | fresh-eyes | 1 | the new tagline is not a rename | refuted: part of #147's reviewed edits | README |
| F6 | NIT | fresh-eyes, Melious | 1 | the unzip line is a fix, not a rename | fixed in text: the commit and PR say so | `514d292` message |
| F7 | NIT | fresh-eyes | 1 | old name in an eval fixture and a test label | refuted: generic noun / historical reference | — |
| F8 | NIT | fresh-eyes | 1 | `..` right after a self-link fails closed | refuted: intended, the `..x` case must fail | test "joined by two dots" |
| F9 | RISK | Codex, Melious | 2 | the comment's "only its owner could ever" lacked support | fixed: claim removed, the accepted trade-off stated (externally_reverified, prose re-gate) | `9de3b79` |
| F10 | NIT | Melious | 2 | `package.sh` comment outlives its subject | fixed (externally_reverified, prose re-gate) | `9de3b79` |

Waivers and deferrals: none.
Follow-ups: F4.
Notes: round 1 ran its seats on two heads, `bf76317` adding one comment line; Melious had not
been given this repo before and the owner said yes first. My own `bf76317` comment named the
account and the check reported it: caught by `make smoke`, not by a reviewer, fixed in
`608f85e`. Checks at the closing head: `make check` (names read), `make test` 191,
`make smoke` 320 files, `scripts/test_clean_denylist.sh` all pass; four mutations of the
self-link rule each fail at least one case.
Antigravity (2026-10-08, the owner asked for it): no findings. Its open questions were settled
here: the exact two-rule `sed` chain on macOS `/usr/bin/sed` blanks both self-links and keeps
`..x`; CI's `clean` job ran `scripts/test_clean_denylist.sh` on ubuntu (GNU sed) for this
branch and passed; `unzip croftweaver.zip -d croftweaver` creates the folder (exit 0).
