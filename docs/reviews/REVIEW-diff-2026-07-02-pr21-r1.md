# Independent review trail — DIFF gate, PR #21, round 1

- **Artifact:** `git diff main...docs/no-probe-before-active` (PR #21 — docs-only:
  "never request a live-domain page before its build is Active" section in
  `skills/new-website/SKILL.md`), 30 lines.
- **Reviewer:** Antigravity CLI `agy` 1.0.15, model **Gemini 3.1 Pro (High)**,
  `--sandbox -p`, throwaway dir. Cross-model seat (host agent: Claude). Other tiers
  skipped at the owner's request — Antigravity only.
- **Data check:** diff grepped for denylist names + credential formats — clean.
- **Date:** 2026-07-02. Fix commit: `7531038`.

## Findings and dispositions

| # | Sev | Location | Finding | Disposition |
|---|-----|----------|---------|-------------|
| 1 | BUG | SKILL.md §"Never request…", bullet 1 | `?cb=` cache-bust offered as a PRE-Active verification path — but pre-Active the live domain serves the *previous* deployment, so the new path 404s at origin regardless; the bullet couldn't work | **Fixed** — pre-Active = hash URL only; `?cb=` moved to the post-Active live-domain check |
| 2 | RISK | bullet 4 | "single-URL purge in the dashboard" implies the agent can do it; it's a human-only GUI action | **Fixed** — "ask the owner … (a human-only step — the agent has no dashboard access)" |
| 3 | NIT | bullet 2 | "owner's browser to cache the 404 for everyone" — browsers cache locally; the *request* makes the edge cache it | **Fixed** — reworded to the edge caching on the owner's first click |

## Reviewer's CLEAN list (round 1)

Core Cache-Everything-caches-404 premise validated; wrangler OAuth token cannot
purge (zone read only) — manual-dashboard claim correct; cached-404s surviving
past TTL and ignoring plain re-requests accurate; GSC Request-Indexing danger
real (Googlebot hits the same edge cache); Active-before-canonical sequencing
correct.

## Verdict after round 1

1 BUG, 1 RISK, 1 NIT — all fixed in `7531038`. Round 2 = verification; see
`REVIEW-diff-2026-07-02-pr21-r2.md`.
