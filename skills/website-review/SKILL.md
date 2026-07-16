---
name: website-review
description: >
  The Double-Knuth review for a site — a two-pass correctness + cross-file
  consistency audit run at the END of a build (pre-launch) and after ADDING or
  substantially editing a page (the moments cross-file consistency silently
  breaks). Pass 1 = bugs/correctness/Rule-12 (delegates the diff to /code-review);
  Pass 2 = completeness + route/URL/SEO/config/email/docs consistency against the
  site contract. Read-only: returns a ranked BUG/RISK/NIT list with file:line +
  fixes. Prerequisite: website-qa green. Also owns the "review depth" decision
  for website work: this skill (or /code-review alone for a small diff) is the
  free default, sufficient for most changes; a single external reviewer via
  `independent-review` is an owner-approved OPTIONAL extra for genuinely
  higher-stakes changes (site-wide SEO repositioning, payment/checkout flows,
  sensitive-data forms, major redesigns) — never independent-review's own
  default of two reviewers, and never decided silently. Trigger phrases:
  "double-knuth", "double knuth the site", "review the site", "site review",
  "final review before launch", "review this page", "did adding the page break
  anything", "consistency check the site", "audit the site code", "how much
  review does this need", "do I need a second opinion on this", "should I use
  independent-review for this".
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

## Review depth — the owner chooses, every time

A website is lower-stakes than application code: a subtle bug in a landing
page's copy costs a bad reading experience, not a broken payment or a data
leak. This skill (Double-Knuth, below) is free, runs entirely in the current
session, and is **the default, sufficient review for the large majority of
website changes** — new pages, copy edits, layout tweaks, small SEO
adjustments, content updates. An external AI reviewer on top of it is an
*optional* extra, never a requirement, and never more than one at a time.

**Default — no setup, no cost, use this unless there's a specific reason not to:**
- **This skill, both passes** — Pass 1 delegates to `/code-review`
  (correctness bugs), Pass 2 is the cross-file/consistency sweep below.
- **`/code-review` alone** — just Pass 1, for a small, self-contained diff
  where cross-file consistency clearly isn't at risk (a one-page copy fix, a
  single component tweak). Faster than the full two-pass audit when that's
  all the change touches.

**Optional escalation — one external reviewer, only when it's genuinely worth it:**
A handful of website changes carry enough risk that a second, independent
model is worth the extra step: a **site-wide SEO repositioning** (the
`seo-reposition` skill's plan/diff gates), a **payment or checkout flow**, a
form collecting **sensitive personal data**, or a **major structural
redesign** where the author reviewing their own architecture risks sharing
its blind spots. Even for these, use **one** external reviewer, not the
`independent-review` skill's own default of two — that default is calibrated
for production application code (Rails migrations, auth changes), not
website content/structure work:
```bash
# from this repo's skills root, or the equivalent path in a site that has
# independent-review vendored in:
skills/independent-review/scripts/independent_review.sh <file> --plan --first-success   # or --diff
```
`--first-success` stops at the first reviewer that answers (Codex CLI,
falling back to ollama-cloud) instead of running both — independent-review
honors this override for plans, it doesn't force the pair. Setup: if
`independent-review` isn't already working in this repo, its own SKILL.md
has a guided onboarding wizard for getting Codex or ollama-cloud running
(free, no payment) — walk through that first rather than assuming it's ready.
In a scaffolded site the skill isn't shipped at all: check that the
`independent-review` folder actually exists before offering this escalation
as ready-to-run. If it doesn't, either vendor it first (copy
`skills/independent-review/` from the website-builder suite — the same kit
this skill was copied from — into the site's `.claude/skills/`) or frame the
offer honestly as "available after a one-time setup step".

**Explain the choice, then ask — don't decide silently.** Before reaching for
anything beyond this skill's own two passes, say plainly what the options
are and what's actually at stake: *"I can review this with the built-in
check — free, runs now — or also send it to an outside AI for a second
opinion, which costs nothing either but takes a few extra minutes. For
[this kind of change] I'd lean toward
[recommendation] because [reason] — want that, or would you rather [the
other option]?"* The owner decides; this skill's job is to make an informed
recommendation, never to pick unasked.

## Pass 1 — correctness / bugs
- Run **`/code-review`** on the branch/diff (correctness bugs + reuse/simplification).
  `/code-review` is Claude Code-only — under another host, review the diff by
  hand against this pass's checklist, or vendor the generic `double-knuth`
  skill from the website-builder suite.
- `npm run build` is clean — no errors **or warnings**; TS strict passes.
- `npm test` green (a11y/seo/navigation/anchors/orphans/images/tone/positioning/email/links/llms-coverage) — nothing skipped or loosened. (A site scaffolded before a spec existed: copy it in from the starter rather than reviewing without it.)
- `astro preview` the new/edited pages — **no console errors**; interactions work.
- Nothing half-done: no TODO/placeholder/lorem and no leftover `[BRACKET]` slots in shipped
  pages OR `public/` assets (the manifest's fields are brackets too — no spec reads them).
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
- **Language/i18n (non-English or multi-locale sites):** every page's CONTENT language
  matches its `<html lang>` (the tone gate's density check covers German; eyeball other
  languages); `og:locale` present and matching on every page; chrome (skip link, footer)
  in the site's language; German-market sites carry the filled Impressum and the German
  privacy page at the right URL (`/datenschutz` single-locale, `/de/privacy` multilingual);
  multi-locale sites: hreflang sets complete + reciprocal (`tests/i18n.spec.ts` green, or
  the twin-page seo.spec test for the light path), every `/locale` route in PAGES, the
  language switcher on every multi-locale page, llms.txt entries in each page's language.

## Output / done means
A ranked **BUG / RISK / NIT** list, each with `file:line` and a concrete fix (same shape as
the portfolio Double-Knuth). Fix BUGs before launch; RISK/NIT by judgment. Re-run `website-qa`
after fixes. **Done = both passes clean**, or the remaining items explicitly listed — never hidden.
