---
name: astro-i18n-setup
description: >
  Turn a new-website scaffold into a turnkey multi-language site: Astro i18n
  routing (clean default locale + prefixed others), self-referencing hreflang +
  x-default in the Base layout, i18n sitemap alternates, a language switcher, and
  the test-harness changes that keep the green-from-commit-1 gate honest across
  locales. Run ONCE, at scaffold time, when new-website Q4 = "two+ languages at
  launch". Trigger phrases: "multi-language site", "add i18n", "DE+EN site",
  "internationalization", "hreflang setup", "two languages at launch".
---

# Astro i18n setup (scaffold-time, opt-in)

Wires turnkey internationalization into the `new-website` Astro overlay. **Opt-in:**
the default scaffold stays single-locale; run this only when the site ships **2+
languages at launch** (new-website §1 Q4). Retrofitting an existing single-locale
site is OUT of scope — changing URL structure after launch breaks links and SEO
(Astro's own warning); for that, plan a full migration, not this skill.

Routing model (house default): **clean default locale, prefixed others** —
`/` and `/about` are the default language (marked `x-default`); other languages get
a prefix (`/de/`, `/de/about`). `prefixDefaultLocale: false`. This keeps the
default-locale URLs identical to a single-locale build, so nothing regresses.

Deep SEO rules (reciprocity, x-default, canonical-vs-hreflang, sitemap structure,
"translate the whole page not just chrome") live in
`seo-audit/references/international-seo.md` — read it, don't re-derive it.

## What it changes

### 1. `astro.config.mjs` — i18n routing + sitemap alternates
```js
export default defineConfig({
  site: 'https://example.com',
  trailingSlash: 'never',
  build: { format: 'file', inlineStylesheets: 'always' },
  i18n: {
    defaultLocale: 'en',
    locales: ['en', 'de'],                 // ← the launch locales
    routing: { prefixDefaultLocale: false },
  },
  integrations: [
    // The i18n map makes @astrojs/sitemap emit <xhtml:link> hreflang alternates.
    sitemap({ i18n: { defaultLocale: 'en', locales: { en: 'en', de: 'de' } }, changefreq: 'monthly', priority: 0.7 }),
  ],
});
```

### 2. `src/config.ts` — replace the single locale
```ts
// was: locale: 'en'  inside SITE
export const LOCALES = ['en', 'de'] as const;        // keep in sync with astro.config i18n.locales
export const DEFAULT_LOCALE = 'en';
export const LOCALE_LABELS: Record<string, string> = { en: 'English', de: 'Deutsch' };
```
Remove `SITE.locale`; everything reads `DEFAULT_LOCALE` / `Astro.currentLocale` now.

### 3. `src/layouts/Base.astro` — locale-aware (VERIFIED build output)
Add the imports + derive locale/alternates, set `<html lang>` from the current
locale, and emit self-referencing hreflang + `x-default`. This exact code was
built and its output checked (reciprocal hreflang, correct trailing slashes):
```astro
---
import { getRelativeLocaleUrl } from 'astro:i18n';
import { SITE, LOCALES, DEFAULT_LOCALE /* … */ } from '../config';
// … existing title/description/image props …

const site = Astro.site ?? new URL(SITE.url);
// clean URL: drop index.html + .html, strip trailing slash except root
let cleanPath = Astro.url.pathname.replace(/\/index\.html$/, '/').replace(/\.html$/, '');
if (cleanPath !== '/' && cleanPath.endsWith('/')) cleanPath = cleanPath.slice(0, -1);
const canonical = new URL(cleanPath, site).href;

const currentLocale = Astro.currentLocale ?? DEFAULT_LOCALE;
let neutral = cleanPath;
if (currentLocale !== DEFAULT_LOCALE) {
  neutral = cleanPath.replace(new RegExp('^/' + currentLocale + '(?=/|$)'), '');
}
if (neutral === '') neutral = '/';
const alternates = LOCALES.map((loc) => ({ loc, href: new URL(getRelativeLocaleUrl(loc, neutral), site).href }));
const xDefault = new URL(getRelativeLocaleUrl(DEFAULT_LOCALE, neutral), site).href;
---
<html lang={currentLocale}>
  <head>
    …
    <link rel="canonical" href={canonical} />
    {alternates.map((a) => <link rel="alternate" hreflang={a.loc} href={a.href} />)}
    <link rel="alternate" hreflang="x-default" href={xDefault} />
    …
  </head>
```
Keep the existing `OG_LOCALES`/`ogLocale` block (it already maps `lang → og:locale`);
optionally add `og:locale:alternate` for the non-current locales. `inLanguage` in the
WebPage/WebSite schema should use `currentLocale`.

### 4. `src/components/LanguageSwitcher.astro` (new)
A small nav control that links the **current page** in each locale, using the same
`getRelativeLocaleUrl(loc, neutral)` it computes from `Astro.url`/`Astro.currentLocale`,
labelled from `LOCALE_LABELS`, marking the active one `aria-current="true"`.

### 5. Page/content structure
- Default-locale pages stay at `src/pages/*` (e.g. `src/pages/about.astro` → `/about`).
- Each other locale lives under `src/pages/<locale>/*` (e.g. `src/pages/de/about.astro` → `/de/about`).
- With Content Collections, add a `locale` field (or per-locale entry dirs) and render
  locale routes from it. **Translate the whole page**, not just the chrome — partial
  translation reads as thin/duplicate (international-seo.md).

### 6. `public/llms.txt` — keep ONE unified file
List the key pages across all locales in a single `/llms.txt` (do not split per locale).

## Test-harness changes (the part that keeps the gate honest)

### `tests/_helpers.ts` — generate PAGES per locale
```ts
import { LOCALES, DEFAULT_LOCALE } from '../src/config';
const BASE = ['/', '/privacy'] as const;          // locale-neutral paths
export const PAGES = LOCALES.flatMap((loc) =>
  BASE.map((p) =>
    loc === DEFAULT_LOCALE ? p : (p === '/' ? `/${loc}` : `/${loc}${p}`),
  ),
) as readonly string[];
```
This yields `/`, `/privacy`, `/de`, `/de/privacy`. `seo.spec.ts`'s canonical check
(`canonical === SITE.url + path`) and the sitemap-drift test then pass unchanged,
because the i18n sitemap still emits one `<loc>` per page (alternates are
`<xhtml:link>`, not extra `<loc>`s).

### `tests/i18n.spec.ts` (new) — hreflang contract
Drop in the ready spec `references/i18n.spec.ts` (copy it to the project's `tests/`).
For every page in PAGES it asserts: exactly one `<link hreflang>` per locale in `LOCALES`
**plus** `x-default`; every href is the absolute production URL; the page's canonical
equals its OWN-locale alternate; `x-default` → the default-locale variant; and cross-page
**reciprocity** (A→B implies B→A — the #1 hreflang mistake). It self-skips on a
single-locale site. The matching `<xhtml:link>` sitemap alternates come from the
`sitemap({ i18n })` config above — confirm them by inspecting `dist/sitemap-0.xml`.

### `tests/positioning.spec.ts` — key per locale
Add a `POSITIONING` row per locale path (`'/de/about': { term: '…DE term…' }`); the
positioning term is translated, so each locale owns its own phrase.

`tests/tone.spec.ts` already branches on `<html lang>` (English rules only fire for
`lang` starting `en`) — no change needed.

## Wiring (done once in the suite)
- `new-website/SKILL.md` §1 Q4 → "if 2+ languages: run `astro-i18n-setup`"; add the
  skill to the §3 bundled-skills copy list (so multilingual handoffs are self-contained).
- `references/WEBSITE_ARCHITECTURE.md` Part 7 → point at this skill.

## Verify (scaffold a throwaway 2-locale site in /tmp)
```
npm run build
# dist/ has /index.html + /de.html (served /de) + nested /de/<page>.html
grep -o 'hreflang="[^"]*"' dist/index.html      # en, de, x-default present & reciprocal
grep -c '<xhtml:link' dist/sitemap-0.xml        # alternates present
npm test                                        # green, INCLUDING tests/i18n.spec.ts
```
Confirm: every page self-references + lists all locales + `x-default`; default-locale
URLs are unchanged from a single-locale build; trailing slashes are consistent
(`/` keeps its slash, `/de` and sub-pages have none).
