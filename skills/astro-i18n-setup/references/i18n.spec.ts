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
        // SITE.url + '/' (not bare SITE.url) so a lookalike origin or a slash-less
        // join like "https://example.comabout" can't sneak through.
        expect(a.href.startsWith(SITE.url + '/'), `${path}: alternate "${a.hreflang}" href must be the absolute production URL (${a.href})`).toBe(true);
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
        // Every locale alternate must resolve to a page in PAGES — otherwise that
        // locale's pages were never built/listed and its reciprocity goes unchecked
        // (the exact "A links B, B never links back" mistake this file exists to catch).
        expect(target, `${path}: alternate "${a.hreflang}" → ${a.href} has no matching page in PAGES — build + list every locale's routes`).toBeDefined();
        const back = seen.get(target!)!.alts.find((x) => x.hreflang === selfLocale);
        expect(back?.href, `${target} must link back to ${path} under hreflang="${selfLocale}"`).toBe(url);
      }
    }
  });

  test('translated pages are not thin — body content roughly matches the default-locale original', async ({ page }) => {
    // Reverse lookup: production URL -> PAGES path (mirrors the reciprocity check's urlToPath
    // above), so a page's own default-locale hreflang href can be resolved back to a page we
    // can navigate to and compare against.
    const urlToPath = new Map(PAGES.map((p) => [urlFor(p), p]));

    const countWords = async () =>
      page
        .evaluate(() => document.body.innerText)
        .then((text) => text.trim().split(/\s+/).filter(Boolean).length);

    for (const path of PAGES) {
      if (localeOf(path) === DEFAULT_LOCALE) continue;

      await page.goto(path);
      const defaultHref = await page
        .locator(`link[rel="alternate"][hreflang="${DEFAULT_LOCALE}"]`)
        .getAttribute('href');
      const originalPath = defaultHref ? urlToPath.get(defaultHref) : undefined;
      expect(
        originalPath,
        `${path}: default-locale ("${DEFAULT_LOCALE}") alternate href "${defaultHref}" has no matching page in PAGES`,
      ).toBeDefined();

      const translatedWords = await countWords();

      await page.goto(originalPath!);
      const originalWords = await countWords();

      // Divide-by-zero guard: an empty original has nothing to be "thinner" than.
      const ratio = originalWords === 0 ? 1 : translatedWords / originalWords;

      expect(
        ratio,
        `${path} (${translatedWords} words) looks like a partial translation of its default-locale ` +
          `original ${originalPath} (${originalWords} words) — only ${(ratio * 100).toFixed(0)}% as much ` +
          `content. Translate the whole page, not just the chrome: partial translation reads as thin/duplicate ` +
          `content. Google's own guidance: "Translating only the boilerplate text of your pages while keeping ` +
          `the bulk of your content in a single language...can create a bad user experience" ` +
          `(seo-audit/references/international-seo.md, "Partial Translation").`,
      ).toBeGreaterThanOrEqual(0.4);
    }
  });
});
