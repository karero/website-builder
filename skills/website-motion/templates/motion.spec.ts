import { test, expect } from '@playwright/test';

// Guards the `website-motion` contract: decorative motion may never cost a
// visitor access to content. A heading stranded at opacity 0 is invisible text,
// not a missed animation.
//
// This file exists because that failure mode is silent everywhere else. The rest
// of the suite reads textContent, which an opacity-0 element still returns, and
// a11y.spec.ts deliberately runs with reduced motion so axe sees a deterministic
// page. Without these tests the reveal could hide half the homepage and every
// other spec would still pass.
//
// Motion preference is set with page.emulateMedia, NOT test.use. Measured on
// Playwright 1.60 against this config, the test.use form was accepted without
// complaint and never reached the browser, which would leave the reduced-motion
// test below silently asserting nothing. Re-measure matchMedia before changing it.
//
// Delete the describe blocks for effects this site does not use.

const HEADINGS = '.section-title, .section-subtitle';

test.describe('with motion enabled', () => {
  test('no heading is left invisible after scrolling the whole page', async ({ page }) => {
    await page.emulateMedia({ reducedMotion: 'no-preference' });
    await page.goto('/');
    await page.waitForLoadState('load');

    // Headings below the fold start hidden — that is the effect working. If this
    // is zero the reveal is silently dead and the rest of the test proves nothing.
    const hiddenAtLoad = await page.locator(HEADINGS).evaluateAll(
      (els) => els.filter((e) => getComputedStyle(e).opacity !== '1').length);
    expect(hiddenAtLoad, 'reveal never engaged — the effect is silently dead').toBeGreaterThan(0);

    await page.evaluate(async () => {
      document.documentElement.style.scrollBehavior = 'auto';
      for (let y = 0; y < document.body.scrollHeight; y += 300) {
        window.scrollTo({ top: y, behavior: 'instant' as ScrollBehavior });
        await new Promise((r) => setTimeout(r, 25));
      }
    });

    await expect
      .poll(async () => page.locator(HEADINGS).evaluateAll(
        (els) => els.filter((e) => getComputedStyle(e).opacity !== '1')
          .map((e) => e.textContent!.trim().slice(0, 40))), {
        message: 'headings still invisible after a full scroll-through',
        timeout: 5000,
      })
      .toEqual([]);
  });

  test('hero stats settle on their published values', async ({ page }) => {
    await page.emulateMedia({ reducedMotion: 'no-preference' });
    await page.goto('/');
    // Pins the published figures — they are real claims and should not change
    // silently. Deliberately NOT a test of the count-up: the final frame restores
    // the authored string, so this also passes with the animation dead. Catching
    // a broken parse mid-flight means sampling a 1.4s rAF animation, which is
    // flakiness this gate declines to buy.
    // EDIT THIS LIST to the site's real numbers.
    await expect(page.locator('.hero-stat-number')).toHaveText(
      ['14+', '1,200+'], { timeout: 5000 });
  });
});

test.describe('with reduced motion', () => {
  test('nothing animates and nothing is hidden', async ({ page }) => {
    await page.emulateMedia({ reducedMotion: 'reduce' });
    await page.goto('/');
    await page.waitForLoadState('load');

    const state = await page.evaluate(() => ({
      hidden: [...document.querySelectorAll('.section-title, .section-subtitle')]
        .filter((e) => getComputedStyle(e).opacity !== '1').length,
      // Cover the page's OTHER animations too, not just the ones this skill added
      // — otherwise the test's own name is a lie. Add any ambient/decorative
      // animation this site runs.
      heroAmbient: getComputedStyle(document.querySelector('.hero')!, '::before').animationName,
      scrollBehavior: getComputedStyle(document.documentElement).scrollBehavior,
    }));

    expect(state.hidden, 'content hidden despite reduced motion').toBe(0);
    expect(state.heroAmbient, 'ambient hero animation still running').toBe('none');
    expect(state.scrollBehavior, 'smooth scrolling still on').toBe('auto');
  });
});
