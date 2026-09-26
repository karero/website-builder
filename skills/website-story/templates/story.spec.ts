import { test, expect } from '@playwright/test';

// Guards the website-story layer on the home page (see STORY.md): the direct CTA is
// repeated, the story's key line is really on the page, and the plan is a real
// numbered list. Hermetic string checks, a sibling of positioning.spec.ts: no
// network, no extraction library, not a density check.
//
// This file lives in the website-story skill rather than the new-website Astro
// overlay because a fresh scaffold has no story to assert. Copy it into tests/ only
// when the site opted in, then fill CONFIG from the values listed at the end of
// STORY.md. While CONFIG is empty every test skips with a stated reason, so an
// unconfigured copy reports "not applicable" instead of failing like a product bug.

// ── EDIT THIS BLOCK ──────────────────────────────────────────────────────────
const CONFIG = {
  /** Direct CTA label, verbatim from STORY.md §5. Empty = every test skips. */
  directCta: '',
  /** Header plus at least one repeat. */
  directCtaMin: 2,
  /** The one-liner OR the controlling idea, verbatim. Empty = that test skips. */
  keyLine: '',
  /** Selector for the plan's <ol> (e.g. '#plan ol'). Empty = that test skips. */
  planList: '',
  /** A plan has three steps; four at most. Five is a process page. */
  planSteps: { min: 3, max: 4 },
  /** The page the story is told on. */
  home: '/',
};
// ─────────────────────────────────────────────────────────────────────────────

// Case- and whitespace-insensitive containment, same spirit as positioning.spec.ts:
// a label wrapped onto two lines or set in small caps still counts.
const norm = (s: string) => s.toLowerCase().replace(/\s+/g, ' ').trim();

test.beforeEach(() => {
  test.skip(!CONFIG.directCta,
    'CONFIG.directCta is empty: fill it from STORY.md §5 to enable the story guard');
});

test.describe('story layer (home page)', () => {
  test('the direct CTA appears as a link or button at least twice', async ({ page }) => {
    await page.goto(CONFIG.home);
    // Counted in <a>/<button> text, not body text, so a sentence that merely
    // mentions the words is not mistaken for a call to action.
    const labels = await page.locator('a, button').allInnerTexts();
    const hits = labels.filter((t) => norm(t).includes(norm(CONFIG.directCta))).length;
    expect(hits,
      `"${CONFIG.directCta}" found ${hits}x as a link/button on ${CONFIG.home}; ` +
      `STORY.md asks for at least ${CONFIG.directCtaMin} (header + one repeat)`)
      .toBeGreaterThanOrEqual(CONFIG.directCtaMin);
  });

  test('the one-liner or controlling idea is in the body text', async ({ page }) => {
    test.skip(!CONFIG.keyLine,
      'CONFIG.keyLine is empty: set the one-liner or the controlling idea');
    await page.goto(CONFIG.home);
    const body = await page.evaluate(() => document.body.innerText);
    expect(norm(body).includes(norm(CONFIG.keyLine)),
      `key line missing from ${CONFIG.home}: "${CONFIG.keyLine}". ` +
      'Say it once, in the header or the intro paragraph.')
      .toBe(true);
  });

  test('the plan is one numbered list of three or four non-empty steps', async ({ page }) => {
    test.skip(!CONFIG.planList,
      'CONFIG.planList is empty: point it at the plan <ol>');
    await page.goto(CONFIG.home);
    const ol = page.locator(CONFIG.planList);
    await expect(ol, `expected exactly one element matching "${CONFIG.planList}"`)
      .toHaveCount(1);
    const steps = await ol.locator(':scope > li').allInnerTexts();
    expect(steps.length,
      `plan has ${steps.length} steps; STORY.md asks for ${CONFIG.planSteps.min}-${CONFIG.planSteps.max}`)
      .toBeGreaterThanOrEqual(CONFIG.planSteps.min);
    expect(steps.length,
      `plan has ${steps.length} steps; more than ${CONFIG.planSteps.max} is a process page, not a plan`)
      .toBeLessThanOrEqual(CONFIG.planSteps.max);
    expect(steps.filter((s) => !s.trim()).length, 'an empty plan step').toBe(0);
  });
});
