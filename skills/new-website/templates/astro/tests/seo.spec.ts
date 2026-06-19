import { test, expect } from '@playwright/test';
import { PAGES } from './_helpers';
import { SITE } from '../src/config';
import { readdirSync, readFileSync } from 'node:fs';
import { join } from 'node:path';

// SEO contract + tag-consistency guardrail. Base.astro derives <title>, OG,
// Twitter, canonical and the WebPage schema from a single (title, description)
// pair plus the URL path, so they MUST stay in lockstep. Read via the DOM, not
// raw HTML: the browser decodes entities, so a title with "&" compares equal —
// we test the value the way a crawler sees it.

// Limits — keep in sync with the website-seo-geo skill (120 is a hard floor).
const TITLE_MAX = 60, DESC_MAX = 160, DESC_MIN = 120;

async function meta(page: import('@playwright/test').Page, sel: string) {
  return page.locator(sel).getAttribute('content');
}

for (const path of PAGES) {
  test(`seo — head contract on ${path}`, async ({ page }) => {
    await page.goto(path);

    const title = await page.title();
    const description = (await meta(page, 'meta[name="description"]')) ?? '';
    const canonical = await page.locator('link[rel="canonical"]').getAttribute('href');

    expect(title.length, '<title> must not be empty').toBeGreaterThan(0);
    expect(title.length, `<title> "${title}" is ${title.length} chars > ${TITLE_MAX}`).toBeLessThanOrEqual(TITLE_MAX);
    expect(description.length, `meta description ${description.length} chars < ${DESC_MIN} (wastes SERP space — the website-seo-geo floor)`).toBeGreaterThanOrEqual(DESC_MIN);
    expect(description.length, `meta description ${description.length} chars > ${DESC_MAX}`).toBeLessThanOrEqual(DESC_MAX);

    expect(await meta(page, 'meta[property="og:title"]'), 'og:title must equal <title>').toBe(title);
    expect(await meta(page, 'meta[name="twitter:title"]'), 'twitter:title must equal <title>').toBe(title);
    expect(await meta(page, 'meta[property="og:description"]'), 'og:description must equal meta description').toBe(description);
    expect(await meta(page, 'meta[name="twitter:description"]'), 'twitter:description must equal meta description').toBe(description);

    expect(canonical, 'canonical missing').toBeTruthy();
    expect(await meta(page, 'meta[property="og:url"]'), 'og:url must equal canonical').toBe(canonical);
    // canonical is always the PRODUCTION URL (Astro.site), even when previewing on
    // localhost — compare to SITE.url, not the runtime origin.
    expect(canonical, 'canonical must be the absolute production URL for this path').toBe(`${SITE.url}${path}`);

    await expect(page.locator('h1'), 'each page must have exactly one <h1>').toHaveCount(1);

    const blocks = await page.locator('script[type="application/ld+json"]').allTextContents();
    expect(blocks.length, 'page should emit JSON-LD (WebPage/Organization/WebSite)').toBeGreaterThan(0);
    for (const b of blocks) expect(() => JSON.parse(b), 'JSON-LD must parse').not.toThrow();
  });
}

// Drift alarm: the sitemap is built from src/pages/**, PAGES is hand-maintained.
// If they differ, a page was added without a PAGES entry — and EVERY suite
// (a11y/seo/navigation/images/tone/email) would silently skip it. noindex pages:
// exclude them from the sitemap (filter in astro.config.mjs) AND from PAGES.
test('sitemap matches PAGES (drift alarm)', async ({ request, baseURL }) => {
  const idx = await request.get(`${baseURL}/sitemap-index.xml`);
  expect(idx.status(), 'sitemap-index.xml should exist (@astrojs/sitemap)').toBe(200);
  const children = [...(await idx.text()).matchAll(/<loc>([^<]+)<\/loc>/g)].map((m) => m[1]);
  expect(children.length, 'sitemap index should reference at least one sitemap').toBeGreaterThan(0);

  const built: string[] = [];
  for (const child of children) {
    // The <loc> values carry the production origin; fetch via the preview server.
    const res = await request.get(new URL(new URL(child).pathname, baseURL!).href);
    expect(res.status(), `child sitemap ${child} should fetch (otherwise the comparison below lies)`).toBe(200);
    const xml = await res.text();
    for (const m of xml.matchAll(/<loc>([^<]+)<\/loc>/g)) {
      const p = new URL(m[1]).pathname;
      built.push(p === '/' ? '/' : p.replace(/\/$/, ''));
    }
  }
  expect(
    built.sort(),
    'sitemap pages ≠ PAGES — add the new route to tests/_helpers.ts PAGES (or remove the stale entry)',
  ).toEqual([...PAGES].sort());
});

// Indexability guard: the site is useless if a future edit silently closes it to
// crawlers. Cloudflare's "Disable robots.txt configuration" leaves THIS file
// authoritative, so it must stay open and point at the real domain. A blanket
// `Disallow: /` (or a llms.txt that 404s) is the failure we refuse to ship.
test('robots.txt stays open and llms.txt exists', async ({ request, baseURL }) => {
  const robots = await request.get(`${baseURL}/robots.txt`);
  expect(robots.status(), 'public/robots.txt must be served').toBe(200);
  const body = await robots.text();

  expect(
    /^\s*Disallow:\s*\/\s*$/m.test(body),
    'robots.txt blocks the whole site (Disallow: /) — crawlers and AI engines can\'t index it',
  ).toBe(false);

  // Two sources of truth (SITE.url and the static Sitemap line) must agree, or the
  // declared sitemap 404s — the classic "forgot to set the domain before launch".
  const sitemap = body.match(/^\s*Sitemap:\s*(\S+)/im)?.[1];
  expect(sitemap, 'robots.txt must declare a Sitemap: line').toBeTruthy();
  expect(
    new URL(sitemap!).host,
    `robots.txt Sitemap host ≠ SITE.url host (${SITE.url}) — update public/robots.txt`,
  ).toBe(new URL(SITE.url).host);

  const llms = await request.get(`${baseURL}/llms.txt`);
  expect(llms.status(), 'public/llms.txt (the AI answer-engine index) must be served').toBe(200);
});

// ── Hosted PDFs: the doc-title IS the search-result title ──────────────────────
// A PDF has no <title>; Bing/Google print its embedded doc-title in results.
// Authoring tools leave a placeholder ("PowerPoint-Präsentation") or a filename
// slug, which Bing flags as "page title too short". Crawlers read the title from
// TWO places — the Info dict /Title and the XMP dc:title — so we check both.
// Set a good one with scripts/set_pdf_title.py. No-op when public/ has no PDFs.
// Dep-free: parses the bytes directly (no PDF library), mirroring website-seo-geo.
const PDF_TITLE_MIN = 15;
const PDF_PLACEHOLDERS = new Set([
  'powerpoint-präsentation', 'powerpoint presentation', 'präsentation', 'präsentation1',
  'presentation1', 'microsoft word', 'untitled', 'folie 1', 'slide 1', 'dokument1', 'keynote',
]);

function findPdfs(dir: string): string[] {
  const out: string[] = [];
  let entries: import('node:fs').Dirent[];
  try { entries = readdirSync(dir, { withFileTypes: true }); } catch { return out; }
  for (const e of entries) {
    const p = join(dir, e.name);
    if (e.isDirectory()) out.push(...findPdfs(p));
    else if (e.name.toLowerCase().endsWith('.pdf')) out.push(p);
  }
  return out;
}

function decodeLiteral(s: string): string {
  return s.replace(/\\([nrtbf()\\]|[0-7]{1,3})/g, (_, c) => {
    const map: Record<string, string> = { n: '\n', r: '\r', t: '\t', b: '\b', f: '\f', '(': '(', ')': ')', '\\': '\\' };
    if (c in map) return map[c];
    return String.fromCharCode(parseInt(c, 8) & 0xff); // octal escape → byte
  }).trim();
}

function decodeHex(hex: string): string {
  const bytes = Buffer.from(hex.replace(/\s/g, ''), 'hex');
  if (bytes[0] === 0xfe && bytes[1] === 0xff) {        // UTF-16BE BOM
    const be = bytes.subarray(2);
    const le = Buffer.allocUnsafe(be.length);          // swap pairs → UTF-16LE for Node
    for (let i = 0; i + 1 < be.length; i += 2) { le[i] = be[i + 1]; le[i + 1] = be[i]; }
    return le.toString('utf16le').trim();
  }
  return bytes.toString('latin1').trim();
}

// Every doc-title a crawler might read: Info dict /Title (resolved via the trailer
// /Info ref, so per-page "(Slide N)" structure titles are ignored) + XMP dc:title.
function pdfTitles(buf: Buffer): string[] {
  const titles: string[] = [];
  const utf = buf.toString('utf8');
  const xm = utf.match(/<dc:title>[\s\S]*?<rdf:li[^>]*>([\s\S]*?)<\/rdf:li>/);
  if (xm) titles.push(xm[1].replace(/&amp;/g, '&').replace(/&lt;/g, '<').replace(/&gt;/g, '>').trim());

  const raw = buf.toString('latin1');
  const refs = [...raw.matchAll(/\/Info\s+(\d+)\s+(\d+)\s+R/g)];
  if (refs.length) {
    const [, num, gen] = refs[refs.length - 1];
    const om = raw.match(new RegExp(`(?:^|[^0-9])${num}\\s+${gen}\\s+obj([\\s\\S]*?)endobj`));
    const body = om ? om[1] : '';
    const lit = body.match(/\/Title\s*\(((?:\\.|[^\\()])*)\)/);
    const hex = body.match(/\/Title\s*<([0-9A-Fa-f\s]+)>/);
    if (lit) titles.push(decodeLiteral(lit[1]));
    else if (hex) titles.push(decodeHex(hex[1]));
  }
  return titles.filter(Boolean);
}

test('seo — hosted PDFs carry a descriptive doc-title', () => {
  const pdfs = findPdfs(join(process.cwd(), 'public'));
  for (const file of pdfs) {
    const titles = pdfTitles(readFileSync(file));
    expect(titles.length, `${file}: no readable doc-title (set Info /Title + XMP dc:title via scripts/set_pdf_title.py)`).toBeGreaterThan(0);
    for (const t of titles) {
      expect(PDF_PLACEHOLDERS.has(t.toLowerCase()), `${file}: doc-title is an authoring placeholder ("${t}") — run scripts/set_pdf_title.py`).toBe(false);
      expect(t.length, `${file}: doc-title too short ("${t}", ${t.length} chars, need ≥${PDF_TITLE_MIN})`).toBeGreaterThanOrEqual(PDF_TITLE_MIN);
    }
  }
});
