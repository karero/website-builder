# DIFF review — karero/website-builder#181 — decisions: settle the four open capability-gaps rows
Base `b55b66b` · depth: Normal (docs only, but decisions someone will build from) · verdict: CLEAN · authority used: POST AUTHORITY, WORKTREE-WRITE, BRANCH-COMMIT — atom A (this session created the PR, its worktree and its branch); GATED-THIS-DIFF — atom A (codex's verification chain below)

Owner's OK to send the diff out (2026-10-06, this session): "Codex + ollama-cloud (Recommended)". The repo has no standing consent; this is session-scoped.

The artifact names both changed files explicitly (`docs/DECISIONS_PENDING.md`, `docs/reviews/SKILL-PLAN-capability-gaps.md`): the plan lives under `docs/reviews/`, so the default `:(exclude)docs/reviews/` would have dropped half the change.

| Round | Head | Artifact | Reviewers | seconds, tokens per seat | BUG/RISK/NIT |
|---|---|---|---|---|---|
| 1 | `4ea4557` | full, `b55b66b...4ea4557` | codex-cli 0.160.1 (gpt-6.1-sol, config effort, read-only); ollama kimi-k2.7-code:cloud (text only); fresh-eyes Sonnet sub-agent (read-only) | codex 290s/101929; ollama 42s; fresh-eyes 73s/68122 | 0/5/3 |
| 2 | `25297e8` | delta since `4ea4557` | codex (medium); ollama kimi-k2.7-code:cloud | codex 107s/67876; ollama 248s | 0/1/1 |
| wording pass | this file's commit | delta since `25297e8`, prose only | codex (medium) | in the PR comment | in the PR comment |

| id | Sev | Source | Round | Finding — one line | Status | Evidence |
|---|---|---|---|---|---|---|
| R1 | RISK | codex, fresh-eyes | 1 | A3 positioning rule keyed on `SITE.url` cannot tell a draft from a launch, and broke the opt-in contract for sites with no terms | fixed by owner decision (hard stop at publish, not CI; no-terms sites exempt), externally_reverified (round 2) | `25297e8`; `src/config.ts:6`, `PUBLISHING.md` two-stage, `tests/positioning.spec.ts:56-66` |
| R2 | RISK | fresh-eyes | 1 | A1 "exact values only" missed the default home title, description and "Example GmbH" | fixed, externally_reverified (round 2) | `25297e8`; `src/config.ts:7-17` |
| R3 | RISK | codex | 1 | A2 probe proved refusals only, not that a green `main` still publishes | fixed, externally_reverified (round 2) | `25297e8` |
| R4 | RISK | fresh-eyes | 1 | duplicate-title test scope (pages, language, exemptions) unspecified | fixed, externally_reverified (round 2) | `25297e8` |
| R5 | RISK | codex | 1, 2 | npm name and initializer claims lacked retained evidence | fixed: evidence below, locally_verified | see "npm evidence" |
| N1 | NIT | fresh-eyes | 1 | `llms.txt` already fails on `example.com`; only bracket slots are new | fixed, externally_reverified (round 2) | `25297e8`; `tests/seo.spec.ts:280` |
| N2 | NIT | fresh-eyes | 1 | A2 "Not built yet" paragraph stale | fixed, externally_reverified (round 2) | `25297e8` |
| N3 | NIT | fresh-eyes | 1 | `tests/placeholders.spec.ts:14-17` comment goes stale once A1's extension is built | follow-up | — |
| N4 | NIT | ollama | 2 | plan's A1 bullet omitted "Example GmbH", which the decision row names | fixed, locally_verified | this file's commit |

npm evidence (2026-10-06, `npm view <name> name version`): `webcroft` → `E404`; `create-webcroft` → `E404`; `website-builder` → `name = 'website-builder'` (taken). `npm help init`: "npm init <package-spec> (same as `npx create-<package-spec>`)", aliases "create, innit". Neither name is claimed yet; that is the owner's action. Whether the packaged initializer works stays step E's own done-criterion (plan §E row 2).

Follow-ups: N3; GitHub's refusal wording may differ for organization-owned repos or other plans (already named in the A2 row; a real site closes the step).

Notes: no round produced a BUG. Round 2 left one RISK about the record itself and one NIT, so no round 3 was owed (step 6 (a2)). Fresh-eyes' chain ends at round 1 by design (Normal depth); ollama's at round 2; codex carries the chain through the wording pass. UNVERIFIABLE entries (GitHub rulesets, npm, unchanged Cloudflare and Playwright context): 9 asked across seats, none a finding.
