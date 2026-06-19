// One source of truth for routes. Every suite iterates PAGES — add a route here
// and the a11y / SEO / navigation / image checks all cover it automatically.
// CONVENTION: NO trailing slash (matches `trailingSlash: 'never'`); home stays '/'.
export const PAGES = [
  '/',
  '/privacy',
  // '/about',
  // '/contact',
] as const;

// a11y (and any visual check) runs in both themes; the toggle is driven by
// localStorage['theme'], read by the no-FOUC script in Base.astro's <head>.
export const THEMES = ['light', 'dark'] as const;
