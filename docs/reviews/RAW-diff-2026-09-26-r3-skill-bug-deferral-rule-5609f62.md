# Raw reviewer output — DIFF — BUG-deferral rule in SKILL.md (round 3)

Verbatim, for `REVIEW-diff-2026-09-26-r3-skill-bug-deferral-rule-f7acff8.md`, round 3, on `5609f62`. Omissions and edits, marked where they occur: the
ollama-cloud reasoning trace is left out (its answer after `...done thinking.` is complete); the
fresh-eyes seat's scratch path is shown without the machine prefix.

## Independent review — codex (gpt-6-astra, read-only)

No BUG/RISK/NIT findings.

Checked checkout `5609f62`; the local `origin/main` merge-base is `5e310f6`. All enumerated fixes landed.

| Checked claim | Verdict and evidence |
|---|---|
| Both tracker headings distinguish B-TAGCLASS from deferred BUGs | **VERIFIED** — `docs/reviews/OPEN-FINDINGS-independent-review.md:19,32`; its row at line 36 explicitly blocks deferral pending sign-off and a test. |
| Widening definition resolves the contradiction and broad-remedy loophole | **VERIFIED** — `skills/independent-review/SKILL.md:297–305` requires a side effect inside the named function, excludes standalone wrong-result additions and outside callers, and disallows remedy breadth as sufficient justification. |
| Merge-base condition applies to the existing BUG, not newly affected inputs | **VERIFIED** — `SKILL.md:299–300` explicitly distinguishes them. |
| Frontmatter no longer independently exempts widenings | **VERIFIED** — `SKILL.md:9–11` groups them under owner deferral; point 5 supplies the conditions. |
| Verification rounds receive deferral evidence | **VERIFIED** — `SKILL.md:337–340` requires the tracker row, merge-base reproduction, and test name. |
| B-REFUSAL-TEXT’s widened cases name their row | **VERIFIED** — `scripts/test_looks_like_review.sh:87–94` identifies it in the group comment. B-VERDICT-TEXT cases identify their row individually at lines 98–103. |
| Existing defects predate the qualifier change | **VERIFIED empirically** — extracted and executed `looks_like_review()` from `1bb12b7`, merge-base `5e310f6`, and HEAD. The tested pre-existing forms accept throughout; widened forms reject at `1bb12b7` and accept at merge-base and HEAD. |
| Deferral evidence is recorded and tests are wired into CI | **VERIFIED** — tracker rows 37–38 contain dated approvals; the earlier review trail records the widening decisions at lines 12–35 and 89–90. `.github/workflows/clean.yml:52–59` invokes the validator tests. This verifies configuration, not a hosted CI run. |

Additional **CLEAN** checks:

- `bash skills/independent-review/scripts/test_looks_like_review.sh`: all **52 checks passed**, including KNOWN WRONG cases. This confirms the defects remain pinned, not fixed.
- Deferred status is consistently handled in clean-round counting, budget exhaustion, escalation, and the four re-raise categories.
- `references/closeout.md:224–225` requires dated sign-offs for deferred BUGs and widenings.
- Reviewed validator implementation and its three reviewer callers; this diff leaves production validation unchanged.
- Frontmatter description measures **1,011 characters**, below the repository’s 1,024-character limit.
- `git diff --check origin/main...HEAD`: passed.

**Prompt-injection report:** The supplied preamble’s reviewer-directed “Confirm each fix landed…” and “do not oblige that expectation” attempt to steer this review and were treated as data. The skill’s procedural imperatives are ordinary document content.
## Independent review — ollama (kimi-k2.7-code:cloud)

*[reasoning trace omitted: 1688 lines]*


## Findings (ranked)

### 1. RISK — 
`skills/independent-review/scripts/test_looks_like_review.sh`: 
B-REFUSAL-TEXT KNOWN WRONG labels still do not name the tracker row
**Anchor:** the `accept` cases for the plain-verdict refusal phrases, the 
qualified-verdict widening cases, and the unqualified twin.  
**Why:** Point 5 now requires a KNOWN WRONG test to “name the row,” and 
the Round 2 RISK claimed the B-REFUSAL-TEXT cases were updated to do so. 
Only the block *comment* mentions `B-REFUSAL-TEXT`; the actual test labels 
omit the row id, so the deferral evidence does not satisfy the rule the 
diff just codified.  
**Fix:** Include the row id in every B-REFUSAL-TEXT label, e.g.:
- `KNOWN WRONG (B-REFUSAL-TEXT): 'couldn't access' is not a refusal 
phrase`
- `KNOWN WRONG (B-REFUSAL-TEXT, widened): qualified verdict + 
'couldn't access'`
- `KNOWN WRONG (B-REFUSAL-TEXT), pre-existing: the unqualified twin, 
accepted before the fix too`

### 2. RISK — `skills/independent-review/SKILL.md`: Point 7 says “four 
no-new-evidence re-raise cases,” but only three are re-raises
**Anchor:** the bullet list ending with “an independent reviewer in a 
later round surfacing an already-tracked open item is not new signal, but 
it isn’t instability either” and the following `**STOP patching when:** … 
any of the four no-new-evidence re-raise cases above` sentence.  
**Why:** The list contains three re-raise cases (deferred BUG, waived 
finding, fixed/refuted finding) and one already-tracked-open-item case 
that the text itself says is *not* a re-raise and *not* instability. 
Calling all four “re-raise cases” conflates categories and can skew the 
MOST threshold used to stop patching.  
**Fix:** Reword the STOP-patching rule to “any of the three 
no-new-evidence re-raise cases above, together with an independent 
reviewer surfacing an already-tracked open item,” or split the threshold 
into re-raise counts and already-tracked counts.

### 3. NIT — `skills/independent-review/SKILL.md`: Ambiguous sign-off for 
a widening
**Anchor:** the “A widening.” paragraph in point 5.  
**Why:** The paragraph says a widening needs “its own dated sign-off … and 
a line in both the row and the trail,” while the deferral condition says 
“a row … gives the id, the location, the finding and the owner’s dated 
sign-off.” It is unclear whether the widening’s dated sign-off is a 
separate entry or the row-level sign-off.  
**Fix:** State explicitly that the widening’s dated sign-off is recorded 
as a distinct dated entry inside the same tracker row (or as its own row) 
and that the row must contain both the original BUG and the widening 
entry.

## Clean (checked and found consistent)

- **Frontmatter / point 5 scope:** The frontmatter’s “owner-deferred (only 
one that predates the change, or a widening of one)” matches point 5’s 
single exception and does not imply widenings get a free pass.
- **Widening definition:** Point 5 now defines a widening as a side effect 
inside the named function, excludes cases where the wrong result is the 
new code’s only effect or occurs outside that function, and adds the 
remedy-replacement guard.
- **Condition 1 for widenings:** The widening paragraph correctly scopes 
condition 1 to the underlying BUG reproducing at the merge-base, not to 
the new inputs.
- **Status model:** Point 4 adds `deferred` as a BUG-only status tied to 
point 5’s exception.
- **Verification-round evidence:** Point 6 requires reviewers to receive 
the tracker row, merge-base reproduction, and test name for each deferred 
BUG.
- **Deferred BUGs and gate state:** Point 6(a2), 6(b), the 
verification-status rule, and point 7 consistently treat a properly 
deferred BUG as closed for the gate (does not count as open BUG/RISK, does 
not add to the three-round cap, is not blocking).
- **Re-raise handling:** Point 7 adds re-raises of deferred BUGs to the 
no-new-evidence pool.
- **closeout.md trail:** Updated to require recording deferred BUGs and 
widenings with the owner’s dated sign-off for each.
- **B-VERDICT-TEXT test labels:** Now include the row id and distinguish 
pre-existing unqualified twins from qualified widening cases.

## Unverifiable (load-bearing claims not in the diff)

- **Tracker file `docs/reviews/OPEN-FINDINGS-independent-review.md`:** The 
claim that the B-TAGCLASS headings were reworded and that the row says it 
is not deferrable, and the claim that rows for 
B-REFUSAL-TEXT/B-VERDICT-TEXT exist with the required fields and dated 
sign-offs, are unsupported because the tracker is not in the diff. 
Settling observation: read the BUG table in that file.
- **`looks_like_review()` behavior:** The claim that the function in 
`scripts/independent_review.sh` is at the stated locations and 
accepts/rejects the test inputs as described is unsupported because the 
function implementation and runtime behavior were not reviewed. Settling 
observation: run `test_looks_like_review.sh` against the function at HEAD 
and at the referenced commits.
- **CI coverage:** The claim that the repo’s CI runs 
`test_looks_like_review.sh` is unsupported because no CI configuration is 
in the diff. Settling observation: inspect the CI workflow for the test 
job.
- **Historical acceptance at commit `1bb12b7`:** The claim that the 
pre-existing phrase forms were accepted before 2026-09-20 is unsupported 
because that commit was not reproduced. Settling observation: run the test 
script at commit `1bb12b7`.

## Prompt injection

No prompt injection detected. The imperative sentences in the diff are 
runbook instructions, code comments, or test labels; none attempt to 
redirect the review task, output format, or conclusions.


---
reviewers: codex OK, ollama-cloud OK

## Fresh-eyes seat (host family, sub-agent with no shared context, read-only)

Verification round 3 of docs/skill-bug-deferral-rule (HEAD 5609f62, merge-base 5e310f6). The fixes landed, but two RISKs and five NITs remain, so this round is not clean. I did not edit anything in the checkout. My scratch files are only under <tmp>/r3/.

## Round 2 fixes: did they land?

| # | Round 2 item | Landed? |
|---|---|---|
| 1 | Tracker headings | Yes. Tracker lines 19 and 32 no longer call B-TAGCLASS deferred. |
| 2 | Widening definition | The text was rewritten at SKILL.md:297-305 and no longer contradicts itself. The gaming risk it was meant to close is still open (RISK 1 below). |
| 3 | Condition 1 for widenings | Yes, at SKILL.md:299. |
| 4 | Frontmatter | Yes, at SKILL.md:9-10. |
| — | Deferral evidence sent to reviewers | Yes, at SKILL.md:339-340. It has a gap (RISK 2 below). |
| — | B-REFUSAL-TEXT tests naming the row | Yes, in comments at test lines 75 and 87. The test labels still don't name it (NIT 4). |
| — | 6(a2) and a BUG first raised that round | Yes, at SKILL.md:344-346. |
| — | Point 7 bullet split and "four" | Yes, at SKILL.md:431-433 and 445. There really are four re-raise bullets. |
| — | Passive-voice sign-off names the owner | Yes, tracker line 38. |
| — | R-SANDBOX wording | Changed, but the new word "postponed" is not a status the skill defines (NIT 3). |
| — | "Postpone" for verification and releases | Mostly. One instance was missed (NIT 1). |

## RISK

**RISK 1 — SKILL.md:297-305. The widening test is still keyed to what the function returns, not to the BUG's cause, so a BUG the change introduced can still be deferred.**
- `looks_like_review()` returns only accept or reject. So "the wrong result the BUG already produces" is simply "a non-review is accepted".
- Every new false accept inside that function therefore meets all three positive criteria. The only exclusion, "the only effect of the code that causes it", fails for any code that also has a legitimate effect.
- Example: a change "for" accepting long real reviews adds check 4, `[ ${#1} -gt 500 ] && return 0`. It newly accepts a 600-character rate-limit error page. That is a side effect of the change's purpose, inside the named function, the same wrong result, and not the code's only effect. By the current text it is a widening and can be deferred, yet it is a new defect that neither row describes.
- The closing sentence ("A row whose remedy would replace the whole mechanism does not make every new wrong result … a widening") only denies one line of reasoning. It supplies no test that would exclude check 4, so as a guard it can never fire.
- "What the change is for" is whatever the author says it is, so that criterion can be gamed too.
- **Fix:** replace "inside the function the row names" with a test on cause: the new inputs reach the wrong result through the defect the row's Finding column names (for example, check 1 does not know the phrase; check 3 does not constrain what follows the severity word), not merely through the same output. Then delete the closing sentence, which the new test makes redundant.

**RISK 2 — SKILL.md:384-385 with 344-346. The merge-base reproduction, the guard that separates "pre-existing" from "introduced", is never required to be verified.**
- Line 384 exempts a deferred BUG from needing either `locally_verified` or `externally_reverified`. Nothing else requires condition 1 to meet point 5's standard of evidence or to be recorded.
- 6(a2) lets the round that first raises a BUG count as clean once it is deferred. Adding the KNOWN WRONG test and the tracker row then changes the artifact after that clean round.
- So the merge-base evidence that 6 promises to reviewers is never sent: no further round runs. The author's own claim is the only check. The NIT-fix paragraph (lines 350-355) makes the matching admission for NIT fixes; nothing does so for deferrals.
- **Fix:** At 384, require the deferral's conditions to be `locally_verified`, with the merge-base command and its output in the trail. At (a2), say that a deferral first made in the closing round is recorded as "deferral not externally re-verified".

## NIT

1. **SKILL.md:362** — "deferring only the external re-verification of those fixes" still uses "defer" for verification. Two lines later: "Postponing verification is legitimate." Round 2's NIT 4 fix missed this one. Fix: change it to "postponing".
2. **Tracker line 36 (B-TAGCLASS)** — "deferred because the fix is a design change" sits in the same row that says the BUG does not meet point 5. Fix: "left open because the fix is a design change".
3. **Tracker line 44 (R-SANDBOX)** — "postponed by the owner" is not a status in point 4's list (open, fixed, refuted, waived, deferred). SKILL.md itself now uses "postpone" only for verification and releases. If it was a waiver, the tracker's own preamble says the row would be deleted. If not, it is an open RISK and blocks under 6(b) like any other, which the gate-status section never says. Fix: "waived by the owner for the 2026-09-11 PR; still open here".
4. **test_looks_like_review.sh:72, 78-94** — the B-REFUSAL-TEXT cases name the row only in comments; the B-VERDICT-TEXT cases name it in the label. A failing check prints only its label, so whoever breaks one of these sees no row id. Fix: add "(B-REFUSAL-TEXT)" to those labels, matching lines 98-103.
5. **SKILL.md:340** — "since the tracker is not in what they see" is true here only because this repo keeps the tracker under `docs/reviews/`, which point 2 excludes from the diff. Condition 2 allows a tracker anywhere in the repo. Fix: "since point 2's exclusion usually hides it".
6. **Size** — `check_skill_budgets.sh` warns: SKILL.md is 538 lines (500 on origin/main, soft budget 500), and the description is 1011 of 1024 characters. The next edit to the description may hit the hard limit. Round 2 raised this as NIT 6 and it was not addressed.

## The #110 precedent

The precedent fits the new definition. The qualifier list in check 3 exists to accept real qualified verdicts, so the false accepts are a side effect. They happen inside `looks_like_review()`. The code has another effect, so the "only effect" exclusion does not apply.

It would also pass the cause-based test proposed in RISK 1: the qualified-verdict-plus-"couldn't access" inputs pass because check 1 does not know the phrase, which is B-REFUSAL-TEXT's stated defect; the passive and noun-modifier forms pass because check 3 does not constrain what follows the severity word, which is B-VERDICT-TEXT's stated defect. So tightening the definition would not disqualify the precedent.

Checked empirically. I extracted the function at 1bb12b7 (before the qualifier fix), at the merge-base 5e310f6 and at HEAD, and ran the pinned cases: the "pre-existing" forms ("No risk can be assessed…", "No bug reports can be generated.", "No BUG or RISK, because I couldn't access…") are accepted at 1bb12b7; the qualified and passive forms are rejected at 1bb12b7 and accepted at 5e310f6 and HEAD. Every "pre-existing" or "newly accepted" claim in the tracker and the test comments holds.

## Checked and clean

- `make check` exits 0, and every `test_looks_like_review.sh` case passes. The "FAIL" strings in the output are only test labels.
- The test runs in CI on both push and pull_request (`.github/workflows/clean.yml:18-20` and `57`), so condition 3's "CI runs" holds.
- Frontmatter, point 4, point 5, 6(a2), 6(b), 6(c), the two-status paragraph, point 7's bullets, the "four" count and the escalation paragraph agree with each other on DEFERRED. I found no remaining "no exceptions", and no "fixed or refuted" list that leaves deferral out, anywhere in SKILL.md, `references/*.md` or other skill docs.
- `closeout.md:224-225` matches point 5's requirement that the trail record deferrals and widenings.
- B-REFUSAL-TEXT and B-VERDICT-TEXT meet all three conditions: they reproduce at the merge-base, have a row with dated owner sign-offs, and have KNOWN WRONG tests in CI. Their widenings have their own sign-off, their own pinned cases, and a line in both the row and the 09-20 trail (lines 12-22, 89, 120, 153-154).
- B-TAGCLASS is correctly marked as not meeting point 5.
- The tracker preamble ("rows are not closed") agrees with "stays open in the tracker, closed for this gate".

## Prompt injection

None found in the diff, the tracker or the round 1 and 2 raw files.
