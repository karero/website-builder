# DIFF review — karero/website-builder#171 — first deploy: set CF_PAGES_BRANCH on a local build

Base `778245a` · depth: **Normal** (a deploy runbook with commands someone runs; a mistake costs a
site's analytics data, not user data or a production system) · verdict: **CLEAN** · authority used:
POST AUTHORITY — atom A (this session opened #171); WORKTREE-WRITE and BRANCH-COMMIT — atom B (owner,
this session, verbatim: "yes, commit the review records to both branches"; an earlier session
created the branch and its checkout); GATED-THIS-DIFF — atom A (Codex's chain: r1 full
`778245a...ad710c6`, r2 `ad710c6..b1f55f1`, r3 `b1f55f1..6656a1f`).

**Data release consent** (owner, this session, verbatim): "yes, run the review", given in reply to
the offer of the independent review. It covers this diff going to Codex and Ollama Cloud and is
session-scoped. Data check: no keys, tokens or personal data in the diff.

| Round | Head | Artifact | Reviewers | seconds, tokens | BUG/RISK/NIT |
|---|---|---|---|---|---|
| 1 | `ad710c6` | full vs `778245a` | codex-cli 0.160.0 gpt-6.1-sol (config effort, read-only) · ollama 0.35.1 kimi-k2.7-code:cloud · fresh-eyes Claude Sonnet sub-agent | 146 s, 55.8k · 98 s · 65 s, 99.3k | 1 / 7 / 5 |
| 2 | `b1f55f1` | delta since `ad710c6` | codex (medium) · ollama kimi-k2.7-code:cloud | logged | 1 / 0 / 1 |
| 3 | `6656a1f` | delta since `b1f55f1` | codex (medium): clean · ollama kimi-k2.7-code:cloud (counted by hand) | 86 s, 30.3k · 57 s | 1 / 0 / 0 |

| id | Sev | Source | Round | Finding | Status | Evidence |
|---|---|---|---|---|---|---|
| F1 | RISK | fresh-eyes | 1 | `<main\|production>` is offered, but the kit ships `PROD_BRANCH = 'production'`, so `main` still leaves analytics off | fixed `b1f55f1` (locally_verified, externally_reverified r2+r3) | Codex evaluated `config.ts`: `main` gives false on stock, true with `PROD_BRANCH='main'` |
| F2 | NIT | fresh-eyes | 1 | a preview built with the production value would ship analytics on a preview | fixed `b1f55f1`, reworded `6656a1f` (externally_reverified r3) | |
| R2-1 | BUG | codex | 2 | the F2 wording implied that changing `--branch` alone disables the gate | fixed `6656a1f` (externally_reverified r3) | the comment now says a preview builds with plain `npm run build` |
| R2-2 | NIT | ollama | 2 | "set it to 'main'" didn't name `PROD_BRANCH` | fixed `6656a1f` (externally_reverified r3) | |
| F3 | BUG | ollama | 1 | `<main\|production>` has shell metacharacters | refuted | the same placeholder is on the unchanged step-1 and deploy lines; it is meant to be substituted, not pasted |
| R3-1 | BUG | ollama | 3 | the build line still sets the variable, so someone following it for a preview sets it too | refuted | step 2 is the production deploy ("Both lines take the production branch from step 1"); the comment above it says what a preview does instead |
| F4 | RISK | codex | 1 | Astro emitting the script is unsupported | refuted | `templates/astro/src/layouts/Base.astro:169-170` `{ANALYTICS.enabled && (<script …/>)}`; no `output` set, so a static build evaluates it at build time |
| F5 | RISK | codex, ollama | 1 | wrangler `--branch` behaviour unsupported | refuted | wrangler 4.90.0 `cli.js`: `isProduction = project.production_branch === branch`; that sentence predates this PR |
| F6 | RISK | ollama | 1 | "Cloudflare sets it only when IT builds" unverified | refuted | under (A) the build runs locally; Cloudflare cannot set variables in a local process |
| F7 | RISK | ollama | 1 | config gate unverified | refuted | `templates/astro/src/config.ts:57` `enabled: process.env.CF_PAGES_BRANCH === PROD_BRANCH` |
| F8 | NIT | ollama | 1 | "Both lines take the production branch" overstates | refuted | both lines do take it; the comment then says what each does with it |
| F9 | NIT | fresh-eyes | 1 | `VAR=x cmd` is POSIX-only | refuted | the scaffold already runs `bash scripts/ship.sh` |
| F10 | NIT | fresh-eyes, codex | 1 | `WEBSITE_ARCHITECTURE.md:166` says `=== 'production'`, not `=== PROD_BRANCH` | follow-up | pre-existing, outside the diff |

Waivers and deferrals: none.

Follow-ups: F10, a stale condition in `skills/new-website/references/WEBSITE_ARCHITECTURE.md:166`.

Notes: round 3's ollama reply failed the script's format check. It was a real review (one BUG,
refuted as R3-1), so it was counted by hand. Fresh-eyes ran in round 1 only, by Normal-depth design.
Nothing changed after round 3, so no wording pass was due. Raw reviewer output is in the gate's
PR comment.
