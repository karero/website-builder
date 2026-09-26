# Independent review — DIFF — an owner may defer a BUG the change did not introduce (rounds 1–5)

Branch `docs/skill-bug-deferral-rule`; base `origin/main` `7a17049`, after two merges from main.
Rounds 1–4 reviewed against `5e310f6`, round 5 against `4cc0f10`.

**The change.** SKILL.md said every confirmed BUG must be fixed, "no exceptions", yet the owner had
deferred three BUGs, one of them a widening. On 2026-09-26 the owner decided to change
the rule rather than keep ignoring it. Point 5 now lets the owner defer a BUG the change did not
introduce, when every wrong input its row quotes goes wrong at the merge-base, the row carries a dated
sign-off, and KNOWN WRONG tests in CI pin those inputs. A widening is a BUG the change introduced.
DEFERRED becomes its own status: closed for the gate, open in the tracker. The tracker is brought
into line: R-VERDICT-TEXT's BUG-rated half moves to the BUG table as B-VERDICT-TEXT, and B-TAGCLASS
is marked as not yet meeting the rule.

**Owner decision, 2026-09-26: widenings left out (option A).** Rounds 1–4 each found a new hole in
the definition of a widening. After round 4 the choice went to the owner: drop widenings, or try a
fifth definition. The owner chose to drop them.

**Verdict after round 5: no BUG or RISK open.** Five rounds, 76 findings (18, 15, 10, 13, 20).
Round 5's real findings — one BUG, three RISKs — are fixed, and those fixes are
`locally_verified` only: no reviewer has read them. The two deferred BUGs meet point 5's three
conditions, reproduced below at the merge-base. B-TAGCLASS does not, and blocks any gate that
raises it.

## Rounds

| Round | Reviewed | Reviewers — CLI, model, sandbox | Findings | BUG / RISK / NIT |
|---|---|---|---|---|
| 1 | `105d314` | Codex CLI 0.157.0, `gpt-6-astra`, `exec -s read-only`; ollama 0.34.2, `kimi-k2.7-code:cloud`, text only; fresh-eyes seat (host family, sub-agent with no shared context, read-only) | 18 | 5 / 5 / 8 |
| 2 | `ae16cc9` | same three | 15 | 4 / 4 / 7 |
| 3 | `5609f62` | same three; Codex returned no findings | 10 | 0 / 4 / 6 |
| 4 | `2e67451` | same three, plus Antigravity (`agy` 1.2.9, CLI default model), run by hand after the gate's own run failed | 13 | 1 / 6 / 6 |
| 5 | `9ff0256` | same four; Antigravity by hand; Codex counted by hand, see Round 5 | 20 | 3 / 6 / 11 raised; 1 / 3 real after refutations |

Counts are after merging duplicates across seats. Rounds 1–4 ran Codex and ollama through the
pinned gate script (`5e310f6`) and closed with `reviewers: codex OK, ollama-cloud OK`; round 5 is
described in its section. The artifact was
`git diff origin/main...HEAD -- . ':(exclude)docs/reviews/'`; rounds 2 and 3 prepended the prior
round's BUG list, as point 6 prescribes, and Codex called that preamble's "do not oblige" line
review-steering text both times, which it is. The fresh-eyes seat read the tracker from the
checkout each round. Verbatim output: `RAW-diff-2026-09-26-r1-skill-bug-deferral-rule-105d314.md`,
`…-r2-…-ae16cc9.md`, `…-r3-…-5609f62.md`, `…-r4-…-2e67451.md`, `…-r5-…-9ff0256.md`, the ollama
reasoning traces omitted and marked.

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

**Size, raised twice (B12, C10): not fixed.** `make check` passes with a warning: SKILL.md is 546
lines against a 500-line soft budget (502 on `main`, already over), and the description is 995 of
1,024 characters. Moving point 5's exception into `references/` would clear it, but would put the rule
out of sight of the step that enforces it. The owner's call.

## Round 4 (on `2e67451`, code diff identical to `f7acff8`) — verification

Four seats: Codex, ollama-cloud, fresh-eyes, and Antigravity. Antigravity failed through the gate
again (headless mode denied a shell-command tool), then ran once by hand with the gate's own
text-only prompt and the gate's flags plus read-only `--mode plan`, in an empty temporary
directory; its model is the CLI's default. Consent: the owner's "ok round 4, include agy".

| id | Sev | Source | Finding | Disposition |
|---|---|---|---|---|
| D1 | BUG | Codex, fresh-eyes, Antigravity | The rule now requires each deferral's merge-base reproduction (command and output) in the trail, and none was recorded; closeout item 3 did not list it | Fixed: recorded below; closeout item 3 lists it |
| D2 | RISK | fresh-eyes | "A new caller" is excluded, yet it reaches the wrong result through the very defect the row names; two readers would split | Fixed by the owner's decision: widenings are gone. Condition 1 now asks that every input go wrong at the merge-base through an entry point production already uses there, so a new caller's results fail it |
| D3 | RISK | fresh-eyes | The change can write the row, so "the defect the row names" is as broad as its author makes it | Fixed by the same decision: what counts now is the row's inputs going wrong at the merge-base, not how the row describes the defect |
| D4 | RISK | fresh-eyes | #113 merged after the base, so the tracker conflicted in two places | Fixed: `origin/main` merged in (`cb00025`), R-PROJCTX kept, both "Last updated" notes combined |
| D5 | RISK | Antigravity, fresh-eyes | The two-status paragraph read as if a deferred BUG needs no verification at all | Fixed: its merge-base reproduction must be `locally_verified` |
| D6 | RISK | Antigravity, ollama | A verification round was told to "confirm each fix landed", not to check the deferrals | Fixed: it also confirms each deferral meets point 5's three conditions |
| D7 | RISK | ollama | "Its test's name" and "a test" were singular, where a BUG has many KNOWN WRONG cases | Fixed: plural throughout |
| D8–D11 | NIT | fresh-eyes 4 | "Its own dated line in the row"; the round-3 trail cited `1bb12b7`, not #110's merge-base `b586b4b`; whether a sign-off carries over to later gates; the gate-status body read as contradicting its heading | Fixed, or gone with widenings. `b586b4b` and `1bb12b7` hold the same function byte for byte, so the round-3 result stands. A sign-off now carries over; each gate records its own reproduction |
| D12 | NIT | ollama | "Point 2's exclusion" names the wrong point | **Refuted:** Procedure point 2 is where `docs/reviews/` is left out of the artifact |
| D13 | NIT | Antigravity | A deferred BUG's re-raise duplicates the "still OPEN" bullet, so point 7 double-counts | **Refuted:** that bullet covers a claim held open on a missing prerequisite; a deferral is a different disposition, and the owner accepted it |

## Round 5 (on `9ff0256`) — verification, the last

Four seats. Codex and ollama through the gate; Antigravity by hand, as in round 4. The gate
reported Codex `FAILED (output is not a review)`: its reply was one BUG plus a verified-claims
table, and its note that a check "could not complete" in its sandbox tripped the refusal check.
That is B-REFUSAL-TEXT's pinned false reject ("a lone real finding saying 'cannot return' is
discarded") seen live. The reply is a real review, so it is counted by hand, as the gate's own
message says to. Consent: the owner's "a", given with the plan to fix and run one final round.

| id | Sev | Source | Finding | Disposition |
|---|---|---|---|---|
| E1 | BUG | Codex, ollama, Antigravity | The trail gave "19 lines, all `ok`" in place of the reproduction's output | Fixed: the full output is in the reproduction section |
| E2 | BUG | Antigravity | The widening paragraph contradicts the codified note, and "the row may be new" is misplaced | **Refuted:** the paragraph states the rule and the note says why; they agree. Where the sentence sits is style |
| E3 | BUG | Antigravity | 6(a2) lets a BUG first deferred in the last round end the gate with no reviewer checking the deferral | **Refuted:** point 5 marks such a deferral "not externally re-verified" and requires its reproduction to be `locally_verified` — the same trade 6(c) makes for a BUG fix when the budget runs out |
| E4 | RISK | fresh-eyes | #114 merged, so the tracker conflicted again | Fixed: merged (`1c4c4d7`), R-PROJCTX taken from main as is |
| E5 | RISK | fresh-eyes | "Every input the row covers" is undefined when a row describes a class of inputs | Fixed: "every wrong input the row quotes", in SKILL.md, the tracker and this trail |
| E6 | RISK | ollama | "An entry point production already uses there" could be read as after the change | Fixed: "the target branch already used at the merge-base, before this change" |
| E7 | RISK | ollama | Point 4's list lets a RISK be marked deferred | **Refuted:** the next sentence limits deferred to a BUG under point 5 |
| E8 | RISK | ollama | 6(a2) and point 7 disagree on a round of re-raised deferred BUGs | **Refuted:** both say stop |
| E9 | RISK | Antigravity | Not every unqualified form is pinned | **Refuted:** every wrong input the rows quote is pinned, which is what the rule now asks |
| E10–E20 | NIT | fresh-eyes 8, ollama 2, Antigravity 3, merged to 11 | "Only one that predates the change" reads as a count (all three seats); trail header, size figures, 89 → 93 checks, round-4 numbering, caller order and one garbled sentence; a test comment; the two-status wording; a label format; "point 2" again | All fixed except "point 2", **refuted** as in D12 |

## Merge-base reproduction for the two deferred BUGs (D1, E1)

Merge-base `7a17049` (`origin/main` after #114). Run from the repo root on this branch; it runs this
branch's pins against `main`'s copy of `looks_like_review()`, the function the three reviewer tiers
pass their raw output to (`independent_review.sh` line 487 in `run_codex`, 527 in `run_agy`, 550 in
`run_ollama`):

```
d=$(mktemp -d); git show "$(git merge-base origin/main HEAD):skills/independent-review/scripts/independent_review.sh" > "$d/independent_review.sh"
cp skills/independent-review/scripts/test_looks_like_review.sh "$d/"; bash "$d/test_looks_like_review.sh" | grep 'KNOWN WRONG'
```

Output, in full:

```
ok   KNOWN WRONG (B-REFUSAL-TEXT): an honest lone finding that cannot read its evidence is discarded
ok   KNOWN WRONG (B-REFUSAL-TEXT): two refusal-shaped findings count as a review
ok   KNOWN WRONG (B-REFUSAL-TEXT): the prescribed clean-verdict shape is discarded when an UNVERIFIABLE entry says a COMPONENT cannot do something
ok   KNOWN WRONG (B-REFUSAL-TEXT): a lone real finding saying 'cannot return' is discarded
ok   KNOWN WRONG (B-REFUSAL-TEXT): 'couldn't access' is not a refusal phrase
ok   KNOWN WRONG (B-REFUSAL-TEXT): 'don't have access' is not a refusal phrase
ok   KNOWN WRONG (B-REFUSAL-TEXT): 'can not review' is not a refusal phrase
ok   KNOWN WRONG (B-REFUSAL-TEXT): 'unable to view' is not a refusal phrase
ok   KNOWN WRONG (B-REFUSAL-TEXT): qualified verdict + 'couldn't access'
ok   KNOWN WRONG (B-REFUSAL-TEXT): qualified verdict + 'don't have access'
ok   KNOWN WRONG (B-REFUSAL-TEXT): qualified verdict + 'unable to view'
ok   KNOWN WRONG (B-REFUSAL-TEXT): qualified verdict + 'can not review'
ok   KNOWN WRONG (B-REFUSAL-TEXT): the unqualified twin, accepted before the fix too
ok   KNOWN WRONG (B-VERDICT-TEXT): pre-existing 'No risk can be assessed'
ok   KNOWN WRONG (B-VERDICT-TEXT): pre-existing 'No bug reports can be generated'
ok   KNOWN WRONG (B-VERDICT-TEXT): passive 'can be assessed'
ok   KNOWN WRONG (B-VERDICT-TEXT): passive 'could be evaluated'
ok   KNOWN WRONG (B-VERDICT-TEXT): 'no further risk analysis possible'
ok   KNOWN WRONG (B-VERDICT-TEXT): 'No further bug reports can be generated'
```

Every B-REFUSAL-TEXT case (13) and every B-VERDICT-TEXT case (6) goes wrong at the merge-base
exactly as pinned. The 2026-09-20 widening's inputs are among them: that change has merged, so they
are pre-existing for this one. Rounds 4 and 5 ran the same check at `4cc0f10`, with the same result.

## Convergence

BUG/RISK per round: 10, 8, 4, 7, with BUGs 5, 4, 0, 1. Round 3's four RISKs: two landed on round
2's own fixes, one was new ground, one was refuted. Round 4 rose again, and two of its RISKs were
the widening definition once more: every round found a new gap in it. That is point 7's signal to
stop patching, so the owner took the decision, and the definition is gone rather than rewritten a
fifth time. Round 5 raised 9 BUG/RISK, of which 4 were real: one missing record (E1), one merge
(E4) and two wording gaps (E5, E6). None needed a redesign. Its fixes are `locally_verified` and
not externally re-verified; by the skill's cap this was the last round.

## Tests

`test_looks_like_review.sh` 52/52: three new KNOWN WRONG cases for B-VERDICT-TEXT, two of them
pre-existing (accepted at `1bb12b7`) and one a widening (rejected there), and every B-REFUSAL-TEXT
and B-VERDICT-TEXT label now names its row. `test_failed_tier_report.sh` 93/93 since #113. `make check`
passes, with the size warning above.
