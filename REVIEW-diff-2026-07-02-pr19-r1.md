# REVIEW — DIFF gate, PR #19, round 1 (2026-07-02)

Artifact: `git diff main...feat/llms-coverage-guard` — the llms-coverage test guard
(port of the m-squad.com guard into the new-website starter suite) + doc updates.

## Reviewers (version / model / sandbox)
| Seat | Tool | Model | Sandbox | Outcome |
|---|---|---|---|---|
| cross-model 1 | codex-cli 0.142.5 (Codex.app bundle) | gpt-5.5 / xhigh | `exec -s read-only` | 5 findings (4 RISK · 1 NIT) |
| cross-model 2 | antigravity-cli (agy) 1.0.15 | Gemini 3.1 Pro (High) | `--sandbox`, throwaway dir | 4 findings (1 BUG · 2 RISK · 1 NIT) |
| fresh-eyes | Claude (read-only sub-agent, no shared context) | Fable-class | read-only tools | 5 findings (1 BUG · 2 RISK · 2 NIT) |

Independence: host = Claude Code; gate satisfied by two cross-model seats (codex, gemini).
Data check: diff grepped for secrets before dispatch — clean; owner requested the external review explicitly.

## Dispositions

### Fixed (all BUGs — none waived)
- **gemini B1 / codex R2** — the guard forced *deliberately-unlinked* pages (paid-ad
  landers, the `ORPHAN_EXEMPT` kind) into the PUBLIC llms.txt, exposing them to AI
  engines. Fixed: `LLMS_EXEMPT` opt-out set (explicit, with-reason — mirrors the
  orphans.spec pattern).
- **codex R4 / gemini R2 / claude R1** — `${SITE.url}${route}` double-slashes if the
  config ever ships a trailing slash. Fixed: `const base = SITE.url.replace(/\/+$/, '')`;
  verified green under both config forms.
- **codex R3** — the guard was one-way: a removed/renamed route left a stale llms.txt
  entry forever. Fixed: second test — every same-site page link in llms.txt must map
  back to a `PAGES` route (asset links like `.pdf` skipped). Negative-tested: a
  simulated rename fires the guard. Template llms.txt's phantom example pages
  (`/about`, `/how-it-works`) removed — they'd now correctly fail it.
- **codex R1** — docs claimed the test enforces coverage unconditionally; older sites
  don't have it. Fixed: website-seo-geo qualified ("new-website starter suite; on a
  site that predates the guard, copy the spec in").
- **claude B1 (reclassified: false positive, hardening adopted)** — claimed the `(URL)`
  match can't see markdown links; wrong (a markdown link *contains* `(URL)`, and the
  check passes in production on m-squad). But the stricter `](URL)` anchor was adopted:
  it pins a markdown link TARGET, so a bare URL in prose no longer satisfies coverage.

### Rejected, with reason
- **gemini R3** (`process.cwd()` brittle) — suite convention: `seo.spec.ts:92,275` uses
  the identical pattern; Playwright runs from the config root in this kit (Rule 11 —
  don't fork convention in one spec).
- **gemini N1** (eager error-message evaluation) — cost trivial; the message carries the
  `- [Title](URL): description` how-to-fix that Playwright's native array dump lacks.
- **codex N1** (dated "FOUR times" anecdote too long) — house style: the suite's specs
  carry long WHY comments (orphans.spec precedent); the anecdote is the test's reason
  to exist.
- **claude R2** (template could false-positive on real projects / "run it in CI") — it
  does run in CI (`npm test` in the scaffold's ci.yml); template green-from-commit-1
  verified mechanically.
- **claude N1** (docs don't show the match format) — covered: README blockquote says
  "markdown link to its full production URL" and the failure message shows the line format.
- **claude N2** (pre-commit hook to force same-commit updates) — CI on the PR is the
  enforcement point; a pre-commit hook is over-engineering (Rule 2).

## Verdict — round 1
Both BUGs (one per Gemini, one reclassified) dispositioned; all four accepted RISKs
fixed and mechanically verified (missing + stale + trailing-slash + rename simulations).
No waivers pending. Round 2 = external verification of the fixes.
