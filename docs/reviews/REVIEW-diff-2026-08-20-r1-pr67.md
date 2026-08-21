# Independent review — PR #67, round 1

**Artifact:** `skills/independent-review/SKILL.md`, +18/−0 — a prose-only addition to the
clerk procedure: *"When a re-gate's own trigger is itself prose … scope the re-run narrow
rather than skip it."*

**Reviewed pair:** base `32b1f2e` → head `c47e1f7` (verified unchanged at post time).
**Gate:** DIFF. **Round:** 1 — the PR had no prior review of any kind.

| seat | tool | model | sandbox |
|---|---|---|---|
| cross-model | OpenAI Codex v0.148.0 | `gpt-5.6-sol` | `-s read-only` |
| cross-model | ollama cloud | `glm-5.2:cloud` | hosted, no repo access |

Independence: satisfied — both seats are cross-model relative to the Claude host. No
tier-3 fresh-eyes pass was run; this round is the external pair only.

**Scope note.** The narrow-scope rule this PR introduces was deliberately NOT applied to
the PR itself. That rule governs a *re-gate* — a later pass after fixes. This is round 1
on a change nobody had reviewed, so the full strict prompt applied. Reviewers were given
the complete current `SKILL.md` alongside the diff: an 18-line prose insert cannot be
judged for self-contradiction without the document it joins.

## Findings

| id | sev | source | finding | status |
|---|---|---|---|---|
| P67-1 | BUG | codex; ollama (2) | The trigger delta can be prose-only while the gated `(base, head)` diff still contains code. Telling every seat "the diff changes only prose" then contradicts clerk item 2's requirement that each seat see the current pair and that the verdict be rebuilt from those reruns alone — it can stamp a pair whose code was excluded from review. ollama reached the same defect via the second incident, whose trigger ("fix commits repeatedly moving the head") is a mechanical event, not a content type. | open |
| P67-2 | BUG | codex | *"Run the narrow pass and let it tell you"* is unconditional, but step 7 can require STOP, clerk item 2 bounds re-gates at two attempts, and step 6(c) can stop on exhausted credits. Contradictory instructions at exactly the terminal conditions. | open |
| P67-3 | BUG | codex | *"flag ONLY a factual contradiction … against the code/behavior it describes"* directs reviewers to ignore false or materially incomplete claims about review evidence, SHAs, models, permissions, waivers and dispositions — the things the surrounding procedure requires a trail to record correctly. | open |
| P67-4 | RISK | codex | "prose-only" has no defined actor or test. Code fences, YAML, shell snippets, generated docs, mixed commits. Two clerks can legitimately choose opposite gates, and a mistaken classification is imposed on every seat. | open |
| P67-5 | RISK | codex | *"A clean result on that narrow prompt IS the re-gate"* can be read as one reviewer's clean response, against clerk item 2's every-seat rule and the cross-model independence requirement. | open |
| P67-6 | RISK | ollama (1) | The headline incident — rounds 6–9, ~40 findings, zero contract defects — is textbook step-7 `(b)`-failure; the convergence check should already have fired STOP. Either re-gate rounds are exempt from step 7 (stated nowhere), or the real lesson is convergence enforcement rather than scoping, and the change addresses the wrong cause. | open |
| P67-7 | NIT | ollama (3) | The rule tells the clerk to change what seats are told, but not whether that is prepended to, replaces, or preambles the fixed strict prompt. Three materially different prompts are reachable from the same instruction. | open |

**Dispositions: none.** All seven are open. This session did not author the artifact and
holds no authority to fix, waive or refute on the owner's behalf; every finding is
recorded as raised and left for the PR's owner.

## Checked and clean (both seats)

- The three incident narratives are internally compatible with each other.
- The addition creates no exception letting prose or docs bypass a moved-diff re-gate.
- Excluding style, tone and phrasing findings is consistent with the stated objective.
- The addition still nominally requires every seat to participate — the defect in P67-1
  is the *scope supplied* to those seats, not the omission of a seat.
- The incident counts do not contradict step 6's per-finding three-round cap.
- The new text introduces no duplicate grant or fallback into the permission table.

## Gated actions taken, and the authority for each

| action | property | atom relied on |
|---|---|---|
| Post raw + consolidated review on PR #67 | POST AUTHORITY | Atom B — owner's instruction in session, naming the action: *"post it as a comment on #67"* |
| Write this trail file | WORKTREE-WRITE | Atom A — this session created worktree `trail-pr67` |
| Commit/push this trail on `docs/review-trail-pr67` | BRANCH-COMMIT | Atom A — this session created that branch. Deliberately NOT committed onto `docs/independent-review-narrow-scope-regate`, which this session did not create. |
| Stamp the consolidated marker | GATED-THIS-DIFF | Atom A — reviewer input captured against base `32b1f2e` / head `c47e1f7`, re-verified unchanged immediately before posting |

**Not done:** this session did not fix, waive or merge anything on PR #67, and did not
commit to its branch.

---

## Round 2 — adjudication (2026-08-21)

The owner read the change and said "I think it's good." That was disclosed to the
adjudicating reviewer along with an explicit instruction not to defer to it, or to round 1.

| seat | tool | model |
|---|---|---|
| cross-model | ollama cloud | `kimi-k3:cloud` |

**Verdicts: 2 VALID, 3 OVERSTATED, 2 WRONG.**

| id | verdict | disposition |
|---|---|---|
| P67-1 | OVERSTATED | Refuted as stated — unchanged code was reviewed when it was gated; induction over the re-gate chain covers it. Residue (the carry-over was never stated) FIXED. |
| P67-2 | WRONG | Refuted. The two-attempt bound has its own terminal clause one paragraph up; budget exhaustion is answered at this step by "No seen pair, no stamp, whatever the budget says". |
| P67-3 | OVERSTATED | Seats cannot run commands under the strict prompt, so SHAs and model names were never seat-verifiable under the wide prompt either. Residue about trail process-claims left for #67's owner. |
| P67-4 | VALID | FIXED — the classification is asymmetric and had no test and no failure direction. |
| P67-5 | WRONG | Refuted. "tell every seat" sits two clauses above the sentence read as singular. |
| P67-6 | OVERSTATED | Step 7's remedies structurally cannot fire on a re-gate. Residue (whether re-gate rounds feed step 7's signals) left for #67's owner — it is about step 7, not this paragraph. |
| P67-7 | VALID | FIXED — full pair to every seat, scope prepended to the unchanged strict prompt. |

Fixes landed in PR #71. Two residues (P67-3, P67-6) are recorded as open and belong to
sections this change does not touch.
