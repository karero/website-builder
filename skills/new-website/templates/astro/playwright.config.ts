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
  },
});
