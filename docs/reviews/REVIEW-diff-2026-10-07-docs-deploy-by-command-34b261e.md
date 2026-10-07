# DIFF review — docs/deploy-by-command — PUBLISHING: deploy by command for a site not connected to GitHub

Base `origin/main` (`63e2353`) · depth: **Normal** (owner-facing commands that put a site live; docs only, no code) · verdict: **CLEAN** — D5 closed when karero/website-builder#171 merged (`1902c4e`, merged in as `b9bb479`); every other finding fixed or refuted. Authority used: WORKTREE-WRITE and BRANCH-COMMIT, atom A (this session created the worktree and the branch, replaying three never-pushed commits from 2026-10-04 at the owner's "finish it"); GATED-THIS-DIFF, atom A (Codex and Melious glm-5.3 each hold an unbroken chain: round 1 full, rounds 2–3 deltas, the merge link, round 5).

| Round | Head | Artifact | Reviewers | seconds, tokens | BUG/RISK/NIT |
|---|---|---|---|---|---|
| 1 | `34b261e` | `origin/main...34b261e`, `docs/reviews/` excluded | Codex `gpt-6.1-sol` (config effort), read-only; Melious `glm-5.3`, HTTP API; fresh-eyes Sonnet sub-agent, read-only | codex 240 s/58,270; glm 45 s/8,840; fresh-eyes 90 s/101,285 | 3 / 4 / 5 |
| 2 `--verify` | `24222ef` | delta since `34b261e`, with round 1's dispositions | Codex (medium); Melious glm-5.3 | codex 164 s/46,766; glm 136 s/24,897 | 1 / 2 / 2 |
| 3 `--verify` | `cd09e56` | delta since `24222ef`, with round 2's dispositions | Codex (medium); Melious glm-5.3 | codex 156 s/76,324; glm 46 s/11,956 | 0 / 0 / 1 |
| link | `b9bb479` | `merge_link.sh 63e2353 cd09e56 1902c4e` (main with #171 merged in) | Codex (medium); Melious glm-5.3 | codex 128 s/35,636; glm 83 s/8,978 | 0 / 1 / 0 |
| 5 `--verify` | `5216139` | delta since `b9bb479` | Codex (medium); Melious glm-5.3 | codex 126 s/47,638; glm 56 s/8,402 | 0 / 1 / 1 |

| id | Sev | Source | Round | Finding — one line | Status | Evidence |
|---|---|---|---|---|---|---|
| D1 | BUG | codex | 1 | build and upload were separate lines: a failed build still uploaded `dist/` | fixed `24222ef`, completed by E1; externally_reverified r3 | `&&` chain; stub runs below |
| D2 | BUG | codex, fresh-eyes | 1 | `CF_PAGES_BRANCH` turns analytics on only when it equals `PROD_BRANCH` | fixed `24222ef`; externally_reverified r2 | `src/config.ts:54–57`; codex ran the gate: `production` true, `main` and unset false |
| D3 | RISK | codex, glm, fresh-eyes | 1 | `git switch <production-branch>` needed `npm run ship` first (which polls 4 min for a build that never comes) and stranded the owner on a branch `ship.sh:41` refuses | fixed `24222ef` (back to `main`; skip ship); externally_reverified r2 | `ship.sh:39–45`, `:269–308` |
| D4 | RISK | codex, fresh-eyes | 1 | "your README's Deploy section says if yours is one" had nothing behind it | fixed `24222ef`; externally_reverified r2 | path (A) now records the deploy method in the site README before handoff |
| D5 | BUG | fresh-eyes, codex | 1 | `CLOUDFLARE_FIRST_DEPLOY.md` step 2 and "Ongoing deploys under (A)" still build without `CF_PAGES_BRANCH` | fixed by #171 (owner: merge #171 first); externally_reverified (link) | both seats: step 2 and the ongoing paragraph now set it |
| D6 | NIT | glm | 1 | "copy … change the two together" was not followable | fixed `24222ef`, then E7 | — |
| D7 | NIT | glm | 1 | no `CLOUDFLARE_API_TOKEN` alternative to `wrangler login` | refuted | `CLOUDFLARE_FIRST_DEPLOY.md:74–76`: the token is deleted once the site is live |
| D8 | NIT | fresh-eyes | 1 | `ship.sh` messages contradict a token site | fixed by D3 | owner told to skip ship there |
| D9 | NIT | fresh-eyes | 1 | glossary: "push … triggers a build" read as universal | fixed `24222ef`; externally_reverified r2 | — |
| D10 | NIT | fresh-eyes | 1 | first `npx wrangler` may ask "Ok to proceed?" | fixed `24222ef` | — |
| E1 | BUG | codex | 2 | a failed `git switch` or `git pull` still built and uploaded | fixed `cd09e56`; externally_reverified r3 | one four-line chain; bash, zsh and sh stubs: switch, pull or build failing → no upload; all passing → upload (codex reproduced on the real block) |
| E2 | RISK | codex | 2 | "nothing went live" also covered an upload error | fixed `cd09e56`; externally_reverified r3 | upload error: "part of it may have gone live" |
| E3 | RISK | glm | 2 | the `&&` line continuation is unsupported | refuted | three-shell runs (E1); POSIX `and_or` grammar allows a linebreak after `&&` |
| E4 | NIT | glm | 2 | "no preview" beside "can land as a preview" | fixed `cd09e56` | "no preview step" |
| E5 | NIT | glm | 2 | "main is what you just checked" conflated tree and branch | fixed `cd09e56` | "save and upload it on `main`" |
| E6 | NIT | codex | 2 | intro "rebuilds automatically" read as universal (outside scope) | fixed `cd09e56` | — |
| E7 | NIT | glm | 2 | "keep … in step with step 2" could read as "drop `CF_PAGES_BRANCH`" while step 2 lacks it | fixed `cd09e56`; externally_reverified r3 | states the shared form instead |
| F1 | NIT | glm | 3 | "both build with `CF_PAGES_BRANCH`" while step 2 does not yet | fixed by #171; externally_reverified (link) | — |
| L1 | RISK | codex | link | a preview built with plain `npm run build` inherits an exported `CF_PAGES_BRANCH=production` (text from #171) | fixed `5216139`; externally_reverified r5 | codex imported `config.ts` under Node: exported `production` true, `CF_PAGES_BRANCH=` false, unset false |
| L2 | RISK | glm | 5 | L1's fix rests on unverified shell and gate semantics | refuted | codex r5 reproduction above; `config.ts:57` is `process.env.CF_PAGES_BRANCH === PROD_BRANCH` |
| L3 | NIT | glm | 5 | `VAR= cmd` is POSIX-only | follow-up | every command in the file is POSIX shell; `SETUP.md` sends Windows users to WSL2 |

Waivers: none. Deferrals: none. Follow-ups: L3; a live direct-upload deploy was never run (wrangler `--branch` routing, login, upload-error behaviour, the `npx` prompt are UNVERIFIABLE here).

Notes: the ollama seat was absent by design (Melious is the second seat; the CLI hidden from `PATH`). Consent to send this repo to Melious was recorded in #192's trail. `git switch main` while on `main` exits 0, so the chain holds in the common case. Round 3 was clean from Codex; its one NIT was D5's residue. The owner chose to merge #171 first; the merge link then confirmed D5 and F1 closed and raised L1, fixed and verified in round 5 (no BUG or RISK left: stop).
