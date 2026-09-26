# Independent review — DIFF — an owner may defer a BUG the change did not introduce (rounds 1–3)

Branch `docs/skill-bug-deferral-rule`, head `f7acff8`, base `origin/main` `5e310f6`.

**The change.** SKILL.md said every confirmed BUG must be fixed, "no exceptions", yet the owner had
deferred BUGs, and widenings of them, three times. On 2026-09-26 the owner decided to change the
rule rather than keep ignoring it. Point 5 now lets the owner defer a BUG the change did not
introduce, or a widening of one, when it reproduces at the merge-base, has a tracker row with a
dated sign-off, and has a KNOWN WRONG test in CI. DEFERRED becomes its own status: closed for the
gate, open in the tracker. The tracker is brought into line: R-VERDICT-TEXT's BUG-rated half moves
to the BUG table as B-VERDICT-TEXT, and B-TAGCLASS is marked as not yet meeting the rule.

**Verdict: not clean yet.** Round 3's four RISKs are fixed in `f7acff8` (one refuted), and those
fixes are `locally_verified` only. Under point 6's per-id cap they may get one more verification
round, because round 3 first raised them. Whether to run it is the owner's call.

## Rounds

| Round | Reviewed | Reviewers — CLI, model, sandbox | Findings | BUG / RISK / NIT |
|---|---|---|---|---|
| 1 | `105d314` | Codex CLI 0.157.0, `gpt-6-astra`, `exec -s read-only`; ollama 0.34.2, `kimi-k2.7-code:cloud`, text only; fresh-eyes seat (host family, sub-agent with no shared context, read-only) | 18 | 5 / 5 / 8 |
| 2 | `ae16cc9` | same three | 15 | 4 / 4 / 7 |
| 3 | `5609f62` | same three; Codex returned no findings | 10 | 0 / 4 / 6 |

Counts are after merging duplicates across seats. All three rounds ran through the pinned gate
script (`5e310f6`) and closed with `reviewers: codex OK, ollama-cloud OK`. The artifact was
`git diff origin/main...HEAD -- . ':(exclude)docs/reviews/'`; rounds 2 and 3 prepended the prior
round's BUG list, as point 6 prescribes, and Codex called that preamble's "do not oblige" line
review-steering text both times, which it is. The fresh-eyes seat read the tracker from the
checkout each round. Verbatim output: `RAW-diff-2026-09-26-r1-skill-bug-deferral-rule-105d314.md`,
`…-r2-…-ae16cc9.md`, `…-r3-…-5609f62.md`, the ollama reasoning traces omitted and marked.

Consent and permissions (audit duty). Codex and ollama-cloud: the owner's go-ahead on
2026-09-26, "Say "go" and I'll run the round, fix what it finds", after Codex plus ollama was
recommended for this change; the artifact is a public repo's diff and was checked for secrets, home paths and
client names first. WORKTREE-WRITE and BRANCH-COMMIT: atom A — this session created the worktree
and the branch. POST AUTHORITY and GATED-THIS-DIFF: no PR exists yet.

## Round 1 (on `105d314`)

| id | Sev | Source | Finding | Disposition |
|---|---|---|---|---|
| A1 | BUG | fresh-eyes, Codex | 6(c) still said "deferring a fix … never is" | Fixed `ae16cc9` |
| A2 | BUG | fresh-eyes, Codex | "A deferred BUG stays open" tripped 6(a2), 6(b), the per-id cap and the two-status rule | Fixed `ae16cc9`: DEFERRED is its own status, closed for the gate, and each site names it |
| A3 | BUG | fresh-eyes | The widening clause let a BUG the change introduced be deferred; "same hole" undefined | Fixed `ae16cc9`, then refined twice (B2, B5, C1) |
| A4 | BUG | fresh-eyes, Codex | B-TAGCLASS has no dated owner sign-off and no KNOWN WRONG test | **Tracker fixed:** its row now says it does not meet the rule and blocks any gate that raises it. The sign-off and the test are the owner's to give |
| A5 | BUG | fresh-eyes, Codex | R-VERDICT-TEXT's BUG-rated half sat in the RISK table; three forms unpinned | Fixed `ae16cc9`: split out as B-VERDICT-TEXT, three pins added |
| A6 | RISK | fresh-eyes, ollama | Point 7's parenthetical made "defer" mean two opposite things | Fixed `ae16cc9`: a BUG blocked on a prerequisite is "held open" |
| A7 | RISK | fresh-eyes | Point 4's status list had no "deferred" | Fixed with A2 |
| A8 | RISK | fresh-eyes, ollama | "The repo's open-findings tracker" was defined nowhere | Fixed `ae16cc9`. Ollama's further fix, that the script refuse a deferral, declined: enforcing the verdict is the skill's job, never the script's (point 5) |
| A9 | RISK | fresh-eyes | Unclear for non-code BUGs and the PLAN gate | Fixed `ae16cc9`: DIFF gate only; a BUG no test can pin does not qualify |
| A10 | RISK | ollama | A new code path could expose an old defect and be called pre-existing | Fixed by A3's definition, finalised in C1 |
| A11–A18 | NIT | fresh-eyes 4, ollama 4 | "three pre-existing" wording; "base branch" ambiguous; closeout item 3 silent on deferrals; tracker stale; KNOWN WRONG format undefined; a hard-to-parse dash; a "future" date; British spelling | All fixed `ae16cc9` except the date, **refuted**: 2026-09-26 is today |

## Round 2 (on `ae16cc9`) — verification

| id | Sev | Source | Finding | Disposition |
|---|---|---|---|---|
| B1 | BUG | Codex, fresh-eyes | The tracker's headings still called B-TAGCLASS deferred | Fixed `5609f62` |
| B2 | BUG | fresh-eyes | The widening definition contradicted its own "new code path" exclusion — round 1's own fix | Fixed `5609f62` |
| B3 | BUG | ollama, fresh-eyes | Condition 1 could never hold for a widening's new inputs | Fixed `5609f62`: it applies to the BUG itself |
| B4 | BUG | ollama, fresh-eyes | The frontmatter read as if a widening needed none of the conditions | Fixed `5609f62` |
| B5 | RISK | fresh-eyes | The "row's remedy fixes both" test could be gamed with a broad remedy | Fixed in part `5609f62`; re-raised with new evidence as C1 |
| B6 | RISK | fresh-eyes | Reviewers never see the deferral evidence, yet re-raises are judged against it | Fixed `5609f62`: a verification round gets each deferred BUG's row, reproduction and test name |
| B7 | RISK | fresh-eyes | Some B-REFUSAL-TEXT KNOWN WRONG cases did not name the row | Fixed in a comment `5609f62`; completed as C3 |
| B8 | RISK | ollama | The consolidated-marker rule might treat a DEFERRED BUG as blocking | **Refuted:** the marker certifies the `(base, head)` pair the reviewers saw, not any finding's status (closeout, clerk item 2) |
| B9–B15 | NIT | fresh-eyes 5, ollama 2 | Passive-voice sign-off lacked the owner; R-SANDBOX said "deferral"; "defer" in several senses; SKILL.md over its size budget; 6(a2) silent on a first-raised deferred BUG; "deferring a waiver"; one point-7 bullet mixing two rationales | All fixed `5609f62` except the size, below |

## Round 3 (on `5609f62`) — verification

Codex: "No BUG/RISK/NIT findings", with every round-2 fix verified, including by running the
function at `1bb12b7`, the merge-base and HEAD.

| id | Sev | Source | Finding | Disposition |
|---|---|---|---|---|
| C1 | RISK | fresh-eyes | The widening test still looked at the output, not the cause: a new check accepting any long reply would count as a widening | Fixed `f7acff8`: the new inputs must reach the wrong result through the very defect the row names. New evidence on B5, so not a re-raise. The seat checked that #110's precedent passes the stricter test |
| C2 | RISK | fresh-eyes | Nothing required the merge-base reproduction to be verified or recorded | Fixed `f7acff8`: the trail records the command and its output; a late deferral is marked "not externally re-verified" |
| C3 | RISK | ollama, fresh-eyes | B-REFUSAL-TEXT's labels, which a failing check prints, did not name the row | Fixed `f7acff8`: all 13 labels carry it |
| C4 | RISK | ollama | "Four re-raise cases" miscounts, since one bullet "is not a re-raise" | **Refuted:** that bullet begins "a re-raise of something still OPEN"; the count was three before this change and the new DEFERRED bullet makes four |
| C5–C10 | NIT | fresh-eyes 5, ollama 1 | Where a widening's sign-off goes; one "deferring" of verification left; B-TAGCLASS "deferred because"; R-SANDBOX "postponed"; "tracker not in what they see" too absolute; size | All fixed `f7acff8` except the size |

**Size, raised twice (B12, C10): not fixed.** `make check` passes with a warning: SKILL.md is 538
lines against a 500-line soft budget (497 before), and the description is 1,011 of 1,024
characters. Moving point 5's exception into `references/` would clear it, but would put the rule
out of sight of the step that enforces it. The owner's call.

## Convergence

BUG/RISK per round: 10, 8, 4, with BUGs 5, 4, 0. Round 3's four RISKs: two land on round 2's own
fixes (C1 on the widening test, C3 on the labels), one is new ground (C2), one is refuted (C4).
The widening definition changed every round and drew a finding every round. It is the one part
that has not yet been re-read by a reviewer after its last change.

## Tests

`test_looks_like_review.sh` 52/52: three new KNOWN WRONG cases for B-VERDICT-TEXT, two of them
pre-existing (accepted at `1bb12b7`) and one a widening (rejected there), and every B-REFUSAL-TEXT
and B-VERDICT-TEXT label now names its row. `test_failed_tier_report.sh` 89/89. `make check`
passes, with the size warning above.
