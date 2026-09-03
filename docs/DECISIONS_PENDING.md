# Decisions pending

Questions flagged to Daniel that need a yes/no/defer call. SLA: decide or
explicitly defer within 48h (`check_open_ends.sh` flags older rows at
session start). Tick the row with the outcome once answered.

- [ ] 2026-08-31 — Should the hardcoded `PORT = 4329` in `skills/new-website/templates/astro/playwright.config.ts` change to something collision-resistant (derived from the project name/cwd hash, or an OS-assigned ephemeral port), given two unrelated scaffolds/sites on the same dev machine both default to the same port? (context: `skills/new-website/templates/astro/playwright.config.ts:3`; live evidence found 2026-08-31 while verifying the astro-preview-daemon fix: an orphaned `astro preview --port 4329` process from a since-torn-down website-builder worktree — `reverent-murdock-4c0c8c`, no longer in `git worktree list` — had been squatting port 4329 for 2+ days, PID reparented to init. `reuseExistingServer` silently reuses whatever already holds the port, so a second scaffold's `npm test` can pass against a stale/unrelated build without ever exercising its own. This is a separate, smaller judgment call from the daemon-mode fix already merged in #92 — no need to block other work on it.)
