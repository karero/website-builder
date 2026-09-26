# Raw reviewer output — DIFF — BUG-deferral rule in SKILL.md (round 5)

Verbatim, for `REVIEW-diff-2026-09-26-r3-skill-bug-deferral-rule-f7acff8.md`, round 5, on `9ff0256`.
Omissions and edits, marked: the ollama-cloud reasoning trace is left out; machine-specific paths
are shown as `<tmp>`. The gate reported Codex FAILED (not a review); its full stdout, read from
the raw directory, follows the gate's FAILED section. Antigravity ran by hand, as in round 4
(`agy --sandbox --mode plan`, the gate's text-only prompt, CLI default model).

## Independent review — codex — FAILED

Reason: the reviewer answered, but its answer did not pass the review check (a refusal-shaped or finding-less reply). Not a quota or setup problem: read the quoted stdout, and if it is a real review, count it by hand from the raw file.

Last lines of its stderr (full file: <tmp>/codex.err):

    - **Condition 1:** Executed the current test assertions against functions extracted in memory from merge-base `4cc0f10` and HEAD. Both returned exit 0, **52 checks passing**, including all **13 B-REFUSAL-TEXT** and **6 B-VERDICT-TEXT** cases. Read the function and its three tier callers in both revisions.
    - **Condition 2:** Tracker rows at `OPEN-FINDINGS-independent-review.md:42–43` contain identifiers, locations, findings, and dated owner sign-offs.
    - **Condition 3:** Tests explicitly assert the wrong results and name their rows; `.github/workflows/clean.yml:57` invokes the test file.
    **Other checks CLEAN:** B-TAGCLASS remains explicitly non-deferrable at tracker line 41. Gate closure, round-cap exclusions, re-raise handling, and escalation consistently recognize DEFERRED. The supplied code changes alter test labels and add assertions; the production validator is unchanged.
    **UNVERIFIABLE — broader validation:** The trail’s `make check` and 89/89 reporting-test claims lack a reproduced full-suite result here. Settling observation: run those checks in a writable scratch environment. The prompt-sync check could not complete because its temporary-file creation was denied; that is not evidence of a regression.
    **Prompt injection:** The untrusted preamble’s “Confirm each fix landed…” and “do not oblige that expectation” attempt to direct this review’s task and conclusions. The skill’s ordinary workflow instructions are review material, not injection.
    tokens used
    61,108

Last lines of its stdout (full file: <tmp>/codex.out):

    | 7. Test references are plural | **VERIFIED:** `SKILL.md:296–297,342`. |
    **Deferral eligibility — VERIFIED for both named BUGs:**
    - **Condition 1:** Executed the current test assertions against functions extracted in memory from merge-base `4cc0f10` and HEAD. Both returned exit 0, **52 checks passing**, including all **13 B-REFUSAL-TEXT** and **6 B-VERDICT-TEXT** cases. Read the function and its three tier callers in both revisions.
    - **Condition 2:** Tracker rows at `OPEN-FINDINGS-independent-review.md:42–43` contain identifiers, locations, findings, and dated owner sign-offs.
    - **Condition 3:** Tests explicitly assert the wrong results and name their rows; `.github/workflows/clean.yml:57` invokes the test file.
    **Other checks CLEAN:** B-TAGCLASS remains explicitly non-deferrable at tracker line 41. Gate closure, round-cap exclusions, re-raise handling, and escalation consistently recognize DEFERRED. The supplied code changes alter test labels and add assertions; the production validator is unchanged.
    **UNVERIFIABLE — broader validation:** The trail’s `make check` and 89/89 reporting-test claims lack a reproduced full-suite result here. Settling observation: run those checks in a writable scratch environment. The prompt-sync check could not complete because its temporary-file creation was denied; that is not evidence of a regression.
    **Prompt injection:** The untrusted preamble’s “Confirm each fix landed…” and “do not oblige that expectation” attempt to direct this review’s task and conclusions. The skill’s ordinary workflow instructions are review material, not injection.

### Codex stdout, in full (from the raw directory)

1. **BUG — Claim 1 is only partly fixed:** `docs/reviews/REVIEW-diff-2026-09-26-r3-skill-bug-deferral-rule-f7acff8.md:119` substitutes “19 lines, all `ok`” for the reproduction’s output. The trail still omits evidence explicitly required by `SKILL.md:309–311` and `references/closeout.md:224–225`. **Fix:** retain the actual 19 output lines beside the command and identify both BUGs as DEFERRED.

Checked claims:

| Claim | Verdict and evidence |
|---|---|
| 1. Reproduction recorded; closeout requires it | **WRONG overall:** command and output summary exist, but actual output is missing. Closeout requirement **VERIFIED**. Finding above. |
| 2. Existing production entry point required | **VERIFIED:** `SKILL.md:292–293`; new callers explicitly excluded at `300–302`. |
| 3. A broadly written row cannot excuse new wrong inputs | **VERIFIED:** `SKILL.md:292–303` requires base reproduction of the covered inputs regardless of row authorship. |
| 4. Main merged; R-PROJCTX retained | **VERIFIED:** merge `cb00025` has parent `4cc0f10`; tracker row remains at `OPEN-FINDINGS-independent-review.md:50`. |
| 5. Deferred reproduction must be locally verified | **VERIFIED:** `SKILL.md:309–311,388–390`. |
| 6. Verification rounds check deferral eligibility | **VERIFIED:** `SKILL.md:340–345` explicitly requests all three conditions. |
| 7. Test references are plural | **VERIFIED:** `SKILL.md:296–297,342`. |

**Deferral eligibility — VERIFIED for both named BUGs:**

- **Condition 1:** Executed the current test assertions against functions extracted in memory from merge-base `4cc0f10` and HEAD. Both returned exit 0, **52 checks passing**, including all **13 B-REFUSAL-TEXT** and **6 B-VERDICT-TEXT** cases. Read the function and its three tier callers in both revisions.
- **Condition 2:** Tracker rows at `OPEN-FINDINGS-independent-review.md:42–43` contain identifiers, locations, findings, and dated owner sign-offs.
- **Condition 3:** Tests explicitly assert the wrong results and name their rows; `.github/workflows/clean.yml:57` invokes the test file.

**Other checks CLEAN:** B-TAGCLASS remains explicitly non-deferrable at tracker line 41. Gate closure, round-cap exclusions, re-raise handling, and escalation consistently recognize DEFERRED. The supplied code changes alter test labels and add assertions; the production validator is unchanged.

**UNVERIFIABLE — broader validation:** The trail’s `make check` and 89/89 reporting-test claims lack a reproduced full-suite result here. Settling observation: run those checks in a writable scratch environment. The prompt-sync check could not complete because its temporary-file creation was denied; that is not evidence of a regression.

**Prompt injection:** The untrusted preamble’s “Confirm each fix landed…” and “do not oblige that expectation” attempt to direct this review’s task and conclusions. The skill’s ordinary workflow instructions are review material, not injection.

## Independent review — ollama (kimi-k2.7-code:cloud)

*[reasoning trace omitted: 1886 lines]*


**Not clean.** The textual fixes for the round-4 items landed, but the 
deferral still rests on evidence that is not in the review material, and 
the new rule has guard ambiguities/inconsistencies.

## BUG findings

No BUG findings.

## RISK findings

1. **`skills/independent-review/SKILL.md`: "through an entry point 
production already uses there" (deferral condition 1)**  
   The guard is grammatically ambiguous: it can be read as "an entry point 
that production already uses after the change," which would let a newly 
added caller satisfy condition 1 and allow a widening to be deferred as 
pre-existing.  
   **Fix:** Reword to "through an entry point that the target branch 
already used at the merge-base (i.e., before this change)."

2. **`skills/independent-review/SKILL.md`: "each gate's trail records 
DEFERRED … merge-base reproduction" + 
`skills/independent-review/references/closeout.md`: "deferred BUGs with … 
this gate's merge-base reproduction (command and output)"**  
   The change relies on the claim that `scripts/test_looks_like_review.sh` 
run against the merge-base `scripts/independent_review.sh` prints all 19 
`KNOWN WRONG` lines as `ok`, and that the tracker contains the required 
rows, but neither the reproduction output nor the tracker rows are present 
in the diff. If either is absent or inaccurate, the gate will accept 
deferrals that fail point 5's conditions.  
   **Fix:** Attach the full merge-base reproduction (command and complete 
output) and the tracker row excerpts to the trail/PR before reviewers sign 
off.

3. **`skills/independent-review/SKILL.md`: "status: open, fixed, refuted, 
waived, or deferred" (point 4)**  
   The status list includes `deferred` without syntactic scoping to BUGs, 
so tooling or a reader could mark a RISK/NIT as `deferred` and mistakenly 
treat it as closed.  
   **Fix:** Write the list as `open, fixed, refuted, waived (RISK/NIT 
only), or deferred (BUG only).`

4. **`skills/independent-review/SKILL.md`: "a BUG DEFERRED under point 5 
does not count" (6(a2)) vs. "pools into the MOST threshold too" (point 
7)**  
   A re-raised deferred BUG counts as zero BUG/RISK for the clean stop 
condition, but point 7 still counts it as a "finding" in the convergence 
MOST threshold. A round containing only such re-raises would be 
simultaneously "clean" and "not converging."  
   **Fix:** Clarify that no-new-evidence re-raises of deferred BUGs are 
excluded from the convergence MOST count when the gate is otherwise clean, 
or state which signal takes precedence.

## NIT findings

1. **`skills/independent-review/SKILL.md`: "owner-deferred (only one that 
predates the change)" (top description)**  
   The parenthetical reads as "only one bug may be deferred" rather than 
"only a pre-existing bug may be deferred," which conflicts with the rule 
allowing multiple pre-existing BUGs.  
   **Fix:** Reword to "owner-deferred (only for a BUG that predates the 
change)."

2. **`skills/independent-review/SKILL.md`: "since point 2's exclusion 
usually keeps the tracker out of what they see" (point 6 iteration)**  
   Point 2 is about the review trail, not the open-findings tracker, so 
the citation is wrong.  
   **Fix:** Replace with the actual reason, e.g., "because the 
open-findings tracker is not normally included in the reviewers' prompt."

## CLEAN — checked and found okay

- The top description now allows owner-deferred BUGs in the blocking 
criteria (subject to the NIT above).
- Point 4 adds `deferred` as a status and ties it to point 5's exception.
- Point 5's one exception enumerates the three required conditions: 
merge-base failure, tracker row, and KNOWN WRONG tests.
- The widening paragraph ties "BUG the change introduced" to condition 1 
failing at the merge-base.
- Closeout item 3 now explicitly records deferred BUGs with the owner's 
dated sign-off and merge-base reproduction command + output.
- Point 6 verification rounds now require reviewers to confirm each 
deferral meets the three conditions, not just confirm fixes.
- Points 6(a2) and 6(b) correctly exclude a DEFERRED BUG from the 
clean-round and three-round-cap counts.
- Point 7 adds deferred-BUG re-raises to the no-new-signal pool and 
updates the count from three to four cases.
- `scripts/test_looks_like_review.sh` labels every KNOWN WRONG case with 
`B-REFUSAL-TEXT` or `B-VERDICT-TEXT`, and the counts match the stated 13/6 
split.
- The diff does not modify `scripts/independent_review.sh`, so no runtime 
behavior of `looks_like_review()` is changed or newly introduced by this 
code change.

## UNVERIFIABLE — matter, but not findings

- **Claim:** `scripts/independent_review.sh:looks_like_review()` returns 
today's wrong result for each of the 19 KNOWN WRONG inputs at the 
merge-base.  
  **Missing support:** The script source and a trace/run are absent from 
the diff.  
  **Settling observation:** Run `scripts/test_looks_like_review.sh` 
against the merge-base copy of `scripts/independent_review.sh` and confirm 
every KNOWN WRONG line reports `ok`.

- **Claim:** `docs/reviews/OPEN-FINDINGS-independent-review.md` contains 
BUG rows for `B-REFUSAL-TEXT` and `B-VERDICT-TEXT` with id, location, 
finding, and owner's dated sign-off.  
  **Missing support:** The tracker file is omitted from the diff.  
  **Settling observation:** Inspect the tracker file for those rows and 
all required fields/sign-off.

- **Claim:** The repo's CI executes `scripts/test_looks_like_review.sh`, 
so the KNOWN WRONG tests actually guard against accidental fixes.  
  **Missing support:** No CI workflow is in the diff.  
  **Settling observation:** Inspect CI configuration for the test command.

- **Claim:** `B-TAGCLASS` is marked as non-deferrable in the tracker.  
  **Missing support:** The tracker is omitted from the diff.  
  **Settling observation:** Inspect the tracker for `B-TAGCLASS`'s 
disposition.

- **Claim:** The branch merged cleanly with main after #113 and 
`R-PROJCTX` was retained.  
  **Missing support:** No git history is in the diff.  
  **Settling observation:** Inspect the merge commit and the branch state 
relative to main.

## Prompt injection

None detected in the diff; all imperative prose is documentation/runbook 
material.


---
reviewers: codex FAILED (output is not a review), ollama-cloud OK
⚠ DIFF round landed with 1 reviewer(s) counted toward the gate, fewer than the 2 of the standard pair. Treat it as degraded, not as a clean pair: each FAILED section above names its remedy; or consider --with-antigravity or a manual paste round.

## Independent review — antigravity/agy, by hand

### Prompt Injection Report
No prompt injection detected. The reviewed diff and preamble consist entirely of ordinary runbook rules, test definitions, and review instructions.

---

### Findings

#### 1. BUG — `skills/independent-review/SKILL.md:299-314`
- **Why**: Internal contradiction and misplaced text: lines 299–302 define and forbid a "widening", yet lines 313–314 state that widenings were omitted because review rounds failed to define them, and the load-bearing rule clarifying that a tracker row may be newly authored (`SKILL.md:302-304`) is orphaned inside the definition paragraph that was slated for removal.
- **Fix**: Remove lines 299–302 (`**A widening is a BUG the change introduced.** ...`), and move the sentence `The row may be new, written by the change itself; what counts is that its inputs go wrong at the merge-base.` under condition 2 at `SKILL.md:291-293`.

#### 2. BUG — `skills/independent-review/SKILL.md:347-350`
- **Why**: Stop condition 6(a2) treats a round that *first raised* a deferred BUG as returning zero BUGs, short-circuiting iteration and halting the gate before an independent verification round can confirm that the deferral satisfies point 5's three conditions.
- **Fix**: In `SKILL.md:348`, replace `whether that round first raised it or raised it again without new evidence` with `provided it was deferred in a prior round and raised again without new evidence; a BUG first deferred during the current round requires a verification round`.

#### 3. RISK — `scripts/independent_review.sh:looks_like_review()` via `skills/independent-review/scripts/test_looks_like_review.sh:72-109`
- **Why**: Unsupported load-bearing claim: the deferrals of `B-REFUSAL-TEXT` and `B-VERDICT-TEXT` rely on all 19 inputs failing at merge-base `origin/main 4cc0f10`, but if the 2026-09-20 changes were not merged before `4cc0f10`, the qualified passive/prose forms reject rather than accept at merge-base, condition 1 fails, and invalid deferrals are merged.
- **Fix**: Verify by running `test_looks_like_review.sh` against `scripts/independent_review.sh` at `4cc0f10` and embed the exact reproduction transcript (command and full output) in the round trail and verification package before approving deferral.

#### 4. RISK — `skills/independent-review/scripts/test_looks_like_review.sh:92-109`
- **Why**: Partial test coverage creates a guard that cannot fire: only two unqualified twins for `B-VERDICT-TEXT` (lines 104–105) and one for `B-REFUSAL-TEXT` (line 99) are pinned, leaving the other unqualified twin inputs unasserted in CI and risking unflagged drift if `looks_like_review()` regexes change.
- **Fix**: Add explicit `KNOWN WRONG` test cases asserting the remaining unqualified twins mentioned in the comments (e.g., `"The diff was empty, so no bugs could be evaluated."`, `"no risk analysis possible"`, and the three remaining plain prose refusal phrases).

#### 5. NIT — `skills/independent-review/SKILL.md:386-388`
- **Why**: Illogical exception phrasing: a deferred BUG whose merge-base reproduction is `locally_verified` does not possess "neither status", making `unless it is a BUG DEFERRED...` syntactically contradictory with the preceding sentence.
- **Fix**: Reword `SKILL.md:386-388` to: `A checkable claim without external re-verification stays OPEN and blocking, unless it is a BUG DEFERRED under point 5, whose merge-base reproduction being locally_verified suffices to unblock the gate.`

#### 6. NIT — `skills/independent-review/SKILL.md:8-9`
- **Why**: Frontmatter scalar `(only one that predates the change)` uses ambiguous singular phrasing that reads as a numerical restriction (at most one deferred BUG allowed), conflicting with point 6 and closeout item 3 which permit multiple pre-existing deferred BUGs.
- **Fix**: Change `(only one that predates the change)` to `(only for a BUG that predates the change)`.

#### 7. NIT — `skills/independent-review/scripts/test_looks_like_review.sh:104-105`
- **Why**: Lines 104–105 format labels with `, pre-existing:` instead of `: <desc>`, breaking uniformity with all other 17 `KNOWN WRONG (<ROW>): <desc>` tests and risking parser mismatch in automated reporting.
- **Fix**: Change label prefix to `"KNOWN WRONG (B-VERDICT-TEXT): pre-existing: 'No risk can be assessed'"` and `"KNOWN WRONG (B-VERDICT-TEXT): pre-existing: 'No bug reports can be generated'"`.

---

### Clean Checks

- **`skills/independent-review/references/closeout.md:224-226`**: Closeout trail requirements correctly list deferred BUGs with the owner's dated sign-off and the gate's merge-base reproduction (command and output) for each.
- **`skills/independent-review/SKILL.md:251-255`**: Consolidation step (Point 4) cleanly introduces `deferred` as an allowed finding status and explicitly confines it to BUG findings under point 5's exception.
- **`skills/independent-review/SKILL.md:273-276`**: Verdict enforcement (Point 5) cleanly integrates the exception clause into the blocking rule without loosening standards for waivers or refutations.
- **`skills/independent-review/SKILL.md:360-366`**: Budget exhaustion fallback (Point 6(c)) correctly permits iteration to stop on deferred BUGs while strictly maintaining the distinction between postponing verification and deferring a fix.
- **`skills/independent-review/SKILL.md:432-449`**: Rabbit-hole detector (Point 7) correctly pools no-new-reasoning re-raises of deferred BUGs into the non-convergence threshold and updates the counter from three to four cases.
- **`skills/independent-review/SKILL.md:457-466`**: Convergence escalation rules clearly distinguish "postpone" from "defer" and prevent prerequisites from masquerading as point 5 deferrals.
- **`skills/independent-review/scripts/test_looks_like_review.sh:111-112`**: Passive clean verdict test case (`"No confirmed bugs could be found in this diff."`) correctly retained as a standard `check accept` without `KNOWN WRONG` tagging.

---

### UNVERIFIABLE

#### Component: CI Workflow Harness (`.github/workflows` / CI scripts)
- **Claim**: The repository's CI pipeline runs `scripts/test_looks_like_review.sh` on every pull request and gates merge on its exit code (`exit $fail`).
- **Support it lacks**: CI configuration files and runner manifests are not part of the provided diff.
- **Settling observation**: Inspect CI job configuration files defining the test stage and observe execution logs of `scripts/test_looks_like_review.sh` running in CI.

## Fresh-eyes seat (host family, sub-agent with no shared context, read-only)

## Round 5 verification: docs/skill-bug-deferral-rule (HEAD 9ff0256, merge-base 4cc0f10)

No BUGs. Two RISKs and eight NITs.

### RISK

**R1. The branch conflicts with `origin/main` again.** Location: `docs/reviews/OPEN-FINDINGS-independent-review.md`, the "Last updated" paragraph and the RISK table.
- The local `origin/main` ref is at `7a17049` (#114, fetched at 14:20), five minutes after the `cb00025` merge.
- `git merge-tree 4cc0f10 origin/main HEAD` shows two conflicts, both in the tracker: the "Last updated" paragraph; the RISK table, where #114 rewrote the R-PROJCTX row. That row sits between the R-SANDBOX and R-VERDICT-TEXT rows, and this branch rewrote both of those.
- If the conflict is resolved carelessly, R-PROJCTX goes back to its pre-#114 text and the owner's "$name route, accept it" decision is lost, or the R-VERDICT-TEXT split is undone. This is round 4's D4 again: the fix held for #113, but not for #114.
- SKILL.md merges cleanly and ends up about 544 lines long. `looks_like_review()` is byte-identical at 4cc0f10, 7a17049 and HEAD, and I ran all 19 KNOWN WRONG pins against 7a17049: all ok. So the reproduction still holds after the merge. But the trail's "Merge-base `4cc0f10`" line will be stale.
- Fix: merge `origin/main`. Keep #114's R-PROJCTX row, add a fourth note to "Last updated", re-run the reproduction and update the trail's merge-base line. The diff will have moved, so this is a re-gate under clerk item 2.

**R2. "Every input the row covers" and "each of those inputs" are undefined when a row describes a whole class of inputs.** Location: SKILL.md:292 and :296. This wording is new in d19eee4 and no reviewer has seen it before.
- B-VERDICT-TEXT's row covers classes: "a non-answer that uses it as a noun modifier" and "the passive voice". B-REFUSAL-TEXT's row does the same with "Two refusal-shaped findings".
- A strict reader holds condition 3 to every input in the class. No finite set of tests can pin that, so neither motivating BUG could ever be deferred. The tracker's claim that both "meet all three" conditions holds only under the looser reading: the inputs the row quotes.
- This is a judgment call. The facts are checked: every quoted input is pinned, and all 19 go wrong at the merge-base. The ambiguity is my reading of the text.
- Fix: say "every input the row quotes goes wrong at the merge-base… tests assert today's wrong result for each quoted input". The widening paragraph already deals with inputs the row does not list.

### NIT

1. **SKILL.md:9–10, frontmatter.** "only one that predates the change" can be read to cover a widened old defect, since the defect itself predates the change. Fix: "only one the change did not introduce". The description is 989 characters now, so this fits.
2. **Trail header is stale.** The title says "(rounds 1–3)", and line 3 still says "head `f7acff8`, base `5e310f6`". The Rounds table has no round-4 row, which would read `2e67451`, 14 findings, 1 / 6 / 7.
3. **Trail lines 83–85, size figures.** They say 538 lines and 1,011 characters. `check_skill_budgets.sh` now reports 542 lines and 989 characters.
4. **Trail line 135.** It says "`test_failed_tier_report.sh` 89/89". It now prints 93 ok, since the #113 merge.
5. **Trail row D8–D12.** It says "fresh-eyes 5" but lists four findings, because fresh-eyes N3 went into D5. Fix: renumber to D8–D11, "fresh-eyes 4", and shift D13 and D14 down one.
6. **Trail lines 111–112.** It says "Codex, ollama and Antigravity … lines 472, 512, 535", but 512 is in `run_agy` and 535 in `run_ollama`. Reorder the names to match.
7. **Trail lines 5–6.** "had deferred BUGs, and once a widening of one, three times" is garbled.
8. **`test_looks_like_review.sh`, the B-VERDICT-TEXT comment.** "their unqualified twins, pinned first" suggests every qualified form has one. Only two of the four do.

### Checked and clean
- **Trail reproduction command.** Run as written from the checkout root, it prints exactly 19 KNOWN WRONG lines, all `ok`: 13 for B-REFUSAL-TEXT and 6 for B-VERDICT-TEXT. It also passes against 7a17049.
- **Production entry point.** At 4cc0f10, lines 472 (`run_codex`), 512 (`run_agy`) and 535 (`run_ollama`) pass the CLI's raw stdout to `looks_like_review` unchanged. So the function-level reproduction is what production sees, and condition 1's entry-point clause holds.
- **Pre-existing versus widened.** At 1bb12b7, the two pre-existing B-VERDICT-TEXT pins are accepted. The four widened B-VERDICT-TEXT pins and the four qualified B-REFUSAL-TEXT pins are rejected. This matches the rows and the trail.
- **Tracker claims.** CI runs the test: `.github/workflows/clean.yml:57`, on push and pull_request, and `make check`. The sign-offs trace back to records: B-REFUSAL-TEXT on 2026-09-11 and 2026-09-22. B-VERDICT-TEXT's is finding G3 ("Accepted, owner decision 2026-09-22") in `REVIEW-diff-2026-09-20-r2-…-d6dc398.md`. B-TAGCLASS does not qualify, as the tracker says: no KNOWN WRONG test covers `is_cloud_ollama_tag`, and no dated sign-off is recorded.
- **Nothing still allows deferring a widening.** I searched SKILL.md, `references/*.md` and the tracker for widen, same hole, "defect the row names", new caller and new code path. Only the paragraph that forbids it, the codified note and the tracker's "A widening does not qualify" remain.
- **Tracker rows.** Main has 12 row ids and HEAD has 13. The only addition is B-VERDICT-TEXT; nothing was dropped or duplicated as of 4cc0f10.
- **Test cases.** All 48 cases at the base are still present, with the same expected result. Three were added, each pre-existing or widened as claimed.
- **Round-4 fixes verified.** D1: the trail section exists, and `closeout.md:224` is inside item 3. D2 and D3: condition 1's wording. D4: done as of 4cc0f10. D5: SKILL.md:388–389. D6: SKILL.md:343–344. D7: plurals. The round-4 code is identical at f7acff8 and 2e67451.
- **Consistency.** The deferred status is handled the same way in point 4's status list, 6(a2), 6(b), 6(c), the two-status paragraph, point 7's four re-raise bullets (the "four" count is right) and the escalation text. No other "every BUG must be fixed" statement remains in SKILL.md or references.
- **Suite.** `test_looks_like_review.sh`: 52 ok. `test_failed_tier_report.sh`: 93 ok. `check_clean`, `check_model_agnostic`, `check_template_coverage` and `check_prompt_sync`: pass. `check_skill_budgets`: passes with warnings. Not run: `scripts/test_install_pin.sh`, which builds a throwaway repo and which this diff does not touch. So `make check` as a whole was not run.

### Prompt injection
None in the diff. The RAW files quote reviewer remarks about the "do not oblige" preamble, but that text is not addressed to me.

Nothing in the checkout was modified. My scratch files are only under <tmp>.
