import { test, expect } from '@playwright/test';
import { PAGES } from './_helpers';
import { SITE, LOCALES, DEFAULT_LOCALE } from '../src/config';

// hreflang contract for a multi-locale site (the gap seo.spec.ts does NOT cover).
// Drop this file into tests/ when astro-i18n-setup runs. Hermetic: it navigates the
// preview server only (no external network), reads the <head>, and checks the
// cross-locale invariants Google actually enforces — see
// seo-audit/references/international-seo.md for the WHY behind each.
//
// Invariants asserted:
//   • completeness — every page lists ONE alternate per locale + exactly one x-default
//   • absolute     — every alternate href is the production URL (SITE.url + path)
//   • self-canonical — the page's <link rel=canonical> equals its OWN-locale alternate
//   • x-default    — points at the default-locale variant of the page
//   • reciprocity  — if page A (locale x) links B as its locale-y alternate, then B
//                    links A back as its locale-x alternate (the #1 hreflang mistake)

// URL for a route, matching Base.astro's canonical/alternate output: root keeps its
// trailing slash, every other path has none (trailingSlash:'never').
const urlFor = (path: string) => (path === '/' ? `${SITE.url}/` : `${SITE.url}${path}`);

// The locale a route belongs to: the prefix segment if it is a non-default locale,
// else the default locale (clean-default routing — '/', '/about' are the default).
const localeOf = (path: string) =>
  LOCALES.find((l) => l !== DEFAULT_LOCALE && (path === `/${l}` || path.startsWith(`/${l}/`))) ??
  DEFAULT_LOCALE;

const EXPECTED_CODES = [...LOCALES, 'x-default'].sort();

test.describe('i18n — hreflang contract', () => {
  // Single-locale sites have no hreflang to check (astro-i18n-setup only runs for 2+).
  test.skip(LOCALES.length < 2, 'single-locale site — no hreflang contract');

  test('hreflang set is complete, absolute, self-canonical, and reciprocal', async ({ page }) => {
    type Alt = { hreflang: string; href: string };
    const seen = new Map<string, { alts: Alt[]; canonical: string | null; url: string }>();

    for (const path of PAGES) {
      await page.goto(path);
      const alts: Alt[] = await page.$$eval('link[rel="alternate"][hreflang]', (els) =>
        els.map((e) => ({ hreflang: e.getAttribute('hreflang') || '', href: e.getAttribute('href') || '' })),
      );
      const canonical = await page.locator('link[rel="canonical"]').getAttribute('href');
      seen.set(path, { alts, canonical, url: urlFor(path) });
    }

    // Per-page: completeness + absolute hrefs + self-canonical + correct x-default.
    for (const [path, { alts, canonical }] of seen) {
      expect(
        alts.map((a) => a.hreflang).sort(),
        `${path}: hreflang set must be every locale + x-default`,
      ).toEqual(EXPECTED_CODES);

      for (const a of alts) {
        expect(a.href.startsWith(SITE.url), `${path}: alternate "${a.hreflang}" href must be absolute (${a.href})`).toBe(true);
      }

      const selfLocale = localeOf(path);
      const selfAlt = alts.find((a) => a.hreflang === selfLocale);
      expect(canonical, `${path}: canonical must equal its own-locale alternate`).toBe(selfAlt?.href);

      const xDefault = alts.find((a) => a.hreflang === 'x-default');
      const defaultAlt = alts.find((a) => a.hreflang === DEFAULT_LOCALE);
      expect(xDefault?.href, `${path}: x-default must point at the default-locale variant`).toBe(defaultAlt?.href);
    }

    // Cross-page: reciprocity. For each alternate that targets a page we know,
    // that page must link back to this one under this page's locale.
    const urlToPath = new Map([...seen].map(([p, v]) => [v.url, p]));
    for (const [path, { alts, url }] of seen) {
      const selfLocale = localeOf(path);
      for (const a of alts) {
        if (a.hreflang === 'x-default') continue;
        const target = urlToPath.get(a.href);
        if (!target) continue; // alternate outside PAGES (e.g. an unbuilt locale) — skip
        const back = seen.get(target)!.alts.find((x) => x.hreflang === selfLocale);
        expect(back?.href, `${target} must link back to ${path} under hreflang="${selfLocale}"`).toBe(url);
      }
    }
  });
});
