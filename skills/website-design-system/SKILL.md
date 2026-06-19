---
name: website-design-system
description: >
  The visual build standards for a new site: mobile-first responsive graphics
  (WebP/AVIF, sized-to-display, srcset, lazy-load, descriptive alt, no layout
  shift), dark mode (CSS-variable theme tokens + a no-FOUC script + WCAG AA
  contrast in BOTH themes), and the brand/theme token block that BRAND.md
  mirrors. Use when building or reviewing layout, images, theming, or BRAND.md
  (step 5 of the new-website pipeline). Contrast is enforced by a11y.spec.ts
  (light+dark). Trigger phrases: "dark mode", "theme toggle", "responsive
  images", "mobile optimization", "image optimization", "WebP", "layout shift",
  "CLS", "design system", "theme tokens", "brand colors", "BRAND.md".
---

# Website design system

Owns the **how it looks and performs visually** layer: mobile graphics, dark
mode, and the theme tokens. Outputs/maintains `BRAND.md` (template in
`~/.claude/skills/new-website/templates/brand.md`) and the token block in
`~/.claude/skills/new-website/templates/astro/src/styles/global.css`. Image rules
are below (WebP/AVIF via Astro's `astro:assets`); the `images.spec.ts` test
enforces them. For generating image assets, use the `image` skill.

## Dark mode (first-class)

- **Tokens, not hard-coded colours.** All colour flows through CSS custom
  properties; light is the `:root` default, dark overrides under
  `:root[data-theme="dark"]`, plus a `@media (prefers-color-scheme: dark)` block
  for no-JS visitors. The starter ships this exact structure.
- **No-FOUC script** in `<head>` sets `data-theme` from `localStorage.theme` or
  the system preference *before first paint* (already wired in `Base.astro`).
  The toggle writes `localStorage.theme`.
- **Contrast both themes:** every text/background pair passes WCAG AA (4.5:1
  body, 3:1 large/UI). A colour that passes in light often fails in dark — the
  a11y test runs the full light+dark matrix, so check both.

## Mobile & responsive graphics

- **Mobile first:** design from 360px up; tap targets ≥ 44px; no horizontal
  scroll. Verify at 360 / 768 / 1280 (preview_resize).
- **Modern formats:** WebP (or AVIF) over JPEG/PNG for photos.
- **Size to display, not source.** Never ship a 2000px image into an 80px slot;
  generate width variants and use `srcset`/`sizes` (or `<picture>`).
- **No layout shift:** set explicit `width`/`height` **attributes** so the box is
  reserved before the image loads (protects CLS / LCP). Astro's `<Image>` sets them
  automatically; `images.spec.ts` requires the attributes (a CSS-only aspect-ratio
  will not satisfy the test).
- **Lazy vs eager:** `loading="lazy"` below the fold; the LCP/hero image loads
  eager with `fetchpriority="high"` (do NOT lazy-load it).
- **Alt text on every image** (`alt=""` only if purely decorative).
- **Fonts:** self-host woff2 with `font-display: swap`; preload only the 1–2 used
  above the fold. Avoid layout shift from late font swaps.

## Email obfuscation (hide addresses from crawlers)

Never put a plaintext email or `mailto:your@addr` in the HTML source — scrapers harvest it
for spam within hours. Render every address through the **`EmailLink.astro`** component
(`~/.claude/skills/new-website/templates/astro/src/components/EmailLink.astro` + its
`lib/obfuscate.ts` helper): the address is reversed + base64-encoded at build time and
reassembled in the browser, so the served HTML contains no readable address. No-JS visitors
see a still-usable "name [at] domain [dot] com" hint.

```astro
<EmailLink address="hello@example.com" subject="Project enquiry" text="Email us" />
```
Rule: **zero raw `mailto:` links and zero literal `@`-addresses in built HTML** — `website-qa`
checks this. Same idea for any phone number you don't want harvested.

## Brand tokens

Mirror `BRAND.md`'s palette into the token block and keep them in sync. Define:
brand/accent (fixed), and per-theme heading/ink/muted/line/bg/surface. The accent
used for links must pass AA on the background in both themes.

## Done means

`BRAND.md` filled and consistent with the token block; images are WebP, sized,
lazy/eager-correct, with alt; the a11y test (light+dark) is green; layout holds
at 360/768/1280 with no shift. Perf numbers (FCP/LCP) are verified in `website-qa`.
