# Astro starter overlay (the `new-website` kit)

A complete, opinionated overlay you drop on top of a fresh Astro project: the SEO +
theme spine, the test suite, security headers, the preview-noindex function, and CI.
Copy-and-go for an Astro → GitHub → Cloudflare Pages site. The `new-website` skill
drives assembly; this README is the manual reference.

## What's here

```
package.json  tsconfig.json  astro.config.mjs  playwright.config.ts
.nvmrc                        # Node 22 — Astro 6 needs >=22.12 (Cloudflare Pages reads it)
src/config.ts                 # single source of truth (URL, name, analytics, EEAT)
src/layouts/Base.astro        # title/OG/Twitter/canonical/JSON-LD/no-FOUC theme spine
src/styles/global.css         # light/dark theme tokens (mirror BRAND.md)
src/pages/index.astro         # minimal home so the suite is green from commit 1
src/pages/privacy.astro       # GDPR privacy draft (fill [BRACKET] slots before launch)
public/{robots.txt,llms.txt,_headers,manifest.webmanifest}
functions/_middleware.ts      # noindex every *.pages.dev preview (zero config)
.github/workflows/ci.yml      # astro check + the suite on push/PR
scripts/check_external_links.sh  # warn-only outgoing-link liveness sweep (network; not in CI)
scripts/generate_og_cards.py     # branded 1200×630 OG share cards, one per page (npm run og)
scripts/run_og.mjs               # cross-platform launcher for the generator (forwards --check)
tests/_helpers.ts  tests/{a11y,seo,navigation,images,tone,positioning,email,links}.spec.ts
```
Sibling files in the parent `templates/`: `.gitignore`, `SETUP.md`,
`claude/settings.json` (permission allowlist), `content-guide.md`, `brand.md`.

## Bootstrap a new project

1. **Git first** (see SETUP.md): `mkdir <site> && cd <site> && git init`, copy the
   `templates/.gitignore`, commit.
2. `npm create astro@latest .` → Empty, TypeScript **Strict**. Requires **Node ≥22.12**
   (Astro 6); the committed `.nvmrc` pins 22 for local + Cloudflare Pages builds.
3. Copy this overlay over the scaffold (the files above) + `tests/`, then:
   ```bash
   npm i -D @playwright/test @axe-core/playwright @astrojs/check typescript @types/node
   npm i @astrojs/sitemap
   npx playwright install chromium
   ```
   (Or copy this `package.json` and run `npm install`.) **Commit the
   `package-lock.json`** — CI uses `npm ci`, which fails without it.
   On **npm ≥11.16**, `install` no longer auto-runs native install scripts — if it
   prints "packages have install scripts not yet covered", approve the two Astro
   needs or the build fails: `npm approve-scripts esbuild && npm approve-scripts sharp`.
4. Set the real domain in `astro.config.mjs` (`site:`) and `src/config.ts`
   (`SITE.url`, name, theme color, analytics — and check `PROD_BRANCH` matches the
   branch Cloudflare Pages will call "Production", or analytics never loads).
   Add `public/` icons; edit the placeholder `manifest.webmanifest`. Set the BRAND
   block in `scripts/generate_og_cards.py` and run `npm run og` to regenerate the
   1200×630 share cards (`public/images/og/`; the starter ships a default).
   Fill the `[BRACKET]` slots in `src/pages/privacy.astro`
   (controller, date, analytics wording — see the comment block in that file).
5. `npm run check && npm run build && npm test` — the overlay passes strict TS +
   a11y/seo/navigation/images/tone/positioning/email/links out of the box. Then build pages
   test-first (`<Base title="…" description="…">`).

> `links.spec.ts` is the **offline** guard: it only blocks domains you've already
> retired (its `STALE_DOMAINS` list, empty at start) from creeping back in — it makes
> no network calls, so it stays in CI. The **liveness** sweep of the links you keep
> (are they still 200? did one rebrand?) is network-dependent and lives in
> `scripts/check_external_links.sh` + the `outgoing-link-audit` skill — run monthly /
> pre-launch, never in CI.

Deploy: Cloudflare Pages, build `npm run build`, output `dist/`. In the Pages
project settings set the **production branch to `production`** (must equal
`PROD_BRANCH` in `src/config.ts`); `main` stays the preview (every `*.pages.dev`
host is noindexed by the function).
