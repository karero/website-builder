---
name: website-review
description: >
  The Double-Knuth review for a site — a two-pass correctness + cross-file
  consistency audit run at the END of a build (pre-launch) and after ADDING or
  substantially editing a page (the moments cross-file consistency silently
  breaks). Pass 1 = bugs/correctness/Rule-12 (delegates the diff to /code-review);
  Pass 2 = completeness + route/URL/SEO/config/email/docs consistency against the
  site contract. Read-only: returns a ranked BUG/RISK/NIT list with file:line +
  fixes. Prerequisite: website-qa green. Trigger phrases: "double-knuth",
  "double knuth the site", "review the site", "site review", "final review before
  launch", "review this page", "did adding the page break anything", "consistency
  check the site", "audit the site code".
---

# Website review — Double-Knuth (correctness + consistency)

A two-pass audit of a site's code/config/content, modelled on the
`portfolio-code-reviewer` Double-Knuth. It sits **on top of `website-qa`**: the
tests are the floor (must be green first); this is the human-grade review that
catches what a test suite can't — cross-file drift and half-done work.

## When to run
- **End of a build, before launch** (pipeline step 8).
- **After adding or substantially editing a page** — a new route touches `PAGES`,
  nav, the sitemap, internal links and canonical, so consistency can silently break.
- It is **read-only**: produce a ranked list, then fix BUGs before launch. Don't
  fix-and-forget — surface first (Rule 12: never hide a skipped or broken thing).

## Pass 1 — correctness / bugs
- Run **`/code-review`** on the branch/diff (correctness bugs + reuse/simplification).
- `npm run build` is clean — no errors **or warnings**; TS strict passes.
- `npm test` green (a11y/seo/navigation/anchors/orphans/images/tone/positioning/email/links/llms-coverage) — nothing skipped or loosened. (A site scaffolded before a spec existed: copy it in from the starter rather than reviewing without it.)
- `astro preview` the new/edited pages — **no console errors**; interactions work.
- Nothing half-done: no TODO/placeholder/lorem and no leftover `[BRACKET]` slots in shipped pages.
- Nothing silently unshipped (two-stage sites): `git log origin/production..origin/main` empty,
  or the gap is a conscious decision — and the last `npm run ship` ended "✓ LIVE — verified".

## Pass 2 — completeness + cross-file/skill consistency
- **Routes:** every `src/pages/**` route is in `tests/_helpers.ts` `PAGES` (and vice-versa;
  seo.spec.ts's sitemap drift alarm enforces it); nav + every internal link points to a real
  route; every route is reachable via at least one inbound internal link (no orphan pages —
  the privacy page included).
- **URLs:** the no-trailing-slash convention holds everywhere (`/about`, not `/about/`);
  `canonical == og:url == SITE.url + path`.
- **Single source of truth:** address, email, phone, nav come **only** from `src/config.ts` —
  no hardcoded copies drifting inside pages.
- **SEO (`website-seo-geo`):** title ≤60, description 120–160, og/twitter mirror, exactly one
  `<h1>`, JSON-LD valid, sitemap covers every page, `llms.txt` current.
- **Images (`website-design-system`):** WebP/AVIF, explicit `width`/`height`, `alt`; the LCP
  image eager (`fetchpriority="high"`), below-fold lazy; no oversized files.
- **Email:** every address rendered via `<EmailLink>`; `email.spec.ts` green.
- **Headers/redirects:** `_headers` CSP present; legacy URLs 301 in `_redirects`; the
  `*.pages.dev` preview-noindex middleware in place.
- **Secrets:** no `.env`/token committed; `.gitignore` covers them.
- **Docs match code:** README test list + "how to add a page / run tests / deploy" current;
  `CONTENT_GUIDE.md` + `BRAND.md` filled; decision-interview answers recorded; the handoff
  skill set present in `.claude/skills/`.

## Output / done means
A ranked **BUG / RISK / NIT** list, each with `file:line` and a concrete fix (same shape as
the portfolio Double-Knuth). Fix BUGs before launch; RISK/NIT by judgment. Re-run `website-qa`
after fixes. **Done = both passes clean**, or the remaining items explicitly listed — never hidden.
