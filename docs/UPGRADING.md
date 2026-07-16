# Upgrading this site's Astro version

**For your AI assistant.** If you're a person reading this: just tell your AI assistant
"upgrade my site to Astro 7" — it will follow the checklist below. You don't need to run any
of these commands yourself.

## When this applies

Check `package.json` in the site root. If `"astro"` is pinned below `^7.0.0`, this checklist
applies. (Sites scaffolded via `npm create astro@latest` after ~2026-07 already got Astro 7
automatically and don't need this.)

## Before starting

Tell the site owner what you're about to do and why (a build-tooling version bump, not a
content or design change), and confirm they want it now rather than later.

## Steps

1. **Bump the dependency.** In `package.json`, change `"astro": "^6.0.0"` (or whatever's
   currently pinned) to `"astro": "^7.1.0"`. Run `npm install` to regenerate
   `package-lock.json`. Commit the lockfile — CI uses `npm ci`, which needs it.

2. **Do NOT bump `typescript` to `^7` in the same change.** Astro's own type-checker
   (`@astrojs/check`) doesn't support TypeScript 7 yet — its peer range caps at
   `typescript: "^5.0.0 || ^6.0.0"` (tracked at
   [withastro/roadmap#1321](https://github.com/withastro/roadmap/discussions/1321)). If a
   separate dependency update bumps `typescript` around the same time, don't merge both
   together — `npm run check` will break.

3. **Build first, before running the test suite.** `npm run build` (or `astro build`). Astro
   7's compiler is stricter about malformed HTML — unclosed tags/attributes now throw instead
   of being silently auto-corrected. If something's genuinely broken, this is where it
   surfaces, with an exact file:line. Fix the real problem; don't work around it.

4. **Check for a whitespace regression the test suite can't catch.** Astro 7 changed how
   whitespace between inline elements renders by default (`compressHTML` now defaults to
   `'jsx'` — it collapses whitespace using JSX rules instead of the old lossless behavior).
   Anywhere the site has two inline elements (e.g. two `<a>` tags, an icon `<span>` next to
   text) separated only by a newline with no explicit space, a visible gap can silently
   disappear.
   - Build the OLD version to a SEPARATE directory before touching anything (e.g.
     `npm run build && mv dist dist-before-upgrade`, or use a git worktree) — the upgrade
     build will overwrite `dist/` otherwise, and you need something to diff against.
   - After the upgrade build, spot-check rendered pages — especially the footer and nav,
     where adjacent links are common — against `dist-before-upgrade` for words or links that
     now run together.
   - If the site uses `scripts/anchor-ids.mjs` (heading auto-ids), re-run it and diff the
     generated `id`s against the pre-upgrade `dist/`. A shifted id silently breaks any
     hand-authored `#fragment` link elsewhere on the site or from outside it.

5. **Smoke-test the sitemap.** As of this writing, `@astrojs/sitemap` hasn't been separately
   re-certified against Astro 7 by its own maintainers. Confirm `dist/sitemap.xml` (or
   `dist/sitemap-index.xml`) still generates, with the expected URL count.

6. **Run the full test suite.** `npm test`. A pass here does NOT substitute for steps 3–5 —
   none of the a11y/seo/navigation/anchors/orphans/images/tone/positioning/email/links/
   llms-coverage specs do visual-regression or before/after diffing, so they structurally
   cannot catch the whitespace-collapse risk in step 4.

7. **Using Keystatic as a CMS?** Its Astro integration's compatibility with Astro 7 hasn't
   been separately verified. Check `@keystatic/astro`'s current release notes before assuming
   it still works, rather than finding out from a broken build.

8. **Report back to the owner in plain language**: what changed, what you checked, and
   anything that needs a human look (e.g. "the footer looked right, but double-check the nav
   on your phone" if you couldn't verify something visually).

## Why these specific steps

This checklist reflects issues actually found and verified during the karero/website-builder
toolkit's own Astro 6→7 migration (2026-07-16) — it's not generic upgrade advice. If Astro
ships another major version later, this file should be rewritten for that transition rather
than assumed to still apply as-is.
