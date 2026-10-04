# DIFF review — branch `feat/review-fewer-rounds` — independent-review: fewer rounds that find nothing, less noise from text-only seats

Base `0d41e96` · depth: Normal (the rules later reviews follow and one reviewer prompt; no user data, no production path), with a final full read because the change is mostly a procedure document · verdict: **CLEAN; every round ran with one cross-model seat, ollama-cloud being over its weekly limit** · authority used: WORKTREE-WRITE and BRANCH-COMMIT — this session created the worktree and the branch; POST AUTHORITY — this session opens the pull request; GATED-THIS-DIFF — Codex holds an unbroken chain `b7d7405` → `7f0fd61` → `0b1259c` → `2cfd649` → `ab28c52`

**Data release consent** (owner, in this session, quoted verbatim): "Codex + ollama-cloud (Recommended)". The repo has no standing consent; this is session-scoped.

| Round | Head | Artifact | Reviewers: CLI version, model, effort, sandbox | seconds, tokens per seat | BUG/RISK/NIT |
|---|---|---|---|---|---|
| 1 | `b7d7405` | full, `0d41e96...b7d7405` | codex-cli 0.159.3, gpt-6.1-sol, config effort, read-only · ollama 0.35.1, glm-5.3:cloud — FAILED (weekly limit, 429) · fresh-eyes: host-family mid-tier model, read-only sub-agent | codex 573 s, 115 117 · fresh-eyes 498 s, 188 955 | 1 / 6 / 7 |
| 2 | `7f0fd61` | delta since `b7d7405`, with round 1's dispositions | codex, medium, read-only · ollama — FAILED (429) | 185 s, 50 210 | 0 / 0 / 1 |
| wording pass | `0b1259c` | delta since `7f0fd61` (one paragraph rewrapped) | codex, medium, read-only (`--seat codex`) | 48 s, 19 963 | 0 / 0 / 0 |
| final full read | `0b1259c` | full, `0d41e96...0b1259c`, plus the whole current SKILL.md, closeout.md and plan-preconditions.md | host-family top-tier model, read-only sub-agent, new to the change (no other cloud model was within quota, and Antigravity was not asked for) | 742 s, 205 169 | 1 / 6 / 11 |
| 3 | `2cfd649` | delta since `0b1259c`, with the full read's dispositions | codex, medium, read-only · ollama — FAILED (429) | 233 s, 67 747 | 2 outside scope / 0 / 1 outside scope |
| wording pass 2 | `ab28c52` | delta since `2cfd649` (two paragraphs) | codex, medium, read-only (`--seat codex`) | 78 s, 25 557 | 0 / 0 / 0 |

Three rounds, a final full read and two wording passes: 36 findings (4 BUG, 12 RISK, 20 NIT).

| id | Sev | Source | Round | Finding — one line | Status | Evidence |
|---|---|---|---|---|---|---|
| S1 | BUG | codex, fresh-eyes | 1 | the new "nothing to fix" paragraph counted waived RISKs, stop condition (a2) did not | fixed — externally_reverified (round 2) | (a2): "no BUG and no in-scope RISK that calls for a fix"; both list the same cases |
| S2 | RISK | fresh-eyes | 1 | the text-only prompt's "quotes the line" left a fix that did not land with nothing to quote | fixed — externally_reverified (round 2) | "or in a verification round names the prior finding whose fix the diff lacks"; pinned by a test |
| S3 | RISK | fresh-eyes | 1 | a fallback ran fresh-eyes in a later round, against three places that say round 1 only | fixed — externally_reverified (round 2); the rule it belonged to was later removed (FR-R1..R3) | — |
| S4 | RISK | fresh-eyes | 1 | no branch for "no seat holds an unbroken chain" | fixed, then removed with the seat rule | — |
| S5 | RISK | fresh-eyes | 1 | the wording pass never fires for a gate that closes at round 1, so record prose written last went unread | fixed twice: first by changing the trigger, then (FR-R6) by leaving the trigger alone and naming the prose-only re-gate — externally_reverified (round 3) | SKILL.md step 2 |
| S6 | RISK | codex | 1 | precondition 3 accepted any clean trail for the requirements, whatever version it reviewed | fixed — externally_reverified (rounds 2, 3) | plan-preconditions.md §3 |
| S7 | RISK | codex, fresh-eyes | 1 | a sentence on pushing to a PR whose CI checks the marker: a comment cannot exist before its PR | fixed by deleting it — externally_reverified (round 2) | closeout.md is byte-identical to main |
| N6–N10, N13, N14 | NIT | fresh-eyes | 1 | step 8's scope; the trail template; "only feed the cost log"; why agy's prompt is unchanged; `--seat codex` on a Codex host; an ambiguous sentence; long lines | fixed — externally_reverified (round 2), N14 in part | `7f0fd61` |
| N14b | NIT | codex | 2 | one paragraph still ran to 124 columns | fixed — externally_reverified (wording pass) | `0b1259c` |
| FR-B1 | BUG | full read | — | SKILL.md's precondition 3 and plan-preconditions.md §3 set different tests | fixed — externally_reverified (round 3) | both ask for a gate on the requirements as they stand, and for the owner's choice |
| FR-R1, R2, R3 | RISK | full read | — | the rule "a DIFF's verification round goes to the tooled seat alone" was at odds with the per-seat chain the stamp relies on (the wording pass's seat; a seat that missed a round) and left a Codex host with no instruction | fixed by removing the rule — externally_reverified (round 3) | rationale.md says it is not done here, and why |
| FR-R4 | RISK | full read | — | "the gate closes on (a2)" could skip a final full read that was due | fixed — externally_reverified (round 3) | "no further round is owed …; the final full read where one is due, the wording pass and closeout still follow" |
| FR-R5 | RISK | full read | — | "wording alone" was undefined; every fix to a procedure document would have counted as wording | fixed — externally_reverified (round 3) | "an instruction someone follows" is in the list; wording is a fix that leaves the meaning for a builder unchanged |
| FR-R6 | RISK | full read | — | Light gates got conflicting instructions | fixed — externally_reverified (round 3) | the round rule and the record-prose rule say "Normal and High"; the wording pass's trigger is as on main |
| FR-N1..N6, N8..N10 | NIT | full read | — | "Rounds 1–3 run when owed"; closeout's chain sentence and Notes cap; sentences made stale; the depth note's wording; scope of the record-prose rule; an unnamed seat; rationale scope; two test names | fixed (three by the removal) — externally_reverified (round 3) | `2cfd649` |
| FR-N7 | NIT | full read | — | "item 3" in plan-preconditions.md is ambiguous | refuted — externally_reverified (round 3) | the file defines it: `"item 3" (a Reviewer-stack entry)` |
| FR-N11 | NIT | full read | — | step 4 covered only a text-only seat's UNVERIFIABLE entries; PROMPT_PORTABLE lacks the new rule | first half fixed — externally_reverified (round 3); second half is R3-N1 | SKILL.md step 4 |
| R3-B1 | BUG, older than this change | codex | 3 | plan-preconditions.md said fresh-eyes "has no repo access at all" and that Codex and ollama both have it | fixed by deleting both claims — externally_reverified (wording pass 2) | `ab28c52` |
| R3-B2 | BUG, older than this change | codex | 3 | rationale.md said step 6 falls back to a full round when the base moves | fixed — externally_reverified (wording pass 2) | "bridges it with a merge link" |
| R3-N1 | NIT, outside scope | codex | 3 | PROMPT_PORTABLE lacks the unseen-text rule | follow-up | not changed |

Waivers and deferrals: none.
Follow-ups: R3-N1. Wording pass 2 would word "No reviewer seat will do it" (plan-preconditions.md) as "the reviewer prompts do not explicitly request this check"; listed as unverifiable, not as a finding, and not applied. `website-review` and `seo-reposition` call the script without `--depth` and now see the new note. Each round marked the rationale's figures UNVERIFIABLE: their source is another repository's review trails.
Notes: the final full read is what found the seat rule's conflicts; the two delta rounds before it had confirmed every fix. Round 3 was earned by FR-B1. Its two BUGs are in text this change did not write: wording no test can pin, so step 5 has them fixed rather than deferred. `make check` exits 0 at `ab28c52`.
