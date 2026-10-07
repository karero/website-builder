# DIFF review — docs/cloudflare-github-claims — Cloudflare and GitHub claims re-checked against the vendors' docs

Base `origin/main` (`63e2353`) · depth: **Normal** (cost, quota and uptime claims an owner acts on; docs only, no code) · verdict: **CLEAN** — no BUG found; every RISK refuted with the vendors' pages or fixed. Authority used: WORKTREE-WRITE and BRANCH-COMMIT, atom A (this session created the worktree and the branch, replaying a never-pushed commit from 2026-10-05 at the owner's "finish it"); GATED-THIS-DIFF, atom A (Codex holds an unbroken chain: round 1 full, round 2 delta, the prose re-gate delta).

| Round | Head | Artifact | Reviewers | seconds, tokens | BUG/RISK/NIT |
|---|---|---|---|---|---|
| 1 | `b791710` | `origin/main...b791710`, `docs/reviews/` excluded | Codex `gpt-6.1-sol` (config effort), read-only; Melious `glm-5.3`, HTTP API; fresh-eyes Sonnet sub-agent (read the vendor pages) | codex 212 s/55,438; glm 75 s/13,429; fresh-eyes 136 s/122,333 | 0 / 5 / 8 |
| 2 `--verify` | `be1b98b` | delta since `b791710`, with round 1's dispositions | Codex (medium); Melious glm-5.3 | codex 99 s/34,679; glm 47 s/11,557 | 0 / 2 / 1 |
| re-gate | `a60fd2f` | prose-only delta since `be1b98b` (`--seat codex`) | Codex (medium) | codex 82 s/30,656 | 0 / 0 / 0 |

| id | Sev | Source | Round | Finding — one line | Status | Evidence |
|---|---|---|---|---|---|---|
| C1 | RISK | codex, glm | 1 | Cloudflare quota, routing, Fail open/closed, preview-header, 429 and pricing claims lack support | refuted; links added `be1b98b` | read 2026-10-07: pages/functions/pricing "requests to static assets are free and unlimited", 50,000 + 50,000 example, reset at midnight UTC; pages/functions/middleware "including in front of static files"; pages/functions/routing#fail-open--closed (Settings > Runtime; "If on the Workers Free plan"; no default stated); workers/platform/limits#daily-requests (100,000 per account); pages/configuration/preview-deployments (noindex on every preview); workers/static-assets/billing-and-limitations (429 with `run_worker_first`); workers/platform/pricing ($5, 10 million, +$0.30/million); pages/ ("Start new projects with Workers", "Available on all plans") |
| C2 | RISK | codex, glm | 1 | GitHub billing claims unsupported; glm: restore the $0 spending limit | refuted; links added, budgets read first `be1b98b` | docs.github.com billing/concepts/product-billing/github-actions: no payment method, "usage is blocked once you use up your quota"; with one, "spending may be limited by one or more budgets"; billing/how-tos/set-up-budgets: "Stop usage when budget limit is reached"; no current page documents an Actions $0 limit |
| C3 | RISK | fresh-eyes | 1 | Cloudflare's suggested `_routes.json` would silently drop the middleware's protections | fixed `be1b98b`, corrected `a60fd2f`; externally_reverified (re-gate) | — |
| C4 | NIT | fresh-eyes | 1 | Fail open is a free-plan setting | fixed `be1b98b`; externally_reverified r2 | — |
| C5 | NIT | fresh-eyes, codex | 1 | another Function (the contact form) stops either way; a guarding Function means choosing again | fixed `be1b98b`; externally_reverified r2 | `website-forms/templates/contact.ts` sends from the Function |
| C6 | NIT | glm | 1 | name which layer adds each header and redirect | fixed `be1b98b`; externally_reverified r2 | codex traced `_middleware.ts:60–73` and `tests/middleware.spec.ts` |
| C7 | NIT | glm | 1 | "unlimited static requests" drops "unmetered bandwidth" | refuted | the replacement says what the pricing page says; bandwidth not re-verified, so not restated |
| C8 | NIT | fresh-eyes | 1 | SETUP.md step too technical for the tone rules | refuted | SETUP.md is the technical setup sheet (winget/PowerShell blocks) |
| C9 | NIT | fresh-eyes | 1 | two over-long lines | fixed `be1b98b` | `git diff --check` clean |
| C10 | NIT | fresh-eyes | 1 | "Workers Standard" vs "Workers Paid" | refuted | the Workers pricing page names the plan "Workers Paid" |
| G1 | RISK | codex | 2 | C1 and C2 re-raised: links are not evidence | refuted (re-raise, no new evidence; codex had no network) | quotes above |
| G2 | NIT | glm | 2 | the `_routes.json` warning named a preview loss the same file rules out | fixed `a60fd2f`; externally_reverified (re-gate) | previews keep Cloudflare's own noindex; only the alias loses the middleware's |

Waivers: none. Deferrals: none. Follow-ups: the Actions row's unchanged "~5 min per run" and "single biggest saver" estimates (codex, outside scope); the live dashboard path for Fail open / closed and a new project's default were not observed.

Notes: the ollama seat was absent by design (Melious is the second seat; CLI hidden from `PATH`); consent for Melious is recorded in #192's trail. Round 2 had no BUG and no RISK calling for a fix (stop condition a2); G2's fix got the one-seat prose re-gate the stamp needs. Codex flagged the re-gate's scope line ("Flag ONLY…") as a restriction and treated it as data.
