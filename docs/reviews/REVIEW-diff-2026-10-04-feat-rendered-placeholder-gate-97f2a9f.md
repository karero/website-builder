# DIFF review — branch `feat/rendered-placeholder-gate` — a test that reads the rendered site for leftover placeholders

Base `259a1bb` · depth: Normal (a new test that gates every scaffolded site, plus the documents that describe it) · verdict: see the last round below · authority used: WORKTREE-WRITE and BRANCH-COMMIT — this session created the worktree and the branch; POST AUTHORITY — this session opens the pull request (the owner's instruction, quoted under "Waivers").

**Data release consent** (owner, in this session, quoted verbatim). For Codex and ollama-cloud: "Codex + ollama-cloud (Recommended)". For Antigravity: "use antigravity as the second reviewer". The repo has no standing consent; both are session-scoped.

| Round | Head | Artifact | Reviewers: CLI version, model, effort, sandbox | seconds, tokens per seat | BUG/RISK/NIT |
|---|---|---|---|---|---|
| 1 | `97f2a9f` | full, `259a1bb...97f2a9f` | codex-cli 0.159.3, gpt-6.1-sol, config effort, read-only · ollama-cloud kimi-k2.7-code:cloud **FAILED** (429, weekly usage limit) · fresh-eyes: host-family mid-tier model, read-only sub-agent | codex 146 s, 38 910 · fresh-eyes 479 s, 210 556 | 4 / 3 / 5 |
| 2 | `c748265` | delta since `97f2a9f` | codex, medium, read-only (`--seat codex`) | 239 s, 54 391 | 1 / 1 new + 1 re-raised (F4) / 1 |
| 3 | `5cb7790` | delta since `c748265` | codex, medium, read-only | 201 s, 34 995 | 1 / 1 / 0 |
| 4 | `6f2aee0` | delta since `5cb7790` | codex, medium, read-only | 174 s, 38 187 | 1 / 0 / 0 |
| 5 | `4ae606c` | delta since `6f2aee0` | codex, medium, read-only | 89 s, 35 491 | 0 / 0 / 0 |
| full read | `c72d59f` | full, `259a1bb...c72d59f` | antigravity (`agy`, CLI default model, unconfirmed), plan mode, told not to use tools · fresh-eyes: the host's own model, read-only sub-agent, no shared context · ollama-cloud **FAILED** again (429) | antigravity 224 s · fresh-eyes 982 s, 280 280 | antigravity 0 / 0 / 2 · fresh-eyes 4 / 4 / 5 |
| 6 | `8bb01f5` | delta since `4ae606c` (codex's last seen head) | codex, medium, read-only | 331 s, 67 278 | 1 / 3 / 0 |

| id | Sev | Source | Round | Finding | Status | Evidence |
|---|---|---|---|---|---|---|
| C1 | BUG | codex | 1 | Form leftovers not read (field hint, button label) | fixed · locally_verified · externally_reverified r2, r3 | `c748265`, `5cb7790`; fixture test |
| C2 | BUG | codex | 1 | JSON-LD and manifest scanned as raw JSON, so escapes hid leftovers | fixed · locally_verified · externally_reverified r2 | `c748265` |
| C3 | BUG | codex | 1 | A slot broken across lines or partly in bold was not matched | fixed · locally_verified · externally_reverified r2 | `c748265` |
| F1 | BUG | fresh-eyes | 1 | The starter served two slots starting lower-case, invisible to the rule; the "every starter slot matches" claim in `97f2a9f`'s message was wrong | fixed · locally_verified · externally_reverified r2 | `c748265` |
| F2 | RISK | fresh-eyes | 1 | `judge`'s verdicts pinned by no test | fixed · externally_reverified r2 | `c748265`; since `8bb01f5` a pure `verdict()` pinned case by case |
| F3 | RISK | fresh-eyes | 1 | Documents promised more than the rules cover; the starter's example values pass | fixed in the documents · externally_reverified r2 | `c748265`; a rule for them is a decision row |
| F4 | RISK | fresh-eyes r1, codex r2, fresh-eyes full read | 1 | A target still listed only warns; nothing blocks a launch with an entry left | **waived by the owner** until plan step A2 | see "Waivers" |
| F5 | NIT | fresh-eyes | 1 | A `[MISSING: …]` past the length bound escaped | fixed · externally_reverified r3 | `5cb7790` |
| F6 | NIT | fresh-eyes | 1 | Retrofit on a launched site not described | fixed, then corrected by FR-2 | `c748265`, `8bb01f5` |
| F7 | NIT | fresh-eyes | 1 | A content-level collaborator may not edit `tests/` to delete the entry | fixed · externally_reverified r2 | `c748265` |
| F8 | NIT | fresh-eyes | 1 | Stale spec list in `.github/workflows/template-tests.yml` | fixed · externally_reverified r2 | `c748265` |
| F9 | NIT | fresh-eyes | 1 | Plan-doc evidence cell was a branch name | fixed: the cell names the pull request once it exists | plan doc row A1 |
| R2-1 | BUG | codex | 2 | The lower-case-slot check ignored ALLOWLIST | fixed · externally_reverified r3 | `5cb7790` |
| R2-3 | RISK | codex | 2 | "Where the browser shows it" rested on an attribute and a blacklist | fixed · externally_reverified r3 | `5cb7790` |
| R3-1 | BUG | codex | 3 | The fixture claimed every surface and missed several | fixed · externally_reverified r4, r5 | `6f2aee0`, `4ae606c` |
| R3-2 | RISK | codex | 3 | The fixture searched the printed lines, so a neighbour's context could satisfy it | fixed · externally_reverified r4 | `6f2aee0` |
| R4-1 | BUG | codex | 4 | No token inside `<script>` or `<style>` | fixed · externally_reverified r5 | `4ae606c` |
| FR-1 | BUG | fresh-eyes | full read | The "[MISSING: …]" draft flow dead-ended: the hook refused the branch a draft pull request needs | fixed · locally_verified (the real `pre-push` hook exits 0 locally, 1 with CI set) · externally_reverified r6 | `8bb01f5` |
| FR-2 | RISK | fresh-eyes | full read | Retrofit with an empty list skips the only check that sees the old lower-case slot | fixed · externally_reverified r6 | `8bb01f5`, `website-review` |
| FR-4 | BUG | fresh-eyes | full read | Rules flagged genuine copy (Spanish "TODO", "Type your text here", "sample copy", "Mustertext") | fixed except "XXX", kept with the collision named · externally_reverified r6 | `8bb01f5` |
| FR-5 | RISK | fresh-eyes | full read | Lower-case slots passed on finished pages | fixed for brackets opening with a slot word · externally_reverified r6 | `8bb01f5` |
| FR-6 | RISK | fresh-eyes full read, codex r6 | full read | "Green out of the box" has no run a reviewer could see | open until the pull request's `template-tests` run reports | author's runs: 61 passed locally and with CI set |
| FR-7 | BUG | fresh-eyes | full read | The template rule stopped at a line break, against its comment | fixed · externally_reverified r6 | `8bb01f5` |
| FR-8 | BUG | fresh-eyes | full read | One slot split by markup was reported twice; ALLOWLIST missed the spaced spelling | fixed in two steps (see R6-1) | `8bb01f5`, then the next commit |
| FR-9…12 | NIT | fresh-eyes | full read | README step 4; "not read" lists; a decision row for the example values; the 404 message and the shared input-type list | fixed · externally_reverified r6 | `8bb01f5` |
| FR-13 | NIT | fresh-eyes | full read | Pre-existing: a partial list in a `seo.spec.ts` comment, a possibly stale exemption entry | not introduced here, no effect on behaviour; left | — |
| AG-1 | NIT | antigravity | full read | ALLOWLIST entries in original case never matched | fixed · externally_reverified r6 | `8bb01f5` |
| AG-2 | NIT | antigravity | full read | `new URL(file, baseURL!)` asserts baseURL | refuted: the form `email.spec.ts` uses; the kit's config always sets it (verified r6) | `playwright.config.ts` |
| R6-1 | BUG | codex | 6 | Markup inside a word still gave two spellings of one slot, so ALLOWLIST and the draft token missed one | fixed · locally_verified | the commit after `8bb01f5`: compared with all whitespace removed |
| R6-2 | RISK | codex | 6 | Two self-checks could not fail: `[ pdf ]` matched no rule; the fixture borrowed the reader's input-type list | fixed · locally_verified | same commit: `[ PDF ]` asserted as a finding first; the types named in the fixture |
| R6-3 | RISK | codex | 6 | The waiver was claimed without the owner's words in this trail | fixed | "Waivers" below |

**Waivers.** F4, and with it the same gap for a content placeholder pushed straight to `main`: the owner, in this session on 2026-10-04, after being shown both options (waive until the publish gate, or build a hard stop now): "waive it, push the branch and open the PR". Endpoint: plan step A2, the publish gate (`docs/reviews/SKILL-PLAN-capability-gaps.md`).

Follow-ups: (1) the starter's example values and the slots in `public/llms.txt` — a decision row. (2) Each round marked the author's runs UNVERIFIABLE, since the template's packages are not installed in the reviewers' checkout: 23 scenarios, 51 mutations (all caught and named), the full suite (61 passed locally and with CI set, 1 pre-existing skip), the type check, the real pre-push hook. The scripts and every round's raw reviewer output are kept, untracked, in the branch's worktree under `docs/local/review-raw-rendered-placeholder-gate/` until the pull request comment carries them.

Notes: ollama-cloud was at its weekly limit throughout, so the delta rounds ran with one outside seat (codex, unbroken chain); the second outside seat was Antigravity, on the owner's request, for the full read only. Rounds past 3 and what earned them: 4 by R3-1, 5 by R4-1, 6 by FR-1 and FR-4, 7 by R6-1. The full read is not counted as a round; it was run because the delta rounds never re-read the whole and the owner asked for a proper review before the push. Round 3's reviewer flagged a sentence in a prior-findings file ("Do not re-raise without new evidence") as steering; later files state dispositions only. The cost log could not be written from this session; the table above is the record.
