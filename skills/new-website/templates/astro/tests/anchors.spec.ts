import { test, expect } from '@playwright/test';
import { PAGES } from './_helpers';
import { SITE } from '../src/config';

// Anchor-integrity guard — the COMPLEMENT to navigation.spec.ts. That spec proves
// every internal ROUTE returns 200; this proves the OTHER half of "internal links
// resolve": every "#fragment" actually points at a real element id on its target
// page. A link like "/#section" or "/?tag=x#section" makes the page return 200, so
// navigation.spec is satisfied — but if nothing on the page has id="section", the
// click scrolls nowhere (or to the wrong place). It reads the live DOM, so links
// rendered client-side are covered too. Pure markup + fully offline, so it stays in
// the CI gate; external-link *liveness* deliberately does not (see links.spec.ts +
// the outgoing-link-audit skill).

const stripWww = (h: string) => h.replace(/^www\./, '');
const SITE_HOST = stripWww(new URL(SITE.url).hostname.toLowerCase());

type Ref = { route: string; fragment: string };

// Reduce an href to the in-site { route, fragment } it anchors to, or null when the
// link carries no fragment (navigation.spec's job) or is external / non-navigational.
function anchorRef(href: string, sourceRoute: string): Ref | null {
  if (!href) return null;

  // Same-host absolute URLs are internal too (matches navigation.spec) → relativise.
  if (/^https?:\/\//i.test(href)) {
    try {
      const u = new URL(href);
      if (stripWww(u.hostname.toLowerCase()) !== SITE_HOST) return null;
      href = u.pathname + u.search + u.hash;
    } catch {
      return null;
    }
  }
  if (/^(mailto:|tel:|javascript:|data:|\/\/)/i.test(href)) return null;

  const hi = href.indexOf('#');
  if (hi < 0) return null;                 // no fragment → not our concern
  const fragment = href.slice(hi + 1);
  if (!fragment) return null;              // bare "#" = top-of-page no-op

  let path = href.slice(0, hi);
  const qi = path.indexOf('?');
  if (qi >= 0) path = path.slice(0, qi);

  let route: string;
  if (path === '') route = sourceRoute;                 // same-page "#x" / "?q#x"
  else if (path.startsWith('/')) route = path.replace(/\/+$/, '') || '/';
  else return null;                                     // bare-relative → skip
  return { route, fragment };
}

test('every internal #anchor points at a real element id', async ({ page, request }) => {
  // 1) Collect every in-site anchor link across all pages.
  const found: { from: string; href: string; ref: Ref }[] = [];
  for (const path of PAGES) {
    const route = path.replace(/\/+$/, '') || '/';
    await page.goto(path, { waitUntil: 'load' });
    const hrefs = await page
      .locator('a[href]')
      .evaluateAll((as) => as.map((a) => (a as HTMLAnchorElement).getAttribute('href') ?? ''));
    for (const href of hrefs) {
      const ref = anchorRef(href, route);
      if (ref) found.push({ from: route, href, ref });
    }
  }

  // 2) Fetch each referenced page once; index the element ids it exposes.
  const idsByRoute = new Map<string, Set<string> | null>();
  for (const route of new Set(found.map((f) => f.ref.route))) {
    const r = await request.get(route);
    if (!r.ok()) {
      idsByRoute.set(route, null);
      continue;
    }
    const html = await r.text();
    const ids = new Set<string>();
    for (const m of html.matchAll(/\sid="([^"]+)"/g)) ids.add(m[1]);
    idsByRoute.set(route, ids);
  }

  // 3) Every fragment must exist on its target page.
  const problems: string[] = [];
  for (const { from, href, ref } of found) {
    const ids = idsByRoute.get(ref.route);
    if (ids == null) {
      problems.push(`[${from}] ${href} → target page "${ref.route}" did not load (404)`);
      continue;
    }
    if (!ids.has(ref.fragment)) {
      problems.push(`[${from}] ${href} → no element with id="${ref.fragment}" on "${ref.route}"`);
    }
  }
  expect(problems, `dead internal anchor(s):\n${problems.join('\n')}`).toEqual([]);
});
