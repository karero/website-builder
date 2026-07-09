import { defineConfig } from 'astro/config';
import sitemap from '@astrojs/sitemap';

// Set `site` to the real production domain BEFORE first deploy — it drives the
// sitemap, canonical tags and OG URLs. Keep in sync with SITE.url in src/config.ts.
export default defineConfig({
  site: 'https://example.com',
  trailingSlash: 'never',           // CONVENTION: clean URLs with NO trailing slash (/about, not /about/)
  build: {
    format: 'file',                 // emit /about.html → Cloudflare Pages serves it at /about (no slash)
    inlineStylesheets: 'always',    // drop the render-blocking CSS request (LCP)
  },
  integrations: [
    // No lastmod: stamping build time on every URL tells crawlers all pages changed
    // when none did. /404 needs no filter — @astrojs/sitemap excludes status-code
    // pages itself. If you add any OTHER noindex page, exclude it here, e.g.
    //   sitemap({ filter: (url) => new URL(url).pathname !== '/internal' })
    // — and keep it out of tests/_helpers.ts PAGES (seo.spec.ts compares the two).
    sitemap({ changefreq: 'monthly', priority: 0.7 }),
  ],
});
