# REVIEW — DIFF gate, PR #19, round 3 (2026-07-02) — FINAL

Artifact: updated `git diff main...feat/llms-coverage-guard` after the round-2
fixes (9c1e072), verification round with the round-2 finding list attached.

## Reviewers (version / model / sandbox)
| Seat | Tool | Model | Sandbox | Outcome |
|---|---|---|---|---|
| cross-model 1 | codex-cli 0.142.5 (Codex.app bundle) | gpt-5.5 / xhigh | `exec -s read-only` | **no BUGs**; all r2 fixes confirmed; 2 RISK · 1 NIT |
| cross-model 2 | antigravity-cli (agy) 1.0.15 | Gemini 3.1 Pro (High) | `--sandbox`, throwaway dir | all r2 fixes verified mechanic-by-mechanic; 1 "BUG" (rejected, see below) · 1 RISK · 1 NIT |
| fresh-eyes | Claude (read-only sub-agent) | Fable-class | read-only tools | all r2 fixes VERIFIED-FIXED; zero new findings |

## Convergence — stop decision
14 (r1) → 6 (r2) → 6 (r3), but severity collapsed: zero confirmed BUGs, residuals
are parser-edge RISK/NITs. Per the rabbit-hole rule (count plateau two rounds),
iteration stops here: the three one-line hardenings below were applied and
verified mechanically; external re-verification of these micro-fixes is
deliberately deferred (proportionality — no open BUG, no open unwaived RISK).

## Dispositions

### Fixed (applied in the commit carrying this file, mechanically verified)
- **gemini R2** — regex anchored `http` to `](`; CommonMark allows
  `[Title]( url )`. Fixed: `\]\(\s*` whitespace tolerance. Verified: spaced links
  now count as coverage.
- **codex R2** — the asset skip could silently exempt a real PAGE route ending in
  `.json`/`.txt` from the stale guard. Fixed: fail-loud assert that no `PAGES`
  route matches the asset whitelist. Verified: `/data.json` in PAGES fires it.
- **gemini N1** — dead exemptions accumulate silently after a page is deleted.
  Fixed: fourth test — `LLMS_EXEMPT` may contain only live `PAGES` routes.
  Verified: a removed route's exemption fires it.

### Rejected, with reason
- **gemini B1** (percent-encoded links falsely fail; `decodeURI()`) — reclassified
  not-a-BUG: kit routes are Astro file-based slugs; a `PAGES` route containing a
  space/encoded char cannot occur in this scaffold, and `decodeURI` adds a
  URIError throw path for malformed `%` sequences — a new crash for an impossible
  case.
- **codex R1** (bespoke regex vs a Markdown parser; angle-bracket destinations,
  balanced parens) — the file's line format is prescribed by this kit
  (`- [Title](URL): description`, documented in README + the failure message);
  a Markdown parser dependency for syntax the file never uses is Rule-2
  over-engineering.
- **codex N1** (REVIEW-*.md trails at repo root) — house precedent: PR #18 merged
  its round trails at root; the trail surviving PR-comment archaeology is the
  point of the clerk procedure.

## Verdict — gate SATISFIED
All round-1 and round-2 findings independently confirmed fixed by two cross-model
seats + fresh-eyes. Round-3 residuals: 3 fixed + mechanically verified, 3 rejected
with reasons above, none waived-without-reason, no BUG open. Independence rule
met (codex + Gemini cross-model vs the Claude host/author).
