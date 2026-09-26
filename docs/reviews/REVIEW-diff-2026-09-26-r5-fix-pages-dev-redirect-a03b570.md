# Independent review — DIFF — pages.dev production-alias redirect (rounds 1–5)

Branch `fix/pages-dev-redirect`. Reviewed pairs: base `7a17049`, heads `1373e28` → `138c2e1`.
Raw reviewer output, verbatim: `RAW-diff-2026-09-26-r5-fix-pages-dev-redirect-a03b570.md`.

**The change.** AI search engines were seen citing a site's Cloudflare Pages production alias
`<project>.pages.dev` instead of its custom domain, although the template middleware already
noindexed every `*.pages.dev` host. `functions/_middleware.ts` now 301-redirects that exact alias
(the only three-label `pages.dev` host) to the live origin, keeping path and query, once the
Production variable `CANONICAL_URL` is set. Branch and hash previews keep the noindex header and
are never redirected. The switch is a Cloudflare variable, not `SITE.url`, by owner decision:
`SITE.url` is set before launch, when the domain may not serve the site yet, and a redirect then
strands visitors. New `tests/middleware.spec.ts` calls `onRequest` directly (`astro preview` never
runs Pages Functions). Docs: an "After go-live" section in `CLOUDFLARE_FIRST_DEPLOY.md`, including
what existing sites need (new middleware, the variable, a redeploy), and updates wherever the old
behaviour or the spec list was described.

**Verdict.** No open BUG. One RISK (G3, Cloudflare integration untested) is waived by the owner
until the first real site's step-3 check; see "Waived". Round 5's fixes are `locally_verified`
only (`make check`, the template suite) and were not sent to a sixth round, by owner decision.
Every round was degraded: ollama-cloud failed on its weekly usage limit (HTTP 429) each time, so
Codex was the only cross-model seat.

## Rounds

| Round | Reviewed (head) | Reviewers — CLI, model, sandbox | BUG / RISK / NIT |
|---|---|---|---|
| 1 | `1373e28` | Codex CLI 0.157.0, `gpt-6-astra`, `exec -s read-only`; ollama 0.34.4, `kimi-k2.7-code:cloud` — FAILED (429); fresh-eyes (Claude family, host's own, read-only subagent with repo access — not cross-model) | 3 / 2 / 5 |
| 2 | `3051bae` | same three seats, ollama FAILED (429) | 0 / 3 / 6 |
| 3 | `dd9742e` | same, ollama FAILED (429) | 2 / 2 / 2 |
| 4 | `8433304` | same, ollama FAILED (429) | 0 / 2 / 2 |
| 5 | `138c2e1` | same, ollama FAILED (429) | 2 / 0 / 1 |

Counts are distinct findings per round after merging seats; a re-raise of an earlier finding
counts once in the round that re-raised it (G3 in rounds 3 and 4). 30 distinct findings in all.
Each artifact was `git diff origin/main...HEAD -- . ':(exclude)docs/reviews/'`, prefixed from
round 2 on by the prior round's findings and dispositions. Every code fix was checked by running
the template's Playwright spec, and each new guard by a mutation that removes it and turns the
spec red.

## Round 1 (on `1373e28`) — fixed in `3051bae`

| id | Sev | Source | Finding | Disposition |
|---|---|---|---|---|
| F1 | BUG | fresh-eyes, Codex | "Redeploy with `npm run ship`/push" builds nothing when nothing is new, and ship's LIVE check still passes on the old build | Fixed: empty commit (later refined by J1) |
| F2 | BUG | Codex, fresh-eyes | `CANONICAL_URL` of `https://pages.dev` or a trailing-dot `pages.dev` host was accepted | Fixed, tests added |
| F3 | NIT | fresh-eyes | Request host with a trailing dot got neither redirect nor noindex | Fixed, test added |
| F4 | BUG | Codex, fresh-eyes | website-review's "200 means…" line omitted a rejected value and an old middleware | Fixed |
| F5 | RISK | Codex | Docs promised a 301 changes AI citations | Fixed: says what a redirect does |
| F6 | RISK | fresh-eyes | Step 3 checked `main.<project>.pages.dev`, not a preview on single-stage sites | Fixed: hash preview |
| F7 | NIT | fresh-eyes | `make whats-new` needs `PROJECT=` | Fixed |
| F8 | NIT | fresh-eyes | throw used for control flow | Fixed |
| F9 | NIT | fresh-eyes | No test for trailing-slash/path values or an unset-variable preview | Fixed |
| F10 | NIT | fresh-eyes | `new-website/SKILL.md` over its 500-line soft budget, +3 lines | Refuted as a defect of this change: the warning predates it, the guard passes, the reviewer marked it "worth noting only" |

## Round 2 (on `3051bae`) — fixed in `dd9742e`

| id | Sev | Source | Finding | Disposition |
|---|---|---|---|---|
| G1 | RISK | Codex | Direct-upload redeploy lacked `--branch` | Fixed |
| G2 | RISK | fresh-eyes | Spec compared against `SITE.url`; a site still on its `pages.dev` address failed 4 tests (reproduced) | Fixed: fixed `LIVE` constant; 15/15 with such a `SITE.url` |
| G3 | RISK | Codex (re-raised rounds 3–4; UNVERIFIABLE in 5) | Production variables reaching `context.env`, the middleware running on the alias, and workerd's `Response.redirect` are not exercised by Node tests | **Waived** — see below |
| G4 | NIT | fresh-eyes | Step 3 omitted "variable not under Production" | Fixed |
| G5 | NIT | fresh-eyes | "The Functions log says so" pointed nowhere | Fixed with a tail command (removed again in I1) |
| G6 | NIT | fresh-eyes | Only one trailing dot stripped; `example.com.` leaked into Location | Fixed, tests added |
| G7 | NIT | fresh-eyes | An older single-stage site could push its middleware commit before the variable exists | Fixed |
| G8 | NIT | fresh-eyes | Browsers cache a 301; a typo'd value sticks | Fixed: check the value's `/build.txt` first |
| G9 | NIT | fresh-eyes | `docs/UPGRADING.md` spec list lacked `middleware` | Fixed |

## Round 3 (on `dd9742e`) — fixed in `8433304`

| id | Sev | Source | Finding | Disposition |
|---|---|---|---|---|
| H1 | BUG | Codex | `https://.` stripped to an empty host and redirected to `https://about/` (from G6's fix) | Fixed, tests added |
| H2 | BUG | Codex | Pre-save check read `https://<value>/build.txt`, doubling the scheme (from G8's fix) | Fixed |
| H5 | RISK | fresh-eyes | §A's own `wrangler pages deploy` lines lacked `--branch`, contradicting G1's text; wrangler falls back to `git rev-parse --abbrev-ref HEAD` (reviewer read wrangler 4.90.1 source) | Fixed: pre-existing lines, same file, fixed inline |
| H3 | NIT | fresh-eyes | `/build.txt` checks lacked a cache-bust | Fixed |
| H4 | NIT | Codex, fresh-eyes | A search-and-replace garbled a spec comment | Fixed |

## Round 4 (on `8433304`) — fixed in `138c2e1`

| id | Sev | Source | Finding | Disposition |
|---|---|---|---|---|
| I1 | RISK | fresh-eyes | `wrangler pages deployment tail` without a deployment ID fails in a non-interactive shell (wrangler source), where the agent runs it (from G5's fix) | Fixed: hint removed; step 3 lists the rules to check by eye |
| I2 | NIT | fresh-eyes | Hosts with an empty label (`example..com`) accepted | Fixed, test added |
| I3 | NIT | fresh-eyes | Fixed `?cb=1` key reused | Fixed |

## Round 5 (on `138c2e1`) — fixed in `eb2f03f`, `locally_verified` only

| id | Sev | Source | Finding | Disposition |
|---|---|---|---|---|
| J1 | BUG | Codex | Step 2 told the reader to push `main` directly; `AGENTS.md` §2 routes an assistant's changes through pull requests, and an optional pre-push hook blocks it | Fixed: follow the site's usual route; notes the redirect otherwise starts with the next publish |
| J2 | BUG | Codex | `https://example.com..` still redirects, so "any empty label is rejected" is overstated | Refuted: trailing dots are stripped by design (G6), `example.com..` names the same host, and the code comment says what is rejected; only the round-4 disposition wording was loose |
| K1 | NIT | fresh-eyes | Rejected-value list out of date; "name the live domain" is not machine-checked | Fixed; also says a well-formed wrong domain is not caught |

## Waived

**G3** (RISK, Cloudflare integration). Owner decision in this session, 2026-09-26, answering "The
open RISK: nothing here has tested the redirect on real Cloudflare. How should it be handled?"
with: "Waive until the first site (Recommended)". Reason: it cannot be exercised without a real
Pages deployment; the settling observation is the doc's step-3 check
(`curl -sI https://<project>.pages.dev/about` → `301` to the live domain; a preview still `200`
with `x-robots-tag`) on the first site that sets `CANONICAL_URL`. If the claim is false, the alias
keeps today's behaviour (served, noindexed), except a workerd `Response.redirect` failure, which
would show as 5xx in that same check.

Also not externally verified: round 5's fixes (owner answered "Close the gate (Recommended)").

## Close-out properties (audit)

- WORKTREE-WRITE and BRANCH-COMMIT: atom A — this session ran
  `git worktree add --no-track -b fix/pages-dev-redirect ../website-builder-pages-dev origin/main`.
- POST AUTHORITY: atom B — owner answered "Yes, push and open PR" in this session; atom A once this
  session creates the PR.
- GATED-THIS-DIFF: **not held.** Reviewers last saw (`7a17049`, `138c2e1`). The branch now carries
  `eb2f03f` (round-5 fixes) and a merge of `origin/main` (`6f960b4`, touching only
  independent-review and `docs/reviews` files), so the consolidated PR comment carries no marker.
