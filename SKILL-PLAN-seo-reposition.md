# Skill plan — `seo-reposition` + `independent-review`

> **Status 2026-07-02: BUILT** — shipped as `skills/independent-review/`,
> `skills/seo-reposition/`, and the vendored `skills/double-knuth/` (PR #18).
> This document is the design record + review trail, not a live proposal;
> where it and the shipped skills disagree, the skills win.

A design distilling the apreet.com + m-squad.com engagements into
website-builder skills. Two things were proven twice and aren't captured anywhere:

1. **A repositioning method** — diagnose where a site's own phrasing collides with unrelated
   concepts (Google/LLMs mis-file it), find the *winnable* term, and rewrite onto it **with
   guard tests** so the old phrasing can't creep back.
2. **A cross-model review loop** — plan in markdown, have a *different* model (your "CODEX")
   tear it apart before you build, implement behind test gates, then review the PR the same
   way before merge. This caught real test-blind-spots on both sites.

The gap analysis (existing skills: `seo-audit`, `ai-seo`, `website-seo-geo`, `schema-markup`,
`search-console-insights`, `website-review`, `website-qa`) shows neither is covered.

---

## Recommendation: two skills, one calls the other

- **`independent-review`** — a small, *domain-agnostic* review gate. Runs a planning MD or a PR/diff
  through (a) an external model via CLI, (b) a fresh-eyes Claude sub-agent, (c) human-paste
  fallback; consolidates a ranked BUG/RISK/NIT list; **blocks progress until each finding is
  addressed or explicitly waived.** This is the piece you were unsure how to implement — and
  it's reusable far beyond SEO.
- **`seo-reposition`** — the domain method (SERP trap-test → wedge/target/copy → SEO-FINDINGS
  → rewording plan → guard tests → phased ship → grade). It **calls `independent-review`** at two
  gates.

You *can* fold `independent-review` inside `seo-reposition`, but extracting it is worth it: the
review loop is the reusable crown jewel, and `new-website` / `website-review` can call it too.

---

## `independent-review` — the review loop, made concrete

This is the answer to "how do we implement the CODEX review as a skill step."

### Two gate types
- **PLAN gate** — reviews a planning markdown *before* any code is written. Catches strategy
  errors, stale assumptions, internal contradictions. (Ran ~5× on apreet's plan.)
- **DIFF gate** — reviews a branch/PR diff *before* merge. Catches test blind spots — a guard
  passing while the thing it protects regressed (e.g. bare "trip overlap" moved into a title
  slot; a homepage trust card blurring two product concepts; stale related-card anchors).

### Reviewer stack — in order *(historical: drop-through was the draft design; the shipped script runs ALL available by default, `--first-success` = opt-in drop-through)*
1. **`codex` — OpenAI Codex CLI (gpt-5.5 / xhigh).** The strong, independent cross-model seat,
   run **DIRECTLY — no Cursor**. Reads `~/.codex/config.toml` (model + reasoning effort) +
   `auth.json` (already logged in); **`codex exec -s read-only` is a GENUINE read-only sandbox**,
   so it cannot touch your repo. The binary ships inside the ChatGPT VS Code extension (not on
   PATH) — the script resolves it. Always uses the highest configured model (currently gpt-5.5
   xhigh). *Verified live 2026-07-01: `model: gpt-5.5`, returns cleanly.*
2. **Gemini 3.1 Pro (High) via the Antigravity CLI (`agy`) — Google, the third model family.**
   A second independent external model → OpenAI + Google + Anthropic = maximum blind-spot
   diversity. **The headless path is the Antigravity CLI** (`brew install antigravity-cli`,
   binary `agy`) — **free tier via the Antigravity Google login** (shared with the IDE; no
   separate auth, **no API key needed**), and it exposes the **literal "Gemini 3.1 Pro (High)"**
   model. *Verified live 2026-07-02: `agy --sandbox --model "Gemini 3.1 Pro (High)" -p …` →
   replies headlessly; also lists Gemini 3.5 Flash tiers, Claude, GPT-OSS.* Wired in the script
   as `run_agy` (`AGY_MODEL` env, default 3.1 Pro High; `--sandbox`; throwaway dir; never
   `--dangerously-skip-permissions`).
   **⚠ DEPRECATED — the old `gemini` CLI (`@google/gemini-cli`) path:** Google discontinued its
   free "Login with Google" tier on **2026-06-18** (`IneligibleTierError: UNSUPPORTED_CLIENT`,
   verified live 2026-07-02; API-key-only since, and it doesn't carry 3.1 Pro anyway). Dropped
   from the stack; safe to uninstall.
3. **Claude Code Double-Knuth — the fresh-eyes pass, always runs** (even after the external
   models). A no-shared-context adversarial review via the **`website-review`** skill (or generic
   `double-knuth`). Cross-model (codex, gemini) + fresh-eyes-Claude catch different classes of
   issue — run all. *(SUPERSEDED: `double-knuth` IS now vendored — `skills/double-knuth/`. Draft text: the skill vendors it
   into `skills/`, as `new-website` does, or degrades gracefully.)*
4. **ollama-cloud** (e.g. `glm-5.2:cloud`) — strong + private-ish fallback when the above are
   unavailable. Named explicitly via `OLLAMA_MODEL` (cloud vs local is NOT detectable from
   `ollama list`). Needs an ollama cloud sign-in.
5. **ollama-local** (14B: qwen2.5-coder, deepseek-r1) — OFFLINE FALLBACK ONLY; too weak for the
   subtle blind-spot catches, limited context. Sanity pass, never the sole gate.
6. **Any model, copy & paste** — the script emits the strict prompt + artifact; paste into
   whatever you have, feed the findings back.

The external-model half (tiers 1, 2, 4, 5, 6) ships as **`independent_review.sh`** — *(shipped
contract: runs ALL available reviewers by default; codex → agy → ollama → paste is the
`--first-success` order)* — and **exits non-zero (= gate FAIL) if none succeed** (never
silent-clean). Tier 3 (Claude Double-Knuth) is run by the orchestrating skill. *(cursor-agent
dropped: codex is the direct path with a real read-only sandbox.)*

### The strict review prompt (same shape both gates)
> Read this {plan | diff}. You are an adversarial reviewer; the author cannot see their own
> blind spots. Return a ranked list — **BUG** (wrong/contradictory now) / **RISK** (breaks
> under a normal future change, or a guard that can't fire) / **NIT** — each with a file:line,
> a one-line why, and a concrete fix. Then list what you checked that came back clean. Verify
> every claim against the actual files; do not trust the artifact's own line numbers.

### Output + the blocking rule
- Consolidate all reviewers' findings, dedup, rank.
- **BUGs must be fixed — never waived. RISK/NIT may be waived only with a named reason by the
  human owner** (no blanket waivers). Re-run after fixes; cap at 3 rounds, and any BUG/RISK still
  open at the cap is a **hard gate-FAIL** (surface + block), not pass-with-notes.
- Emit a short `REVIEW-<gate>-<date>.md` trail (what was found, what was fixed/waived).

### Triggers
"cross-review this plan", "get a second model to review", "codex review", "review before I
merge", "adversarial review of the PR".

---

## `seo-reposition` — the domain method

### When to use
A live site whose category/keyword phrasing isn't ranking, or is getting mis-filed by Google/
LLMs (GSC shows brand-only demand, or the category pages pull ~0 non-brand impressions).
Prereq: `search-console-insights` connected (GSC data) + a SERP key (Serper) for the trap-test.

### Phase 1 — Diagnose → `SEO-FINDINGS.md`
Reuse the exact structure both sites converged on:
- **GSC pull** (`search-console-insights`): brand vs non-brand demand, per-page impressions.
- **SERP trap-test** (the core technique): for each candidate phrase, search US Google
  (`serp_check.py`, explicit `gl`/`hl` for the site's target market — `gl=us hl=en` was
  right for these two engagements, never a default) and **read the top-10 by *intent*, not
  keyword overlap**.
  Classify each: **✅ wedge** (on-intent, no entrenched incumbent) · **🟠 crowded** (right
  category, owned) · **🚫 trap** (resolves to a *different* concept — lenses, miles, LinkedIn,
  board meetings, ETF tools, meet-strangers apps).
- Output sections (template): Headline · The data · Queries (brand vs non-brand) · SERP
  competition (the wedge / wrong-intent / listicle-gated) · Keyword-fit research (tested
  candidates, ≥2 rounds) · One-line strategy · Tracking.

### Phase 2 — Strategy → `<site>-rewording-plan.md` + `WORDING-GUIDE.md`
- **Target-vs-copy rule** (the load-bearing distinction): a phrase can be great *body copy* but
  a toxic *rank target*. Only trap-clean phrases go in title/H1/anchor/slug/schema/llms.txt.
- **Blacklist** (what Google returns instead) + **approved vocabulary** (wedge / lanes /
  comparison-bait) + **route decisions** (retarget / 301 / rename) + **canonical description**
  (schema + llms.txt) + competitor facts.
- **This plan is run through the `independent-review` PLAN gate** (≈ the 5 CODEX rounds) until clean.

### Phase 3 — Guard tests FIRST (red → green ratchet)
Generate, from the WORDING-GUIDE, failing test specs that ratchet green as copy lands:
- **`trap-guard`** — scan built HTML + llms.txt + OG source for blacklisted phrases (source of
  truth = WORDING-GUIDE blacklist).
- **`slot-guard`** — bans "copy-legal but not-a-target" phrases from title/H1/schema/anchor
  (the apreet blind spot: bare "trip overlap" in a title). This needs a **per-route slot
  extractor** (parse `<title>`/`<h1>`/JSON-LD/anchor text per built page) with a negative-lookbehind
  on the allowed qualifier — a flat regex over `dist/` can't tell a slot from body copy. So
  slot-guard is **templated + hand-finished per site**, not fully auto-generated.
- **`two-label`** / product-honesty guard — pages that must name two distinct concepts do.
- **`homepage-locked`**, **redirect** guards for exact locked values + 301s.
- Every guard is **negative-tested** (break the thing, confirm it fires).

### Phase 4 — Phased, gated implementation
- Sequence by leverage: config/site-wide cascade first (one edit clears many pages), then
  money pages, then supporting/related-card sweep, then new comparison pages.
- **Stop after each gate; show the burn-down** (e.g. trap-guard 143→0). Commit per phase.
- **`independent-review` DIFF gate on the PR before merge.** Address findings, re-review.

### Phase 5 — Ship → grade (close the loop)
- Deploy (repo's own deploy model), submit sitemap / IndexNow, GSC request-index the top pages.
- **`SEO-CHANGELOG.md`** — one row per change: page · old→new target · expected GSC query ·
  outcome (blank). Flip `planned→deployed`.
- **Schedule a grading run** (~3–6 wks): re-pull GSC + SERP, fill outcomes, report
  predicted-vs-actual. (This is the audit-loop-closing move — otherwise it's a write-only log.)

### Triggers
"reposition the site's SEO", "our keywords collide with X", "we're not ranking for our
category", "trap-phrase audit", "rewording plan", "find our SEO wedge".

---

## Artifacts the pair produces (all reusable templates)
`SEO-FINDINGS.md` · `<site>-rewording-plan.md` · `WORDING-GUIDE.md` (the digestible reference)
· guard specs (`trap-guard`/`slot-guard`/`two-label`) · `SEO-CHANGELOG.md` · `REVIEW-*.md`
trails · a scheduled grading task.

## What the skill scripts would ship
- `scripts/trap_test.py` — wraps `serp_check.py`, classifies top-10 by intent (assists, human
  confirms the 🚫/🟠/✅ call — model for judgment, code for the fetch).
- `scripts/gen_guards.mjs` — auto-generates **trap-guard** (mechanical: grep the blacklist in
  built HTML/llms.txt/OG). **slot-guard + two-label are templated but hand-finished per site**
  (they need per-route slot parsing / product-concept knowledge a generator can't infer).
- `independent_review.sh` — **shipped** in `skills/independent-review/scripts/`; runs ALL available reviewers (default), the
  strict prompt, and **exits non-zero (= gate FAIL) if none succeed** — never a silent "clean".
- `templates/` — SEO-FINDINGS, rewording-plan, WORDING-GUIDE, SEO-CHANGELOG.

---

## Proposed next steps (dogfood our own method)
1. ✅ **DONE — `independent-review` PLAN gate, round 1 (Claude fresh-eyes tier)** + ✅ **round 2
   (codex gpt-5.5/xhigh cross-model, 2026-07-02).** Both dogfooded on this plan; findings folded
   in (see Review trail).
2. Build with **`skill-creator`** — `independent-review` first (small, testable), then
   `seo-reposition` on top of it.
3. Ship to website-builder via PR (public repo) — with a `independent-review` DIFF gate on that PR.

## Decisions (locked 2026-07-01)
- **Two skills** — `independent-review` (reusable gate) + `seo-reposition` (domain method that
  calls it).
- **Reviewer default = ALL available, always — NOT first-success.** Each gate runs every
  *authenticated* external model — **codex gpt-5.5/xhigh** + **Gemini 3.1 Pro (High) via the
  Antigravity CLI `agy`** — AND the fresh-eyes **Claude Code Double-Knuth** pass, then
  consolidates their findings. ollama-cloud (`glm-5.2:cloud`) → ollama-local → paste are **fallbacks only** (used
  when the primaries are unavailable), not part of the always-run set. **Three model families
  (OpenAI · Google · Anthropic) = maximum blind-spot diversity.** Always use the highest available
  model per tool. cursor-agent dropped entirely.
  - ✅ **Contract fix (codex round 2, BUG #3/#5) — SHIPPED:** `independent_review.sh` now
    defaults to running ALL available reviewers (one output section each); `--first-success`
    is the opt-in fallthrough mode. The **gate verdict is enforced by the skill parsing
    findings** (unaddressed BUG / unwaived RISK = FAIL) — the script's exit code only says
    whether any reviewer produced review-shaped output (exit 4 = none), never "clean."
  - ~~Antigravity/Gemini 3.1 Pro = manual paste-only~~ **SUPERSEDED 2026-07-02:** the
    **Antigravity CLI (`agy`)** runs the literal **Gemini 3.1 Pro (High)** headlessly on the free
    Antigravity login — proven live. The `gemini` CLI tier is deprecated/dropped (free OAuth
    discontinued by Google 2026-06-18).
- **`seo-reposition` scope = full end-to-end**, but Phases 4–5 **delegate** to existing skills
  rather than reimplement: the DIFF gate → `website-review` + `independent-review`; GSC/SERP →
  `search-console-insights`; QA → `website-qa`. The skill owns Phases 1–3 (the novel core:
  diagnose, plan, guard-tests) and orchestrates the rest.

---

## Review trail — round 1 (2026-07-01, `independent-review` PLAN gate, Claude fresh-eyes tier)
Dogfooded on its own plan. 14 findings; fixed before building:
- **BUG — false "read-only" claim.** `cursor-agent -p` HAS write/bash tools (per its `--help`);
  `--force` only governs confirmation. → script now runs it from a throwaway dir + honest
  "not sandboxed, treat as untrusted" note; prose corrected.
- **BUG — `exec` with no fallthrough defeated a *blocking* gate.** → replaced with tiered
  functions that fall through; no reviewer → **exit 4 (FAIL)**, never silent-clean.
- **BUG — claimed `double-knuth` is in the suite.** It's a *global* skill, not vendored. →
  corrected: delegate to `website-review`; vendor `double-knuth` or degrade gracefully.
- **RISK — cloud-vs-local not detectable from `ollama list`.** → `OLLAMA_MODEL` must be named;
  any un-named-cloud model is warned as weak.
- **RISK — arg parsing mis-typed the pipe form; `REVIEW_MODEL` collided across tiers;
  `PIPESTATUS` could mask a failed run.** → real flag parse + `--plan/--diff` + auto-detect;
  `CURSOR_MODEL`/`OLLAMA_MODEL` namespaced; exit checked via temp-file before trusting output.
- **RISK — blocking rule could "waive everything" and pass.** → BUGs unwaivable; RISK/NIT need a
  named human waiver; open BUG/RISK at the round cap = hard FAIL.
- **RISK — `slot-guard` generation hand-wavy.** → documented as templated + hand-finished
  (needs a per-route slot extractor, not a flat regex).
- NITs (Phases 4–6→4–5, tier mislabel, `cross_review.sh`↔`independent_review.sh` naming): fixed.

This is the gate working as designed — it caught bugs the author (me) shipped.

## Review trail — round 2 (2026-07-02, `independent-review` PLAN gate, codex gpt-5.5/xhigh)
Cross-model tier, run **directly** via `codex exec -s read-only` (session `019f2155`, exit 0,
~18.8k tokens). 16 findings (5 BUG · 10 RISK · 1 NIT). Verdict + disposition:
- **BUG #3 — "ALL available" vs script first-success fallthrough (the sharp one).** ✅ fixed in
  Decisions: skill fans out to all authenticated reviewers; `--first-success` is opt-in.
- **BUG #5 — exit code ≠ review verdict.** ✅ clarified: the *skill* enforces the block from parsed
  findings; the script's non-zero only means "no reviewer ran."
- **BUG #1 — `cursor-agent` both dropped and still gating round 2.** ✅ removed the stale
  `cursor-agent login` references (Proposed next steps + this trail's old tail).
- **BUG #2 — Gemini "3.1 Pro headless" over-promised.** ✅ tier reframed at the time; then
  **superseded 2026-07-02**: the Antigravity CLI (`agy`) delivers literal 3.1 Pro (High)
  headlessly on the free tier — codex's concern resolved by a better path, not a hedge.
- **BUG #4 — "not built yet" vs "script already written."** Accepted as a wording tension —
  proposal = *skills* not built; `independent_review.sh` is a working prototype helper. (Kept, it's
  already stated both places; no contradiction once read that way.)
- **RISK #6 — recursion: `independent-review` ↔ `website-review`.** ⚠ ADOPT when building:
  `independent-review` depends only on a generic fresh-eyes reviewer; website skills call it, never
  the reverse.
- **RISK #8 — no external-review data policy.** ⚠ ADOPT: add a secret-scan / approval / local-only
  mode before shipping any artifact to codex/gemini/ollama-cloud.
- **RISK #9 — read-only ≠ no exfiltration.** ⚠ ADOPT: record CLI version/model/sandbox in the
  review trail (done here); add a canary-write check.
- **RISK #11 — US-only SERP hardcoded.** ⚠ ADOPT: make market/lang/device/date explicit inputs to
  `trap_test.py`.
- **RISK #15 — "schedule a grading run" needs a mechanism.** ✅ we already ship one — the
  `scheduled-tasks` entry (`grade-apreet-seo-rewording`, fires 2026-07-29). Name that as the
  artifact in the skill.
- **RISK #10/#7 — free-form findings, file:line for pasted artifacts.** ⚠ note: adopt a finding
  schema (id/severity/source/status/waiver) + require section-anchor (not file:line) for non-repo
  artifacts.
- **RISK #12/#13/#14 — trap-guard grep variants, slot-guard brittleness, negative tests not
  reproducible.** ⚠ ADOPT at build: normalize per surface (HTML text / JSON-LD / anchors /
  llms.txt) with fixtures; parse slots before matching; use mutation fixtures, not live-copy edits.
- **NIT #16 — `REVIEW-<gate>-<date>.md` collides same-day.** ✅ add round + timestamp
  (`REVIEW-plan-2026-07-02-r2.md`).
- **Codex confirmed CLEAN:** the two-skill split, the target-vs-copy rule, slot-guard/two-label as
  not-auto-generatable, the BUG/RISK/NIT taxonomy, the "BUGs unwaivable" rule (once enforceable),
  the phased flow, and the "list clean checks" requirement.

Both cross-model tiers (Claude round 1, codex round 2) are now on record; the ⚠ ADOPT items are
carried into the `skill-creator` build.
