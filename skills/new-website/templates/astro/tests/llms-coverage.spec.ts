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
// a test, not a checklist line. This makes the MISSING-entry half of the defect
// mechanical: every crawlable route must appear in llms.txt as its full
// production URL. (The other half — an entry whose WORDING has drifted from the
// page — is not mechanically checkable and stays a website-review Pass-2 /
// website-seo-geo judgment item.)
test('every PAGES route is listed in public/llms.txt', () => {
  const txt = readFileSync(join(process.cwd(), 'public', 'llms.txt'), 'utf8');
  const missing = PAGES.filter((route) => {
    const url = route === '/' ? `${SITE.url}/` : `${SITE.url}${route}`;
    return !txt.includes(`(${url})`);
  });
  expect(
    missing,
    `routes missing from public/llms.txt (add a "- [Title](URL): description" line):\n  ` +
      missing.join('\n  '),
  ).toEqual([]);
});
