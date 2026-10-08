# DIFF review — docs/deploy-follow-ups — the follow-ups left by #207 and #208

Base `origin/main` (`c67d932`) · depth: **Normal** (deploy commands and budget numbers an owner or assistant acts on; docs and one CI comment, no code) · verdict: **CLEAN** — round 1's one BUG fixed and confirmed; every RISK fixed or refuted with the vendors' pages. Authority used: WORKTREE-WRITE and BRANCH-COMMIT (this session created the worktree and the branch at the owner's "work on them now"); GATED

| Round | Head | Artifact | Reviewers | seconds, tokens | BUG/RISK/NIT |
|---|---|---|---|---|---|
| 1 | `f2e373c` | `origin/main...f2e373c`, `docs/reviews/` excluded | Codex `gpt-6.1-sol` (config effort), read-only; Melious `glm-5.3`, HTTP API; fresh-eyes Sonnet sub-agent | codex 250 s/70,536; glm 58 s/9,772; fresh-eyes 63 s/94,698 | 1 / 3 / 4 |
| 2 `--verify` | `32feebb` | delta since `f2e373c`, with round 1's dispositions | Codex (medium); Melious glm-5.3 | codex 205 s/56,560; glm 89 s/13,743 | 0 / 1 / 2 |
| 3 `--verify` | `211ac5e` | delta since `32feebb`, with round 2's dispositions | Codex (medium); Melious glm-5.3 | codex 89 s/32,547; glm 18 s/4,062 | 0 / 1 / 0 |
| wording | `f03bbb2` | prose-only delta since `211ac5e` (the owner's amendments), `--seat codex` | Codex (medium) | codex 81 s/44,122 | 0 / 0 / 0 |

| id | Sev | Source | Round | Finding — one line | Status | Evidence |
|---|---|---|---|---|---|---|
| F1 | BUG | glm | 1 | README: "a site deployed by command has no preview step" contradicts step 2 of the first-deploy reference, and the noindex note covered Git-connected previews only | fixed `32feebb`, reworded `211ac5e`; externally_reverified r2, r3 | — |
| F2 | RISK | codex, glm, fresh-eyes | 1 | "about a minute (measured)" came from this public repo's `playwright` job: bigger runner, no `astro check` | fixed `32feebb`; externally_reverified r2 | 171 successful runs, median 48 s, max 202 s; docs.github.com runners reference: public `ubuntu-latest` 4 CPU/16 GB, private 2 CPU/8 GB. SKILL.md named the source and its limits; the owner then chose no number (`f03bbb2`): the row points to the Actions tab, and `ci.yml` carries none |
| F3 | RISK | fresh-eyes | 1 | the 2024–25 history of the Fail open setting was uncited | fixed `32feebb`; externally_reverified r2 | cloudflare-docs #17200 (merged 2024-11-11) removes "The default configuration for all Pages projects is to Fail open."; #22331 (merged 2025-05-14): "Mistakenly removed from the dashboard and documentation." Both linked under Sources |
| F4 | RISK | fresh-eyes, codex | 1 | PUBLISHING.md sent a non-technical owner to WSL2, which SETUP.md never sets up | fixed `32feebb`; externally_reverified r2 | owner asks the assistant to run it, or to set up WSL2 |
| F5 | NIT | fresh-eyes | 1 | "burns minutes fast" no longer fits the run-time row | fixed `32feebb`; externally_reverified r2 | — |
| F6 | NIT | fresh-eyes | 1 | BUGLOG row: "every other claim checked" too broad; API claim unsourced | fixed `32feebb`; externally_reverified r2 | Pages API reference linked |
| F7 | NIT | fresh-eyes | 1 | README opens "set the production branch to `production`" though a single-stage site uses `main` | refuted | pre-existing line; "(must equal `PROD_BRANCH`)" makes the equality the rule, and the kit ships `PROD_BRANCH = 'production'` (both seats accepted, r2) |
| F8 | NIT | glm | 1 | step-2 comment read as "POSIX shell … fails in PowerShell" | fixed `32feebb`, pointer dropped `211ac5e`; externally_reverified r2, r3 | — |
| G1 | RISK | codex (glm NIT) | 2 | README "a preview only when someone deploys with another `--branch`" claims exclusivity; omitting `--branch` can also make one | fixed `211ac5e`; externally_reverified r3 | — |
| G2 | NIT | glm | 2 | step-2 comment pointed to SETUP.md for WSL2 steps it lacks | fixed `211ac5e`; externally_reverified r3 | — |
| G3 | NIT | glm | 2 | "so you can." dangled | fixed `211ac5e`; externally_reverified r3 | — |
| H1 | RISK | codex | 3 | "a deploy to any branch other than the production branch is a preview" lacks a vendor source | refuted | developers.cloudflare.com/pages/get-started/direct-upload: "To deploy assets to a preview environment, run: `npx wrangler pages deploy <OUTPUT_DIRECTORY> --branch=<BRANCH_NAME>`", each branch getting a `<BRANCH_NAME>.<PROJECT_NAME>.pages.dev` alias |

Waivers: none. Deferrals: none. Follow-ups: one real run of "Deploy by command" (codex r1, UNVERIFIABLE), a `docs/BUGLOG.md` row. Fail open's scope (per project or per environment) and a new project's default are checked by the owner's live test, run elsewhere; its row was dropped at the owner's call (`f03bbb2`). The build-output check of the analytics gate (codex r1, UNVERIFIABLE) is a separate change, `test/analytics-build-gate`.

Notes: the ollama seat was absent by design (Melious is the second seat; CLI hidden from `PATH`); consent for Melious is recorded in #192's trail. Round 3 had no BUG and its one RISK was refuted (stop condition a2); the owner's amendments after it (Windows note as one sentence naming Git Bash or WSL, `SETUP.md:66` installs `Git.Git`; no run-time figure; Fail open row dropped) got the one-seat wording pass, clean. Measuring a private site's CI was not done: listing the owner's private repos was refused as client data, so the row states its source instead.
