// One source of truth for routes. Every suite iterates PAGES — add a route here
// and the a11y / SEO / navigation / image checks all cover it automatically.
// CONVENTION: NO trailing slash (matches `trailingSlash: 'never'`); home stays '/'.
export const PAGES = [
  '/',
  '/privacy',
  '/impressum',  // German-market legal page; non-DE/AT/CH sites delete it (see new-website checklist)
  // '/about',
  // '/contact',
] as const;

// a11y (and any visual check) runs in both themes; the toggle is driven by
// localStorage['theme'], read by the no-FOUC script in Base.astro's <head>.
export const THEMES = ['light', 'dark'] as const;

// German function-word density — the wrong-language detector shared by
// tone.spec.ts (single-locale German sites) and astro-i18n-setup's
// i18n.spec.ts (multi-locale). ONE implementation so the two enforcement
// points can't drift. Real German prose runs ~15-20% density, directory/legal
// genre (addresses, register numbers) ~4%, a non-German body ~0% — these exact
// words essentially don't occur in other languages, which is the margin the 3%
// threshold actually relies on.
export const GERMAN_FUNCTION_WORDS = /\b(der|die|das|und|ist|nicht|mit|für|von|auf|dass|sich|eine?|den|dem|des|sind|wird|werden|können|kann|auch|oder)\b/gi;
export function germanFunctionWordDensity(text: string): number {
  const words = text.trim().split(/\s+/).filter(Boolean).length;
  const hits = (text.match(GERMAN_FUNCTION_WORDS) || []).length;
  return words === 0 ? 0 : hits / words;
}
