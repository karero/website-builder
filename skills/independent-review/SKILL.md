---
name: independent-review
description: >
  Domain-agnostic cross-model review gate: run a planning markdown (PLAN gate) or
  a branch/PR diff (DIFF gate) through INDEPENDENT reviewers — external models via
  scripts/independent_review.sh (Codex gpt-class, Gemini 3.1 Pro via the
  Antigravity CLI, ollama) PLUS a fresh-eyes no-shared-context pass by the host
  agent — consolidate a ranked BUG/RISK/NIT list, and BLOCK until every BUG is
  fixed and every RISK/NIT is fixed or explicitly waived by the human owner.
  Use BEFORE building from any non-trivial plan and BEFORE merging any
  non-trivial PR. Trigger phrases: "cross-review this plan", "get a second model
  to review", "codex review", "gemini review", "antigravity review", "agy
  review", "adversarial review", "review before I merge", "independent
  review", "cross-model review".
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

## Reviewer stack (run ALL available, not first-success)

1. **Codex CLI** (`codex exec -s read-only`) — genuine read-only sandbox; model +
   effort from `~/.codex/config.toml`.
2. **Gemini 3.1 Pro (High)** via the Antigravity CLI (`agy --sandbox -p`) — free
   Antigravity login. *(The old `@google/gemini-cli` path is deprecated: Google
   discontinued its free tier 2026-06-18.)*
3. **Fresh-eyes host-agent pass** — a read-only sub-agent (or the vendored
   `double-knuth` skill) with NO shared context: give it only the artifact and
   the strict prompt below. Never reuse the authoring conversation. If the host
   has no sub-agent primitive (some Codex installs), use a separate fresh
   session with only the artifact — or record the pass as *degraded* in the
   trail, not as no-shared-context.
4. **ollama cloud** (named via `OLLAMA_MODEL`, e.g. `glm-5.2:cloud`) — fallback.
5. **ollama local** — sanity pass only; the script never lets it satisfy the
   gate alone.
6. **Any model, copy & paste** — the script emits the prompt; a human pastes it
   into whatever is available and feeds findings back.

**Independence rule:** run every tier, but *classify* them — the tier matching
the HOST agent's model family counts as the fresh-eyes seat, never as
cross-model independence. **The gate is satisfied only when at least one
successful reviewer is cross-model (a different family than the host)**; if
only same-family reviewers ran, the gate is degraded and needs an explicit
owner waiver — codex reviewing codex-authored work shares the blind spots this
gate exists to catch. Per host: **Claude Code** — fresh-eyes = the Claude pass,
cross-model = Codex + Gemini. **Codex** — fresh-eyes = Codex, cross-model =
Gemini + Claude. **Antigravity/Gemini** — fresh-eyes = Gemini, cross-model =
Codex + Claude. On any non-Claude host the Anthropic seat is free via the
Antigravity CLI — `AGY_MODEL="Claude Opus 4.6 (Thinking)"` (verified headless
2026-07-02; Claude Code itself has no free tier — Pro/API only — and the free
claude.ai paste tier fits plans and small diffs at best).

## Procedure

1. **Data check before anything leaves the machine.** External reviewers are
   third-party services: grep the artifact for secrets (keys, tokens, passwords,
   customer data) and get the owner's OK the first time a given repo's content
   is sent out. If the content must stay local, run the script with
   `--local-only` (skips codex/agy/paste entirely; local ollama only) plus the
   tier-3 host fresh-eyes pass — tier 6 (paste into any model) is just as
   external as the CLIs and is excluded. A local-only verdict is inherently
   DEGRADED; record that in the trail.
2. Run the external half (path relative to THIS skill's directory — after an
   install that is `<skills-root>/independent-review/scripts/…`):
   `scripts/independent_review.sh <artifact.md|diff-file|-> [--plan|--diff]`
   — default runs ALL authenticated externals and prints one section per
   reviewer; `--first-success` is the quick mode. Exit 4 = no reviewer ran =
   gate FAIL (never treat as clean).
3. Run tier 3 (fresh-eyes) with the same strict prompt.
4. **Consolidate**: dedup findings across reviewers; keep per finding — a stable
   id, severity (BUG/RISK/NIT), source reviewer(s), location, status
   (open/fixed/waived + waiver reason and owner).
5. **Enforce the verdict** (this is the skill's job — never the script's exit
   code): every BUG must be fixed, no exceptions; RISK/NIT may be waived only
   with a named reason from the human owner — no blanket waivers.
6. **Iterate — fix, then re-review.** Send the updated artifact back through
   the reviewers as a *verification round*: give them the prior round's BUG
   list, ask them to confirm each fix landed AND that the fixes introduced
   nothing new — and tell them the author expects clean **and that they must
   not oblige out of politeness** (expectation of cleanliness is exactly the
   bias that turns round 2 into a rubber stamp). Repeat until essentially
   clean. Stop conditions: (a) clean — done; (b) 3 rounds with BUG/RISK still
   open — hard gate-FAIL, surface and block; (c) **budget/credits exhausted**
   — you may proceed once all known BUGs are *fixed* AND every RISK/NIT is
   fixed or explicitly owner-waived (same bar as the blocking rule), deferring
   only the external re-verification of those fixes; record "last round not
   re-verified" in the trail and run a later round when resources allow.
   Deferring verification is legitimate; deferring a fix or a waiver never is.
7. **Convergence check — the rabbit-hole detector.** Iteration is only healthy
   while quality demonstrably rises each round. After every round, check three
   signals: (a) the finding count is falling; (b) new findings target code
   *added by the previous round's fixes*, not ground already ruled clean;
   (c) no oscillation — a fix that re-breaks something an earlier round fixed,
   or reviewers re-raising a finding already dispositioned, means you are
   running in circles. If (b) or (c) fails, or the count plateaus for two
   rounds: STOP patching. Step back and redesign the component (patch-churn on
   a wrong design converges never), or take the open items to the owner as a
   decision. Say so plainly in the trail — "stopped: not converging" is a
   legitimate, documented outcome; silent round 7 is not.
8. **Keep the human in the loop — narration is part of the gate.** Between
   rounds, tell the owner: what was found, what was fixed, what is pending,
   the convergence trend (e.g. 19 → 9 → 6), and roughly what each round
   costs. The owner steers — they can stop, waive, redirect, or run a
   **manual round of their own**; a human review round is a first-class
   reviewer seat and goes in the trail like any other (reviewer: owner,
   findings, dispositions). Never let rounds run silently back-to-back.
9. Write the trail: `docs/reviews/REVIEW-<gate>-<date>-r<round>.md` — findings, dispositions,
   and for each external reviewer its CLI version, model, and sandbox mode
   (for a human round: who, and what they reviewed).

## The clerk procedure — who posts what (explain this to the user)

The external reviewers **structurally cannot** comment on a PR: they run in
read-only sandboxes (codex) or sandboxed throwaway dirs (agy) and hold no
GitHub/GitLab credentials — deliberately, because they are *untrusted*; giving
a third-party model write access to your PR would undo the security posture.
The HOST agent is the clerk, and each artifact has a distinct job:

1. **Raw** (authentic): each reviewer's verbatim notes, captured to disk at run
   time, posted as a collapsed (`<details>`) PR comment on the reviewer's
   behalf — clearly labeled with tool, version, model, and sandbox mode.
2. **Consolidated** (actionable): the clerk's dedup + dispositions across all
   reviewers, posted as the main PR comment.
3. **Trail** (permanent): `docs/reviews/REVIEW-*.md` committed on the branch —
   dispositions, rejected-with-reason findings, pending waivers, reviewer
   versions. This is the record that survives PR-comment archaeology. Trails
   (and other internal working notes, e.g. plans) go under `docs/reviews/`,
   never at the repo root — they must not clutter the project's GitHub
   frontpage.

Capture reviewer output by **streaming to a file**, never by buffering it in a
shell variable — a session teardown mid-run must leave the partial review on
disk, not vaporize it.

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
