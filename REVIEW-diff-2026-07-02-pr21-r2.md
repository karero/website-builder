# Independent review trail — DIFF gate, PR #21, round 2 (verification + new findings)

- **Artifact:** `git diff main...docs/no-probe-before-active` incl. fix commit `7531038`.
- **Reviewer:** Antigravity CLI `agy` 1.0.15, **Gemini 3.1 Pro (High)**, `--sandbox -p`,
  throwaway dir. Given the round-1 finding list + the no-politeness instruction.
- **Date:** 2026-07-02.

## Round-1 verdicts

| # | Round-1 finding | Verdict |
|---|-----------------|---------|
| 1 | BUG — `?cb=` as pre-Active verification path | **FIXED** |
| 2 | RISK — dashboard purge implied agent-doable | **FIXED** |
| 3 | NIT — "browser caches for everyone" wording | **FIXED** |

## New findings (both in the round-1-fixed text — healthy convergence)

| # | Sev | Finding | Disposition |
|---|-----|---------|-------------|
| 4 | RISK | Doc says "until the deployment shows Active" but never says HOW to check Active — an agent polling the live domain to "see if it's up" causes the exact cache-poisoning event the section prevents | **Fixed** in `afed8d1` — safe checks named (`wrangler pages deployment list`, `<project>.pages.dev` alias, ask the owner) + "NEVER poll the live custom domain" |
| 5 | NIT | "`?cb=` = distinct cache key" only true under default cache settings ("Ignore Query String" shares the key; still safe post-Active, but the reasoning was overbroad) | **Fixed** in `afed8d1` — scoped with "under default cache settings" |

## Reviewer's CLEAN list (round 2)

Hash-URL / pages.dev-alias / live-domain distinction; contextual depth of the
cached-404 explanation; GSC Request-Indexing warning technically flawless;
recovery flow respects agent limitations.

Round 3 = verification of #4–#5; see `REVIEW-diff-2026-07-02-pr21-r3.md`.
