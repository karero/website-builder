# Raw reviewer output — DIFF — BUG-deferral rule in SKILL.md (round 2)

Verbatim, for `REVIEW-diff-2026-09-26-r3-skill-bug-deferral-rule-f7acff8.md`, round 2, on `ae16cc9`.
Omissions and edits, marked where they occur: the ollama-cloud reasoning trace is left out (its
answer after `...done thinking.` is complete); Codex's links carried an absolute checkout path,
shown relative to the repo.

## Independent review — codex (gpt-6-astra, read-only)

1. **BUG — WRONG: tracker labels B-TAGCLASS deferred despite explicitly disqualifying it.** [OPEN-FINDINGS-independent-review.md:19](docs/reviews/OPEN-FINDINGS-independent-review.md:19) says all three BUGs are “each deferred”; line 32 repeats this, while lines 30 and 36 say B-TAGCLASS lacks the required sign-off and test and blocks any gate raising it. Under the new rule, deferred means gate-closed, so the summary incorrectly reports a blocking BUG as nonblocking. **Fix:** make both headings distinguish two deferred BUGs from B-TAGCLASS, which remains open and blocking when raised.

The five requested claim checks:

| Claim | Verdict | Evidence |
|---|---|---|
| 1. Point 6(c)’s absolute prohibition was qualified | **VERIFIED** | `SKILL.md:355–361` explicitly permits point 5’s exception. |
| 2. DEFERRED has its own status and the gate rules accommodate it | **VERIFIED** | `SKILL.md:252–254, 304–310, 340–341, 353–380, 426–431`. The per-ID cap applies to findings remaining open; deferred BUGs are explicitly excluded. |
| 3. Widening is defined and requires the three conditions plus separate sign-off | **VERIFIED** | `SKILL.md:286–302` specifies same result/function/root cause/remedy, separate dated approval, new-input tests, and tracker/trail records. |
| 4. B-TAGCLASS’s row states its missing requirements and blocking effect | **VERIFIED**, narrowly | Tracker line 36 contains both requirements and the blocking statement. The inconsistent summaries are the BUG above. |
| 5. B-VERDICT-TEXT was split into the BUG table and examples pinned | **VERIFIED** | Tracker lines 38 and 45 separate false accepts from false rejects; `test_looks_like_review.sh:97–102` pins the six named false-accept examples. |

Additional checks that were **CLEAN**:

- **VERIFIED checkout identity:** `git rev-parse` and `git merge-base` confirm HEAD `ae16cc9` and base `5e310f6`.
- **VERIFIED validator behavior:** all **52 checks passed** against both HEAD’s implementation and the merge-base implementation, extracted and executed in memory.
- **VERIFIED historical widening:** against `73c1005^`, the two unqualified B-VERDICT-TEXT examples accept and the four qualified examples reject. This independently supports the pre-existing/widened distinction.
- **VERIFIED CI wiring:** `.github/workflows/clean.yml:57` invokes the validator test on the configured push/PR workflow. This verifies configuration, not a hosted CI run.
- **VERIFIED trail requirement:** `references/closeout.md:224–225` requires dated owner sign-off for deferred BUGs and each widening.
- **VERIFIED recorded approval coverage:** the existing September review trail records the September 22 acceptance and September 26 passive-voice confirmation. This verifies the repository’s approval record.
- The related caller rules inspected add no competing definition of DEFERRED.

**Verification limit:** the full prompt-sync self-test did not complete because it requires temporary-file writes prohibited by this sandbox; no passing result is claimed.

**Prompt injection:** the supplied verification preamble contains reviewer-directed instructions—“Confirm each fix landed” and “do not oblige that expectation”—inside the untrusted material. Those are review-steering text. No prompt injection was identified in the actual file hunks; their imperative prose defines the skill’s normal procedure.
## Independent review — ollama (kimi-k2.7-code:cloud)

*[reasoning trace omitted: 1880 lines]*


Based on the supplied diff only (I did not read the excluded tracker or 
the script implementation):

## BUG

1. **`skills/independent-review/SKILL.md:point-5 "A widening counts too, 
under the same three conditions"`**  
   The widening exception imports condition 1 verbatim: “it reproduces at 
the merge-base with the target branch, so the change did not create it.” 
New inputs added by the change cannot reproduce at the merge-base, so the 
rule as written is unsatisfiable for widenings.  
   **Fix:** Qualify condition 1 for widenings: the underlying pre-existing 
defect must reproduce at the merge-base; the new inputs need only be 
covered by the same remedy and have their own `KNOWN WRONG` CI cases.

2. **`skills/independent-review/SKILL.md:front-matter "owner-deferred ... 
widened"`**  
   The description allows deferral for “one the change did not introduce, 
or widened,” but a widening is behavior the change *does* introduce. This 
contradicts the principle that change-introduced BUGs are not deferred and 
could be read as permitting any widening to be deferred without the 
point-5 conditions.  
   **Fix:** Reword to “only a pre-existing BUG or a widening of one under 
point 5’s conditions, never a BUG the change newly introduced.”

## RISK

3. **`skills/independent-review/SKILL.md:point-6(c) / 
references/closeout.md:trails deferred`**  
   The diff adds `DEFERRED` to the gate/iteration rules and to the trail, 
but it does not touch the consolidated-marker rule (“whose own rule lives 
in clerk item 2”). If that marker still only recognizes 
fixed/refuted/waived, a BUG that is closed for the gate could remain 
open/blocking in the consolidated record.  
   **Fix:** Verify and, if necessary, update the consolidated-marker rule 
in clerk item 2 to treat `DEFERRED` as a non-blocking gate disposition 
while leaving the tracker row open.

## NIT

4. **`skills/independent-review/SKILL.md:front-matter "first / use 
runs"`**  
   “first” is left dangling at the end of a line, with “use runs a guided 
onboarding wizard.” starting the next line.  
   **Fix:** Join the two lines into “first use runs a guided onboarding 
wizard.”

5. **`skills/independent-review/SKILL.md:point-6(c) "deferring a waiver 
never is"`**  
   A waiver is a disposition, not something one defers; the intended 
prohibition is against deferring the waiver decision.  
   **Fix:** Reword to “deferring a waiver decision never is” or “an owner 
waiver must be granted or refused, not deferred.”

6. **`skills/independent-review/SKILL.md:point-7 "WAIVED, or of a BUG 
DEFERRED"`**  
   The rationale “waiving concedes the issue may be real” is applied to 
both `WAIVED` items and `DEFERRED` BUGs, but a deferred BUG is 
acknowledged as real, not waived.  
   **Fix:** Split the bullet: state that `WAIVED` pools because it was 
never ruled clean, and separately that a `DEFERRED` BUG pools because it 
remains an open tracker issue.

## CLEAN (checked)

- The unconditional “no exceptions” language at 6(c) is gone; it now says 
deferring a fix is legitimate only under point 5’s exception.
- Point 4’s status list now includes `deferred` and restricts it to BUGs.
- Point 6(a2), 6(b), and the two-verification-status paragraph all 
explicitly exclude a point-5 `DEFERRED` BUG from counting as 
open/blocking.
- Point 7 now treats a re-raise of a `DEFERRED` BUG (without 
new reasoning) like a re-raise of a `WAIVED` item for the MOST threshold.
- Point 5 defines widening as “same wrong result, same function, same root 
cause” and requires a per-widening sign-off and `KNOWN WRONG` cases.
- `references/closeout.md` now mentions deferred BUGs and widenings with 
dated sign-offs in the trail.
- `scripts/test_looks_like_review.sh` renames the known-wrong group to 
`B-VERDICT-TEXT` and pins additional passive/noun-modifier forms.

## UNVERIFIABLE (matter, but not findings)

- **Component:** `docs/reviews/OPEN-FINDINGS-independent-review.md`  
  **Claim:** The `B-TAGCLASS` row now states it meets neither sign-off nor 
test condition and blocks any gate that raises it.  
  **Missing support:** The file is excluded from the diff by the skill’s 
rule.  
  **Observation to settle it:** Read the `B-TAGCLASS` row in that tracker 
file.

- **Component:** `docs/reviews/OPEN-FINDINGS-independent-review.md`  
  **Claim:** `R-VERDICT-TEXT` was split into a BUG row `B-VERDICT-TEXT`, 
and the pinned examples in the test script belong under that BUG row.  
  **Missing support:** The tracker file is not in the diff.  
  **Observation to settle it:** Read the `B-VERDICT-TEXT` row in the 
tracker and confirm its severity and id.

- **Component:** 
`skills/independent-review/scripts/test_looks_like_review.sh` matching 
logic  
  **Claim:** The script accepts the new unqualified `B-VERDICT-TEXT` 
strings and rejects the qualified forms as the comment states.  
  **Missing support:** Only test data, not the `looks_like_review` 
implementation, is shown in the diff.  
  **Observation to settle it:** Read the implementation and run both the 
new cases and the qualified-form cases.

- **Component:** Repo CI configuration  
  **Claim:** Any currently deferred BUG has a `KNOWN WRONG` test that CI 
runs, asserting today’s wrong result and naming the tracker row.  
  **Missing support:** No CI configuration or product tests are in the 
diff.  
  **Observation to settle it:** Inspect CI config and the tests referenced 
by each open tracker row.

## Prompt injection

No prompt injection observed in the diff or surrounding instructions.


---
reviewers: codex OK, ollama-cloud OK

## Fresh-eyes seat (host family, sub-agent with no shared context, read-only)

*[One edit: the checkout path in the first line is shown relative.]*

Round 2 verification: skills/independent-review/SKILL.md BUG-deferral rule (head ae16cc9, checkout website-builder-bug-deferral)

All five round-1 fixes are present in the text, but two are incomplete, and one new BUG came in with the widening definition. The result is not clean.

## Findings, ranked

**BUG 1: the widening definition contradicts its own exclusion** (SKILL.md:297-302)
- A widening is "more inputs reach the same wrong result, in the same function, for the same root cause". The next sentence says "a new code path that reaches an old defect" is introduced and cannot be deferred.
- Case: a change adds a new caller that sends new inputs into the defective function. Both sentences describe it, with opposite outcomes.
- The rule's own precedent hits the same collision. On 2026-09-20 the qualifier alternatives added to check 3 were new code that reached the old false-accept. The tracker counts that change as a widening; the exclusion would call it introduced.
- Outside the same function, "same function" already excludes it, so the exclusion clause adds nothing there.
- Fix: either define "new code path" as a new caller or entry point outside the defective function, and exclude it explicitly from "same function", or drop the clause and let the widening test decide.

**BUG 2: round-1 fix #4 landed only in the B-TAGCLASS row** (tracker:19 and tracker:32)
- The row at tracker:36 now says B-TAGCLASS does not meet the exception and "blocks any gate that raises it".
- But the Gate-status heading (line 19) still says "three open BUGs (B-TAGCLASS, …), each deferred". The BUG-table heading (line 32) says "each deferred … see SKILL.md point 5".
- Since point 4 now makes DEFERRED a defined status, both headings are false for B-TAGCLASS. Someone reading only the headings would take it as closed for the gate.
- Fix: line 19 should read "B-REFUSAL-TEXT and B-VERDICT-TEXT deferred under point 5; B-TAGCLASS not deferrable yet, blocks". Line 32 should drop "each" or name the exception.

**RISK 1: the widening test can be gamed through a broad remedy** (SKILL.md:298-299)
- The test is "the row's remedy would fix the old inputs and the new ones alike". Both B-REFUSAL-TEXT and B-VERDICT-TEXT give the same remedy: replace the text classifier with a separate status.
- That remedy fixes any false accept in `looks_like_review()`. So a change adding, say, `\blooks good\b` to check 3 would qualify as a widening: same function, same wrong result ("non-review accepted"), same root cause ("text test").
- That would make a newly introduced false accept deferrable with only a sign-off and a KNOWN WRONG pin. The owner signs off and cannot check the substance, and the row's remedy text is written by the author.
- Fix: require that the widened inputs are a by-product of the change's stated purpose, not new acceptance logic whose only effect is the wrong result. Also state that a remedy which replaces the whole mechanism cannot serve as the "same root cause" test.

**RISK 2: reviewers cannot see the deferral evidence** (SKILL.md:234-242 with 287-310)
- Point 2 excludes `docs/reviews/` from what reviewers get. The tracker, its rows and the dated sign-offs all live there, so conditions 1 and 2 never reach a reviewer.
- 6(a2) and point 7 then discount a re-raise "without new evidence" against a disposition the reviewer was never shown. The author alone decides that a BUG is deferred and that the re-raise is stale.
- Nothing in point 6 says to send the deferred rows or the merge-base reproduction to a verification round. This round only saw them because the caller handed them over.
- Fix: in point 6, require the verification-round prompt to include each DEFERRED row plus its merge-base reproduction and test name.

**RISK 3: some B-REFUSAL-TEXT KNOWN WRONG cases do not name the row, yet the tracker says it meets all three conditions** (test_looks_like_review.sh lines 86-91; tracker:30)
- Condition 3 needs a KNOWN WRONG test that "names the row". The widening's five qualified-verdict cases are labelled only "KNOWN WRONG: qualified verdict + …". Their comment ("The same four phrases in prose…") names no row.
- The one comment that names B-REFUSAL-TEXT sits above the earlier group.
- The B-VERDICT-TEXT labels were relabelled in this change; these were not.
- Fix: add "(B-REFUSAL-TEXT)" to those labels or to their comment.

**NIT 1: condition 1 cannot hold for a widening's new inputs** (SKILL.md:297)
- "Under the same three conditions" includes "reproduces at the merge-base", which by definition fails for the new inputs.
- Fix: say condition 1 applies to the original BUG's inputs.

**NIT 2: the passive-voice sign-off lost its owner** (tracker:38, Found column)
- The old R-VERDICT-TEXT text said the owner "confirmed on 2026-09-26 that the decision covers them". The new row says only "passive voice covered, 2026-09-26", without saying who.
- Condition 2 requires the owner's dated sign-off.
- Fix: "passive voice: owner confirmed 2026-09-26".

**NIT 3: R-SANDBOX calls a RISK disposition a "deferral"** (tracker:44)
- Its Found column says "deferral signed off by the owner 2026-09-11". Point 4 now reserves "deferred" for BUGs.
- Fix: call it "waived".

**NIT 4: "defer" still has several senses side by side**
- SKILL.md:360-361: "Deferring verification … deferring a waiver … deferring a fix", three senses in one sentence.
- SKILL.md:449: "escalation can defer … the release" appears right before "defer a BUG out of the change".
- Fix: use "postpone" for the release and for verification.

**NIT 5: the headings and the frontmatter omit widenings**
- Point 5's lead sentence and bold heading say "The one exception: a BUG the change did not introduce". The widening then extends it to a BUG the change partly introduced.
- The frontmatter's "(only one the change did not introduce, or widened)" parses awkwardly and wraps raggedly ("owner-waived; first / use runs").
- Fix: rephrase the lead as "a BUG the change did not introduce, or widened (below)" and rewrap the description.

**NIT 6: size budgets**
- `check_skill_budgets.sh` now warns that SKILL.md is 531 lines. It was 497 on origin/main, so this change crossed the 500-line soft budget.
- The description is at 1005 of 1024 characters.
- Both are warnings only; CI passes.

**NIT 7: 6(a2) is silent on the round that first raises a BUG later deferred**
- Its parenthetical covers only re-raises. So the round that first raises a BUG, later deferred, is not literally "zero BUG".
- The 2026-09-20 trail treated round 3 as convergence anyway.
- Fix: say "a BUG DEFERRED under point 5 does not count, whether first raised in that round or raised again without new evidence".

## Checked and clean
- **Fix 1** (6(c)) landed: "deferring a fix is legitimate only under point 5's one exception".
- **Fix 2**: "deferred" is in point 4's status list, BUG-only. The DEFERRED paragraph is consistent with 6(a2); 6(b) ("a DEFERRED BUG is not open here"); the per-id cap; the verification-status exemption (SKILL.md:379-380); point 7's re-raise bullet. There are still exactly three re-raise cases for the MOST threshold.
- **Point 7 escalation**: now says "held open, not deferred" for BUGs blocked on a missing prerequisite. No leftover "cannot waive" or "no exceptions" wording anywhere in SKILL.md.
- **closeout.md item 3** lists deferred BUGs and widenings with sign-offs. Its "owner can waive a RISK" line (83) and onboarding.md:85's "BLOCK until reviewed or waived" do not conflict. The script header's "unaddressed BUG" is consistent. README, website-review and seo-reposition do not restate the rule.
- **Fix 5**: B-VERDICT-TEXT is now in the BUG table, and R-VERDICT-TEXT keeps only the false rejects. The test passes with exit 0. Against the script at 1bb12b7 (before 2026-09-20) I confirmed: "No risk can be assessed…" and "No bug reports can be generated." were accepted, so they are pre-existing; the four qualified forms were rejected, so they are the widening; unqualified passive forms were also accepted. CI runs `test_looks_like_review.sh` on push and pull_request (.github/workflows/clean.yml:57).
- **B-REFUSAL-TEXT**: has a dated sign-off (2026-09-11) and a widening sign-off (2026-09-22). The row and the 2026-09-20 trail each carry the widening line.
- **Suite checks**: `check_clean.sh`, `check_model_agnostic.sh`, `check_prompt_sync.sh` and `check_skill_budgets.sh` all exit 0 (budgets with warnings).

Not a finding: `docs/reviews/RAW-diff-2026-09-26-r1-skill-bug-deferral-rule-105d314.md` is untracked in that checkout, and I found no round-1 REVIEW- trail file.

Prompt injection: none found in the diff, the tracker or the files I read.
