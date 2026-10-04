import { test, expect } from '@playwright/test';
import { PAGES } from './_helpers';

// Leftover guardrail on the RENDERED site: nothing a visitor, a search engine or a
// share card can read may still be a placeholder or a note the author wrote to
// themselves. Reads every page's copy, <head> metadata, alt texts, aria-labels and
// JSON-LD, plus the web manifest.
//
// The "[MISSING:" grep in .github/workflows/ci.yml is the fast source-side half: it
// knows one token and looks in src/ and public/ only. This spec reads what a page
// actually serves, whichever file it came from, and knows the leftovers that grep
// was never told about.
//
// Precision over recall: every rule matches text that is essentially never genuine
// copy, so a failure is a real leftover. Text that only LOOKS like one stays legal in
// <code>/<pre>/<kbd>/<samp>, under [data-placeholder-exempt], or via ALLOWLIST.
// Multi-word rules use \s+ because the page text is joined from its text nodes.
const RULES: { label: string; re: RegExp }[] = [
  // The content token "[MISSING: year built]" (AGENTS.md §4), a translated one
  // ("[FEHLT: …]") and every slot: an opening bracket followed by a capital letter.
  // That is the shape of all the kit's own slots ("[DATE]", "[W-IdNr., …]",
  // "[Handelsregister / Vereinsregister]") and of the ones AI assistants leave behind
  // ("[Your Name]"). "[1]", "[A]", "[sic]" and EmailLink's "[at]" do not match.
  // Genuine bracketed text that starts with a capital ("[PDF]", an editor's note in a
  // quote) does: ALLOWLIST it or mark it [data-placeholder-exempt].
  { label: 'unfilled [SLOT]', re: /\[\p{Lu}[^\]\n]{1,120}\]/gu },
  { label: 'filler text', re: /\b(?:lorem\s+ipsum|dolor\s+sit\s+amet)\b/gi },
  // Case-sensitive: "todo" in running prose is a word, "TODO" is a note.
  { label: 'author note', re: /\b(?:TODO|FIXME|XXX)\b/g },
  // A template expression nobody evaluated, or an object printed as text.
  { label: 'unrendered template', re: /\{\{[^{}\n]{0,80}\}\}|\$\{[^{}\n]{0,80}\}|\[object Object\]/g },
  {
    label: 'placeholder wording',
    re: /\b(?:your\s+(?:text|headline|title|content|copy|tagline|logo|company\s+name)\s+(?:goes\s+)?here|placeholder\s+(?:text|copy|content|image)|(?:sample|dummy)\s+(?:text|copy|content)|(?:john|jane)\s+doe)\b/gi,
  },
  // German. \p{L} lookarounds instead of \b, which does not see ä/ö/ü/ß as letters
  // (same reasoning as GERMAN_RULES in tone.spec.ts).
  {
    label: 'placeholder wording',
    re: /(?<!\p{L})(?:platzhaltertext|blindtext|mustertext|hier\s+steht\s+(?:ihr|dein|euer)\s+text|(?:max|erika)\s+mustermann|musterstra(?:ß|ss)e|musterstadt|musterfirma)(?!\p{L})/giu,
  },
];
// Exact matches to tolerate (lowercase), e.g. '[pdf]' for a download label.
const ALLOWLIST = new Set<string>([]);

// Served files that carry copy but are not pages.
const STATIC_FILES = ['/manifest.webmanifest'] as const;

// The starter's legal pages and manifest ship with [BRACKET] slots only the owner can
// fill (legal name, address, register number), and the suite has to be green from
// commit 1. So the targets listed here are REPORTED on every run, not failed, while
// they still carry leftovers.
//
// The list empties itself: the moment a listed target is clean, its test fails until
// the entry is deleted, and an entry naming no checked target (page renamed or
// removed) fails too. So the exemption cannot outlive its reason. The site may not
// launch while anything is listed (new-website §4).
//
// Add an entry only when routing another of the kit's slot-carrying drafts before
// launch (a second locale's privacy page). Never to get an unfinished page green:
// that is weakening the test (AGENTS.md §5). Fill the slot, or keep the pull request
// a draft.
const UNFILLED_UNTIL_LAUNCH = new Set<string>(['/privacy', '/impressum', '/manifest.webmanifest']);

function scan(text: string): string[] {
  const found = new Set<string>();
  for (const { label, re } of RULES) {
    for (const m of text.matchAll(re)) {
      if (ALLOWLIST.has(m[0].toLowerCase())) continue;
      const i = m.index ?? 0;
      const ctx = text.slice(Math.max(0, i - 25), i + m[0].length + 25).replace(/\s+/g, ' ').trim();
      found.add(`"${label}" → …${ctx}…`);
    }
  }
  return [...found];
}

function judge(target: string, findings: string[]) {
  const list = findings.map((f) => '  • ' + f).join('\n');
  if (!UNFILLED_UNTIL_LAUNCH.has(target)) {
    expect(
      findings,
      `${target} still serves a placeholder or an author note. Fill it or remove it. Genuine ` +
        `text that only looks like one → <code>, [data-placeholder-exempt] or ALLOWLIST.\n${list}`,
    ).toEqual([]);
    return;
  }
  expect(
    findings.length,
    `${target} has nothing left to fill but is still listed in UNFILLED_UNTIL_LAUNCH. Delete ` +
      `its entry in tests/placeholders.spec.ts so it stays checked from now on.`,
  ).toBeGreaterThan(0);
  // Warn-only while listed (same mechanism as the coverage flag in positioning.spec.ts):
  // visible on every run, never silent (Rule 12), and not launchable in this state.
  const first = findings.slice(0, 3).map((f) => '  • ' + f).join('\n');
  const more = findings.length > 3 ? `\n  • … and ${findings.length - 3} more` : '';
  const msg = `${target} is not ready to launch, ${findings.length} leftover(s) to fill:\n${first}${more}`;
  console.warn('⚠ placeholders: ' + msg);
  test.info().annotations.push({ type: 'warning', description: msg });
}

// The rules, pinned by example. An edit that stops catching one of these, or starts
// flagging genuine copy, fails here before it can wave a real leftover through.
test('placeholders — the rules catch leftovers and pass genuine copy', () => {
  const leftovers = [
    'Built in [MISSING: year built].',
    'Baujahr: [FEHLT: Baujahr]',
    'Last updated: [DATE].',
    '[LEGAL NAME INCL. FORM, e.g. Beispiel GmbH]',
    '[W-IdNr., e.g. DE123456789-00001]',
    '[Handelsregister / Vereinsregister]: Registergericht',
    'Kind regards, [Your Name]',
    'Lorem ipsum dolor sit amet',
    'TODO: add the prices',
    'Hello {{ name }}',
    'Hello ${name}',
    'Team: [object Object]',
    'Your headline here',
    'Jane Doe, CEO',
    'Max Mustermann, Musterstraße 1, 12345 Musterstadt',
    'Hier steht Ihr Text',
  ];
  const genuine = [
    'See footnote [1] and appendix [A], quoted as written [sic].',
    'hello [at] example [dot] com',
    'A todo list for the week',
    'Sizes S to XXXL',
    'Prices from $5 {per month}',
    'Das Muster der Tapete, ein Text für alle',
  ];
  expect(leftovers.filter((s) => scan(s).length === 0), 'leftovers the rules no longer catch').toEqual([]);
  expect(genuine.filter((s) => scan(s).length > 0), 'genuine copy the rules now flag').toEqual([]);
});

test('placeholders — UNFILLED_UNTIL_LAUNCH names only checked targets', () => {
  const checked = new Set<string>([...PAGES, ...STATIC_FILES]);
  const stale = [...UNFILLED_UNTIL_LAUNCH].filter((t) => !checked.has(t));
  expect(
    stale,
    `UNFILLED_UNTIL_LAUNCH lists ${stale.join(', ')}, which this spec does not check (not in ` +
      `PAGES, not a static file). Page renamed → rename the entry. Page removed → delete it.`,
  ).toEqual([]);
});

for (const path of PAGES) {
  test(`placeholders — no leftover on ${path}`, async ({ page }) => {
    await page.goto(path);
    const text = await page.evaluate(() => {
      const exempt = 'code, pre, kbd, samp, [data-placeholder-exempt]';
      const body = document.body.cloneNode(true) as HTMLElement;
      body.querySelectorAll(`script, style, noscript, ${exempt}`).forEach((el) => el.remove());
      // Text nodes, not innerText: content the layout hides (a closed <details>, a
      // collapsed menu) is still served and still indexed. Joined with a space so two
      // adjacent blocks never fuse into one word.
      const walker = document.createTreeWalker(body, NodeFilter.SHOW_TEXT);
      const copy: string[] = [];
      while (walker.nextNode()) copy.push(walker.currentNode.nodeValue ?? '');
      // Same <head> surfaces as tone.spec.ts: user-facing in SERPs and share cards.
      const metaSel = [
        'meta[name="description"]',
        'meta[property="og:title"]', 'meta[property="og:description"]',
        'meta[name="twitter:title"]', 'meta[name="twitter:description"]',
      ];
      const meta = [document.title, ...metaSel.map((s) => document.querySelector(s)?.getAttribute('content') ?? '')];
      const attrs = Array.from(document.querySelectorAll('img[alt], [aria-label]'))
        .filter((el) => !el.closest(exempt))
        .flatMap((el) => [el.getAttribute('alt') ?? '', el.getAttribute('aria-label') ?? '']);
      const jsonLd = Array.from(document.querySelectorAll('script[type="application/ld+json"]'))
        .map((el) => el.textContent ?? '');
      return [...meta, copy.join(' '), ...attrs, ...jsonLd].join('\n');
    });
    judge(path, scan(text));
  });
}

for (const file of STATIC_FILES) {
  test(`placeholders — no leftover in ${file}`, async ({ request, baseURL }) => {
    const res = await request.get(new URL(file, baseURL!).href);
    // 404 = this site ships no such file, so there is nothing to read (an entry still
    // listed for it fails in judge). Anything else must not pass as "nothing found".
    expect([200, 404], `${file} answered ${res.status()}, so it was not checked`).toContain(res.status());
    judge(file, res.status() === 200 ? scan(await res.text()) : []);
  });
}
