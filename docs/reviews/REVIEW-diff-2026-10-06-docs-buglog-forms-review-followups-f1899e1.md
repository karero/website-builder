# DIFF review — branch docs/buglog-forms-review-followups — 13 BUGLOG rows for the follow-ups from the reviews of #174, #191 and #195

Base `bc3a63d` · depth: **Light gate** (one docs file, a bug list nobody executes; each row only records a known gap) · verdict: **CLEAN** after local fixes · authority used: WORKTREE-WRITE, BRANCH-COMMIT, POST AUTHORITY — atom A (this session created the branch, its worktree and the PR). Light gates carry no cross-model seat and no stamp marker.

Nothing left the machine: the one seat was the host's own fresh-eyes sub-agent (`/code-review` needs a PR, and the review ran before the push).

| Round | Head | Artifact | Reviewer | BUG/RISK/NIT |
|---|---|---|---|---|
| 1 | `f1899e1` | full `bc3a63d..f1899e1` | fresh-eyes sub-agent, claude-opus-5-5, read-only (233 s, 139k tokens) | 0/1/9 |

| id | Sev | Finding | Status | Evidence |
|---|---|---|---|---|
| L1 | RISK | the README row named six missing files; `package-lock.json` is a seventh, and the row's own source lists it | fixed `8e6660e` — locally_verified | `git ls-tree` of the starter against the "What's here" block |
| L2–L10 | NIT | F4 covers "arrived but reported failed" too, and needs an onboarded domain; N7's mechanism (`emailHint` throws first); N6's accepted characters; N5's fourth site copy; the 100 kB row's reach and the `unreadable` case; the 15 s / 10 s row's triggers; the `form=` row's source and untested browser claim; source pointers to the review records | fixed `8e6660e` — locally_verified | each checked against the file the reviewer cited (`obfuscate.ts:24`, `contact.ts:78`, the #195 raw output for re-gate 1) |

Every row's claim was checked against `main` at `bc3a63d` before writing it, and the reviewer re-checked each one; none was already fixed.

Waivers and deferrals: none. Follow-ups: none new.

Notes: Light runs one round, plus one only after a BUG; round 1 found none, so the fixes are locally verified, not externally re-verified. The first commit's message says "six starter files"; the second commit makes it seven.
