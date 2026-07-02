# REVIEW — DIFF gate, PR #19, round 2 (2026-07-02)

Artifact: updated `git diff main...feat/llms-coverage-guard` after the round-1
fixes (b9c3a58), sent back as a VERIFICATION round: reviewers got the round-1
finding list, were asked to confirm each fix landed AND that the fixes introduced
nothing new, and were explicitly told not to oblige out of politeness.

## Reviewers (version / model / sandbox)
| Seat | Tool | Model | Sandbox | Outcome |
|---|---|---|---|---|
| cross-model 1 | codex-cli 0.142.5 (Codex.app bundle) | gpt-5.5 / xhigh | `exec -s read-only` | all r1 fixes confirmed; 4 new findings (1 BUG · 3 RISK) |
| cross-model 2 | antigravity-cli (agy) 1.0.15 | Gemini 3.1 Pro (High) | `--sandbox`, throwaway dir | all r1 fixes confirmed; 4 new findings (2 BUG · 2 RISK) |
| fresh-eyes | Claude (read-only sub-agent) | Fable-class | read-only tools | all r1 fixes VERIFIED-FIXED; no new findings |

Operational note: the first round-2 dispatch failed with exit 4 — the runner
script does not `mkdir -p` a custom `REVIEW_RAW_DIR` and misreported the I/O
failure as "no reviewer available". Never treated as clean; re-run after mkdir.
Script fix tracked as a separate task (spawned chip).

## Convergence
14 findings (r1) → 6 deduped new findings (r2), all targeting code ADDED by the
round-1 fixes, none re-litigating dispositioned ground, no oscillation — healthy.

## Dispositions

### Fixed (commit after this file)
- **gemini B1 + B2 (unified)** — the two tests parsed llms.txt two different ways:
  the missing-check hard-coded `](URL)` so a legit entry with a `#fragment`,
  `?query`, or markdown title falsely FAILED coverage, while the stale-check's
  regex captured `?query` into the path and falsely fired. Fixed: ONE shared
  `linkedPaths()` parse (link-target regex, fragment/query stripped, slash
  normalized) feeding all tests. Negative-tested: fragment/query/title links now
  count as coverage.
- **codex R4 / gemini R3** — asset filter `\.[a-z0-9]+$` swallowed dotted ROUTES
  (`/guides/v2.0`), silently exempting them from the stale guard. Fixed: explicit
  extension whitelist (`pdf|png|…|zip`). Negative-tested: `/guides/v2.0` now
  flags stale, `/whitepaper.pdf` still skipped.
- **codex R2 (assertion half)** — `LLMS_EXEMPT` only suppressed the missing-check;
  a deliberately-hidden page could still be LISTED in the public file and pass.
  Fixed: third test — exempt routes must stay OUT of llms.txt. Negative-tested:
  a leaked exempt page fires it.
- **codex B1** — the website-review Pass-1 edit reintroduced the unscoped
  "llms-coverage exists everywhere" claim that r1's codex R1 fix had scoped.
  Fixed: qualifier added (older sites copy the spec in from the starter).

### Rejected, with reason
- **codex R3** (require the `- [Title](URL): description` bullet format inside
  `## Key pages`) — any markdown link target in the public file hands the URL to
  AI engines, which is the guard's contract; format policing adds fragility for
  no coverage gain (Rule 2).
- **codex R2 ({route, reason} structure)** — comment-with-reason is the house
  pattern (`ORPHAN_EXEMPT`); a data structure can hold an empty reason just as
  easily as a missing comment.
- **gemini R4** (support `trailingSlash: 'always'` PAGES variants) — the kit pins
  `trailingSlash: 'never'`; `tests/_helpers.ts` states the slash-less convention
  and navigation/seo specs share the assumption. Not this suite's variant.

## Verdict — round 2
All round-1 fixes independently confirmed by both cross-model seats + fresh-eyes.
All round-2 BUGs fixed; accepted RISKs fixed; 3 rejections reasoned above.
Round 3 = external verification of the round-2 fixes.
