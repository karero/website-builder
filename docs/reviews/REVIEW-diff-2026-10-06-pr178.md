# DIFF review — karero/website-builder#178 — website-forms: one file for the form's words, and a step to add a language

Base `1674e06` (`origin/feat/website-forms`, stacked on #174) · depth: **Normal** (the function's handling
of visitor data is unchanged, only its strings and limits now come from an import; new are a build-time
guard, tests, CI and docs; owner chose Normal over High, this session) · verdict: **CLEAN** (2 owner
waivers) · authority used: POST AUTHORITY — atom A (this session opened #178); WORKTREE-WRITE and
BRANCH-COMMIT — atom A (this session created the worktree `website-builder-forms-languages` and the
branch); GATED-THIS-DIFF — atom A: Codex and ollama-cloud each counted in round 1 (`1674e06...0e4f4c4`,
full) and in every link after it (`0e4f4c4..da33f9f`, `da33f9f..ae59f72`). The trail commit after
`ae59f72` touches `docs/reviews/` only; the diff-scope is byte-identical.

**Data release consent** (owner, this session, verbatim): "Codex + ollama-cloud (Recommended)". Session-
scoped; the repo has no standing consent. Data check: no keys, tokens or personal data in the diff.

| Round | Head | Artifact | Reviewers | Seconds, tokens | BUG/RISK/NIT |
|---|---|---|---|---|---|
| 1 | `0e4f4c4` | full, `1674e06...0e4f4c4` (36 KB) | codex-cli 0.160.1, gpt-6.1-sol, config effort, read-only; ollama 0.35.1, kimi-k2.7-code:cloud, text only; fresh-eyes: Claude Sonnet sub-agent, read-only | codex 478 s, 98,729; ollama 275 s; fresh-eyes 265 s, 152,793 | 5/1/4 (raw, before dedup) |
| 2 | `da33f9f` | delta since `0e4f4c4` (12 KB), `--verify` | codex (effort medium), ollama | codex 190 s, 50,388; ollama 328 s | 0/5/1 |
| 3 | `ae59f72` | delta since `da33f9f` (3 KB), `--verify` | codex (effort medium), ollama | codex 92 s, 33,855; ollama 238 s | 0/3/1 (raw) |

| id | Sev | Source | Round | Finding | Status | Evidence |
|---|---|---|---|---|---|---|
| C1 | RISK | codex | 1 | CI never checks that Cloudflare's bundler takes in the shared file imported from outside `functions/` | fixed, locally_verified, externally_reverified (r2) | `da33f9f`: wrangler bundle step in the forms-skill job |
| C2 | BUG | codex | 1 | docs claimed `WORDS` catches a sentence "that says the wrong thing"; it is a keyword check | fixed, locally_verified, externally_reverified (r2) | `da33f9f`: SKILL.md "Add a language" step 7, `contact-form.ts` header |
| C3 | BUG | codex | 1 | "the spec follows a new subject line by itself" false above 91 units (exact-subject check ignores the cut; `repeat(-1)` above 119) | fixed, locally_verified, externally_reverified (r2) | `da33f9f`: spec asserts `MAIL.subject.length <= 90`; mutant: a 95-char prefix fails with that message |
| C4 | BUG | codex | 1 | no-JS address hint followed `SITE.locale`: a German form on an English site said `[dot]` (present at the merge-base too) | fixed, locally_verified, externally_reverified (r2) | `da33f9f`: `text={emailHint(fallback, language)}`; spec decodes `data-email`; mutant fails only `forms.de.spec.ts` |
| C5 | NIT | codex, fresh-eyes | 1 | spec header said "three files" | fixed, externally_reverified (r2) | `da33f9f` |
| K1 | BUG | ollama | 1 | `handle()` renders `de-AT` in English | refuted, externally_reverified (r2, Codex reproduced) | `decide()` normalizes with `.toLowerCase().split('-')[0]` (`contact.ts:123`); the spec's `de-AT` case passes |
| K2 | NIT | ollama | 1 | "one file to translate" understates: `WORDS` too | fixed, externally_reverified (r2) | `da33f9f`: README, SKILL.md §1 |
| F2 | NIT | fresh-eyes | 1 | count the subject prefix in code points | refuted, externally_reverified (r2) | the check targets a cut by code units: with `.length` the emoji straddles units 119/120 and that mutant fails; by code points it would sit past the cut and pass |
| R2-1 | RISK | codex | 2 | CI grepped two template sentences: a legitimate text edit turns CI red | fixed, locally_verified, externally_reverified (r3) | `ae59f72`: `grep -F` for the bundle's path comment `// ../src/components/contact-form.ts`; passes on wrangler 4.147.0; fails when the function imports its own copy, and when the file moves ("Could not resolve") |
| R2-2 | RISK | codex | 2 | "bundles the way Cloudflare bundles it" unsupported | fixed (comment narrowed), externally_reverified (r3) | `ae59f72`; trace: wrangler 4.147.0 `cli.js` `deploy2` (~301008–301017) calls `buildFunctions` with `cwd/functions`, as the `pages functions build` handler does (~300023). Cloudflare's Git build not traced, and the comment says so |
| K2-1 | RISK | ollama | 2 | 90 + `LIMITS.name` 100 exceeds 120 | refuted, externally_reverified (r3, Codex reproduced) | the subject was always cut at 120; the full name is in the mail text; the exact-subject check's name is 29 units |
| K2-2 | RISK | ollama | 2 | "characters" vs `.length` units; a cut may split surrogates | refuted, externally_reverified (r3) | the cut is `Array.from` (code points); the `.length` guard is stricter. Message now says "(JavaScript length)" |
| K2-3 | RISK | ollama | 2 | wrangler not pinned | refuted | deliberate: sites deploy with whatever `npx wrangler` fetches; the step's comment says so |
| K2-4 | NIT | ollama | 2 | `grep -q` without `-F`, no message | fixed, externally_reverified (r3) | `ae59f72` |
| R3-1 | RISK | codex, ollama | 3 | CI depends on wrangler writing a path comment into the bundle; a valid bundle without it turns CI red | **waived** | owner, below |
| R3-2 | RISK | codex, ollama | 3 | deploy/build bundling equivalence still unsupported | refuted (re-raise of R2-2 without new evidence) | trace cited at R2-2 |
| R3-3 | NIT | ollama | 3 | the error message should say the marker is missing, not the file | **waived** | owner, below |

**Waivers.** R3-1 and R3-3, owner, 2026-10-06, verbatim: "Waive both (Recommended)". The choice read:
the failure is a loud false red in this repo's CI, never a false green; both mutants were shown.

**Follow-ups.**
- If wrangler stops writing path comments (R3-1), replace the grep with a check that runs the bundle.
- The starter's German Impressum shows its own email link as `[dot]`: `EmailLink` defaults to `SITE.locale`. Starter code, outside this change.
- `tests/tone.spec.ts` does not read the form's status sentences or the no-JS answer page (`data-*` attributes, the function's HTML); SKILL.md step 7 asks for a read by hand.

**Notes.** Round 3 ran on a RISK fix (R2-1), with the owner's OK for each of rounds 2 and 3. No round
4: round 3 found no BUG. No wording pass: rounds 2–3 covered every change since round 1 at full scope,
and no prose in the diff changed after round 3. Not verified: a real deploy, and this PR's own CI run.
