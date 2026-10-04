import { test, expect } from '@playwright/test';
import { existsSync, readFileSync } from 'node:fs';
import { summarize, parseLighthouse, sameState } from '../scripts/scorecard.mjs';

// Guards the published scorecard (the website-scorecard skill): the numbers on the
// page are the numbers in scorecard.json, the file adds up, and the script's own
// arithmetic is pinned. It lives in that skill, not in the starter, because a new
// site has no scorecard to check. Copy it into tests/ when the site adopts one and
// set PAGE below. Until scorecard.json exists the two file tests skip and say why.

// The page that carries <Scorecard />, e.g. '/about'. Empty = the page test skips.
const PAGE = '';

const card = existsSync('scorecard.json') ? JSON.parse(readFileSync('scorecard.json', 'utf8')) : null;

// While `npm run scorecard` writes a new card, the checks of the old one sit out:
// otherwise a card that is wrong could never be replaced.
test.skip(!!process.env.SCORECARD_RUN, 'a new scorecard is being written');

test('scorecard — the script counts a run correctly and refuses bad scores', () => {
  const run = {
    suites: [
      { file: 'a11y.spec.ts', specs: [{ tests: [{ status: 'expected' }, { status: 'expected' }] }] },
      { file: 'seo.spec.ts', specs: [{ tests: [{ status: 'expected' }] }], suites: [{ specs: [{ tests: [{ status: 'skipped' }] }] }] },
      { file: 'tone.spec.ts', specs: [{ tests: [{ status: 'unexpected' }, { status: 'flaky' }] }] },
      { file: 'scorecard.spec.ts', specs: [{ tests: [{ status: 'expected' }, { status: 'skipped' }] }] },
    ],
  };
  expect(summarize(run)).toEqual({
    checks: [
      { area: 'a11y', passed: 2, skipped: 0, failed: 0 },
      { area: 'seo', passed: 1, skipped: 1, failed: 0 },
      { area: 'tone', passed: 0, skipped: 0, failed: 2 },
    ],
    passed: 3, skipped: 1, failed: 2,
  });
  expect(parseLighthouse('98,100,100,100', '2026-10-04').value).toEqual({
    date: '2026-10-04', strategy: 'mobile', performance: 98, accessibility: 100, bestPractices: 100, seo: 100,
  });
  for (const bad of ['98,100,100', '98,100,100,101', '98,100,100,x', '9.8,100,100,100', '']) {
    expect(parseLighthouse(bad, '2026-10-04').error, `"${bad}" must be refused`).toBeTruthy();
  }
  expect(parseLighthouse('98,100,100,100', '4 October').error, 'a date that is not a date must be refused').toBeTruthy();
  expect(parseLighthouse('98,100,100,100', '2026-10-04', 'tablet').error, 'an unknown strategy must be refused').toBeTruthy();
  // "Edited since" is decided here: any path added, removed or changed counts.
  expect(sameState({ src: 'a', public: 'b' }, { src: 'a', public: 'b' })).toBe(true);
  expect(sameState({ src: 'a', public: 'b' }, { src: 'a', public: 'c' }), 'a changed folder').toBe(false);
  expect(sameState({ src: 'a', functions: 'f' }, { src: 'a' }), 'a folder added later').toBe(false);
  expect(sameState({ src: 'a' }, { src: 'a', functions: 'f' }), 'a folder removed later').toBe(false);
  expect(sameState({}, undefined), 'nothing to compare is not "unchanged"').toBe(false);
});

test('scorecard — scorecard.json adds up and claims no failure', () => {
  test.skip(!card, 'no scorecard.json yet: run "npm run scorecard"');
  const sum = (k: 'passed' | 'skipped') => card.checks.reduce((n: number, c: Record<string, number>) => n + (c[k] ?? 0), 0);
  expect(card.passed, 'the total must be the sum of the areas').toBe(sum('passed'));
  expect(card.skipped, 'the skipped total must be the sum of the areas').toBe(sum('skipped'));
  expect(card.passed, 'a card with nothing passed is not a card').toBeGreaterThan(0);
  expect(card.checks.filter((c: Record<string, number>) => c.failed), 'the script never writes a failed area').toEqual([]);
  expect(card.commit, 'the tested commit must be a full id').toMatch(/^[0-9a-f]{40}$/);
  expect(card.generated).toMatch(/^\d{4}-\d{2}-\d{2}$/);
  expect(Object.keys(card.tested ?? {}), 'the card must say what it tested').toEqual(expect.arrayContaining(['src', 'tests', 'package.json']));
});

test('scorecard — the page shows the numbers in the file', async ({ page }) => {
  test.skip(!PAGE, 'PAGE is not set: name the page that carries <Scorecard />');
  test.skip(!card, 'no scorecard.json yet: run "npm run scorecard"');
  await page.goto(PAGE);
  const section = page.locator('[data-scorecard]');
  await expect(section, `${PAGE} must render the scorecard`).toHaveCount(1);
  await expect(section.locator('[data-scorecard-passed]')).toContainText(String(card.passed));
  await expect(section.locator('[data-scorecard-tested]')).toContainText(card.generated);
  await expect(section.locator('[data-scorecard-tested]')).toContainText(card.commit.slice(0, 7));
  const rows = await section.locator('tbody tr').count();
  expect(rows, 'one row per area in the file').toBe(card.checks.length);
  // A card that no longer describes the site must say so; one that does must not.
  const state = await section.getAttribute('data-state');
  await expect(section.locator('[data-scorecard-edited]')).toHaveCount(state === 'edited' ? 1 : 0);
});
