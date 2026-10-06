import { test, expect } from '@playwright/test';
import { PAGES } from './_helpers';
import { emailHint } from '../src/lib/obfuscate';

// Anti-harvest guardrail: the SERVED HTML of every page must contain no plaintext
// email address and no `mailto:` link. Addresses go through <EmailLink>, which
// obfuscates at build time and reassembles the mailto in the browser (the decode
// logic lives in an external bundle, not the page HTML). Catches an accidental raw
// address before scrapers do. Fetches the raw HTML (no JS), which is what a bot sees.
// The bare string "mailto:" from EmailLink's reassembly script is fine — it carries
// no address; we flag a harvestable ADDRESS (including one inside a mailto: link).
// The negative lookahead skips asset-style names like "team@2x.webp" (an image
// filename, not an address) — a real TLD is never an image/asset extension.
const EMAIL = /[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.(?!(?:png|jpe?g|gif|webp|avif|svg|ico|css|js|mjs|json|xml|txt|woff2?)\b)[A-Za-z]{2,}/;

for (const path of PAGES) {
  test(`email — ${path} ships no harvestable address`, async ({ request, baseURL }) => {
    const html = await (await request.get(new URL(path, baseURL!).href)).text();
    const m = html.match(EMAIL);
    expect(m?.[0] ?? null, `${path} ships a plaintext email "${m?.[0]}" — use <EmailLink>`).toBeNull();
  });
}

// The no-JS hint speaks the language of the page it is on, not the site's: the
// German Impressum on an English site must say "[punkt]", not "[dot]". Runs with
// JavaScript off, as a no-JS visitor sees it (with JS on, the decode script swaps
// the hint for the address). Each hint is rebuilt from its encoded address and
// the page's <html lang>; links with their own `text` (no "[at]") are skipped.
test.describe('without JavaScript', () => {
  test.use({ javaScriptEnabled: false });
  for (const path of PAGES) {
    test(`email — ${path} hints use the page's language`, async ({ page }) => {
      await page.goto(path);
      const lang = (await page.locator('html').getAttribute('lang')) ?? '';
      const links = await page.locator('a.email-link[data-email]').evaluateAll((els) =>
        els.map((a) => ({ data: (a as HTMLElement).dataset.email!, text: a.textContent ?? '' })));
      for (const { data, text } of links.filter((l) => l.text.includes('[at]'))) {
        const address = Buffer.from(data, 'base64').toString('utf-8').split('').reverse().join('');
        expect(text, `${path} (<html lang="${lang}">) shows the hint in another language`).toBe(emailHint(address, lang));
      }
    });
  }
});
