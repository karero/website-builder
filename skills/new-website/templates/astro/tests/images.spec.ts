import { test, expect } from '@playwright/test';
import { PAGES } from './_helpers';

// Enforces the image rules on every rendered <img> AND every <picture><source>:
// a non-empty alt (or an intentional empty alt), explicit width+height (no layout
// shift / CLS), a modern raster format (WebP/AVIF — checked in src, srcset and
// <source>; SVG and the OG image are exempt), and an explicit loading choice:
// `loading="lazy"` for everything below the fold, `loading="eager"` (ideally with
// fetchpriority="high") ONLY for the LCP/above-fold image (website-design-system).
const RASTER = /\.(jpe?g|png|gif)(\?|#|$)/i;
// Simple comma split: srcset URLs containing literal commas (some image-CDN
// transform paths) come out garbled in messages, but raster extensions still match.
const srcsetUrls = (srcset: string) =>
  srcset.split(',').map((c) => c.trim().split(/\s+/)[0]).filter(Boolean);

for (const path of PAGES) {
  test(`images — ${path} uses optimised, dimensioned, described images`, async ({ page }) => {
    await page.goto(path);
    const imgs = await page.locator('img').evaluateAll((els) =>
      els.map((el) => {
        const img = el as HTMLImageElement;
        const sources = Array.from(img.closest('picture')?.querySelectorAll('source') ?? [])
          .map((s) => s.getAttribute('srcset') ?? '');
        return {
          src: img.getAttribute('src') ?? '',
          srcset: img.getAttribute('srcset') ?? '',
          sources,
          loading: img.getAttribute('loading'),
          hasAlt: img.hasAttribute('alt'),                 // alt="" is allowed (decorative)
          w: img.getAttribute('width'),
          h: img.getAttribute('height'),
        };
      }));

    const problems: string[] = [];
    for (const i of imgs) {
      if (!i.hasAlt) problems.push(`<img src="${i.src}"> has no alt attribute`);
      if (!i.w || !i.h) problems.push(`<img src="${i.src}"> missing width/height (CLS risk)`);
      // Astro's <Picture formats={['avif','webp']}> intentionally keeps a raster
      // fallback in <img src> for legacy browsers — exempt the fallback src when
      // the sibling <source>s offer a modern format; everything else is checked.
      const sourceCandidates = i.sources.flatMap(srcsetUrls);
      const hasModernSource = sourceCandidates.some((c) => !RASTER.test(c));
      const candidates = [...(hasModernSource ? [] : [i.src]), ...srcsetUrls(i.srcset), ...sourceCandidates];
      for (const c of candidates) {
        if (RASTER.test(c)) problems.push(`"${c}" (via <img src="${i.src}">) is raw JPEG/PNG/GIF — use WebP/AVIF`);
      }
      const loading = i.loading?.toLowerCase();
      if (loading !== 'lazy' && loading !== 'eager') {
        problems.push(`<img src="${i.src}"> has no loading attribute — "lazy" below the fold, "eager" only for the LCP image`);
      }
    }
    expect(problems, `image issues on ${path}:\n${problems.map((p) => '  • ' + p).join('\n')}`).toEqual([]);
  });
}
