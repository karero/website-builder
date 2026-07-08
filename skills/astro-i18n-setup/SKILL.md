---
name: astro-i18n-setup
description: >
  Turn a new-website scaffold into a turnkey multi-language site: Astro i18n
  routing (clean default locale + prefixed others), self-referencing hreflang +
  x-default in the Base layout, i18n sitemap alternates, a language switcher, and
  the test-harness changes that keep the green-from-commit-1 gate honest across
  locales. Run at scaffold time when new-website Q4 = "two+ languages at launch", OR
  later to add a second language to a single-locale site whose default stays unprefixed
  (phased rollout). Trigger phrases: "multi-language site", "add i18n", "DE+EN site",
  "internationalization", "hreflang setup", "two languages at launch".
---

# Astro i18n setup (scaffold-time, opt-in)

Wires turnkey internationalization into the `new-website` Astro overlay. **Opt-in:**
the default scaffold stays single-locale. Run it either **at scaffold time** for a
2+-language launch (new-website §1 Q4), **or later** when you add a second language to
an existing single-locale site — see **Phased rollout** below.

Safe vs unsafe: because the default locale stays **unprefixed** (`/`, not `/en/`), adding
a *secondary* prefixed locale (`/de/…`) is purely additive — it never moves an existing
URL. What DOES break links/SEO is moving the **default locale itself** off `/` (e.g.
retrofitting `/` → `/en/`); this skill never does that, so keep `prefixDefaultLocale:
false`. A full re-prefixing of the default is a migration, not this skill.

Routing model (house default): **clean default locale, prefixed others** —
`/` and `/about` are the default language (marked `x-default`); other languages get
a prefix (`/de/`, `/de/about`). `prefixDefaultLocale: false`. This keeps the
default-locale URLs identical to a single-locale build, so nothing regresses.

Deep SEO rules (reciprocity, x-default, canonical-vs-hreflang, sitemap structure,
"translate the whole page not just chrome") live in
`seo-audit/references/international-seo.md` — read it, don't re-derive it.

## Phased rollout (primary language first, translate later)

You don't have to translate everything before launch. Because the default locale is
unprefixed, you can build and ship the **primary language first**, then add the second
locale when the translations are ready — without moving a single existing URL:

1. **Phase 1 — primary only.** Build the site in the default language and ship it. Keep
   `LOCALES = [DEFAULT_LOCALE]` (one entry). `tests/i18n.spec.ts` **self-skips** while
   there's a single locale (`LOCALES.length < 2`), so the full QA gate is green with no
   half-built hreflang. You can skip this skill entirely for now, or apply it with a
   single-locale `LOCALES` to pre-wire the layout.
2. **Phase 2 — add the locale.** When translating, apply this skill's changes: add the new
   locale to `astro.config` `i18n.locales`, the `sitemap({ i18n })` map, and `LOCALES`;
   create the `src/pages/<locale>/…` pages. hreflang, `x-default`, sitemap alternates and
   `i18n.spec.ts` now enforce both locales — and the default-language URLs are exactly what
   they were in Phase 1.

The one rule: commit to an **unprefixed default** from day 1 (`prefixDefaultLocale:
false`). That's the only decision that's expensive to change later; the translations
themselves are always additive.

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
Remove `SITE.locale` — and the matching `lang = SITE.locale` default prop in
`Base.astro` (line ~28): the layout derives the locale from `Astro.currentLocale` now
(step 3), so leaving that default referencing the deleted export breaks the build.
Everything reads `DEFAULT_LOCALE` / `Astro.currentLocale`.

### 3. `src/layouts/Base.astro` — locale-aware (VERIFIED build output)
Add the imports + derive locale/alternates, set `<html lang>` from the current
locale, and emit self-referencing hreflang + `x-default`. Build and confirm the output
(reciprocal hreflang, and clean trailing slashes under `trailingSlash: 'never'`):
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
// getRelativeLocaleUrl() expects a bare path segment (or none for the locale root) — NOT a
// leading-slash path — or it can drift the trailing slash under trailingSlash: 'never'.
const localePath = neutral === '/' ? undefined : neutral.replace(/^\//, '');
const alternates = LOCALES.map((loc) => ({ loc, href: new URL(getRelativeLocaleUrl(loc, localePath), site).href }));
const xDefault = new URL(getRelativeLocaleUrl(DEFAULT_LOCALE, localePath), site).href;
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
`getRelativeLocaleUrl(loc, localePath)` it computes from `Astro.url`/`Astro.currentLocale`,
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
**reciprocity** (A→B implies B→A — the #1 hreflang mistake). It also machine-checks the
"translate the whole page" rule below, in two parts (word-count thinness and wrong-language
body are different failure modes — one check can't catch both):
- **Stub/thin translation**: for every non-default-locale page it follows its own
  default-locale hreflang alternate back to the original, counts words in both via
  `document.body.innerText`, and fails if the translated page has under 40% as many words —
  catching a dramatically shorter placeholder page.
- **Wrong-language body** (German only): word count can't tell a same-length body that's
  still in the original language from a real translation — nav/footer translated, body left
  untranslated, and the ratio check above passes clean since nothing got shorter. For pages
  whose locale is literally `de`, a second check counts common German function words
  (der/die/das/und/ist/…) and fails if their density is near zero — real German prose runs
  ~15–20%, a non-German body runs ~0%.

Both self-skip on a single-locale site (the loop has nothing to iterate). The matching
`<xhtml:link>` sitemap alternates come from the `sitemap({ i18n })` config above — confirm
them by inspecting `dist/sitemap-0.xml`.

### `tests/positioning.spec.ts` — key per locale
Add a `POSITIONING` row per locale path (`'/de/about': { term: '…DE term…' }`); the
positioning term is translated, so each locale owns its own phrase.

`tests/tone.spec.ts` already branches on `<html lang>`: universal rules (the em-dash ban)
always apply, and English-specific rules layer on top for `lang` starting `en`, German-
specific rules layer on top for `lang` starting `de` — other languages get only the
universal rules. No change needed.

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
