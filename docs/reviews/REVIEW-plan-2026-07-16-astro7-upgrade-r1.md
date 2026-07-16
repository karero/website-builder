# REVIEW — PLAN gate, Astro 6→7 upgrade plan, round 1 (2026-07-16)

Artifact: `astro7-upgrade-plan.md` (scratchpad, not committed to the repo) — the plan for
bumping `skills/new-website/templates/astro/`'s pinned Astro dependency from `^6.0.0` to
`^7.1.0`, produced after an earlier 4-agent investigation workflow and one ad-hoc single-model
(`ollama-review`, `glm-5.2:cloud`) pass on an unrevised draft. This round is the actual
`independent-review` gate, run at Daniel's explicit request.

## Reviewers (version / model / sandbox)

| Seat | Tool | Model | Sandbox | Outcome |
|---|---|---|---|---|
| cross-model | codex-cli | gpt-5.6-terra | `exec -s read-only` | 11 findings (1 BUG · 8 RISK · 2 NIT) |
| cross-model | ollama-cloud | glm-5.2:cloud | hosted API | 5 findings (2 BUG · 2 RISK · 1 NIT) |
| fresh-eyes | Claude sub-agent (no shared context) | claude-sonnet-5 | read-only sub-agent | 3 BUG · 1 RISK · 5 NIT |

Independence: host = Claude Code; gate satisfied (Codex and ollama-cloud are both cross-model).
Fresh-eyes ran as a genuinely blind sub-agent (only the plan file + repo read access, no
conversation context) rather than the host's own authoring pass.
Data check: plan file grepped for secret-shaped strings — clean; website-builder is a public
repo already cleared by `make check`.

## Consolidated findings — verified against ground truth, not accepted on any reviewer's word

Every checkable claim below was independently re-verified (npm registry queries, `gh api`,
direct file reads) before disposition — several plausible-sounding findings from all three
reviewers did not survive this and are marked REFUTED.

1. **BUG (Codex + fresh-eyes, independently)** — "Timing decision" section claimed real sites
   have run **Astro 7.1.0** specifically for ~3.5 weeks; 7.1.0 published 2026-07-16 (today),
   so that's impossible. **CONFIRMED** via `npm view astro time` (7.0.0: 2026-06-22, 7.1.0:
   2026-07-16). Fixed: reworded to "some Astro 7.x" for the 3.5-week claim, explicit new note
   that 7.1.0 itself has zero days of bake time, argument reweighted accordingly rather than
   silently patched.

2. **BUG (fresh-eyes)** — "One real trap to avoid" cited `withastro/roadmap#1321` as the
   TypeScript-7 tracking issue with an "ETA ~October 2026." **CONFIRMED fabricated/wrong**:
   `gh api repos/withastro/roadmap/issues/1321` → 404. Real issue is
   [withastro/astro#17268](https://github.com/withastro/astro/issues/17268), confirmed open,
   title matches exactly. No ETA exists in that thread — maintainer says blocked upstream with
   no committed date. Fixed: citation replaced, fabricated ETA removed.

3. **BUG (fresh-eyes)** — two of the doc-sweep line citations (`README.md:47`, `SETUP.md:69`)
   point at an unrelated `npm approve-scripts esbuild && npm approve-scripts sharp` sentence,
   not "Astro 6" text. **CONFIRMED** via direct `Read`. Fixed: dropped from the sweep list (the
   correct lines, 36 and 65, were already separately listed).

4. **RISK (GLM, ollama-cloud)** — PR #56's green CI (37 tests, 36 passed) already proves a real
   `astro build` succeeds against Astro 7.1.0, since `playwright.config.ts`'s `webServer` runs
   `npm run build && npm run preview` and `build` chains `astro build && anchor-ids.mjs`. The
   plan's step 3 ("run astro build locally to surface the risk") was framed as discovering an
   open unknown when it's actually re-confirming an already-closed one. **CONFIRMED** via direct
   read of `playwright.config.ts` + `package.json`. Fixed: reframed step 3 and risk #2 in "Two
   concrete risks" to state this is already empirically cleared.

5. **RISK/overclaim (GLM, ollama-cloud)** — "Already shipped" section said `whats-new.sh`'s new
   astro-version check "activates automatically" for real sites once the toolkit's template pin
   bumps. Logically, sites already on Astro 7.x are never "behind" the pin (before OR after the
   bump), so the check can never fire for them — it only ever helps a straggler still on Astro
   6. **CONFIRMED** by re-deriving the actual comparison logic in `check_astro_version()`.
   Fixed: reworded to state the real, narrower benefit.

6. **RISK — permanent guard vs. one-time check (Codex + fresh-eyes, converging independently)**
   — the compressHTML/footer-whitespace fix relies on a manual diff at migration time; nothing
   stops a future page author from reintroducing the same whitespace-collapse bug class with no
   CI guard to catch it. Fresh-eyes additionally confirmed via grep that no existing spec
   (`navigation`, `a11y`, `seo`) asserts on footer text/spacing at all. **CONFIRMED, both the
   gap and the missing coverage.** Fixed: step 4a now also recommends making the footer
   separator explicit in markup/CSS (removing the bug class, not just detecting one instance),
   plus a text-diff-first approach (more reliable than eyeballing minified/rendered HTML).

7. **RISK — anchor-id fixture (Codex + fresh-eyes)** — `Base.astro` has zero headings, so
   "no current heading hits the risky pattern" is trivially true and doesn't demonstrate the
   check works. Fresh-eyes additionally checked `privacy.astro`/`impressum.astro`/
   `_datenschutz.astro` (the pages that DO have headings) directly and found them clean too —
   the conclusion holds, but the plan's own stated scope didn't show that. **CONFIRMED.** Fixed:
   step 4b now names the actually-checked pages and recommends a deliberate test fixture for
   durable coverage rather than relying on today's content happening to be clean.

8. **RISK — engines floor precision (Codex)** — `.nvmrc`'s bare `22` doesn't pin the actual
   `>=22.12.0` floor (confirmed via `npm view astro@7.1.0 engines` — unchanged from 6.4.8); a
   bare major resolves to "latest at install time," which is fine today but isn't an explicit
   guarantee. **CONFIRMED, low-cost fix accepted.** Added to step 7's sweep list.

9. **RISK — sitemap assertion specificity (Codex)** — "correct URL count" is weaker than
   asserting the actual expected route set; could pass while silently omitting a URL if the
   count happens to coincidentally match. **Accepted as a reasonable hardening**, not verified
   against any current bug (none exists yet) — folded into step 5.

10. **RISK — esbuild tree-wide audit (Codex)** — a regenerated lockfile could still resolve a
    vulnerable nested `esbuild` via some other transitive path independent of astro's own.
    **Accepted as a reasonable acceptance criterion** — added `npm ls esbuild` check to step 1.

11. **NIT — WEBSITE_ARCHITECTURE.md over-inclusion (Codex's general caution, fresh-eyes'
    specific verdict, AND independently confirmed by the plan's author before either review
    completed)** — only line 71 (the "Astro 5 → Astro 6" section header) is genuinely stale;
    lines 64 and 230/235 are accurate historical citations needing no edit. **CONFIRMED**
    (triple-checked). Fixed: sweep list narrowed to line 71 only.

12. **NIT — package.json:21 double-counted (fresh-eyes)** — listed in both step 1 (the actual
    bump) and step 7 (the doc sweep) as if two separate actions. **CONFIRMED, trivial.** Fixed:
    removed from step 7, it's step 1's own target.

## REFUTED (raised, checked, did not hold up)

- **GLM: `@astrojs/sitemap` peer-dependency conflict risk** — REFUTED. `npm view
  @astrojs/sitemap@3.7.3 peerDependencies` → none exist. No ERESOLVE risk regardless of Astro
  version.
- **GLM: `compressHTML` type-error risk on an existing explicit config** — REFUTED on two
  counts: `astro.config.mjs` has no explicit `compressHTML` setting (grepped, confirmed empty),
  and even if it did, `true` remains valid under Astro 7's `boolean | 'jsx'` type (confirmed
  from the published type definitions) — no type error either way.
- **Codex: switching `template-tests.yml` to `npm ci` breaks recipients' floating installs** —
  REFUTED. Conflates the toolkit's own internal CI (which only tests the toolkit repo's own
  committed lockfile) with the separate, unrelated CI file (`templates/astro/.github/workflows/
  ci.yml`) that ships INTO a scaffolded site and uses that site's own freshly-generated
  lockfile. The two are unrelated; switching the toolkit's internal CI to `npm ci` doesn't
  affect any recipient's repo.
- **Codex: unbounded `npm create astro@latest` risk (future Astro 8 bypasses validation)** —
  not refuted, but out of scope for this specific bump; folded into the plan's existing
  step 9 follow-up note rather than treated as a standalone blocking finding.

## Open decision — not resolved by this round, flagged to the owner

Codex's strongest finding (framed as a BUG, treated here as a scope decision rather than an
error to silently fix): the plan validates the "copy `package.json`, `npm install`" path (what
the toolkit's own CI tests) but has never run a clean-room scaffold exercising the PRIMARY
documented path (`npm create astro@latest` + `npm i` the extra packages on top) end-to-end to
directly confirm what real recipients get, rather than inferring it. Whether to add that
clean-room test as a merge gate now versus as a fast-follow is Daniel's call — recorded in the
plan's "Timing decision" section, not decided here.

## Disposition

All 3 BUGs fixed. All 7 RISKs and 3 NITs (of the CONFIRMED/accepted findings) fixed in the plan
file. 4 findings REFUTED with evidence, not silently dropped. 1 finding elevated to an explicit
open decision for the owner rather than resolved unilaterally. No verification round run yet
(the fix is to a planning document, not code — the next real check is whether the executed
upgrade matches this now-corrected plan).
