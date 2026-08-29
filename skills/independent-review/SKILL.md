---
name: independent-review
description: >
  Domain-agnostic cross-model review gate: run a planning markdown (PLAN gate)
  or a branch/PR diff (DIFF gate) through INDEPENDENT external reviewers via
  scripts/independent_review.sh — the standard pair (Codex + your signed-in
  ollama-cloud model) runs automatically; Antigravity/Gemini only on explicit
  opt-in, its credits are scarce. Consolidates a ranked BUG/RISK/NIT list and
  BLOCKS until every BUG is fixed or refuted and every RISK/NIT is fixed,
  refuted, or owner-waived; first use runs a guided onboarding wizard. Use
  BEFORE building from any non-trivial plan, BEFORE merging any non-trivial
  PR, and whenever asked for a "codex review", "gemini review", "antigravity
  review", "agy review", "adversarial review", "cross-model review",
  "independent review", "get a second model to review", "review before I
  merge", "which review tool should I use", or to "set up AI code review" /
  "set up codex, ollama, or antigravity for review".
---

# Independent review — the cross-model gate

A blocking review gate for two artifact types. The value is *independence*: a
model that did not write the artifact, ideally from a different model family,
cannot share the author's blind spots. Dogfooded on its own design plan — two
rounds caught 5 BUGs the author had shipped.

## The two gates

- **PLAN gate** — reviews a planning markdown *before* any code is written.
  Catches strategy errors, stale assumptions, internal contradictions.
- **DIFF gate** — reviews a branch/PR diff *before* merge. Catches test blind
  spots: a guard passing while the thing it protects regressed.

### "It's only a docs row" is the wrong test — ask what the reader will DO

(Codified 2026-08-03 after a single session sent five MRs through this gate and
**every one came back with something real**, including two where the defect was
in the artifact's *proposed fix* rather than its description.)

The instinct that a BUGLOG row, a ledger row, or a runbook is "too small to
review" is about the artifact's SIZE. The thing that matters is whether someone
will later ACT on it without re-deriving it. A deferred-bug row's "suggested
fix" field is a **delegated instruction**: months later, an implementer reads it,
trusts it, and builds it. It is simultaneously the field the author reasons
about least (the bug is already understood; the fix is an afterthought) and the
one the reader trusts most. That asymmetry is where the defects were:

- A row said "add the missing build steps to the CI job." The job was *manual*,
  so the fix would not have closed the gap. Round 1 caught it.
- The rewrite said "…and add a cross-project trigger." A triggered pipeline ran
  the *automatic* job, still never the manual one. **Round 2 caught the same
  class of error one level down** — which is the case for a verification round
  after any BUG, not just a code one.

Practical rule: **gate on consequence, not on diff size or file extension.** A
row whose fix someone will implement, a runbook headed for a production session,
a plan a stage agent will execute — all carry more downstream weight than a
small code change that CI will catch anyway. Where a lighter gate is genuinely
right, name the gate it got and why (Procedure step 9's trail does this), rather
than skipping silently.

**Corollary — send the code that CONSUMES the config, not just the config.**
A compose/env/infra diff reviewed in isolation reliably draws "silent no-op?"
and "fails indistinguishably?" findings the consuming source already answers —
one round spent a full standard pair producing exactly those two speculations,
both refuted from twenty lines of the code that reads the variable. Include
the reading code in the artifact, or expect to spend the round refuting.

### PLAN gate preconditions — two things to check before spending a round

**The HOST agent runs these checks itself, before the external pair goes out.**
Check 1 is structurally invisible to the reviewers (the fresh-eyes seat has no
repo access; the external pair is never asked it). Full reasoning, scope, and
what each check does NOT establish: `references/plan-preconditions.md` —
consult it whenever a check's verdict is contested or unclear.

1. **Can the plan report its own progress?** The plan (or a sibling document it
   names) has a place where each step's state is recorded, and every state
   claiming progress carries a reference another person can open — a commit
   SHA, a repository-qualified PR, a test-run link retained per the project's
   own policy, never an ephemeral CI console URL. ("Not started" is the one
   state needing no reference.) If not: record it as a **RISK, not a NIT**, in
   the host's own findings and the trail (Procedure step 9), and keep it OUT
   of the artifact sent to the external pair — including a verification
   round's prior-findings list. Their round still runs on the plan's content
   exactly as usual.
2. **Are the plan's own decisions settled?** A plan whose steps are still
   changing needs its open decisions closed first, not another round —
   re-reviewing a moving target is how a plan reaches round seven. This defers
   the verification round (Procedure step 6 still applies in full); it never
   replaces it.

## Reviewer stack (default STANDARD PAIR runs automatically; Antigravity is opt-in only)

1. **Codex CLI** (`codex exec -s read-only`) — genuine read-only sandbox; model +
   effort from `~/.codex/config.toml` (daily-driver default). Override per-run with
   `CODEX_MODEL=<model-tag>` for a harder case or a long plan — config.toml's
   reasoning-effort setting still applies on top, since the override only touches
   the model key.
2. **ollama cloud** (`OLLAMA_MODEL`) — the standard second reviewer, runs
   automatically alongside Codex with no env var needed: the script
   auto-detects your signed-in `:cloud` model from `ollama list`. The skill
   prescribes no specific model — set `OLLAMA_MODEL` to pick a different
   cloud or local tag if a specific case warrants it.
3. **Fresh-eyes host-agent pass** — a read-only sub-agent (or the vendored
   `double-knuth` skill) with NO shared context: give it only the artifact and
   the strict prompt below. Never reuse the authoring conversation. If the host
   has no sub-agent primitive (some Codex installs), use a separate fresh
   session with only the artifact — or record the pass as *degraded* in the
   trail, not as no-shared-context. On a Claude Code host, an extra pass with
   a stronger host-family model (the Agent tool's model option) is a good
   candidate for this seat when the owner wants a second same-family opinion
   on top of the host's own — it's free (no external credits, no CLI), just
   not cross-model (see the Independence rule below). Offer it after
   presenting results, don't run it unasked.
4. **Antigravity — OPT-IN ONLY, never automatic.** Google Gemini via the
   Antigravity CLI (`agy --sandbox -p`; setting `AGY_MODEL` overrides the
   CLI's own default model — `references/onboarding.md` Step 5 has the full
   invocation), free Antigravity login. The
   owner's Antigravity free-tier credits are scarce and get spent only when
   explicitly worth it: pass `--with-antigravity` to the script, or the owner
   directly asks ("antigravity review", "agy review", "worth burning a
   credit on this one"). The default run (no flags) never touches it — this
   is a deliberate change from earlier drafts of this skill, which ran it
   unconditionally on every default pass and burned credits silently.
5. **ollama local** — sanity pass only; the script never lets it satisfy the
   gate alone.
6. **Any model, copy & paste** — the script emits the prompt; a human pastes it
   into whatever is available and feeds findings back.

**The standard pair (Codex + ollama-cloud) is the un-flagged default for both gates** —
DIFF included, not only PLAN; `--first-success` reduces either to a single reviewer.
**PLAN additionally treats fewer than 2 as worth flagging**: a plan is often high-stakes
enough that "whichever one answered first" isn't enough independence, so the script
notes it explicitly (see Procedure below) whenever a plan lands with fewer than 2
reviewers — DIFF gets no equivalent note. This is a default expectation, not a hard
floor: passing `--first-success` on a plan is a caller's conscious choice to accept one
reviewer instead (the script honors this, it does not override it — see the
credit-cost tradeoff this represents). If a
plan lands with only one reviewer's output for any reason — an explicit
`--first-success` or a tier failing — treat the round as degraded *only if
that wasn't the deliberate choice*, and say so either way.

**Independence rule:** *classify* every tier that actually ran — which tiers
those are is decided by the reviewer stack above (the standard pair by default;
Antigravity only on explicit opt-in; paste always manual; local ollama runs
whenever `OLLAMA_MODEL` names a local tag, but never *closes the gate* on its
own), and this rule governs how the ones that ran are scored, not how many to
launch. The tier matching the HOST agent's model family counts as the
fresh-eyes seat, never as cross-model independence. **The gate is satisfied only when at least one
successful reviewer is cross-model (a different family than the host)**; if
only same-family reviewers ran, the gate is degraded and needs an explicit
owner waiver — codex reviewing codex-authored work shares the blind spots this
gate exists to catch. Per host: **Claude Code** — fresh-eyes = the Claude pass
(optionally a stronger same-family pass, see the reviewer stack above —
doesn't count as cross-model either), cross-model = Codex + ollama-cloud
(classified by the family of the tag actually used — the standard default
pair) + Gemini/Antigravity (opt-in extra,
not needed to satisfy the gate since Codex or ollama-cloud already does).
**Codex** — fresh-eyes = Codex, cross-model = ollama-cloud + Gemini + Claude.
**Antigravity/Gemini** — fresh-eyes = Gemini, cross-model = Codex +
ollama-cloud + Claude. On any non-Claude host, an Anthropic seat may be
reachable via the Antigravity CLI — see `references/setup-guide.md` for the
current model tag, verification status, and free-tier caveat; it shares the
same scarce-quota, opt-in-only rule as every other `agy` use in this skill,
not a standing free lane.

## Onboarding — first use

When the skill is invoked and no reviewer that is **cross-model for the
current host** is installed and working (per the Independence rule above —
LOCAL ollama alone, or a same-family cloud tool, never counts), read
`references/onboarding.md` and run its wizard rather than dumping install
commands: sell the benefit, detect what already works (never re-onboard a
returning user), help them choose a tool, walk the human-only steps one at a
time, confirm each tool with a real test review quoted as evidence, then
teach the plain-language trigger phrases.

## Procedure

1. **Data check before anything leaves the machine.** External reviewers are
   third-party services: grep the artifact for secrets (keys, tokens, passwords,
   customer data) and get the owner's OK the first time a given repo's content
   is sent out **to each destination service, not just each named tool** —
   Codex, ollama-cloud, and Antigravity are separate services with separate
   consent, not one blanket "external reviewers are OK," and naming the tool
   isn't always naming the destination: Antigravity with `AGY_MODEL` set to
   a Claude tag routes content on to Anthropic too, a distinct destination
   from Antigravity's own Gemini path, needing its own consent — and the
   paste tier (tier 6) sends the same artifact to whatever service a human
   pastes it into, chosen ad hoc, which needs the same per-destination
   consent as any named provider, not a free pass for being manual. Record
   the OK the way the permission table (`references/closeout.md`) records
   an owner instruction (atom B: quoted verbatim). **Only a standing
   instruction durably written in the repo persists across sessions** — a
   later session can check for that and tell "owner consented for this
   provider" from "nobody has asked yet." This session's own in-conversation
   record is real consent for the current session, but per this file's own
   durability standard (an in-session hand-off doesn't count as durable
   anywhere else here either) it is invisible to a later one — that session
   re-asks rather than assuming consent it cannot see. Adding a new provider
   later needs its own consent, not an inherited one. If the content must stay local, run the script with
   `--local-only` (skips codex/agy/paste entirely; local ollama only — the
   script requires the EFFECTIVE ollama tag to be local: under `--local-only` the
   cloud auto-detect default is never applied, and an explicitly-set cloud tag is refused outright,
   rather than silently sending content out) plus the tier-3 host fresh-eyes
   pass — tier 6 (paste into any model) is just as
   external as the CLIs and is excluded. A local-only verdict is inherently
   DEGRADED; record that in the trail.
2. Run the external half (path relative to THIS skill's directory — after an
   install that is `<skills-root>/independent-review/scripts/…`):
   `scripts/independent_review.sh <artifact.md|diff-file|-> [--plan|--diff]`
   — `--plan`/`--diff` is optional: the script auto-detects from the input —
   a `.diff`/`.patch` filename resolves to diff, anything else to plan, and
   **stdin (`-`) has no filename to guess from at all, so it defaults to
   diff** — that resolved value is the `<gate>` step 9(a)'s trail filename
   uses. Pass the flag explicitly whenever the filename wouldn't guess
   right, and always when piping a plan through stdin (a piped plan
   otherwise silently loses the PLAN gate's <2-reviewers flag and gets
   mis-named as a diff trail). Default runs the standard pair (Codex + ollama-cloud) and prints one
   section per reviewer; `--first-success` is the quick mode (for a `--plan`
   this deliberately drops from the default 2 reviewers to 1 — a conscious
   choice for lower-stakes plans, honored not overridden — see the reviewer
   stack above). Add `--with-antigravity` only when it's genuinely worth
   spending one of the owner's scarce Antigravity credits — never by default.
   Exit 4 = no reviewer ran = gate FAIL (never treat as clean).

   **Build that artifact from the CHANGE, not from the whole diff — exclude `docs/reviews/`.** A
   DIFF gate on a branch that already carries a trail file will otherwise send the trail to the
   reviewers, and they will review it: its arithmetic, its finding counts, whether it describes the
   round currently reading it. Those findings are real — an arithmetic error in a trail IS an error
   — but they are about the review RECORD, not the change under review, and they arrive in rounds
   that would not otherwise have happened. Generate the artifact with the trail excluded:

   ```
   git diff <base>...HEAD -- . ':(exclude)docs/reviews/'
   ```

   Audit the trail's own numbers yourself instead. Two MRs on the same internal backend repo
   (8 and 7 rounds) each paid a late round that found nothing but the trail auditing itself —
   excluding the file PREVENTS that loop; the "scope it by RULE, not round number" guidance
   only BOUNDS it. **The trail must still be in the MR diff** — a repo CI gate may require it
   and clerk item 3 (`references/closeout.md`) commits it — this is only about what reaches the reviewers.
3. Run tier 3 (fresh-eyes) with the same strict prompt.
4. **Consolidate**: dedup findings across reviewers; keep per finding — a stable
   id, severity (BUG/RISK/NIT), source reviewer(s), location, and status: open, fixed, refuted, or
   waived. A waiver needs a reason and the human owner's sign-off. Refuted applies the same way to
   a BUG, RISK, or NIT alike — it needs the disproving reasoning instead of an owner sign-off,
   since a refuted finding was never a real issue.

   **A pre-existing artifact annotation never auto-closes a finding that re-raises it — its own
   reasoning must actually cover what THIS reviewer raised, confirm that first.** Only once
   confirmed: if the artifact itself already explains a deliberate choice a finding re-raises (a
   code comment, a plan annotation — e.g. from a prior planning-stage review whose reasoning was
   carried forward, see `phased-plan-runner`'s equivalent convention for artifacts produced by
   that skill), triage can cite that existing reasoning instead of a from-scratch re-derivation —
   but citing it does not by itself pick a status: the finding still resolves to REFUTED only if
   the annotation's reasoning actually disproves it, or to WAIVED only if the annotation traces to
   a real prior owner decision (citing an old waiver does not manufacture a NEW one's required
   sign-off out of nothing — get a fresh one if the annotation doesn't already clearly carry it).
   An annotation that merely explains a tradeoff the team accepted, without disproving the finding,
   is waiver-shaped, not refutation-shaped — treat it as such, not as an automatic close.
   Whenever the annotation's reasoning does NOT cover what the new finding raises, that finding is
   new signal — not repetition — regardless of whether the reviewer saw the annotation; it gets
   triaged like any other finding, never dismissed because *something* was already written nearby.
5. **Enforce the verdict** (this is the skill's job — never the script's exit
   code): every BUG confirmed real by verification must be fixed, no exceptions — one conclusively
   shown to be a non-issue is REFUTED, not waived, and needs no owner sign-off; RISK/NIT
   may be waived only with a reason and the human owner's sign-off, OR likewise REFUTED (not waived)
   if conclusively shown to be a non-issue — no blanket waivers either way. "Conclusively shown"
   means evidence appropriate to what's actually being claimed: empirical verification (run it,
   reproduce it, or rule it out — under the SAME standard as failure shape (a) below, testing the
   claim's full stated reasoning, not just one cited example) for a claim about runtime/checkable
   behavior; direct textual or
   logical demonstration — quoting the actual contradiction, or its absence — for a claim about
   structure, logic, or wording, where there is no runtime to check against. Don't demand an
   empirical test a claim was never about in the first place.

   **Verify checkable claims — empirically where the claim is about runtime/checkable behavior, by
   direct textual/logical demonstration where it's about structure, logic, or wording — before
   calling them fixed OR refuted; a reviewer's named example is illustrative, not exhaustive.** Two
   recurring failure shapes:
   (a) a fix that resolves only the ONE example a reviewer happened to cite (a specific
   string, a specific input) can still leave the reviewer's actual, broader claim true — test
   against their full stated reasoning, not just the named case, before marking it fixed
   (caught in practice: a regex fix was accepted after disproving only one cited false-positive
   string, but the reviewer's broader point still reproduced on a harder test). (b) a finding that an
   API/data surface is reachable, or behaves a certain way, is NOT settled by confirming a
   type/field/shape matches — trace the real access path (auth mechanism, routing,
   permissions) it actually goes through; a correctly-shaped type sitting behind different
   auth than assumed is still wrong, and "the shape looks right" is exactly the plausible
   half-check that misses it. Both apply symmetrically to REFUTING a finding, not just
   fixing one: don't dismiss a reviewer's claim as wrong just because its own cited example
   fails to reproduce — check whether the underlying point still holds under a harder case
   before writing it off. **A claim that's checkable in principle but can't actually be tested
   right now** (missing environment, credentials, or permissions) **stays OPEN**, with the
   missing prerequisite recorded — don't force it into fixed or refuted without the check that
   would justify either. (A RISK/NIT in this state may still be WAIVED with a reason and the
   owner's sign-off, same as any other open RISK/NIT — waiving needs no check, just the owner's
   call; only fixed/refuted are blocked pending the missing prerequisite.)
6. **Iterate — fix, then re-review.** Send the updated artifact back through
   the reviewers as a *verification round*: give them the prior round's BUG
   list, ask them to confirm each fix landed AND that the fixes introduced
   nothing new — and tell them the author expects clean **and that they must
   not oblige out of politeness** (expectation of cleanliness is exactly the
   bias that turns round 2 into a rubber stamp). Repeat until essentially
   clean. Stop conditions: (a) clean — done; **(a2) a round returns ZERO BUG and ZERO RISK — that
   IS "clean", and it is the signal to stop, not an invitation to spend one more round chasing the
   NITs it did return.** NIT-only rounds are where a gate quietly doubles in cost: each one returns
   two or three more, because prose can always be tightened and a reviewer asked for findings will
   find some. Fix or refute that round's NITs and close, without sending them back out. **A NIT you FIX
   changes the artifact, so the thing you close on is not the thing that came back clean** —
   record those fixes as `locally_verified` (point 6's own two statuses) and note in the trail
   that the closing edits were not externally re-verified, the same admission (c) makes for the
   same reason. Refusing this costs another full round and defeats (a2); leaving it unsaid
   claims a coverage the gate did not have. A NIT that is refused or waived edits nothing and
   needs neither. Re-read the
   BUG/RISK-per-round series, not the raw finding count — a series like 5 → 2 → 2 → 1 → 0 has
   already converged at the 0, whatever the NIT column says; (b) 3 rounds with BUG/RISK still
   open — hard gate-FAIL, surface and block; (c) **budget/credits exhausted**
   — you may stop ITERATING once all known BUGs are *fixed or refuted* AND every RISK/NIT is
   fixed, refuted, or explicitly owner-waived (same bar as point 5's blocking rule), deferring
   only the external re-verification of those fixes; record "last round not
   re-verified" in the trail and run a later round when resources allow.
   Deferring verification is legitimate; deferring a fix or a waiver never is.
   **This governs whether to run another round, and nothing else** — in particular it has no
   bearing on the consolidated marker, whose own rule lives in clerk item 2.

   **What "3 rounds" counts, since this is ambiguous the moment you need it.** The cap is
   **per stable finding id** (point 4's id), not per calendar round: a finding first raised in
   round 3 gets its own remediation-and-verification round before the cap can fire on it, and a
   finding open across rounds 1–3 fails the gate even if that round found other, newer things.
   **A redesign starts a NEW artifact and a new count.** When point 7 says stop patching and
   redesign, the review of the redesign is round 1 of that new artifact, not round 4 of the cycle
   it replaced — otherwise the cap would forbid reviewing the very rewrite it just demanded. Say
   in the trail which artifact a round belongs to, so the count is never reconstructed by memory.
   Re-gates forced by a moved diff (clerk item 2) do not count against the cap — they re-establish
   coverage rather than iterating on findings.

   **Two verification statuses, not one — "verified" alone is what makes 6(c) ambiguous.**
   `locally_verified` = the author reproduced, demonstrated, or ruled out the claim themselves,
   to point 5's standard. `externally_reverified` = an independent reviewer confirmed the fix in
   a later round. A checkable claim with neither status stays OPEN and blocking. Record both per
   finding; a trail that says only "fixed" does not say which.
7. **Convergence check — the rabbit-hole detector.** Iteration is only healthy
   while quality demonstrably rises each round. After every round, check three signals:

   **(a) Finding count.** Is it falling? Don't read this alone as the verdict — a rising count
   from genuinely new scrutiny is healthy: a later round that finally verifies claims no earlier
   round checked SHOULD find more, not fewer, real issues.

   **(b) Are findings landing on genuinely new ground?** A finding PASSES (b) when it targets
   code *added by the previous round's fixes*, or when checking it names a concrete new thing —
   a specific check, input class, execution path, invariant, or evidence source the earlier pass
   didn't use (e.g. round 3 starts empirically tracing auth/data-access paths where rounds 1-2
   only reasoned from reviewer prose) — regardless of whether the overall method is nominally the
   same or different; simply asserting a pass was "more careful," "deeper," or used a "different"
   method, without naming that concrete delta, does not pass (b) on its own. A genuinely new
   method that comes back CLEAN isn't a (b) failure either — there's no finding for it to
   classify; it's valid convergence evidence, not wasted effort. (b) FAILS when a finding
   re-covers ground a PRIOR PASS explicitly checked and reported CLEAN, without naming that
   concrete new thing — this is about ground nothing was ever raised against, a different
   population from the re-raises (c) below covers, where something WAS raised and dispositioned.

   **(c) No oscillation.** A fix that, once verified per point 5's own standard (reproduced or
   demonstrated, not just asserted), DEMONSTRABLY re-breaks something an earlier round FIXED means
   STOP regardless of how many other findings that round are genuinely new — a regression isn't
   offset by unrelated progress elsewhere. This is the only EVEN-ONE-finding trigger in this
   section; every other case below pools into the STOP threshold's MOST-of-the-round test instead.

   A reviewer re-raising a finding THIS REVIEW's own round-to-round trail already dispositioned
   (matched by the stable id from point 4, not just similar wording) is common and NOT
   automatically oscillation — an independent reviewer, especially the no-shared-context
   fresh-eyes seat, is expected to sometimes re-notice something a prior round already
   handled, precisely because that seat doesn't know the prior rounds happened. What matters,
   checked with the same verification standard as any other claim (not just asserted): does the
   re-raise bring new reasoning or evidence beyond what the prior disposition already considered —
   the same coverage test point 4 uses for pre-existing artifact annotations (does the prior
   disposition's reasoning actually cover what the new evidence raises?), adapted here to
   round-to-round dispositions *within this review*. If it does, it's a fresh finding, full stop,
   regardless of what the prior disposition was. If it doesn't (checked, and the original
   disposition still holds), where it counts depends on that prior disposition:
   - a re-raise of something FIXED or REFUTED with no new reasoning pools into the MOST threshold
     below, alongside (b)-failures — NOT this signal's strict even-one bucket above. It's reviewer
     overhead (re-checking a claim that turned out to still be nothing new), not the artifact
     regressing; the strict bucket is for a DEMONSTRATED regression specifically, and holding a
     routine no-shared-context re-raise to that same bar would effectively punish running a
     genuinely independent reviewer every round — the whole point of that seat.
   - a re-raise of something WAIVED with no new reasoning also pools into the MOST threshold, for
     a related but distinct reason: waiving concedes the issue may be real, so it was never "ruled
     clean" (that's (b)'s own test above) and re-noticing it isn't a regression of something
     dispositioned-as-resolved (that's this signal's own test above) — it's an independent
     reviewer correctly re-noticing something the owner already knew about and accepted.
   - a re-raise of something still OPEN under point 5's untestable-claim rule (blocked on a
     missing prerequisite) pools into the MOST threshold the same way: it was never "ruled clean"
     either, and there's no fixed/refuted disposition for it to contradict — restating a known,
     already-tracked open item is not new signal, but it isn't instability either.

   **STOP patching when:** the regression case above fires for even one finding; OR (b)-failures
   and any of the three no-new-evidence re-raise cases above, TOGETHER, characterize MOST (more
   than half) or all of the round's findings — not just one stray finding amid otherwise-new ones;
   OR the count plateaus for two consecutive rounds AND those plateauing findings are not
   predominantly (b)-passing (a plateau of genuinely distinct, newly-surfaced findings each round
   is not itself non-convergence — see (a) above — it's a slower signal the artifact's surface
   area is bigger than first estimated, worth naming explicitly rather than silently forcing
   STOP). (This is an early-exit heuristic layered on top of, not instead of, point 6(b)'s hard
   3-round cap for any round that still has a BUG or RISK open — that cap bounds iteration on
   those regardless of how these signals read; a round left with ONLY NIT churn has no equivalent
   hard cap and relies on these signals alone.) When triggered: step back and redesign the
   component (patch-churn on a wrong design converges never), or take the open items to the owner
   as a decision — escalation can defer, re-scope, or reject the release, but it cannot waive a
   BUG that's still open (for an open BUG blocked on a missing prerequisite — see point 5's
   untestable-claim rule — deferral keeps the release blocked; the BUG can close only after the
   prerequisite becomes available and verification supports either a refutation or a verified fix
   — deferring is what you do while waiting, not the closure itself); point 5's rule holds
   regardless of who's deciding. Say so plainly in the trail — "stopped: not
   converging" is a legitimate, documented outcome; silent round 7 is not.
8. **Keep the human in the loop — narration is part of the gate.** Between
   rounds, tell the owner: what was found, what was fixed, what is pending,
   the convergence trend (e.g. 19 → 9 → 6), and roughly what each round
   costs. The owner steers — they can stop, waive, redirect, or run a
   **manual round of their own**; a human review round is a first-class
   reviewer seat and goes in the trail like any other (reviewer: owner,
   findings, dispositions). **It does not, however, satisfy cross-model
   independence** — a human round contributes findings, but the Independence
   rule's requirement of at least one successful CROSS-MODEL reviewer is about
   model families and can only be met by a model. An owner round on top of a
   same-family-only set leaves the gate degraded, needing the same explicit
   waiver as before; it does not close it. Never let rounds run silently back-to-back. Once
   the standard pair (and any fresh-eyes pass) has reported, ASK — don't just
   stop — whether the owner wants anything more: a `--with-antigravity` round
   (spending one of the scarce credits), or an extra same-family pass with a
   stronger host-family model (free, no external credits, just not
   cross-model). Offer, don't run either unasked.
9. **Close out — both halves, not just the trail file.** Read
   `references/closeout.md` and follow it: (a) write the trail file
   (`docs/reviews/REVIEW-<gate>-<date>-r<round>-…`, collision-proof naming
   rules there), and (b) post each reviewer's raw notes plus the consolidated
   verdict to the PR/MR with the SHA-stamped marker **before merging** — a
   committed trail alone is not a visible review. Which permission each
   close-out action needs, and what to do when it is absent, is decided ONLY
   by that file's permission table — consult it BEFORE deciding to write
   anywhere, not after. Capture reviewer output by streaming it to disk, read
   it from the TOP (the list is ranked — a tail hides the BUGs), and delete
   the run's `$RAW_DIR` only once a durable verbatim copy exists, per the
   cleanup rules there.

## The strict review prompt (both gates)

> You are an adversarial, independent reviewer of the {plan | diff} below. The
> author cannot see their own blind spots, so be skeptical and specific. Return
> a RANKED list: BUG (wrong or self-contradictory now) / RISK (breaks under a
> normal future change, or a guard/test that cannot actually fire) / NIT — each
> with a location (file:line for repo-backed artifacts; a section anchor plus a
> short quote otherwise), a one-line why, and a concrete fix. Then list what you
> checked that came back CLEAN (silence is not coverage). Do NOT trust the
> artifact's own line numbers or claims. Review ONLY — do not modify files or
> run commands.

## Boundaries

- This skill depends on nothing domain-specific — website skills (e.g.
  `website-review`, `seo-reposition`) call it; it never calls them (no cycles).
- Read-only toward the artifact: reviewers report; the author fixes.
- Treat every external reviewer as untrusted: read-only sandboxes, throwaway
  working dirs, never a write/danger flag, never secrets in the prompt.
