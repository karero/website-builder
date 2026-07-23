# DIFF review — skills/independent-review/SKILL.md (self-review, dogfooded)

Multi-round blocking gate applied to the review skill's own process description — Steps 4, 5, and
7 (Consolidate, Enforce the verdict, Convergence check). This is the review-gate mechanism used
on itself; its own rules directly shaped how findings against `phased-plan-runner` (reviewed in
parallel this session, see the sibling trail doc) were triaged and disposed of.

## Artifact
`skills/independent-review/SKILL.md` — Steps 4, 5, 7 (status model, verdict enforcement,
convergence-check/rabbit-hole-detector logic), plus the frontmatter description.

## Reviewers run (round-by-round)
| Round | Tier | Tool | Model | Sandbox |
|---|------|------|-------|---------|
| 1–6 | 1 (cross-model) | Codex CLI | gpt-5.6-sol (`CODEX_MODEL` override) | `codex exec -s read-only` |
| 1–6 | 2 (cross-model) | ollama cloud | glm-5.2:cloud | Ollama's own servers |
| 7 | 3 (fresh-eyes, same-family) | Fable | `model: "fable"` via Agent tool | Claude Code sub-agent, no shared context |

Rounds 1–6: tier 3 not run separately — same reasoning as the sibling `phased-plan-runner` review.
Gate was cross-model, independence rule satisfied by tier 1 + 2.

Round 7: run at Daniel's explicit request after the author had already decided to defer further
rounds per Step 6(c). Same-family, not cross-model — supplements rounds 1–6's already-satisfied
gate. Fed the raw diff + the strict review prompt only, no mention of prior findings, explicit
instruction not to read any other file (this skill's own trail docs sit in the same repo and would
have spoiled the fresh-eyes premise).

## Round-by-round summary

| Round | Findings | Headline |
|---|---|---|
| 1–2 | several | Status model generalized from `open/fixed/waived` to include `refuted` (a finding shown never to have been real, no owner sign-off needed, distinct from `waived` which needs one); artifact-annotation triage rule tightened (an existing comment doesn't auto-close a re-raised finding unless its reasoning actually covers what was raised). |
| 3 | 6 confirmed | Step 5's REFUTED definition required "empirical" evidence even for purely logical/structural claims (no runtime to check against) — self-contradicting the very findings this review process was producing about itself. Convergence-check (`Step 7`) had a literal logical contradiction: "Signal (b) fails ONLY when the SAME method... re-covers the SAME ground" let a *merely different* method pass even though the preceding sentence required "not merely different." |
| 4 | 7 confirmed | STOP condition triggered on a single stray repeat even when a round had other genuinely new findings; oscillation (c) lacked a defined "most" threshold; "per point 4's coverage test" cross-reference was ambiguous outside its original (artifact-annotation) context; Step 4/5 waiver wording wasn't textually aligned. |
| 5 | 7 confirmed | Signal (b) re-anchored to a *finding* rather than a *pass* (unit mismatch with how the STOP threshold actually counts); oscillation split into a strict even-one-instance bar separate from (b)'s softer bulk-repeat bar; a re-raised *waived* finding was (correctly) carved out of oscillation, since waiving concedes an issue may be real. |
| 6 | 1 BUG (both reviewers, converging), 2 NIT | The round-5 waived-finding carve-out said a re-raised waiver "counts toward (b)'s bulk-repeat threshold" — but (b)'s own definition requires "ground already ruled clean," and a waiver explicitly is NOT ruled clean. Direct contradiction between the routing instruction and the definition of the bucket it routed into. Also: the "verified, not just claimed" requirement (round 5's other fix) only covered one of signal (c)'s two failure branches. Both fixed. |
| 7 | 2 BUG, 4 RISK, 4 NIT (Fable) | **Every finding was either a genuine fix or resolved as a side effect of one — no refutations needed, unlike the sibling review.** Headline: the round-5/6 "stays OPEN" untestable-claim provision (added to Step 5) was never reconciled with Step 7's convergence taxonomy — a bare re-raise of a still-open finding fit none of signals (a)/(b)/(c) or the existing waived-bucket, a genuine classification gap. Also: Step 6(c)'s "same bar as the blocking rule" restatement had gone stale the moment Step 5 added REFUTED as a closing status — it still only said "fixed or owner-waived." |

## Round 3–6 findings and dispositions (detailed)

### Round 3
1. **BUG** — REFUTED required "empirical" evidence unconditionally, making a purely
   logical/stylistic finding un-refutable in principle. **Fixed**: "conclusively shown" now
   means evidence appropriate to the claim — empirical for runtime/checkable behavior, direct
   textual/logical demonstration otherwise.
2. **BUG/RISK (both, converging on the same clause)** — Signal (b)'s "fails ONLY when the SAME
   method... re-covers the SAME ground" directly contradicted the preceding "not merely
   different" requirement, and "depth of scrutiny" was undefined/unenforceable. **Fixed**:
   rewritten so (b) fails when ground already ruled clean is re-covered *without the trail naming
   a concrete new thing* (a specific check/input class/execution path/invariant/evidence source),
   regardless of whether the method is nominally the same or different.
3. **RISK** — STOP triggered on a single stray repeat amid an otherwise-healthy round. **Fixed**:
   STOP now requires (b)/(c) to characterize *most or all* of the round's findings.
4. **NIT** — "named reason" wording inconsistent with Step 4's "reason + owner." **Fixed**
   (further tightened in round 6).

### Round 4
1. **RISK** — "or fail to [reproduce]" as a refutation standard could be satisfied by testing only
   the reviewer's one cited example, contradicting the very next paragraph's warning against
   exactly that half-check. **Fixed**: tied to the same full-reasoning standard as failure shape
   (a).
2. **RISK** — oscillation (signal c) and bulk-repeat (signal b) shared one undifferentiated
   "most or all" threshold, under-weighting a genuine oscillation if enough unrelated findings
   were also new that round. **Fixed** (round 5): oscillation split out with its own even-one bar.
3. **RISK** — signal (b)'s "fails when a pass..." language operated on passes, but the STOP
   condition counts findings — a unit mismatch. **Fixed** (round 5): re-anchored to "a finding."
4. **RISK** — "only... surfaces something the earlier pass missed" could read as delegitimizing a
   genuinely-new method that comes back clean. **Fixed**: added an explicit clarifying
   parenthetical (a clean result from real new scrutiny is convergence evidence, not failure).
5. **NIT (both, converging)** — Step 4's waiver wording ("reason + owner") vs. Step 5's ("reason
   and the human owner's sign-off") not textually aligned. **Fixed**: Step 4 updated to match.

### Round 5
1. **RISK** — a re-raised *waived* finding was treated as oscillation (strict one-strike STOP),
   but waiving explicitly concedes an issue may be real — an independent reviewer correctly
   re-noticing it isn't instability. **Fixed, but the fix itself had a bug** — see round 6 #2.
2. **RISK** — "EVEN ONE finding failing (c) means STOP" fired on a bare re-raise *claim*, not a
   confirmed regression — one reviewer missing the trail could halt an otherwise-healthy round.
   **Fixed** (partially — round 6 found the fix only covered one of two branches; completed in
   round 6, then restructured further in round 7 — see below).
3. **RISK (ollama)** — the (b)/(c) boundary (same finding re-raised vs. new finding on old
   ground) implicitly depends on matching by Step 4's stable id, never stated explicitly.
   **Fixed**: signal (c) now explicitly says "matched by the stable id from point 4."
4. **RISK (ollama)** — an untestable open BUG's escalation paths (defer/re-scope/reject) never
   connected "defer" to "wait for the missing prerequisite" specifically. **Fixed**.
5. **RISK (ollama)** — "per point 4's coverage test" cross-referenced a scope (pre-existing
   artifact annotations) that doesn't directly govern round-to-round re-raises. **Fixed**:
   reworded to make the adaptation explicit (same test, different context).
6. **NIT (both, independently)** — signal (b) had grown into a dense, hard-to-parse block.
   **Fixed**: restructured the whole convergence-check section into labeled sub-paragraphs.
7. **NIT (ollama)** — Step 4's nested parenthetical in the refuted-status definition was hard to
   parse. **Fixed**: pulled into its own sentence.

### Round 6
1. **BUG (both reviewers, converging on the same core contradiction)** — the round-5
   waived-finding carve-out said a re-raised waiver "counts toward (b)'s bulk-repeat threshold,"
   but signal (b)'s own definition requires "ground already ruled clean" — which a waiver
   explicitly is NOT (waiving concedes the issue may be real). The routing instruction
   contradicted the definition of the bucket it routed into. **Fixed**: a re-raised waived
   finding formed its own explicit third bucket (neither a (b)-failure nor a (c)-failure by
   either signal's own test), counted *separately* in the STOP threshold — later restructured
   further in round 7 to also fix a naming collision this created (see below).
2. **RISK (Codex)** — the "verified, not just claimed" requirement (round 5 fix #2) was written
   into only the *first* of signal (c)'s two failure branches (a fix demonstrably re-breaking
   something) — the *second* branch (a bare re-raise of a fixed/refuted finding) had no such
   requirement, so round 5's fix was only partially effective. **Fixed**: the verification
   requirement now applies to signal (c) as a whole, stated once upfront, covering both branches.
3. **NIT (Codex)** — "that's the only way an untestable BUG closes" conflated the *act* of
   deferring with actual closure (deferring just keeps waiting; the BUG only closes once
   verification later supports a refutation or a verified fix). **Fixed**: reworded.

## Round 7 findings and dispositions (Fable, 2026-07-23)

Fable was given the full diff (whole-file context, not narrow hunks) plus the strict review
prompt, no mention of prior rounds' findings, explicit instructions not to read any other file.
Both BUGs held up on verification (tracing hypothetical findings through the actual taxonomy by
hand); every RISK and half the NITs were real gaps; the other two NITs resolved as side effects of
fixing the BUGs, rather than needing separate treatment.

1. **BUG** — Step 5's round-4/5-added "stays OPEN" rule for untestable claims (blocked on a
   missing prerequisite) created a new possible finding-state that Step 7's convergence taxonomy
   was never updated to classify: a bare re-raise of a still-OPEN finding, with no new evidence,
   fits NONE of the existing buckets — not a (b)-PASS (nothing was fixed, no new method named),
   not a (b)-FAIL (open ground was never "ruled clean," (b)'s own test), not (c) (never
   dispositioned as fixed or refuted, so nothing for a re-raise to contradict), and not the
   existing waived-bucket (it wasn't waived). Traced by hand against a 2-finding hypothetical
   round: whether such a finding counts toward the STOP threshold's numerator, denominator, or
   neither was genuinely undefined. **Fixed**: extended the re-raise handling in signal (c) to a
   third named case — a still-open re-raise pools into the same MOST-threshold bucket as an
   unsupported fixed/refuted re-raise and a re-raised waiver, for the same underlying reason
   (never "ruled clean," nothing dispositioned for it to contradict).
2. **BUG** — Step 6(c) ("you may proceed once all known BUGs are *fixed* AND every RISK/NIT is
   fixed or explicitly owner-waived — same bar as the blocking rule") and the frontmatter
   description ("BLOCK until every BUG is fixed and every RISK/NIT is fixed or explicitly waived")
   both went stale the moment Step 5 added REFUTED as a legitimate closing status (round 3) —
   neither restatement mentions it, so read literally, a refuted BUG can never satisfy 6(c)'s
   proceed condition, and a refuted RISK/NIT fails the description's own bar, even though Step 5
   itself has allowed refutation without owner sign-off since round 3. **Fixed**: both updated to
   "fixed or refuted" / "fixed, refuted, or explicitly owner-waived."
3. **RISK** — Step 4's new annotation-citation path ("if the artifact itself already explains a
   deliberate choice a finding re-raises... triage can cite that existing reasoning") described a
   *process* (cite the reasoning) without specifying the *resulting status* — the status enum is
   exhaustive (open/fixed/refuted/waived), and "a deliberate choice, we accepted the tradeoff" is
   naturally waiver-shaped (conceding the issue may be real), not refutation-shaped, yet the path
   as written could read as an automatic close needing no owner sign-off, undercutting Step 5's
   own waiver requirement. **Fixed**: added an explicit rule — REFUTED only if the annotation's
   reasoning actually disproves the finding, WAIVED only if it traces to a real prior owner
   decision (citing an old waiver doesn't manufacture a new one's sign-off out of nothing); an
   annotation that merely explains an accepted tradeoff is waiver-shaped, treated as such.
4. **RISK** — signal (c)'s "EVEN ONE finding failing means STOP" applied identically to a
   demonstrated regression (a fix re-breaking something) and to a bare, no-new-evidence re-raise
   of something already fixed/refuted — but the fresh-eyes/Fable seat is *designed* to have no
   memory of prior rounds, so it re-raising something already handled is expected, routine
   reviewer overhead, not artifact instability, and holding it to the same one-strike bar as a
   genuine regression would effectively punish running a truly independent reviewer every round.
   **Fixed**: signal (c) restructured — only a demonstrated regression keeps the strict even-one
   trigger; an unsupported re-raise of something fixed/refuted now pools into the same
   MOST-threshold bucket as (b)-failures and the other re-raise cases (this also resolved a
   separate NIT about (b) and (c) appearing to double-cover the same finding with no counting
   precedence — see NIT list below).
5. **RISK** — the STOP-patching clause's plateau trigger ("the count plateaus for two rounds")
   read as unconditional, in apparent tension with signal (a)'s own point that "a rising count
   from genuinely new scrutiny is healthy" — as written, two rounds each finding several
   genuinely-new, real, distinct findings (a flat but healthy count) would trigger STOP the same
   as two rounds of pure repetition. **Fixed**: the plateau trigger now requires the plateauing
   findings to NOT be predominantly (b)-passing, with an explicit note that a plateau of
   genuinely distinct new findings is a slower convergence signal, not a stall, worth naming
   rather than silently forcing STOP.
6. **RISK** — the parenthetical claiming Step 6(b)'s hard 3-round cap "bounds total iteration
   regardless of how these signals read" overclaimed: 6(b) fires only on "BUG/RISK still open,"
   so a round with only NIT-level churn recurring for 3+ rounds has no hard cap at all, contrary
   to what "regardless" implies. **Fixed**: reworded to state the cap bounds iteration
   specifically "for any round that still has a BUG or RISK open," with an explicit note that
   pure NIT churn relies on Step 7's own signals alone.
7. **NIT** — signal (b)'s PASS criteria read as two different tests (a "genuinely new method" vs.
   "names a concrete new thing"), when the clarifying sentence right after it ("a more careful
   pass with the SAME nominal method still counts, once that concrete delta is named") makes
   method-novelty irrelevant — the operative test is only ever "names a concrete new thing."
   **Fixed**: collapsed to state the single test once, regardless of whether the method is
   nominally the same or different.
8. **NIT** — pre-existing (not part of this session's diff) terminology drift: the clerk
   procedure's "rejected-with-reason findings" predates the formal REFUTED status Step 4/5
   introduced and doesn't use that term; Step 4's own new "waved off" phrasing is a near-homophone
   of the load-bearing term "waived" in the same document. **Fixed**: aligned to "refuted
   (rejected-with-reason)"; "waved off" → "dismissed."
9. **NIT — resolved as a side effect, no separate edit needed.** (b)-FAIL and the (then-)second
   branch of (c) could both plausibly apply to the same finding (an unsupported re-raise of
   something fixed/refuted), with no stated precedence between them. Once RISK #4's restructure
   moved that case out of (c) into the pooled MOST-threshold bucket, and (b)'s own text was
   clarified to be specifically about ground a PRIOR PASS explicitly checked and reported clean
   (never about ground where something WAS raised and dispositioned — a different population by
   definition), the two no longer compete for the same finding at all.
10. **NIT — resolved as a side effect, no separate edit needed.** "Third bucket... counted
    separately in the STOP threshold" used "third" against a document that separately labels
    signals (a)/(b)/(c), and "separately" was ambiguous (a separate threshold, or pooled into the
    same one?) — it was pooled, not separate. The RISK #4 + BUG #1 restructure replaced the
    single "third bucket" framing with three explicitly enumerated, symmetrically-worded pooling
    cases (fixed/refuted re-raise, waived re-raise, open re-raise), removing both the numeral
    collision and the "separately" ambiguity as part of the same rewrite.

## Checked clean (cumulative highlights)
- Status model (open/fixed/refuted/waived) internally consistent across Steps 4, 5, 7 in every
  round from round 3 onward — including round 7's REFUTED-propagation fix, verified by grepping
  every remaining restatement of the blocking bar in the file for staleness.
- Empirical-verification failure shapes (a) and (b) in Step 5, and their symmetric application to
  refuting (not just fixing) a finding — confirmed sound every round it was checked, including a
  round-7 direct re-check.
- Untestable-claim handling (stays OPEN; RISK/NIT may still be waived; BUG may not) — confirmed
  internally consistent in rounds 5, 6, and 7 (round 7 specifically closed the one place this
  interacted badly with a different section — see BUG #1 above).
- "Most" (bulk-repeat threshold) unambiguously defined as "more than half" (round 6, confirmed by
  both reviewers with boundary-case arithmetic: 1-of-1, 2-of-2, 2-of-3, etc.) — still accurate
  after round 7's restructure, which changed what pools into the threshold, not the threshold math.
- The early-exit heuristic (Step 7's STOP conditions) vs. the hard 3-round cap (Step 6(b)) —
  confirmed as complementary, not conflicting, every round it was checked (round 7 tightened the
  overclaim about the cap's own scope — see RISK #6 above — without changing this relationship).
- Escalation cannot waive a still-open BUG — confirmed consistent in rounds 5, 6, and 7.
- Round 7 (Fable), independently re-derived from scratch (not shown prior rounds' findings):
  every cross-reference to "point N" or "signal (x)" in the diff resolves to text that actually
  says what the referencing text claims; no fifth status was introduced anywhere in the new text;
  tier-number and Procedure-step-number cross-references throughout the Onboarding section all
  match the Reviewer stack's own numbering.

## Convergence assessment (applying this skill's own Step 7 logic to itself)
- **Signal (b)**: every round's headline finding targeted language the *previous* round had just
  written (round 4 found problems in round 3's new signal-(b) rewrite; round 5 found problems in
  round 4's own new STOP-condition wording; round 6 found a contradiction in round 5's own new
  waived-finding carve-out; round 7 found a gap created by round 5/6's OWN "stays OPEN" addition
  to a *different* section (Step 5) that nobody had checked against Step 7 since). Textbook
  healthy pattern per this skill's own rule, six rounds running.
- **Signal (c)**: no oscillation — no fix was reverted or reintroduced a previously-fixed problem,
  including round 7's own restructure (verified by hand-tracing the same hypothetical cases the
  round-5/6 fixes were built to handle against the round-7 rewrite, confirming they still resolve
  the same way).
- Round 7's 10 findings (2 BUG, 4 RISK, 4 NIT) is a higher count than round 6's 3, driven entirely
  by genuinely new scrutiny (a from-scratch fresh-eyes pass reading the WHOLE convergence-check
  section at once, vs. six rounds of increasingly narrow, context-aware Codex/ollama focus) rather
  than repetition — signal (a) explicitly does not read a rising count alone as a bad sign, and
  every round-7 finding independently checks out as targeting either genuinely new ground or a
  real cross-section interaction no prior round's narrower scope had reached.

## Round 8 status: not run
Round 7 (Fable) is documented and its fixes applied. Per Step 6(c), the same reasoning that
justified deferring after round 6 applies again: both round-7 BUGs are fixed, all four RISKs are
fixed, all four NITs are fixed or resolved as side effects — nothing here needs an owner waiver,
unlike the sibling `phased-plan-runner` review. Round 7's own fixes (the three-way re-raise
pooling, the REFUTED-propagation fix, the annotation-status rule, the plateau reconciliation, the
6(b)-scope correction) have not been externally re-verified by Codex/ollama or a second fresh-eyes
pass — only by direct re-reading and hand-traced hypothetical cases. Recorded here per Step 6(c)'s
explicit instruction.
