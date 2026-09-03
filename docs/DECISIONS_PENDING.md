# Decisions pending

Open maintainer decisions on this toolkit, kept in the repo so they don't die with a chat
session. Each needs a yes/no/defer call within 48h (a maintainer-side script surfaces older
rows at session start). Tick the row with the outcome once answered.

- [ ] 2026-08-31 — Should the hardcoded `PORT = 4329` in `skills/new-website/templates/astro/playwright.config.ts` change to something collision-resistant (derived from the project name/cwd hash, or an OS-assigned ephemeral port), given two unrelated scaffolds/sites on the same dev machine both default to the same port? (context: `skills/new-website/templates/astro/playwright.config.ts:3`; found 2026-08-31 while verifying the astro-preview-daemon fix from #92: an orphaned `astro preview --port 4329` from an earlier, deleted checkout had held the port for 2+ days, and `reuseExistingServer` silently reuses whatever holds the port, so a second scaffold's `npm test` can pass against a stale, unrelated build without ever exercising its own. A separate, smaller call than the daemon-mode fix — no need to block other work on it.)
