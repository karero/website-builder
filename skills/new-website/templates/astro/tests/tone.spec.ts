import { test, expect } from '@playwright/test';
import { PAGES, germanFunctionWordDensity } from './_helpers';

// Tone-of-voice guardrail (see the website-content-guide skill + CONTENT_GUIDE.md).
// Hard rules across all user-facing copy AND metadata. Genuinely quoted human/customer
// voice is exempt — wrap it in <blockquote>, <q>, or add data-tov-exempt.
//
// Language-aware: contraction/buzzword rules are ENGLISH rules. German gets its own
// enforced ruleset (GERMAN_RULES below) — buzzwords and AI-tell phrases — but
// deliberately NO German "contraction" rule: colloquial elisions (geht's, kommt's)
// are natural informal register, not an AI tell. Any other <html lang> (French,
// Spanish, …) gets only the universal rules — French elisions (c'est, d'une) would
// otherwise false-positive. The em-dash ban applies to every language.
const UNIVERSAL_RULES: { label: string; re: RegExp }[] = [
  { label: 'em dash —', re: /—/g },
];
const ENGLISH_RULES: { label: string; re: RegExp }[] = [
  // ANY apostrophe contraction (don't, doesn't, won't, we're, you've, I'll, I'd, I'm) —
  // generic, so the guard can't silently lag behind an enumerated list.
  // Known gaps (accepted): y'all, 'tis, int'l, ma'am slip through; gov't/cont'd/OK'd
  // false-positive (ALLOWLIST them). Names like O'Brien/o'clock are safe (suffix list).
  { label: 'contraction', re: /\b[a-z]+[’'](t|re|ve|ll|d|m)\b/gi },
  // 's only on pronouns/determiners — possessives ("the company's", "one's") stay legal.
  { label: "'s contraction", re: /\b(it|that|what|there|here|who|let|she|he|how|where|when)[’']s\b/gi },
  { label: 'buzzword', re: /\b(supercharge|world-class|best in class|best-in-class|leverage|leverages|leveraging|unlock|unlocks|unlocking|utilize|utilizes|seamless|seamlessly|robust|cutting-edge|empower|empowers|holistic|game-changing|revolutionary|synergy|synergies|next-level|turbocharge)\b/gi },
];
const GERMAN_RULES: { label: string; re: RegExp }[] = [
  // Buzzword/AI-tell vocabulary — the German counterpart to ENGLISH_RULES' buzzword
  // line. Deliberately no German "contraction" rule: colloquial elisions (geht's,
  // kommt's) are natural informal register, not an AI tell (see header comment).
  //
  // Unicode-aware boundaries: JS's bare \b is defined against \w, which is only
  // [A-Za-z0-9_] — it does NOT include ä/ö/ü/ß. A plain /\bwort\b/ regex can
  // silently fail to match at a real word boundary when the word starts or ends
  // with one of those characters (JS sees "non-word" on both sides of the
  // boundary, so \b never fires). None of the words below happen to start/end
  // with ä/ö/ü/ß once correctly spelled, but to stay robust against a future edit
  // (e.g. adding "überzeugend"), use \p{L} lookaround + the u flag instead of \b.
  {
    label: 'buzzword',
    // "massgeschneidert" alongside "maßgeschneidert": Swiss German writes ß as ss, and
    // the /i flag does not fold ß↔ss for us. entfesselt gets the same (?:e|er|es|en)?
    // adjective-ending coverage as every other entry (was previously (?:e)? only).
    // Endings cover all four cases incl. dative -em ("mit nahtlosem Übergang"
    // previously slipped through) and superlatives (-ste/-ster/-stes/-sten/-stem,
    // "die nahtloseste Erfahrung").
    re: /(?<!\p{L})(ganzheitlich(?:e|er|es|en|em|ste[mnrs]?)?|nahtlos(?:e|er|es|en|em|este[mnrs]?)?|synergien?|synergieeffekt(?:e|en)?|bahnbrechend(?:e|er|es|en|em|ste[mnrs]?)?|revolutionär(?:e|er|es|en|em|ste[mnrs]?)?|wegweisend(?:e|er|es|en|em|ste[mnrs]?)?|erstklassig(?:e|er|es|en|em|ste[mnrs]?)?|(?:ma(?:ß|ss)geschneidert)(?:e|er|es|en|em|ste[mnrs]?)?|hochmodern(?:e|er|es|en|em|ste[mnrs]?)?|zukunftsweisend(?:e|er|es|en|em|ste[mnrs]?)?|transformativ(?:e|er|es|en|em|ste[mnrs]?)?|unschlagbar(?:e|er|es|en|em|ste[mnrs]?)?|entfesseln|entfesselt(?:e|er|es|en|em)?|spitzenreiter)(?!\p{L})/gui,
  },
  // Multi-word AI-tell phrases — own rule/label (not merged into the buzzword
  // list above). \s+ tolerates whitespace variation between words; same
  // \p{L}-lookaround rationale as the buzzword rule applies at the phrase edges.
  {
    label: 'AI-tell phrase',
    // "in der heutigen ... Welt" tolerates up to two modifiers (the canonical
    // double "schnelllebigen digitalen Welt" and the bare form) plus compound
    // Welt-nouns via \p{L}*welt ("Geschäftswelt", incl. modifiers+compound).
    // The intervening-word slots REJECT determiners/possessives so a real
    // clause boundary can't be swallowed ("in der heutigen Zeit, die Welt
    // dreht sich" and "in der heutigen Ausgabe unserer Welt-Reihe" stay
    // clean). Known accepted edge: "in der heutigen Umwelt" matches (rare,
    // and usually filler prose anyway). The eintauchen family covers
    // Sie/du/wir registers (lassen Sie uns / lass uns / lasst uns).
    re: /(?<!\p{L})(in\s+der\s+heutigen(?:,?\s+(?!(?:der|die|das|den|dem|des|unser\p{L}*|euer|eure\p{L}*|ihr\p{L}*)\b)\p{L}+){0,2}?[\s-]*\p{L}*welt|es\s+ist\s+wichtig\s+zu\s+(?:betonen|beachten|erwähnen),?\s+dass|zusammenfassend\s+lässt\s+sich\s+sagen|lass(?:en\s+sie|t)?\s+uns\s+(?:eintauchen|einen\s+blick\s+werfen))(?!\p{L})/gui,
  },
];
// Exact matches to tolerate (lowercase) — e.g. a brand name like "rock 'n' roll".
const ALLOWLIST = new Set<string>([]);

for (const path of PAGES) {
  test(`tone — no banned phrasing on ${path}`, async ({ page }) => {
    await page.goto(path);
    const { text, lang } = await page.evaluate(() => {
      const body = document.body.cloneNode(true) as HTMLElement;
      body.querySelectorAll('[data-tov-exempt], blockquote, q, script, style, noscript').forEach((el) => el.remove());
      // Also scan <head> metadata: title / description / OG / Twitter are
      // user-facing (SERPs, social cards) but live outside <body>, so they would
      // otherwise slip past the tone rules.
      const metaSel = [
        'meta[name="description"]',
        'meta[property="og:title"]', 'meta[property="og:description"]',
        'meta[name="twitter:title"]', 'meta[name="twitter:description"]',
      ];
      const meta = [document.title, ...metaSel.map((s) => document.querySelector(s)?.getAttribute('content') ?? '')];
      return {
        text: meta.join('\n') + '\n' + body.innerText,
        lang: document.documentElement.lang || '',
      };
    });

    // Primary subtag only (not startsWith) -- startsWith('de') happens to be correct for every
    // real BCP-47 German tag (de, de-DE, de-AT, de-CH all start with "de"), but primary-subtag
    // comparison is the precise form and can't be fooled by a malformed/non-German tag that
    // merely begins with those two letters.
    const primaryLang = lang.toLowerCase().split('-')[0];
    const rules = primaryLang === 'en'
      ? [...UNIVERSAL_RULES, ...ENGLISH_RULES]
      : primaryLang === 'de'
        ? [...UNIVERSAL_RULES, ...GERMAN_RULES]
        : UNIVERSAL_RULES;

    const violations: string[] = [];
    for (const { label, re } of rules) {
      for (const m of text.matchAll(re)) {
        // Normalize the apostrophe so one ALLOWLIST entry covers ’ and '.
        if (ALLOWLIST.has(m[0].toLowerCase().replace(/’/g, "'"))) continue;
        const i = m.index ?? 0;
        const ctx = text.slice(Math.max(0, i - 25), i + 25).replace(/\s+/g, ' ').trim();
        violations.push(`"${label}" → …${ctx}…`);
      }
    }
    expect(
      violations,
      `${path} (lang="${lang}") breaks the tone rules. Em dash → comma/period/colon · contraction → ` +
        `long form · drop the buzzword. Genuine quoted voice → [data-tov-exempt]/<blockquote>/<q>.\n` +
        violations.map((v) => '  • ' + v).join('\n'),
    ).toEqual([]);

    if (primaryLang === 'de') {
      // Wrong-language body (German pages, ANY site shape): a page declaring
      // lang="de" whose body is still English ships silently otherwise — the
      // multi-locale i18n.spec.ts catches this only on sites running
      // astro-i18n-setup, and single-locale German sites are the COMMON case.
      // Same helper and threshold as i18n.spec.ts (word list + math live in
      // _helpers.germanFunctionWordDensity); this extraction additionally
      // strips quoted-voice exemptions, see below. Threshold calibration:
      // real German PROSE runs ~15-20%; directory/legal-genre German
      // (addresses, register numbers — the shipped Impressum) runs ~4%, so 3%
      // keeps a real margin only over NON-German text (~0%) — that is the
      // failure this catches; don't raise the threshold. Pages under 30 body
      // words skip entirely: density is noise on tiny stubs.
      const bodyText = await page.evaluate(() => {
        const body = document.body.cloneNode(true) as HTMLElement;
        // Same exemptions as the rules loop above: quoted human voice
        // (blockquote/q/[data-tov-exempt]) must not trip the register or
        // density checks — a du-voiced customer testimonial on a Sie-register
        // site is the NORMAL case, not a violation.
        body.querySelectorAll('nav, header, footer, script, style, noscript, blockquote, q, [data-tov-exempt]').forEach((el) => el.remove());
        return body.innerText;
      });
      const bodyWords = bodyText.trim().split(/\s+/).filter(Boolean).length;
      if (bodyWords >= 30) {
        const density = germanFunctionWordDensity(bodyText);
        expect(
          density,
          `${path} (lang="de"): body reads as non-German (${(density * 100).toFixed(1)}% German ` +
            `function words in ${bodyWords} words, expected >=3%) — content left in the original ` +
            `language under a German lang attribute?`,
        ).toBeGreaterThanOrEqual(0.03);
      }

      // du/Sie register consistency: mixing informal and formal address on one
      // page reads as a translation error (CONTENT_GUIDE, website-content-guide).
      // PRECISION over recall — only UNAMBIGUOUS markers count, both sides
      // case-sensitive (no i flag):
      //  - informal: lowercase du-family words. Lowercase "du/dich/dein" can
      //    only be informal address in German (capitalized sentence-initial
      //    "Du" is skipped — ambiguous with the formal-letter Du-style).
      //  - formal: capitalized imperative verb+Sie phrases ("Kontaktieren
      //    Sie..."). Bare "Sie/Ihnen/Ihre" is deliberately NOT counted:
      //    sentence-initial it collides with sie=she/they and Ihre=her/their,
      //    and innerText loses too much sentence structure to disambiguate.
      // A miss ships (recall loss, acceptable); a false alarm on clean copy
      // should not — if this still over-fires, the fallback is documenting the
      // rule as manual review, not loosening the match.
      const informal = bodyText.match(/\b(du|dich|dir|dein|deine|deinen|deinem|deiner)\b/g) ?? [];
      const formal = bodyText.match(/\b(?:Kontaktieren|Erreichen|Melden|Rufen|Schreiben|Erfahren|Buchen|Vereinbaren|Testen|Starten|Entdecken|Fragen)\s+Sie\b/g) ?? [];
      expect(
        informal.length === 0 || formal.length === 0,
        `${path} (lang="de"): page mixes du-register (${[...new Set(informal)].join(', ')}) and ` +
          `Sie-register (${[...new Set(formal)].join(', ')}) address — pick ONE (CONTENT_GUIDE "du/Sie"). ` +
          `Genuinely quoted voice (a du-voiced testimonial on a Sie site) → <blockquote>/<q>/[data-tov-exempt].`,
      ).toBe(true);
    }
  });
}
