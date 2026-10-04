import { test, expect } from '@playwright/test';
import { PAGES } from './_helpers';

// Leftover guardrail on the RENDERED site: a placeholder, or a note the author wrote
// to themselves, must not reach a visitor, a search engine or a share card. Reads every
// page's copy, <head> metadata, the text attributes a
// visitor meets (alt, aria-label, title, a form field's hint, a button's label) and
// JSON-LD, plus the web manifest.
//
// The "[MISSING:" grep in .github/workflows/ci.yml is the fast source-side half: it
// knows one token and looks in src/ and public/ only. This spec reads what a page
// actually serves, whichever file it came from, and knows the leftovers that grep
// was never told about.
//
// Not read, so still a human check at launch (new-website §4): other files in
// public/, PDFs, text inside images, and the starter's own example values (the name
// "Example", hello@example.com). No rule here knows those.
//
// Precision over recall: every rule matches text that is essentially never genuine
// copy, so a failure is a real leftover. Text that only LOOKS like one stays legal in
// <code>/<pre>/<kbd>/<samp>, under [data-placeholder-exempt], or via ALLOWLIST.
// Every rule tolerates any whitespace between words (\s+), line breaks included.
const RULES: { label: string; re: RegExp }[] = [
  // The content token "[MISSING: year built]" (AGENTS.md §4), a translated one
  // ("[FEHLT: …]") and every slot: an opening bracket, a capital letter, and at least
  // one more character. That is the shape of all the kit's own slots ("[DATE]",
  // "[W-IdNr., …]", "[Handelsregister / Vereinsregister]") and of the ones AI
  // assistants leave behind ("[Your Name]"). "[1]", "[A]", "[sic]" and EmailLink's
  // "[at]" do not match. Genuine bracketed text that starts with a capital ("[PDF]",
  // an editor's note in a quote) does: ALLOWLIST it or mark it [data-placeholder-exempt].
  { label: 'unfilled [SLOT]', re: /\[\s*\p{Lu}\s*[^\]\s][^\]]{0,300}\]/gu },
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
// Exact matches to tolerate (lowercase, single spaces), e.g. '[pdf]' for a download label.
const ALLOWLIST = new Set<string>([]);

// A slot the rule above cannot see: bracketed, several words, lower-case first
// ("[self-hosted on our own server / operated for us by …]"). In finished copy that
// shape is usually genuine (an editor's "[the team]" in a quote), so it is checked
// only on a target still listed in UNFILLED_UNTIL_LAUNCH: there it is a draft's slot,
// and without this check the owner who fills every reported slot is told the page is
// done while one is still on it.
const UNSEEN_SLOT = /\[\s*\p{Ll}[^\]]*\s[^\]]*\]/gu;

// Served files that carry copy but are not pages. Read as JSON.
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

// One line per distinct leftover: the same slot met in two readings of a page (see
// the page test) is reported once.
function scan(text: string): string[] {
  const found = new Map<string, string>();
  for (const { label, re } of RULES) {
    for (const m of text.matchAll(re)) {
      const match = m[0].replace(/\s+/g, ' ');
      if (ALLOWLIST.has(match.toLowerCase())) continue;
      const key = `${label}|${match}`;
      if (found.has(key)) continue;
      const i = m.index ?? 0;
      const ctx = text.slice(Math.max(0, i - 25), i + m[0].length + 25).replace(/\s+/g, ' ').trim();
      found.set(key, `"${label}" → …${ctx}…`);
    }
  }
  return [...found.values()];
}

// The text inside a JSON document, decoded: in the raw file a line break is the two
// characters \n and any character may be written as \uXXXX, so a rule would look at
// the encoding instead of the words. null = not valid JSON.
function jsonStrings(raw: string): string | null {
  const strings = (v: unknown): string[] =>
    typeof v === 'string' ? [v] : v && typeof v === 'object' ? Object.values(v).flatMap(strings) : [];
  try {
    return strings(JSON.parse(raw)).join('\n');
  } catch {
    return null;
  }
}

function judge(target: string, text: string, listed = UNFILLED_UNTIL_LAUNCH.has(target)) {
  const findings = scan(text);
  const list = findings.map((f) => '  • ' + f).join('\n');
  if (!listed) {
    expect(
      findings,
      `${target} still serves a placeholder or an author note. Fill it or remove it. Genuine ` +
        `text that only looks like one → <code>, [data-placeholder-exempt] or ALLOWLIST.\n${list}`,
    ).toEqual([]);
    return;
  }
  const unseen = [...text.matchAll(UNSEEN_SLOT)].map((m) => m[0].replace(/\s+/g, ' '));
  expect(
    unseen,
    `${target} carries bracketed text the slot rule cannot see, because it starts with a ` +
      `lower-case letter. A slot: start it with a capital word ("[CHOOSE ONE: …]"). Genuine ` +
      `text: mark it [data-placeholder-exempt].\n` + unseen.map((u) => '  • ' + u).join('\n'),
  ).toEqual([]);
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
    '[CHOOSE ONE: self-hosted on our own server / operated for us by Plausible Insights OÜ,\n      Västriku tn 2, 50403 Tartu, Estonia (EU)]',
    'Kind regards, [Your Name]',
    'Visit us at [STREET\n      AND NUMBER]',
    'Call [ PHONE ] today',
    'Lorem ipsum dolor sit amet',
    'Lorem\nipsum',
    'TODO: add the prices',
    'Hello {{ name }}',
    'Hello ${name}',
    'Team: [object Object]',
    'Your headline here',
    'Jane Doe, CEO',
    'Max Mustermann, Musterstraße 1, 12345 Musterstadt',
    'Hier steht Ihr Text',
    jsonStrings('{"name":"Lorem\\nipsum"}') ?? '',
    jsonStrings('{"name":"\\u005bSITE NAME\\u005d"}') ?? '',
  ];
  const genuine = [
    'See footnote [1] and appendix [A], or [ B ], quoted as written [sic].',
    'hello [at] example [dot] com',
    'A todo list for the week',
    'Sizes S to XXXL',
    'Prices from $5 {per month}',
    'Das Muster der Tapete, ein Text für alle',
    jsonStrings('{"@type":["Organization","LocalBusiness"],"name":"Example"}') ?? 'TODO',
  ];
  expect(leftovers.filter((s) => scan(s).length === 0), 'leftovers the rules no longer catch').toEqual([]);
  expect(genuine.filter((s) => scan(s).length > 0), 'genuine copy the rules now flag').toEqual([]);
  expect(jsonStrings('{"name": '), 'broken JSON must be reported as such').toBeNull();

  // The verdicts, pinned the same way: a leftover on an unlisted target fails, a listed
  // target with nothing left fails, and a listed target may not hide a slot the rule
  // cannot see. (A listed target that still has leftovers only warns: the starter's
  // own legal pages exercise that on every run until they are filled.)
  expect(() => judge('/x', 'Prices: TODO', false), 'a leftover must fail').toThrow();
  expect(() => judge('/x', 'All filled in.', false), 'clean copy must pass').not.toThrow();
  expect(() => judge('/x', 'All filled in.', true), 'a filled target must not stay listed').toThrow();
  expect(
    () => judge('/x', 'Hosted [DATE] [self-hosted on our own server / operated for us]', true),
    'a lower-case slot on a listed target must fail',
  ).toThrow();
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
    const { text, jsonLd } = await page.evaluate(() => {
      const exempt = 'code, pre, kbd, samp, [data-placeholder-exempt]';
      const body = document.body.cloneNode(true) as HTMLElement;
      body.querySelectorAll(`script, style, noscript, ${exempt}`).forEach((el) => el.remove());
      // Text nodes, not innerText: content the layout hides (a closed <details>, a
      // collapsed menu) is still served and still indexed.
      const walker = document.createTreeWalker(body, NodeFilter.SHOW_TEXT);
      const nodes: string[] = [];
      while (walker.nextNode()) nodes.push(walker.currentNode.nodeValue ?? '');
      // Two readings of the same copy, because neither is safe alone. Spaced: one
      // block's last word never fuses with the next block's first ("pricesTODO").
      // Fused: a word or slot split by inline markup stays whole ("Lo<em>rem</em>").
      const copy = [nodes.join(' '), nodes.join('')];
      // Same <head> surfaces as tone.spec.ts: user-facing in SERPs and share cards.
      const metaSel = [
        'meta[name="description"]',
        'meta[property="og:title"]', 'meta[property="og:description"]',
        'meta[name="twitter:title"]', 'meta[name="twitter:description"]',
      ];
      const meta = [document.title, ...metaSel.map((s) => document.querySelector(s)?.getAttribute('content') ?? '')];
      // Attributes a visitor reads or hears. An input's value only where the browser
      // shows it (a button's label, a prefilled field), not on a checkbox or hidden field.
      const attrs = Array.from(document.querySelectorAll('[alt], [aria-label], [title], [placeholder], input[value]'))
        .filter((el) => !el.closest(exempt))
        .flatMap((el) => {
          const type = (el.getAttribute('type') ?? 'text').toLowerCase();
          const shown = el.tagName === 'INPUT' && !['hidden', 'checkbox', 'radio'].includes(type);
          return [
            el.getAttribute('alt'), el.getAttribute('aria-label'), el.getAttribute('title'),
            el.getAttribute('placeholder'), shown ? el.getAttribute('value') : null,
          ].map((v) => v ?? '');
        });
      const jsonLd = Array.from(document.querySelectorAll('script[type="application/ld+json"]'))
        .map((el) => el.textContent ?? '');
      return { text: [...meta, ...copy, ...attrs].join('\n'), jsonLd };
    });
    // JSON-LD that does not parse is seo.spec.ts's failure; here it is still read, raw.
    const structured = jsonLd.map((raw) => jsonStrings(raw) ?? raw);
    judge(path, [text, ...structured].join('\n'));
  });
}

for (const file of STATIC_FILES) {
  test(`placeholders — no leftover in ${file}`, async ({ request, baseURL }) => {
    const res = await request.get(new URL(file, baseURL!).href);
    // 404 = this site ships no such file, so there is nothing to read (an entry still
    // listed for it fails in judge). Anything else must not pass as "nothing found".
    expect([200, 404], `${file} answered ${res.status()}, so it was not checked`).toContain(res.status());
    if (res.status() === 404) return judge(file, '');
    const strings = jsonStrings(await res.text());
    expect(strings, `${file} is not valid JSON, so it was not checked`).not.toBeNull();
    judge(file, strings ?? '');
  });
}
