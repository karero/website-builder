// Central site configuration. Edit company facts / analytics HERE only — Base.astro,
// schema, llms.txt and the tests all read from this single source. Keep SITE.url in
// sync with `site:` in astro.config.mjs.

export const SITE = {
  url: 'https://example.com',          // production origin, no trailing slash
  name: 'Example',
  legalName: 'Example GmbH',
  locale: 'en',
  themeColor: '#000000',               // matches the brand primary + manifest
  // Home <title> is special-cased (NOT "Example | Example"). Keep ≤ 60 chars.
  titleHome: 'Example: clear, keyword-tuned home page title',
  tagline: 'One-line positioning.',
  // 120–160 chars: default meta description + Organization/WebPage schema text.
  description:
    'Example is a short, specific description of what this site offers and who ' +
    'it is for, written plainly and within the 120 to 160 character window.',
} as const;

// og:locale mapping from a lang tag's PRIMARY subtag — shared by Base.astro
// (emission) and tests/seo.spec.ts (assertion), one source so they can't
// drift. Regioned tags (de-AT) derive base+region in Base.astro instead.
export const OG_LOCALES: Record<string, string | undefined> = { en: 'en_US', de: 'de_DE', fr: 'fr_FR', es: 'es_ES', it: 'it_IT' };

export const COMPANY = {
  legalName: 'Example GmbH',
  logo: '/images/logo.png',            // resolved against SITE.url for schema
} as const;

// External profiles that corroborate the entity (EEAT). Only ship URLs that
// resolve — a broken sameAs is worse than none. .filter(Boolean) drops the slots.
export const SAME_AS: string[] = [
  // 'https://www.linkedin.com/company/…',
  // 'https://github.com/…',
].filter(Boolean);

// Topics the site is authoritative on (schema knowsAbout).
export const KNOWS_ABOUT: string[] = [];

// Plausible (cookieless; scriptHost is your own self-hosted instance, or
// https://plausible.io for the paid cloud version). Fire only on the production
// deploy: Cloudflare Pages sets CF_PAGES_BRANCH to the branch being built.
//
// IMPORTANT: PROD_BRANCH must equal the branch Cloudflare Pages calls "Production"
// for THIS project (house convention: 'production'; Cloudflare's default is 'main').
// A mismatch means analytics silently never loads — no error, no data.
export const PROD_BRANCH = 'production';

export const ANALYTICS = {
  enabled: process.env.CF_PAGES_BRANCH === PROD_BRANCH,
  domain: 'example.com',
  scriptHost: 'https://analytics.example.com',
} as const;
