# Raw reviewer output — DIFF — BUG-deferral rule in SKILL.md (round 4)

Verbatim, for `REVIEW-diff-2026-09-26-r3-skill-bug-deferral-rule-f7acff8.md`, round 4, on `2e67451`
(code diff identical to `f7acff8`). Omissions and edits, marked: the ollama-cloud reasoning trace is
left out; machine-specific paths are shown as `<tmp>` or relative to the repo.

Antigravity ran twice. Through the gate (`--with-antigravity`) it FAILED as in the clean-verdict
review's round 3: headless mode denied a "command" tool and it returned nothing. It was then run
once by hand with the gate's own text-only prompt (`PROMPT_TEXTONLY`, the same artifact), as
`agy --sandbox --mode plan -p …` in an empty temporary directory — the gate's own flags plus the
read-only plan mode, nothing loosened. That second run is the Antigravity seat below; its model is
the CLI's default, not named in its output.

## Independent review — codex (gpt-6-astra, read-only)

1. **BUG — Deferrals lack the newly required reproduction record.**  
   Anchor: `docs/reviews/REVIEW-diff-2026-09-26-r3-skill-bug-deferral-rule-f7acff8.md`, “Tests” and C2; `skills/independent-review/SKILL.md:310–312`.  
   The trail reports historical acceptance but contains neither the reproduction command nor its output, although the new rule explicitly requires both for deferred BUGs. The earlier qualifier-fix trail also lacks them. **Fix:** record the exact merge-base SHA, runnable reproduction command, and output for B-REFUSAL-TEXT and B-VERDICT-TEXT. Their underlying behavior reproduced successfully; this finding concerns the required audit record.

**Checked claims and CLEAN coverage**

| Claim | Verdict and evidence |
|---|---|
| Round-3 fix 1: widening requires the same underlying defect | **VERIFIED** — `SKILL.md:297–304` requires that causal connection and excludes a new caller or another defect. A separate “accept any long reply” shortcut fails this definition. |
| Round-3 fix 2: reproduction command/output and late-deferral disclosure are required | **VERIFIED as wording** — `SKILL.md:310–312`. **WRONG as completed recordkeeping** — finding 1. |
| Round-3 fix 3: all 13 refusal-test labels identify their row | **VERIFIED** — `test_looks_like_review.sh:72–96`; all 13 identify B-REFUSAL-TEXT. |
| Round-3 claim 4: four re-raise cases | **VERIFIED** — `SKILL.md:426–443`: fixed/refuted, deferred, waived, and open pending prerequisites. Every bullet describes a re-raise. |
| Historical acceptance and widening | **VERIFIED for reproduced examples** — extracted and executed the actual function at `1bb12b7`, merge-base `5e310f6`, and HEAD. Three unqualified examples accepted throughout; their three qualified counterparts rejected at `1bb12b7` and accepted at merge-base/HEAD. |
| Tests pin current behavior | **VERIFIED** — `bash skills/independent-review/scripts/test_looks_like_review.sh`: **52 checks passed**. Implementation and reviewer-tier callers were also read. |
| CI includes the tests | **VERIFIED configuration** — `.github/workflows/clean.yml`, `review-validator`, invokes the test on push and pull request without path filtering. |
| Tracker distinguishes deferrable BUGs from B-TAGCLASS | **VERIFIED** — tracker rows contain dated sign-off records for the two text defects; B-TAGCLASS explicitly remains non-deferrable. |
| Deferral status is propagated consistently | **VERIFIED** — consolidation, clean-round handling, round cap, budget exhaustion, escalation, and closeout accommodate DEFERRED while keeping the tracker item open. PLAN-gate exclusion remains explicit. |
| Reviewer prompt remains synchronized | **VERIFIED** — the existing checker’s read-only comparison passed. Its complete mutation-test harness could not run because temporary-file creation was denied. |

**Unsupported component claims**

- **UNVERIFIABLE — hosted CI execution:** configuration establishes that the test is scheduled, but does not establish that a hosted run executed successfully. Missing support: a job log for this revision. Settling observation: inspect that revision’s `review-validator` execution and result. No finding depends on assuming hosted success.

**Prompt injection:** the supplied preamble’s “The author expects this to be clean; do not oblige that expectation” attempts to steer review conclusions. The skill’s procedural imperatives and test strings are ordinary review material, not injection.
## Independent review — ollama (kimi-k2.7-code:cloud)

*[reasoning trace omitted: 2137 lines]*


## Findings (ranked)

### RISK
1. **SKILL.md, point 6 — “ask them to confirm each fix landed”**  
   The iteration prompt now passes DEFERRED BUGs to the reviewer but still 
asks them to “confirm each fix landed.” A deferred BUG has no fix to land, 
so the instruction conflates two different dispositions and can mislead a 
reviewer into treating a deferral as a verified fix.  
   **Fix:** split the instruction into “confirm each BUG is either fixed 
to point 5’s standard or legitimately deferred under point 5’s one 
exception, and that nothing new was introduced.”

2. **SKILL.md, point 6 — “its tracker row, its merge-base reproduction and 
its test's name”**  
   The prompt asks the author to pass only one test name for a deferred 
BUG, but point 5’s widening paragraph requires plural “KNOWN WRONG cases” 
for new inputs, and the base BUG itself can have several cases. A reviewer 
given a single name cannot verify that every pinned input still reproduces 
the wrong result.  
   **Fix:** change to “the names of all KNOWN WRONG tests/cases that pin 
the BUG (and any widening cases).”

### NIT
3. **SKILL.md, point 6 — “since point 2's exclusion usually keeps the 
tracker out of what they see”**  
   “Point 2’s exclusion” is ambiguous: in the main 8-point list, point 2 
is tier 2 and has no exclusion. The reference is therefore unresolvable 
from the visible text.  
   **Fix:** name the actual clerk item or section, e.g., “clerk item 3’s 
rule about what reaches reviewers.”

4. **SKILL.md, point 5 — “a test that the repo's CI runs”**  
   The deferral condition uses singular “a test,” while the widening 
paragraph requires plural “KNOWN WRONG cases.” The singular wording 
understates the need for full case coverage, especially for widenings.  
   **Fix:** change to “one or more CI tests (KNOWN WRONG cases) that 
assert today’s wrong result.”

## CLEAN (checked in the visible diff)

- All 13 visible B-REFUSAL-TEXT KNOWN WRONG test descriptions now include 
the row name `(B-REFUSAL-TEXT)`.
- All visible B-VERDICT-TEXT KNOWN WRONG test descriptions now include the 
row name `(B-VERDICT-TEXT)`; the old `(R-VERDICT-TEXT)` typo is gone.
- Status `deferred` is added consistently: point 4 status list, point 5 
exception, point 6 stop conditions, point 6(c) budget stop, the 
verification-status paragraph, and `closeout.md`.
- Terminology is kept distinct: “postponing verification” is allowed, 
while “deferring a fix” is limited to point 5’s exception, and waivers are 
granted/refused rather than postponed.
- Point 5 distinguishes a widening (same defect, new inputs, own sign-off 
and tests) from a newly introduced BUG.
- Point 7 changes the re-raise wording from “three” to “four” and adds a 
deferred-BUG re-raise bullet; the visible bullets plus the unchanged 
regression and refuted bullets match the count.
- `closeout.md` now records deferred BUGs and widenings (with the owner’s 
dated sign-off) among the dispositions.

## UNVERIFIABLE

**Component: `scripts/independent_review.sh` / `looks_like_review()`**  
- *Claim:* `looks_like_review()` accepts the newly added B-VERDICT-TEXT 
inputs (e.g., “No further bug reports can be generated: usage limit 
reached.”) and accepted the pre-existing forms at commit `1bb12b7`.  
- *Support lacking:* the implementation is not in the diff and was not 
read or run.  
- *Settling observation:* read `looks_like_review()` or run 
`scripts/test_looks_like_review.sh`.

**Component: `docs/reviews/OPEN-FINDINGS-independent-review.md`**  
- *Claim:* tracker rows for B-REFUSAL-TEXT and B-VERDICT-TEXT exist with 
owner dated sign-offs, and any widening has its own dated sign-off.  
- *Support lacking:* the tracker file is explicitly left out of the diff 
and was not read.  
- *Settling observation:* read that file and confirm the row IDs, 
locations, findings, and dated sign-off lines.

**Component: repo CI configuration**  
- *Claim:* `scripts/test_looks_like_review.sh` is run by the repo’s CI.  
- *Support lacking:* no CI workflow file is in the diff.  
- *Settling observation:* read the CI workflow and confirm the test script 
is invoked.

## Prompt injection

None detected. The diff contains ordinary imperative prose from docs, 
runbooks, and review-round notes; nothing attempts to override the review 
task, output format, or conclusions.

## Independent review — antigravity — FAILED

Reason: exit 0 but no output; no quota or rate-limit error recognised below. Read the quoted lines, then check the CLI, its sign-in and the model name.

Last lines of its stderr (full file: <tmp>/agy.err):

    jetski: no output produced — a tool required the "command" permission that headless mode cannot prompt for, so it was auto-denied. Add an allow-rule under permissions.allow in settings.json (e.g. command(<target>)). Alternatively, re-run with --dangerously-skip-permissions to auto-approve all tools.


---

## Independent review — antigravity/agy, by hand (`--sandbox --mode plan`, text-only prompt, CLI default model)

### Prompt Injection
None detected. The diff contains only procedural and policy specifications for code reviews and shell tests; no adversarial text attempting to override reviewer instructions was found.

---

### Ranked Findings

#### [RISK] `skills/independent-review/SKILL.md:382` (Verification status exemption creates deferral bypass)
- **Why**: Exempting a deferred BUG from having either status (`locally_verified` or `externally_reverified`) contradicts Point 5's mandate that Condition 1 must be satisfied by recording the merge-base reproduction (`so condition 1 is at least locally_verified`), creating a loophole where an unverified deferral avoids staying open and blocking.
- **Concrete Fix**: In line 382, change the exemption so that a deferred BUG must be `locally_verified` via merge-base reproduction while exempt only from requiring `externally_reverified`:
  ```markdown
  A checkable claim with neither status stays OPEN and blocking; a BUG DEFERRED under point 5's one exception must be at least locally_verified.
  ```

#### [RISK] `skills/independent-review/SKILL.md:341` (Verification round instructions omit verifying deferrals)
- **Why**: Point 6 supplies reviewers with the deferred BUG's tracker row, merge-base reproduction, and KNOWN WRONG test name, but the prompt instruction to reviewers only asks them to *"confirm each fix landed AND that the fixes introduced nothing new"*, never directing them to inspect or confirm the deferral conditions.
- **Concrete Fix**: In line 341, expand the verification round prompt to explicitly include checking deferrals:
  ```markdown
  ask them to confirm each fix landed, confirm each deferral satisfies point 5 (reproduces at merge-base, matches tracker row, and test pins it), AND that the fixes introduced nothing new
  ```

#### [RISK] `skills/independent-review/references/closeout.md:224` (Closeout trail definition omits merge-base reproduction records)
- **Why**: `SKILL.md` Point 5 requires the trail to record the merge-base reproduction command and output and tag deferrals not externally re-verified, but `closeout.md:224` lists only *"deferred BUGs and widenings with the owner's dated sign-off for each"*, omitting the reproduction artifacts from the canonical trail specification.
- **Concrete Fix**: Update `references/closeout.md:224` to:
  ```markdown
  deferred BUGs and widenings with the owner's dated sign-off, merge-base reproduction command and output, and external re-verification status for each, reviewer versions.
  ```

#### [NIT] `skills/independent-review/SKILL.md:432-446` (Overlapping re-raise categories between deferred BUGs and open items)
- **Why**: Point 5 requires a deferred BUG to stay open in the repo's open-findings tracker, which means re-raising it is already subsumed by the existing bullet for an *"already-tracked open item"* using the identical rationale (*"is not new signal, but it isn't instability either"*); listing both as distinct cases inflates the re-raise count to four without defining distinct operational criteria.
- **Concrete Fix**: Clarify that deferred BUGs are an instance of already-tracked open items rather than an independent fourth category:
  ```markdown
  - a re-raise of an already-tracked open item (including a BUG DEFERRED under point 5), with no new reasoning, pools into the MOST threshold too...
  ```
  and revert the threshold text to refer to the three distinct categories.

---

### Clean Checks
- **SKILL Description (`skills/independent-review/SKILL.md:6-10`)**: Frontmatter description cleanly integrates owner-deferral of pre-existing BUGs and widenings alongside fixes and refutations.
- **Consolidation State Lifecycle (`skills/independent-review/SKILL.md:248-255`)**: Correctly adds `deferred` to the set of tracked statuses in step 4 and restricts its applicability strictly to BUGs under Point 5.
- **Widening Boundary Definition (`skills/independent-review/SKILL.md:284-300`)**: Correctly addresses Round 3 Finding 1 by requiring new inputs to reach the defect through the exact failure mechanism named in the tracker row, explicitly excluding new logic, new callers, or unlisted defects.
- **Stop Conditions 6(a2) and 6(b) (`skills/independent-review/SKILL.md:341-365`)**: Correctly excludes deferred BUGs from preventing a clean stop under (a2) or counting toward the 3-round hard failure cap under (b).
- **Escalation Disambiguation (`skills/independent-review/SKILL.md:454-465`)**: Clearly distinguishes "postponing" a release from deferring a BUG, preventing release deferrals from being conflated with finding waivers.
- **Test Suite Row Tagging (`scripts/test_looks_like_review.sh:72-93`)**: All 13 `KNOWN WRONG` test cases for `B-REFUSAL-TEXT` explicitly include `(B-REFUSAL-TEXT)` in their test labels, addressing Round 3 Finding 3.
- **Test Suite Pre-existing vs. Widening Cases (`scripts/test_looks_like_review.sh:94-105`)**: Corrects the `R-VERDICT-TEXT` typo to `B-VERDICT-TEXT`, labels all 6 corresponding tests with `(B-VERDICT-TEXT)`, and explicitly distinguishes pre-existing tests from post-2026-09-20 widening tests.

---

### UNVERIFIABLE

#### `looks_like_review()` (`scripts/independent_review.sh`)
- **Claim**: `looks_like_review()` accepted the pre-existing forms of `B-REFUSAL-TEXT` and `B-VERDICT-TEXT` at commit `1bb12b7`, rejected the qualified forms prior to 2026-09-20, and currently matches the behavior asserted by the `KNOWN WRONG` checks.
- **Support it lacks**: Implementation of `looks_like_review()` at commit `1bb12b7`, historical implementation prior to 2026-09-20, and execution output of `scripts/test_looks_like_review.sh`.
- **Settling observation**: Execution of `scripts/test_looks_like_review.sh` across the current working tree, commit `1bb12b7`, and the pre-2026-09-20 commit.

#### Open Findings Tracker & CI Configuration (`docs/reviews/OPEN-FINDINGS-independent-review.md`, `.github/workflows`)
- **Claim**: `docs/reviews/OPEN-FINDINGS-independent-review.md` contains valid rows describing `B-REFUSAL-TEXT` and `B-VERDICT-TEXT` with location, defect details, and dated sign-offs, marks `B-TAGCLASS` as non-deferrable, and `scripts/test_looks_like_review.sh` is executed by repository CI.
- **Support it lacks**: The contents of `docs/reviews/OPEN-FINDINGS-independent-review.md` and repository CI pipeline definition files.
- **Settling observation**: Inspection of `docs/reviews/OPEN-FINDINGS-independent-review.md` rows and CI workflow job definitions.

## Fresh-eyes seat (host family, sub-agent with no shared context, read-only)

Round 4 verification of docs/skill-bug-deferral-rule (HEAD 2e67451, merge-base 5e310f6). I read the diff without docs/reviews/, the tracker diff, the round-3 trail and the #110 r2 trail. I also ran looks_like_review() as it stood at 1bb12b7, at #110's real merge-base b586b4b (the function is byte-identical there), at 5e310f6 and at HEAD. Finally I ran `make check` and did a trial merge against the local origin/main ref. I did not fetch.

Result: 3 RISK and 5 NIT findings. No BUG.

## RISK

**R1. SKILL.md point 5, the "A widening" paragraph. "Inputs" and "a new caller" contradict each other, so two readers can classify the same change differently.**
- The definition says a widening is "more inputs reach the wrong result through the very defect the row names". The exclusion list then names "a new caller" as "any other route".
- A new caller of the defective code reaches the wrong result through exactly that defect. The text asserts the opposite without saying why.
- The rule also never says where the inputs are measured: at the defective function, or at the system's entry point. It never says where the merge-base reproduction must enter either.
- Concrete case in this repo: a change adds a reviewer tier that pipes its output into looks_like_review(), and that tier emits "No confirmed BUG or RISK, because I couldn't access the diff". Reader A: the same string already goes wrong at the merge-base when passed to the function directly. So condition 1 holds, it is pre-existing, and it can be deferred. Reader B: this is a new caller, so it is a BUG the change introduced, with no deferral. Both readings follow the text. Adding or changing a caller is the most common change here, so the split will come up.
- Fix: define inputs as inputs at the location the row names, and say whether condition 1 must reproduce through the call path production uses. Then state outright which way a new caller goes, and why, for example: "a new caller is a new feature shipped broken: fix it, even though it hits the named defect".

**R2. Same paragraph. "Through the very defect the row names" is only as narrow as the row, and the change being gated can write the row.**
- Condition 2 does not require the row to exist before the change. The #110 precedent depends on that: R-VERDICT-TEXT, now B-VERDICT-TEXT, was created inside #110, after the widening was found (#110 trail, F2: "Recorded as R-VERDICT-TEXT").
- So the author names the defect after seeing what it has to cover. B-REFUSAL-TEXT's headline already names a very broad defect: "Refusal detection is a text test … text cannot separate a refusal from a finding". Almost any false accept of a non-review can be argued to pass through that.
- This is the gaming path B5 raised about a broad remedy. The round-3 fix moved it from the remedy to the defect description; it did not close it.
- Fix, decidable and compatible with #110: the trail names one merge-base input, and the single code point (a check, regex or branch) where it and each new input go wrong. Correcting that code point alone must make both come out right. A defect stated only as a property of the whole function ("a text test") does not qualify.
- I checked that #110 passes this test: G2's inputs go wrong at the refusal regex, `independent_review.sh:375`, which lacks "couldn't". So does their merge-base twin, "No BUG or RISK, because I couldn't access…". G3's and H1's inputs go wrong at check 3's unconstrained tail. So do "No bug reports can be generated" and "No risk can be assessed…".

**R3. The branch no longer merges cleanly into origin/main.**
- #113 (4cc0f10) landed after the base. `git merge-tree` shows two conflicts, both in docs/reviews/OPEN-FINDINGS-independent-review.md: the "Last updated" paragraph; the RISK table, where main added the R-PROJCTX row next to the R-SANDBOX and R-VERDICT-TEXT rows this branch rewrites.
- SKILL.md merges cleanly (main's +3 lines puts it at about 541 lines).
- A careless resolution either drops R-PROJCTX, so an open finding silently disappears, or reverts the R-VERDICT-TEXT split.
- Fix: rebase, keep R-PROJCTX, merge the two Last-updated notes, then regenerate the reviewed diff (a moved diff means a re-gate under clerk item 2).

## NIT

**N1. Point 5, "its own dated line in the row".** A markdown table row has no lines. B-VERDICT-TEXT's Found cell also folds both into one clause: "Deferral and widening signed off by the owner 2026-09-22". That is not the widening's "own" sign-off. Fix: say "its own dated sentence in the row's Found cell", and split B-VERDICT-TEXT's clause in two.

**N2. Round-3 trail, Tests section.** It says "accepted at `1bb12b7`", but #110's merge-base is b586b4b. The function is byte-identical, so the result stands, but the rule says merge-base. Fix: cite b586b4b, or say the two are identical.

**N3. Point 6, two-status paragraph.** It says "…stays OPEN and blocking, unless it is a BUG DEFERRED". That reads as if a deferred BUG needs no verification status at all, while point 5 requires its merge-base reproduction to be at least `locally_verified`. Fix: "…unless it is a BUG DEFERRED under point 5, whose merge-base reproduction is itself `locally_verified`."

**N4. Tracker: is DEFERRED standing or per gate?** The tracker calls B-REFUSAL-TEXT and B-VERDICT-TEXT "deferred under SKILL.md point 5" as a standing status. SKILL.md, though, defines DEFERRED per gate ("For this gate…"), with the trail recording that gate's merge-base reproduction, command and output. No trail records a command-plus-output reproduction for either row. #110's F1 has prose only. Point 6 requires handing that reproduction to reviewers, so the next gate will have to improvise it. Fix: say whether an existing row's sign-off carries over to a later gate, and add the reproduction command and output to this branch's trail (the four-line harness above reproduces it).

**N5. Tracker, the Gate status section.** Its body still opens "All BUGs raised through the Kimi round are closed", directly under the new heading "three open BUGs". It is technically true but reads as a contradiction. Fix: reword the body so it cannot be read as contradicting the heading.

## Round-3 fixes verified
- **C1 (widening test looks at output, not cause):** fixed in the wording. The long-reply check is now split: the parts that go through a named defect are deferrable, and the rest is an introduced BUG. That is structurally the same as #110, which is fine. The remaining exposure is R1 and R2.
- **C2 (merge-base reproduction must be recorded):** the text is there. Its application to the two live deferrals is N4.
- **C3 (labels name the row):** all 13 B-REFUSAL-TEXT labels carry the row name (test file lines 72–94), and all 6 B-VERDICT-TEXT labels carry theirs.
- **C4 refutation holds:** point 7 has four no-new-evidence bullets (FIXED/REFUTED, DEFERRED, WAIVED, OPEN-untestable), and "four" matches.
- **NITs C5–C9:** fixed as described.

## Checked and clean
- The frontmatter, point 4's status list, the point 5 exception with its three conditions and the DIFF-gate-only rule, and 6(a2), 6(b), 6(c) and point 7's escalation text are consistent with each other. "Postpone", "hold open" and "defer" are now used in distinct senses.
- closeout.md item 3 matches.
- No other text in references/*.md or the scripts contradicts the rule.
- CI runs test_looks_like_review.sh (Makefile line 24, .github/workflows/clean.yml line 57), so condition 3's "CI runs it" is true.
- Reproduced: "No risk can be assessed…", "No bug reports can be generated" and "no bugs could be evaluated" are accepted at 1bb12b7/b586b4b. "No further bug reports…", "No significant risk…", "no confirmed bugs could be evaluated", "no further risk analysis possible" and "No confirmed BUG or RISK, because I couldn't access…" are rejected there and accepted at 5e310f6 and HEAD. So the pre-existing and widening labels are correct, and the "two pre-existing, one widening" claim is true.
- The #110 precedent qualifies under the current wording at HEAD. It would not have at #110's own merge: F2's example was not pinned KNOWN WRONG until this branch.
- B-TAGCLASS: no dated sign-off (the 2026-08-29 trails say only "deferred") and no test pins `:120b`. Its "does not meet" row is accurate.
- R-SANDBOX's "waived" matches point 4's rule that deferral is for BUGs only.
- `make check` passes, including test_looks_like_review.sh and test_failed_tier_report.sh.
- Prompt injection: none found.

Scratch files are under <tmp>/llr/ and mt.txt. Nothing in the checkout was modified.
