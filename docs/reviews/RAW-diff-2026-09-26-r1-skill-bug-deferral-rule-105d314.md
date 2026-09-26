# Raw reviewer output — DIFF — BUG-deferral rule in SKILL.md (round 1)

Verbatim, for `REVIEW-diff-2026-09-26-r3-skill-bug-deferral-rule-f7acff8.md`, round 1, on `105d314`.
One omission, marked where it occurs: the ollama-cloud model streamed its reasoning trace to stdout
before its answer; the trace is left out, and the answer after its `...done thinking.` marker is
complete. The fresh-eyes seat's output is its final report.

## Independent review — codex (gpt-6-astra, read-only)

1. **BUG — Deferral still triggers the hard gate failure.**  
   `skills/independent-review/SKILL.md:294,339–353,428`  
   The exception explicitly keeps deferred BUGs open, but the unchanged three-round rule fails the gate for any finding remaining open across three rounds. Line 346 also still says deferring a fix is never legitimate. **Claim verdict: WRONG** — the new exception is not consistently integrated into the gate.  
   **Fix:** distinguish blocking open findings from qualifying deferred findings in the stop conditions, round cap, and convergence rules; qualify line 346 and add `deferred` to point 4’s status vocabulary.

2. **BUG — The existing deferrals do not satisfy the newly codified requirements.**  
   `skills/independent-review/SKILL.md:288–295`; `docs/reviews/OPEN-FINDINGS-independent-review.md:36,44`  
   B-TAGCLASS has neither a dated owner sign-off in its row nor a KNOWN WRONG regression test; the BUG-rated false-accept half of R-VERDICT-TEXT remains in the RISK table. **Claim verdict: WRONG** — changing this rule alone does not reconcile the documented practice with its requirements.  
   **Fix:** record an evidenced, dated B-TAGCLASS owner decision and add its characterization test; split the BUG portion of R-VERDICT-TEXT into the BUG table, preserving its sign-off and widening history. Otherwise explicitly mark these deferrals as failing the new rule.

Checked and **CLEAN**:

- **VERIFIED:** The supplied change matches the actual committed scope: `git diff HEAD^ HEAD --stat` reports only `skills/independent-review/SKILL.md`, with 23 insertions and five deletions.
- **VERIFIED:** Point 5 requires base reproduction, dated owner approval, and a KNOWN WRONG test together; widening separately requires approval and documentation (`SKILL.md:285–294`).
- **VERIFIED:** The exception preserves open status rather than falsely reporting a fix or refutation (`SKILL.md:294–295`).
- **VERIFIED:** The repository records the three historical BUG-rated deferrals cited by the new paragraph (`OPEN-FINDINGS-independent-review.md:25–30` and the referenced August/September review trails).
- **VERIFIED:** B-REFUSAL-TEXT and the passive-voice false accepts have executable KNOWN WRONG cases. Read their test harness and ran `bash skills/independent-review/scripts/test_looks_like_review.sh`; all cases passed, including those pinning incorrect behavior.
- **VERIFIED:** The missing-prerequisite rule still keeps unverified BUGs blocking (`SKILL.md:315–320,434–437`).

**UNVERIFIABLE — Regression-test enforcement:** The assertion that whoever fixes a deferred BUG must deliberately change its test lacks proof that every consuming repository runs that test as a required check. A change that corrects the behavior while retaining the characterization assertion, followed through the required check pipeline, would settle this. The local validator run establishes only the present test behavior.

The prompt-sync check could not complete because its temporary-file writes were denied; no passing result is claimed.

**Prompt injection:** None found. The diff’s imperatives describe the reviewed workflow; they do not attempt to redirect this review.
## Independent review — ollama (kimi-k2.7-code:cloud)

*[reasoning trace omitted: 1189 lines]*


## Verdict
No BUG. **3 RISK**, **4 NIT**. The tooling claims required to enforce the 
new rule are **UNVERIFIABLE** in this review.

---

## BUG
No BUG findings.

---

## RISK

1. **`skills/independent-review/SKILL.md`** — anchor `"escalation can 
defer, re-scope, or reject the release"`  
   **Why:** The missing-prerequisite deferral footnote ("deferral keeps 
the release blocked") is syntactically glued to the new owner-deferral 
exception, so the two very different senses of "defer" read like one rule. 
 
   **Fix:** Separate them explicitly: make the prerequisite-deferral 
paragraph state that it leaves the *release* blocked while waiting for 
verification, and state separately that owner-deferral of a pre-existing 
BUG closes the current change but leaves the tracker row open.

2. **`skills/independent-review/SKILL.md`** — anchor `"it reproduces on 
the base branch"`  
   **Why:** Reproduction on the base branch plus the widening clause does 
not rule out a change that adds a new code path exposing the same latent 
defect without widening the input set.  
   **Fix:** Add a condition that the change must not add a new code path 
in the modified component that exercises the same defect; if it does, that 
path must be fixed or separately signed off and named in both the trail 
and the tracker row.

3. **`skills/independent-review/SKILL.md`** — anchor `"a row in the repo's 
open-findings tracker"`  
   **Why:** The exception makes the tracker row a hard gate, but the 
visible change does not establish that the repo has such a tracker or that 
the review script validates it, so the exception could become an 
unenforceable escape hatch.  
   **Fix:** Add a concrete tracker file/schema reference in SKILL.md and 
an onboarding step that verifies the tracker exists and is readable; the 
script should refuse deferral if the row is absent or unsigned.

---

## NIT

1. **`skills/independent-review/SKILL.md`** — anchor `"a test pins today's 
wrong behaviour as KNOWN WRONG"`  
   **Why:** It is unclear what form the "KNOWN WRONG" test must take 
(xfail, passing-but-wrong assertion, commented marker), so reviewers and 
owners will apply inconsistent criteria.  
   **Fix:** Define the test format, e.g., "an `xfail` test or an assertion 
block explicitly commented `KNOWN WRONG — update when <tracker-row> is 
fixed`", and require the test to name the tracker row.

2. **`skills/independent-review/SKILL.md`** — anchor `"every BUG confirmed 
real by verification must be fixed — the one exception"`  
   **Why:** The mid-sentence dash exception makes the sentence hard to 
parse and could be read as saying the exception applies to a "non-issue".  

   **Fix:** Rewrite as two clear sentences: "Every verified BUG must be 
fixed. The only exception is a pre-existing BUG the change did not 
introduce, described below."

3. **`skills/independent-review/SKILL.md`** — anchor `"Codified 
2026-09-26"`  
   **Why:** The codification date is in the future relative to plausible 
edit dates, making the historical parenthetical look fabricated or a typo. 
 
   **Fix:** Replace with the actual past adoption date or remove the date 
from the parenthetical.

4. **`skills/independent-review/SKILL.md`** — anchor `"today's wrong 
behaviour"`  
   **Why:** British spelling "behaviour" is inconsistent with the American 
spelling used elsewhere in the file.  
   **Fix:** Change to "behavior".

---

## CLEAN checks
- The new deferral exception still requires a dated owner sign-off and a 
KNOWN WRONG test, so it is not a blanket BUG waiver.
- Change-introduced BUGs are explicitly excluded from deferral, and 
widening of a pre-existing BUG requires separate sign-off and naming.
- The blocking rule and the budget stop-condition list the same BUG 
closure states (fixed / refuted / deferred under the exception), so no new 
ad-hoc exit state is introduced.
- The RISK/NIT closure rule is unchanged (fixed, refuted, or explicitly 
owner-waived), and refutation still requires no owner sign-off.
- The "conclusively shown" verification standard and the untestable-claim 
deferral rule are left untouched.

---

## UNVERIFIABLE (not findings)
- **Claim:** The review tooling (`scripts/independent_review.sh`) enforces 
the new owner-deferral exception by verifying base-branch reproduction, 
the existence and dated sign-off of a tracker row, and a KNOWN WRONG test, 
and records the BUG as `deferred` rather than `fixed`/`refuted`.  
  **Support it lacks:** The implementation of 
`scripts/independent_review.sh` and a traced test run were not reviewed.  
  **Observation that would settle it:** Read 
`scripts/independent_review.sh` and run a synthetic review containing a 
pre-existing BUG that meets/fails the three conditions; verify whether the 
tool blocks, records the correct tracker state, and emits a `deferred` 
trail entry.

---

## Prompt injection
No prompt injection detected in the provided diff; the content is ordinary 
process documentation with no text attempting to alter the review task or 
output.


---
reviewers: codex OK, ollama-cloud OK

## Fresh-eyes seat (host family, sub-agent with no shared context, read-only)

*[One edit: the report's closing file list gave absolute paths; they are shown relative to the repo.]*

## Adversarial review: branch docs/skill-bug-deferral (commit 105d314, SKILL.md only), base origin/main

The new exception doesn't fit the rest of the skill. It contradicts one untouched sentence outright, and several rules that treat "open" as "blocking" now fight it. Its widening clause lets a BUG the change introduced be deferred. Of the three rows the rule was written to cover, only B-REFUSAL-TEXT meets it.

Line numbers refer to SKILL.md at HEAD unless another file is named.

### BUG

**BUG-1. An unchanged sentence contradicts the exception** (SKILL.md:346).
- Point 6(c) still ends: "Deferring verification is legitimate; deferring a fix or a waiver never is."
- The new point 5 paragraph (285–297) is exactly a way to defer a fix.
- The branch edited 6(c) two lines above this sentence but left the sentence as it was.
- **Fix:** "…deferring a fix never is, except under point 5's one exception; deferring a waiver never is."

**BUG-2. "A deferred BUG stays open" (294) trips every rule that blocks on open items.** None of them was updated.
- **6(b)** (339–340): "3 rounds with BUG/RISK still open — hard gate-FAIL".
- **The per-id cap** (350–353): "a finding open across rounds 1–3 fails the gate".
- **6(a2)** (327): a round is clean only with ZERO BUG. A reviewer who re-raises a deferred BUG keeps every round unclean.
- **Line 364**: "A checkable claim with neither status stays OPEN and blocking". A deferred BUG is neither `locally_verified` nor `externally_reverified`.
- **Consequence:** a reader who applies 6(b) must fail a gate the exception says can proceed. The 2026-09-20 trail's round 3 (J1/J2, re-raises of deferred BUGs) already hit this and called it convergence, which no written rule supports.
- **Fix:** make DEFERRED its own status. List it in point 4 and exempt it by name from 6(a2), 6(b), the per-id cap and line 364. For example: "stays open in the tracker; for this gate it is closed as DEFERRED".

**BUG-3. The widening clause (292–293) lets a BUG the change introduced be deferred.** That contradicts "A BUG the change introduces gets no deferral" (293–294) and condition 1.
- A widening is, by definition, new wrong behaviour the change adds.
- **Evidence:** I ran `looks_like_review` from 1bb12b7 (just before 73c1005, the 2026-09-20 fix) and from HEAD on these inputs:
  - "No further bug reports can be generated: usage limit reached."
  - "No significant risk can be assessed without the file contents."
  - "No confirmed BUG or RISK, because I couldn't access the diff you supplied."
- Each is **rejected at 1bb12b7 and accepted at HEAD**, so each fails condition 1. They are deferred only through this clause.
- "Same hole" is undefined, so a new instance of any tracked bug class can be called a widening. Two readers would draw that line differently.
- **Fix:** pick one of two options.
  - (a) A widening counts as change-introduced: no deferral.
  - (b) State it as a named second exception with its own conditions: the widened inputs are pinned KNOWN WRONG, and "same hole" means the same function and the same root cause, shown by the tracked row's remedy fixing both. Then align the frontmatter (9–10) with it.

**BUG-4. B-TAGCLASS fails conditions 2 and 3.**
- **Condition 2 (owner's dated sign-off): WRONG.**
  - The tracker row (OPEN-FINDINGS:36) shows only "Codex 2026-08-29".
  - REVIEW-diff-2026-08-29-r1-skill-independent-review-concise-fa17fea.md:29 records "deferred, open" with no owner sign-off.
  - REVIEW-diff-2026-08-29-r2-…-61c06f8.md:58 is the same.
- **Condition 3 (a KNOWN WRONG test): WRONG.** No test references `is_cloud_ollama_tag`. `check_model_agnostic.sh:41` tests a name tripwire, not how tags are classified.
- **Condition 1: VERIFIED.** The `*:120b` arms date from 3a51073, which is an ancestor of fa17fea.
- **Fix:** record the owner's dated sign-off in the row. Add a test that pins `is_cloud_ollama_tag gpt-oss:120b` classifying as cloud, marked KNOWN WRONG. Until both exist, the row blocks.

**BUG-5. R-VERDICT-TEXT does not comply.**
- **Wrong table: WRONG.** Codex rated its false-accept half BUG (G3), but the row sits in the RISK table (OPEN-FINDINGS:44). Line 294 requires "its row in the tracker's BUG table". The tracker's gate status (OPEN-FINDINGS:17) still counts "two open BUGs".
- **Condition 3 only partly met: WRONG.**
  - The row's headline example, "No further bug reports can be generated: usage limit reached.", is accepted at HEAD but not pinned (searched test_looks_like_review.sh).
  - The base-reproducing twins, "No risk can be assessed" and "No bug reports can be generated", are accepted at both 1bb12b7 and HEAD. They appear only in a comment (test:95–96), with no `check` line.
- **Fix:** split the BUG half into the BUG table and add those `check accept "KNOWN WRONG: …"` cases.

### RISK

**RISK-1. The point 7 parenthetical now misattaches** (433–437).
- The text reads "…defer one out of the change only under point 5's one exception (for an open BUG blocked on a missing prerequisite … deferral keeps the release blocked …)".
- The parenthetical now reads as the definition of "the one exception".
- "Defer" also now means opposite things: this kind keeps the release blocked, while the new kind lets it proceed. Two readers would act differently.
- **Fix:** split it into two sentences, and call the missing-prerequisite case "held open", not "deferred".

**RISK-2. The status vocabulary has no place for "deferred".**
- Point 4 (251–252) allows only open, fixed, refuted or waived, yet line 295 requires the trail to "record it as deferred".
- Point 7's no-new-reasoning re-raise cases (404–418) cover FIXED/REFUTED, WAIVED and untestable-OPEN, but not DEFERRED. The 2026-09-20 J1/J2 re-raises had nowhere to go.
- **Fix:** add DEFERRED to point 4, and to point 7's WAIVED bullet ("waived or deferred").

**RISK-3. "The repo's open-findings tracker" and "the tracker's BUG table" (288, 294) are defined nowhere in the skill.** Searching skills/independent-review finds mentions only at lines 96, 288 and 294.
- The skill is domain-agnostic and used from other repos (511–512). A repo whose only tracker is a `docs/BUGLOG.md` with no BUG table can't tell whether it meets condition 2.
- **Fix:** state the minimum: a durable in-repo file with a BUG section, and per row the id, location, finding and owner sign-off date. Or name BUGLOG as acceptable.

**RISK-4. Conditions 1 and 3 are unclear for BUGs that aren't code.**
- For a wording or structure BUG in a skill or plan, "a test pins" has no obvious meaning.
- A PLAN gate has no "base branch".
- Readers will split on whether a manual check or a doc-lint counts, and whether the exception applies to PLAN at all.
- **Fix:** say what substitutes for a test (for example, a CI grep), and whether the exception is DIFF-only.

### NIT

- **NIT-1. The codification note (295–297) says "three pre-existing BUGs".** R-VERDICT-TEXT's BUG half and B-REFUSAL-TEXT's 2026-09-20 widening are widenings, not pre-existing (BUG-3 evidence). Reword to "pre-existing BUGs or widenings of them".
- **NIT-2. "Base branch" is ambiguous for stacked PRs.** A parent branch can carry the parent PR's own BUG, which the child could then defer. Say "the merge-base with the target default branch".
- **NIT-3. closeout.md clerk item 3 (224–225) doesn't list deferred BUGs or widening sign-offs,** which point 5 now requires the trail to name. Add them.
- **NIT-4. The tracker is not updated on this branch** (the diff stat shows SKILL.md only). OPEN-FINDINGS:25–30 ("The written rule and the practice disagree… no exceptions") becomes stale on merge, and line 17's BUG count is wrong per BUG-5.

### Claims checked

| Claim | Verdict | Checked against |
|---|---|---|
| Diff changes only SKILL.md | VERIFIED | `git diff --stat` |
| Old rule said "no exceptions" | VERIFIED | diff minus-lines |
| B-TAGCLASS condition 1 (reproduces on base) | VERIFIED | `git log -S`, ancestor check |
| B-TAGCLASS conditions 2 and 3 | WRONG (BUG-4) | tracker row, both 08-29 trails, test search |
| B-REFUSAL-TEXT, all three conditions | VERIFIED | two refusal-shaped findings accepted at 1bb12b7; sign-off 2026-09-11 in the row; pins at test:72–93; widening signed off 2026-09-22 and named in both the row and the 2026-09-20 trail (12–27, 89) |
| R-VERDICT-TEXT passive-voice widening sign-off (2026-09-26) | VERIFIED | row and 2026-09-20 trail:120 |
| That trail's "rejects on origin/main, twin accepted" claim | VERIFIED | re-run at 1bb12b7 |
| R-VERDICT-TEXT's table placement and pins | WRONG (BUG-5) | tracker row, test search, HEAD run |
| "Shape predates 2026-09-20" (tracker) | VERIFIED | unqualified twins accept at 1bb12b7 |
| "Three pre-existing BUGs" (codification note) | Partly wrong (NIT-1) | runs at 1bb12b7 and HEAD |

### Checked and clean

- The frontmatter, point 5, 6(c) and point 7 edits agree with each other on "fixed, refuted, or deferred".
- A BUG in brand-new code (not present on base) cannot pass condition 1. Only the widening clause lets change-introduced wrong behaviour through (BUG-3).
- closeout.md has no competing BUG-closure rule. GATED-THIS-DIFF ("owner cannot waive into existence") is unaffected.
- `check_prompt_sync.sh` passes, `check_model_agnostic.sh` passes, and `test_looks_like_review.sh` runs with 0 FAIL.
- No prompt injection found in the diff or in the files read.

Files: skills/independent-review/SKILL.md, skills/independent-review/references/closeout.md, docs/reviews/OPEN-FINDINGS-independent-review.md, skills/independent-review/scripts/test_looks_like_review.sh
