import { test, expect } from '@playwright/test';
import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { PAGES } from './_helpers';
import { SITE } from '../src/config';

// llms.txt coverage guard. public/llms.txt is the curated GEO / AI-answer-engine
// page map — and it is hand-maintained, so it drifts: a page gets registered in
// PAGES, nav and the sitemap but never added here. That exact slip happened FOUR
// times on a real site built with this kit (2026-06/07), each time caught only by
// a human review — attention wasn't the problem, the workflow was, so the fix is
// a test, not a checklist line. This makes both mechanical halves of the defect
// checkable: a MISSING entry (page added, never listed) and a STALE one (page
// removed/renamed, entry lingers). The third half — an entry whose WORDING has
// drifted from the page — is not mechanically checkable and stays a
// website-review Pass-2 / website-seo-geo judgment item.

// Pages you DELIBERATELY keep out of the public AI index (a paid-ad landing page,
// a print-QR page — typically the same routes as orphans.spec's ORPHAN_EXEMPT).
// llms.txt is served publicly, so listing a hidden page would hand it to AI
// answer engines and defeat the unlinking. Opt OUT explicitly with a reason
// rather than loosen the test (Rule 12).
const LLMS_EXEMPT = new Set<string>([
  // '/lp/spring-promo',  // paid-ad landing page — deliberately not in the AI index
]);

// SITE.url ships without a trailing slash by convention (src/config.ts), but
// normalize anyway — a config edit must not turn every expected URL into a
// double-slash mismatch.
const base = SITE.url.replace(/\/+$/, '');
const llmsTxt = () => readFileSync(join(process.cwd(), 'public', 'llms.txt'), 'utf8');
const toUrl = (route: string) => (route === '/' ? `${base}/` : `${base}${route}`);

test('every PAGES route is listed in public/llms.txt', () => {
  const txt = llmsTxt();
  // `](URL)` pins a markdown link TARGET — a bare URL in prose does not count.
  const missing = PAGES.filter(
    (route) => !LLMS_EXEMPT.has(route) && !txt.includes(`](${toUrl(route)})`),
  );
  expect(
    missing,
    `routes missing from public/llms.txt (add a "- [Title](URL): description" line):\n  ` +
      missing.join('\n  '),
  ).toEqual([]);
});

// The reverse guard: every same-site page link in llms.txt must map back to a
// PAGES route, so a removed or renamed page cannot linger as a stale entry (the
// missing-entry check above structurally cannot see that half). Links to hosted
// assets (/whitepaper.pdf) are not pages and are skipped.
test('no stale llms.txt entry — every same-site page link is a PAGES route', () => {
  const known = new Set<string>(PAGES);
  const linked = [...llmsTxt().matchAll(/\]\((https?:\/\/[^)#\s]+)/g)].map((m) => m[1]);
  const stale = [
    ...new Set(
      linked
        .filter((u) => u === base || u.startsWith(`${base}/`))
        .map((u) => {
          const path = u.slice(base.length).replace(/\/$/, '');
          return path === '' ? '/' : path;
        })
        .filter((p) => !/\.[a-z0-9]+$/i.test(p)) // asset link (.pdf, .png), not a page
        .filter((p) => !known.has(p)),
    ),
  ];
  expect(
    stale,
    `stale llms.txt entries — same-site links to routes not in PAGES (page removed or renamed?):\n  ` +
      stale.join('\n  '),
  ).toEqual([]);
});
