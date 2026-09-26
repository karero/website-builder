import { test, expect } from '@playwright/test';
import { onRequest } from '../functions/_middleware';
import { SITE } from '../src/config';

// functions/_middleware.ts decides which hosts Google and AI engines may treat as the
// site. `astro preview` never runs it (it is a Cloudflare Pages Function), so these tests
// call onRequest directly the way Cloudflare does: a request, the env, and next() for
// the static page behind it. Why each case matters is in its title.

const PROJECT = 'my-site'; // any project name — the rule is about the host's shape
const BODY = '<!doctype html><title>page</title>';

async function serve(url: string, env: { CANONICAL_URL?: string } = {}) {
  let served = false;
  const res = await onRequest({
    request: new Request(url),
    env,
    next: async () => {
      served = true;
      return new Response(BODY, { status: 200, headers: { 'content-type': 'text/html' } });
    },
  });
  return { res, served };
}

test('before launch (CANONICAL_URL unset) the production alias still serves the site, noindexed', async () => {
  // Pre-launch the alias may be the ONLY working address — a redirect to a domain that
  // is not attached yet, or still shows an old site, would strand visitors.
  const { res, served } = await serve(`https://${PROJECT}.pages.dev/about`);
  expect(served).toBe(true);
  expect(res.status).toBe(200);
  expect(res.headers.get('x-robots-tag')).toBe('noindex, nofollow');
  expect(await res.text()).toBe(BODY);
});

test('after launch the production alias 301s to the live domain, keeping path and query', async () => {
  // noindex did not stop AI search engines citing <project>.pages.dev; a permanent
  // redirect moves both visitors and citations to the real domain.
  const { res, served } = await serve(`https://${PROJECT}.pages.dev/about?ref=ai`, {
    CANONICAL_URL: SITE.url,
  });
  expect(served).toBe(false);
  expect(res.status).toBe(301);
  expect(res.headers.get('location')).toBe(`${new URL(SITE.url).origin}/about?ref=ai`);
});

for (const preview of [`main.${PROJECT}.pages.dev`, `3f9a1c2e.${PROJECT}.pages.dev`]) {
  test(`after launch the preview ${preview} still serves, noindexed — not redirected`, async () => {
    // Previews are where the owner checks a change before `npm run ship`; redirecting
    // them to the live domain would hide exactly the build they need to see.
    const { res, served } = await serve(`https://${preview}/`, { CANONICAL_URL: SITE.url });
    expect(served).toBe(true);
    expect(res.status).toBe(200);
    expect(res.headers.get('x-robots-tag')).toBe('noindex, nofollow');
  });
}

test('the live domain is served unchanged — no redirect, no noindex', async () => {
  const { res, served } = await serve(`${SITE.url}/about`, { CANONICAL_URL: SITE.url });
  expect(served).toBe(true);
  expect(res.status).toBe(200);
  expect(res.headers.get('x-robots-tag')).toBeNull();
});

for (const bad of [`https://${PROJECT}.pages.dev`, 'http://example.com', 'example.com']) {
  test(`a CANONICAL_URL of "${bad}" is ignored, never a redirect loop or downgrade`, async () => {
    // A pages.dev value would redirect the alias to itself; plain http or a bare host is
    // a typo. Failing safe keeps the pre-launch behaviour instead of breaking the site.
    const { res, served } = await serve(`https://${PROJECT}.pages.dev/`, { CANONICAL_URL: bad });
    expect(served).toBe(true);
    expect(res.headers.get('x-robots-tag')).toBe('noindex, nofollow');
  });
}
