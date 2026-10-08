# DIFF review — test/analytics-build-gate — a build-output check of the analytics switch

Base `origin/main` (`c67d932`, then `f3eb379` after #210 merged in) · depth: **Light, escalated to Normal** after round 2 found a BUG in test logic CI runs · verdict: **CLEAN** — every BUG fixed; one RISK waived by the owner (the reader is not an HTML parser). Authority used: WORKTREE-WRITE and BRANCH-COMMIT (a background agent of this session created the worktree and branch at the owner's "work on them now"; the session took over from round 1); GATED

| Round | Head | Artifact | Reviewers | seconds, tokens | BUG/RISK/NIT |
|---|---|---|---|---|---|
| 1 (Light) | `cf3051c` | `origin/main...cf3051c` | Codex (config effort), `--seat codex` | codex 261 s/60,365 | 1 / 2 / 0 |
| 2 (Light) `--verify` | `e15bcfd` | delta since `cf3051c` | Codex (medium) | codex 86 s/26,458 | 1 / 0 / 0 |
| 3 (Normal) `--verify` | `2b106a8` | the whole change, `origin/main...2b106a8` | Codex (medium); Melious `glm-5.3`; fresh-eyes Sonnet | codex 144 s/41,530; glm 241 s/18,509; fresh-eyes 157 s/111,940 | 1 / 5 / 5 |
| 4 `--verify` | `c2d7f0f` | delta since `2b106a8` (the tokenizer rewrite) | Codex (medium); Melious glm-5.3 | codex 171 s/33,317; glm 374 s/35,603 | 3 / 2 / 4 |
| 5 `--verify` | `651c8e6` | delta since `c2d7f0f` | Codex (medium); Melious glm-5.3 | codex 115 s/39,371; glm 211 s/21,727 | 0 / 0 / 3 |
| link | `49869e1` | `merge_link.sh c67d932 651c8e6 f3eb379` (main with #210 merged in) | Codex (medium); Melious glm-5.3 | codex 163 s/42,663; glm 101 s/12,583 | 0 / 1 / 0 |
| confirm | `d9daba6` | delta since `49869e1`, `--seat melious` | Melious glm-5.3 | glm 139 s/5,999 | 0 / 1 / 0 |

| id | Sev | Source | Round | Finding — one line | Status | Evidence |
|---|---|---|---|---|---|---|
| T1 | BUG | codex | 1 | comment credited the empty-value preview build to `PUBLISHING.md` | fixed `e15bcfd`; externally_reverified r2 | it is in `CLOUDFLARE_FIRST_DEPLOY.md` step 2 |
| T2 | RISK | codex | 1 | on-check accepted a commented-out tag, rejected reordered attributes | fixed `e15bcfd`, rewritten `c2d7f0f`; externally_reverified r2, r5 | host breakage: tag wrapped in an HTML comment fails the live case |
| T3 | RISK | codex | 1 | `PROD_BRANCH` read failed on double quotes or no semicolon | fixed `e15bcfd`; externally_reverified r2 | `export const PROD_BRANCH = "production"` reads `production` |
| T4 | BUG | codex | 2 | `\bsrc` matched `data-src` | fixed `2b106a8`; externally_reverified r3 | fixtures: data-src, data-data-domain count 0 |
| T5 | BUG | codex | 3 | ` src="…/js/script.js"` inside another attribute's quoted value counted | fixed `c2d7f0f` (attributes read one at a time); externally_reverified r5 | fixture quoted-decoy: full 0 |
| T6 | RISK | codex | 3 | `<script-template>` counted as a script | fixed `c2d7f0f`; externally_reverified r5 | fixture: 0 0 |
| T7 | RISK | codex, glm | 3 | off-check grep matched comments and page text | fixed `c2d7f0f` (same reader as the on-check); externally_reverified r5 | fixture content-mention: 0 0 |
| T8 | RISK | glm | 3 | on-check read `index.html` only | fixed `c2d7f0f` (every page); externally_reverified r5 | `ANALYTICS` used only at `Base.astro:169–170`; every page uses Base; no redirects |
| T9 | RISK | glm | 3 | `--outDir` support unverified | refuted | four builds wrote to the temp dir; a marker file in the project's `dist/` was untouched |
| T10–T13, T15 | NIT | glm, fresh-eyes | 3 | "(exit 0)" message; `npx` could fetch an unpinned astro; silent perl failure; long header line; ships into sites but runs only here | fixed `c2d7f0f`; externally_reverified r5 | — |
| T14 | NIT | fresh-eyes | 3 | "a few seconds" unmeasured | refuted | four builds took 5.75 s locally |
| U1 | RISK (filed BUG) | codex, glm (NIT) | 4 | a script tag spelled out inside another attribute's value or inside script code counts | **waived** by the owner: "keep the current version, accept the limit (the script's comment already states it)" | not wrong now: the only emitter is `Base.astro:170`, and no file under `src/` or `public/` contains `data-domain` or `script.js` |
| U7 | NIT | glm | 4 | a stray `<!--` in page markup swallows content | waived with U1 (same class: markup the template does not emit) | — |
| U2 | BUG | codex | 4 | an empty page printed no line, so it passed | fixed `651c8e6`; externally_reverified r5 | one line per file; lines must equal pages |
| U3, U8 | RISK, NIT | codex, glm | 4 | an unreadable page dropped out with exit 0 | fixed `651c8e6`; externally_reverified r5 | chmod 000 page: "cannot read …: Permission denied", rc 1 |
| U4 | BUG | codex | 4 | `data-domain=""` passed the off-check | fixed `651c8e6`; externally_reverified r5 | fixture: 0 1 |
| U5 | RISK | glm | 4 | header claims template-tests.yml runs the script | refuted | `template-tests.yml:116` `run: bash tests/check_analytics_gate.sh`, job working-directory the template |
| U9 | NIT | glm | 4 | off message overstated a half-tag | fixed `651c8e6`; externally_reverified r5 | — |
| V1, V2 | NIT | glm | 5 | `close` failure worded as a read failure; long message line | fixed `82990a4`; externally_reverified (link) | — |
| V3 / W1 | NIT, then RISK | glm | 5, link | a `\|` in the temp path breaks the report's `sed` | refuted in r5 (wrongly), then fixed `d9daba6`; externally_reverified (confirm) | GNU `mktemp` builds the path from `TMPDIR`; forced a `\|` path: pages listed cleanly |
| X1 | RISK | glm | confirm | the here-string is not POSIX sh | refuted | line 1 `#!/usr/bin/env bash`; CI runs `bash …`; the script already needs bash (`set -o pipefail`) |

Waivers: U1 and U7 (the owner, quoted above). Deferrals: none. Follow-ups: none.

Host evidence at the final head: the real gate passes 4/4 (live, unset, empty, preview branch). Each breakage fails the case it should: `enabled: true` (three off cases), `enabled: false` (live), `enabled: !!process.env.CF_PAGES_BRANCH` (preview branch), the tag inside an HTML comment (live). Repo guards pass: `check_cdpath_safe`, `check_pipefail_pipes`, `check_template_coverage`, `check_lf_checkout`, `check_clean`.

Notes: the ollama seat was absent by design (Melious is the second seat; CLI hidden from `PATH`); consent for Melious is recorded in #192's trail. Convergence: rounds 1–3 patched a regex tag-matcher, and each fix exposed the next lookalike, so round 3's findings were met with a redesign (one attribute reader shared by both checks) rather than another patch. Round 4's remaining class — markup the template never emits — went to the owner as one decision instead of further rounds.
