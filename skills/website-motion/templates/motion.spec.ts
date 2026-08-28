import { test, expect, type Page } from '@playwright/test';

// Guards the `website-motion` contract: decorative motion may never cost a
// visitor access to content. A heading stranded at opacity 0 is invisible text,
// not a missed animation.
//
// This file exists because that failure mode is silent everywhere else. The rest
// of the suite reads textContent, which a hidden element still returns, and
// a11y.spec.ts deliberately runs with reduced motion so axe sees a deterministic
// page. Without these tests the reveal could hide half the homepage and every
// other spec would still pass.
//
// Motion preference is set with page.emulateMedia, NOT test.use — see the skill's
// §4 for the measurement behind that, and re-measure before changing it.

// ── EDIT THIS BLOCK ──────────────────────────────────────────────────────────
// These are YOUR site's class names. The Astro scaffold ships none of them, so
// nothing here works until you point it at your own markup. Leave a value empty
// and the tests needing it skip with a stated reason, rather than throwing a
// selector error that reads like a product bug.
const CONFIG = {
  /** Headings the reveal is applied to. Required, or every test skips. */
  revealTargets: '.section-title, .section-subtitle',
  /** Hero stat numbers the count-up animates. Empty = site has no stats. */
  statNumbers: '.hero-stat-number',
  /** The stats' authored values, in DOM order. Empty = skip the snapshot. */
  publishedStats: [] as string[],
  /**
   * Animation names allowed to keep running under reduced motion. Should stay
   * empty: an entry here is a decision to ignore a visitor's stated preference,
   * not a convenience.
   */
  motionExceptions: [] as string[],
};
// ─────────────────────────────────────────────────────────────────────────────

// opacity alone is not "visible": a refactor to visibility/display hides too, so
// every check below tests all three. The probe is repeated inside each evaluate
// rather than shared — code crossing Playwright's browser boundary cannot close
// over a helper defined out here.
async function hiddenTargets(page: Page): Promise<string[]> {
  return page.locator(CONFIG.revealTargets).evaluateAll((els) =>
    els.filter((el) => {
      const s = getComputedStyle(el);
      return s.display === 'none' || s.visibility !== 'visible' || parseFloat(s.opacity) < 1;
    }).map((e) => (e.textContent ?? '').trim().slice(0, 40)));
}

test.beforeEach(() => {
  test.skip(!CONFIG.revealTargets,
    "CONFIG.revealTargets is empty — point it at this site's headings");
});

test.describe('with motion enabled', () => {
  test('no heading is left invisible after scrolling the whole page', async ({ page }) => {
    await page.emulateMedia({ reducedMotion: 'no-preference' });
    await page.goto('/');
    await page.waitForLoadState('load');

    // Two properties at load, and NOT "every below-fold target is hidden" — the
    // reveal pairs a heading with only its first following subtitle, so a section
    // with two subtitles legitimately leaves one alone. Asserting equality there
    // fails on correct code.
    const { belowFold, hiddenTotal, hiddenAboveFold } = await page.evaluate((sel) => {
      const hiddenNow = (el: Element) => {
        const s = getComputedStyle(el);
        return s.display === 'none' || s.visibility !== 'visible' || parseFloat(s.opacity) < 1;
      };
      const els = [...document.querySelectorAll(sel)];
      const above = els.filter((e) => e.getBoundingClientRect().top < window.innerHeight);
      return {
        belowFold: els.length - above.length,
        hiddenTotal: els.filter(hiddenNow).length,
        hiddenAboveFold: above.filter(hiddenNow).length,
      };
    }, CONFIG.revealTargets);

    // Anything already on screen must be left alone, or it visibly flashes out
    // and fades back in on load. This one holds at any viewport.
    expect(hiddenAboveFold, 'a heading already on screen was hidden — it will flash on load')
      .toBe(0);
    // And the effect has to be doing something, or the scroll-through below
    // proves nothing. Skipped rather than failed when there is nothing to hide.
    test.skip(belowFold === 0,
      'no headings below the fold at this viewport — guard not applicable');
    expect(hiddenTotal, 'nothing was hidden despite headings below the fold — effect not running')
      .toBeGreaterThan(0);

    await page.evaluate(async () => {
      document.documentElement.style.scrollBehavior = 'auto';
      for (let y = 0; y < document.body.scrollHeight; y += 300) {
        window.scrollTo({ top: y, behavior: 'instant' as ScrollBehavior });
        await new Promise((r) => setTimeout(r, 25));
      }
    });

    await expect
      .poll(() => hiddenTargets(page), {
        message: 'headings still invisible after a full scroll-through',
        timeout: 5000,
      })
      .toEqual([]);
  });

  test('reveal targets are visible when printing', async ({ page }) => {
    await page.emulateMedia({ reducedMotion: 'no-preference' });
    await page.goto('/');
    await page.waitForLoadState('load');
    // Deliberately WITHOUT scrolling: the below-fold headings are hidden right
    // now, which is exactly the state a print captures. Printing never scrolls,
    // so IntersectionObserver never fires and only the print override saves
    // them. Delete that override and this is the only test that notices.
    await page.emulateMedia({ media: 'print' });
    expect(await hiddenTargets(page), 'headings would print blank').toEqual([]);
  });

  test('hero stats settle on their published values', async ({ page }) => {
    test.skip(!CONFIG.statNumbers || CONFIG.publishedStats.length === 0,
      'CONFIG.statNumbers / publishedStats not set — site has no hero stats');
    await page.emulateMedia({ reducedMotion: 'no-preference' });
    await page.goto('/');
    // Pins the published figures — they are real claims and should not change
    // silently. Deliberately NOT a test of the count-up: the final frame restores
    // the authored string, so this also passes with the animation dead. Catching
    // a broken parse mid-flight means sampling a ~1.4s rAF animation, which is
    // flakiness this gate declines to buy.
    await expect(page.locator(CONFIG.statNumbers))
      .toHaveText(CONFIG.publishedStats, { timeout: 5000 });
  });
});

test.describe('with reduced motion', () => {
  test('nothing is hidden and nothing is animating', async ({ page }) => {
    await page.emulateMedia({ reducedMotion: 'reduce' });
    await page.goto('/');
    await page.waitForLoadState('load');

    expect(await hiddenTargets(page), 'content hidden despite reduced motion').toEqual([]);

    // Enumerated, not named. Listing specific selectors only catches animations
    // you already thought of, and throws on a site that does not have them.
    // getAnimations finds every running one, pseudo-elements included.
    await page.waitForTimeout(600); // let any legitimate transition finish
    const running = await page.evaluate((allowed) =>
      document.getAnimations({ subtree: true })
        .filter((a) => a.playState === 'running')
        .map((a) => {
          const anim = a as Animation & { animationName?: string; transitionProperty?: string };
          return anim.animationName ?? anim.transitionProperty ?? 'unnamed';
        })
        .filter((name) => !allowed.includes(name)),
      CONFIG.motionExceptions);
    expect(running, 'still animating under reduced motion').toEqual([]);

    // Neither assertion above can catch a mis-ordered CSS override on its own:
    // the reveal's JS bails under reduce, so the hiding class is never added and
    // the stylesheet path is never exercised. Force it on to prove the CSS
    // itself honours the preference.
    const forced = await page.evaluate((sel) => {
      const el = document.querySelector(sel.split(',')[0].trim());
      if (!el) return null;
      el.classList.add('reveal');
      const opacity = getComputedStyle(el).opacity;
      el.classList.remove('reveal');
      return opacity;
    }, CONFIG.revealTargets);
    if (forced !== null) {
      expect(forced, 'the .reveal rule still hides under reduced motion — is the override ' +
        'placed BEFORE the rule it overrides?').toBe('1');
    }
  });
});
