# DIFF review — karero/website-builder#165 — site checks: one `npm run verify`, run by the push, with short output

Base `bb765c6` · depth: Normal (template tooling and agent instructions; no auth, secrets, user data or deploy target; the pre-push gate only gets stricter) · verdict: **OPEN — rounds 1–2 closed every finding; the prose-only re-gate of the round-2 NIT fix (`e66ed73`) could not run (ollama-cloud 502, then 429), so no stamp yet** · authority used: WORKTREE-WRITE and BRANCH-COMMIT — this session created the branch `claude/inspiring-brahmagupta-il6tw8` (assigned) and its commits; POST AUTHORITY — this session opened #165, at the owner's request; GATED-THIS-DIFF — not yet held for `e66ed73` (ollama-cloud chain `4ed8427` → `050cd53` only)

**Data release consent** (owner, in this session, quoted verbatim): "ollama-cloud (Recommended)". The repo has no standing consent; this is session-scoped. Codex is not installed in this cloud container, so ollama-cloud was the one cross-model seat.

| Round | Head | Artifact | Reviewers: CLI version, model, effort, sandbox | seconds, tokens per seat | BUG/RISK/NIT |
|---|---|---|---|---|---|
| 1 | `4ed8427` | full, `bb765c6...4ed8427` | codex — SKIPPED (not installed) · ollama-cloud kimi-k3:cloud, HTTP API, text only · fresh-eyes: host-family mid-tier model, read-only sub-agent | ollama 391 s, 39 853 · fresh-eyes 219 s, 107 539 | 2 / 5 / 3 (deduped) |
| 2 | `050cd53` | delta since `4ed8427`, with round 1's dispositions | ollama-cloud kimi-k3:cloud, HTTP API | 224 s, 22 412 | 0 / 0 / 1 |
| prose re-gate | `e66ed73` | delta since `050cd53` (one Markdown hunk, SETUP.md) | ollama-cloud kimi-k3:cloud — FAILED (502, 429) · glm-5.3:cloud — FAILED (502) | — | not run |

Before round 1 the claims sweep listed 19 sentences; three overclaims were fixed before any reviewer ran ("exactly what text gets wrong", "installs only if package-lock.json changed", "if it prints nothing"), plus "broken links" → "broken internal links" (navigation.spec.ts checks internal links only).

| id | Sev | Source | Round | Finding — one line | Status | Evidence |
|---|---|---|---|---|---|---|
| R1-1 | BUG | fresh-eyes | 1 | package.sh's zip list and REQUIRED omit scripts/test_verify.sh; `make check` fails in the unzipped zip | fixed — externally_reverified (round 2) | `make package`, unzip, `make check` → rc 0 |
| R1-2 | BUG | fresh-eyes, kimi | 1 | test_verify.sh false-fails when TMPDIR is a symlink (macOS /var) | fixed — externally_reverified (round 2) | `TMPDIR=<symlink> bash scripts/test_verify.sh` → all checks passed |
| R1-3 | RISK | fresh-eyes | 1 | spawnSync's 1 MiB maxBuffer turns a noisy passing check into ENOBUFS → red | fixed — externally_reverified (round 2) | test "prints 2 MiB: still green" fails without the fix |
| R1-4 | RISK | fresh-eyes | 1 | stamp hashed only the lockfile; package.json edited alone never reinstalled, while CI's `npm ci` fails | fixed — externally_reverified (round 2) | test "package.json changed, lockfile not: installs" fails without the fix |
| R1-5 | RISK | fresh-eyes | 1 | "same checks as CI" overstated ([MISSING: grep, CI=1 placeholders) | fixed — externally_reverified (round 2) | verify.mjs header names both differences; hook comment points to it |
| R1-6 | RISK | fresh-eyes | 1 | hook-test comment said npm_execpath is unset for a hook; `npm run ship` passes it | fixed — externally_reverified (round 2) | comment reworded |
| R1-7 | RISK | kimi | 1 | gate's build depends on webServer not reusing a stale server | refuted — externally_reverified (round 2) | playwright.config.ts: `command: npm run build && npm run preview …`, `reuseExistingServer: false`; a page throwing at build time fails verify with the error shown |
| R1-8 | NIT | kimi | 1 | `/\.c?js$/` accepts pnpm/yarn entries in npm_execpath | fixed — externally_reverified (round 2) | `/[\\/]npm-cli\.c?js$/`; pnpm test fails without the fix |
| R1-9 | NIT | fresh-eyes | 1 | stale docs (README list, clean.yml header, SETUP.md, website-qa tuning example); `plain()` keyed on stdout only | fixed — externally_reverified (round 2) | `050cd53` |
| R1-10 | NIT | fresh-eyes | 1 | AGENTS.md adds the "small changes → one PR" rule | refuted — in scope (point 2 of the site team's feedback, in the plan the owner approved) | PR description names it |
| R2-1 | NIT | kimi | 2 | SETUP.md said the hook runs `npm run verify`; it runs `node scripts/verify.mjs` | fixed — locally_verified; prose re-gate pending | `e66ed73` |

Waivers and deferrals: none.
Follow-ups: Windows `npm.cmd` / `shell: true` path not exercised (no Windows runner). Real-browser runs used Chromium 1194 symlinked under Playwright 1.63's path (no browser download here).
Notes: degraded — one cross-model seat (Codex not installed). Round 2 met stop condition (a2). Closing edit `e66ed73` not externally re-verified until the prose re-gate runs; the stamp waits for it. `make check` exits 0 at `e66ed73`.
