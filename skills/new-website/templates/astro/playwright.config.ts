import { defineConfig, devices } from '@playwright/test';

const PORT = 4329;
const BASE = `http://localhost:${PORT}`;

// Tests run against a PRODUCTION build served by `astro preview` — the same static
// output Cloudflare serves. Never test a dev mock of the thing you ship.
export default defineConfig({
  testDir: './tests',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 1 : 0,
  reporter: 'list',
  use: { baseURL: BASE, trace: 'on-first-retry' },
  projects: [{ name: 'chromium', use: { ...devices['Desktop Chrome'] } }],
  webServer: {
    command: `npm run build && npm run preview -- --port ${PORT}`,
    url: `${BASE}/`,
    timeout: 120_000,
    reuseExistingServer: !process.env.CI,
    // Astro >=7.2's `astro preview` auto-daemonizes when it detects an AI coding
    // agent as its caller (isRunByAgent()), even without --background — the launcher
    // process then exits immediately and Playwright reports "exited early" even
    // though a server is listening. Astro only checks this var for truthiness
    // (plain `!`/`!!`, no special-casing of any string), so any non-empty value
    // short-circuits the check — use '1', not 'false': the string 'false' is
    // truthy too and "works", but reads as an off-switch and invites a future
    // edit that silently reintroduces this bug.
    env: { ASTRO_PREVIEW_BACKGROUND: '1' },
  },
});
