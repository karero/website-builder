# Independent review — DIFF gate, rounds 1–2

**Artifact:** `independent-review/round-cost-controls` vs `origin/main` — three controls on
review-round cost in `skills/independent-review/SKILL.md`.
**Reviewer:** ollama-cloud `glm-5.2:cloud`, rounds 1–2. Single cross-model seat, proportionate to a
skill-doc change; Codex not run.

**This run used the rule it adds.** The artifact was built with
`git diff origin/main...HEAD -- . ':(exclude)docs/reviews/'`, and it stopped at round 2 on the new
(a2) stop condition — zero BUG, zero RISK.

## Findings

| # | round | sev | finding | disposition |
|---|---|---|---|---|
| 1 | 1 | BUG | the new clerk paragraph is unindented and breaks the numbered list | **REFUTED** — the sibling paragraph it was appended to (line 956, "Capture reviewer output by streaming to a file") is already unindented and already sits outside the list, between clerk items 3 and 4. The addition matches it and introduces no new break. Round 2 upheld. |
| 2 | 1 | BUG | the step-2 paragraph uses 3 leading spaces where context uses 4 | **REFUTED** — context uses 3 (line 560 onward). The claim was inferred from diff prefixes, not the file. Round 2 upheld, naming the diff-prefix confusion itself. |
| 3 | 1 | RISK | the file now tells two stories about that same MR that read as contradictory | **fixed** — the trail-exclusion passage names round 6 and says the truncation incident is a different round of the same MR |
| 4 | 1 | NIT | renumber the stop conditions a,b,c,d rather than a,a2,b,c | **REFUTED** — `6(b)` is referenced at lines 749 and 916 and `6(c)` at 683; renumbering breaks all three. `(a2)` was chosen for exactly that reason. Round 2 upheld. |
| 5 | 2 | NIT | ALL-CAPS mid-sentence emphasis is off-voice; use italics | **REFUTED** — pre-existing house style in this file on `origin/main`: `NOT` ×9, `AND` ×5, `ONLY` ×4. Switching would fork the convention for these paragraphs only. |

**Totals: 5 findings — 2 BUG, 1 RISK, 2 NIT. 1 fixed, 4 refuted, 0 waived, 0 open.**
Per round 4 → 1. BUG/RISK per round 3 → 0.

Four of five refuted is unusual and worth naming: three of them were the reviewer reasoning about
*indentation and list structure from a diff*, where the `+`/context prefixes make column counts
unreliable. That is a known weak spot for a diff-only reviewer, not a reviewer failure — but it means
whitespace findings on a markdown diff should be checked against the file before being actioned.
Each refutation here was verified against the real file, not argued from memory.

## What the change does

1. Exclude `docs/reviews/` from the artifact sent to reviewers, so a committed trail stops
   generating rounds that audit the review record rather than the change. Two runs paid for this: two
   MRs on the same internal backend repo, of 8 and 7 rounds.
2. Add stop condition (a2): a round returning zero BUG and zero RISK *is* clean and is the stop
   signal — NIT-only rounds do not earn another.
3. Never read reviewer output through `tail`; the prompt asks for a RANKED list, so truncation hides
   the severe end.
