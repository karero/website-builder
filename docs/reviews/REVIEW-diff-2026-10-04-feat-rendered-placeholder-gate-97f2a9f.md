# DIFF review — branch `feat/rendered-placeholder-gate` — a test that reads the rendered site for leftover placeholders

Base `259a1bb` · depth: Normal (a new test that gates every scaffolded site, plus the documents that describe it) · verdict: **OPEN** — every BUG fixed and re-verified; one RISK (F4) waits for the owner's waiver or a fix; the pair was degraded (one outside seat) · authority used: WORKTREE-WRITE and BRANCH-COMMIT — this session created the worktree and the branch. No pull request exists yet, so nothing was posted and no marker was stamped.

**Data release consent** (owner, in this session, quoted verbatim): "Codex + ollama-cloud (Recommended)". The repo has no standing consent; this is session-scoped.

| Round | Head | Artifact | Reviewers: CLI version, model, effort, sandbox | seconds, tokens per seat | BUG/RISK/NIT |
|---|---|---|---|---|---|
| 1 | `97f2a9f` | full, `259a1bb...97f2a9f` | codex-cli 0.159.3, gpt-6.1-sol, config effort, read-only · ollama-cloud kimi-k2.7-code:cloud **FAILED** (429, weekly usage limit) · fresh-eyes: host-family mid-tier model, read-only sub-agent | codex 146 s, 38 910 · fresh-eyes 479 s, 210 556 | 4 / 3 / 5 |
| 2 | `c748265` | delta since `97f2a9f` | codex, medium, read-only (`--seat codex`) | 239 s, 54 391 | 1 / 1 new + 1 re-raised (F4) / 1 |
| 3 | `5cb7790` | delta since `c748265` | codex, medium, read-only | 201 s, 34 995 | 1 / 1 / 0 |
| 4 | `6f2aee0` | delta since `5cb7790` | codex, medium, read-only | 174 s, 38 187 | 1 / 0 / 0 |
| 5 | `4ae606c` | delta since `6f2aee0` | codex, medium, read-only | 89 s, 35 491 | 0 / 0 / 0 — "No BUG/RISK/NIT findings." |

| id | Sev | Source | Round | Finding | Status | Evidence |
|---|---|---|---|---|---|---|
| C1 | BUG | codex | 1 | Form leftovers not read (field hint, button label) | fixed · locally_verified · externally_reverified r2, r3 | `c748265`, `5cb7790`; scenario S10; fixture test |
| C2 | BUG | codex | 1 | JSON-LD and manifest scanned as raw JSON, so escapes hid leftovers | fixed · locally_verified · externally_reverified r2 | `c748265`; S11, S13; self-check |
| C3 | BUG | codex | 1 | A slot broken across lines or partly in bold was not matched | fixed · locally_verified · externally_reverified r2 | `c748265`; S12 |
| F1 | BUG | fresh-eyes | 1 | The starter served two slots starting lower-case, invisible to the rule; the "every starter slot matches" claim in `97f2a9f`'s message was wrong | fixed · locally_verified · externally_reverified r2 | `c748265`: both slots capital-led, `UNSEEN_SLOT` on listed targets; S14 |
| F2 | RISK | fresh-eyes | 1 | `judge`'s verdicts pinned by no test | fixed · locally_verified · externally_reverified r2 | `c748265`: self-check asserts each verdict |
| F3 | RISK | fresh-eyes | 1 | Documents promised more than the rules cover; the starter's example values pass | fixed in the documents · externally_reverified r2 | `c748265`. A rule for the example address: follow-up, the owner's call |
| F4 | RISK | fresh-eyes r1, codex r2 | 1 | A target still listed only warns; nothing blocks a launch with an entry left | **OPEN — the owner's waiver or a fix** | disclosed: launch checklist, `website-review`, plan doc "Known limits"; disclosure verified r2–r5 |
| F5 | NIT | fresh-eyes | 1 | A `[MISSING: …]` past the length bound escaped | fixed · externally_reverified r3 | `5cb7790`: no bound |
| F6 | NIT | fresh-eyes | 1 | Retrofit on a launched site not described | fixed · externally_reverified r2 | `c748265`, `website-review` |
| F7 | NIT | fresh-eyes | 1 | A content-level collaborator may not edit `tests/` to delete the entry | fixed · externally_reverified r2 | `c748265`, template `AGENTS.md` §5 |
| F8 | NIT | fresh-eyes | 1 | Stale spec list in `.github/workflows/template-tests.yml` | fixed · externally_reverified r2 | `c748265` |
| F9 | NIT | fresh-eyes | 1 | Plan-doc evidence cell was a branch name | fixed: the cell says no pull request exists yet | plan doc row A1; gets the number when one is opened |
| R2-1 | BUG | codex | 2 | The lower-case-slot check ignored ALLOWLIST | fixed · locally_verified · externally_reverified r3 | `5cb7790` |
| R2-3 | RISK | codex | 2 | "Where the browser shows it" rested on an attribute and a blacklist | fixed · locally_verified · externally_reverified r3 | `5cb7790`: live `.value`, explicit type list, fixture test in the browser |
| R3-1 | BUG | codex | 3 | The fixture claimed every surface and missed several | fixed · locally_verified · externally_reverified r4 (enumerated surfaces) | `6f2aee0` |
| R3-2 | RISK | codex | 3 | The fixture searched the printed lines, so a neighbour's context could satisfy it | fixed · locally_verified · externally_reverified r4 | `6f2aee0`: compares `match` |
| R4-1 | BUG | codex | 4 | No token inside `<script>` or `<style>`, so dropping either exclusion could pass | fixed · locally_verified · externally_reverified r5 | `4ae606c` |

Waivers and deferrals: none granted. F4 is waiting for the owner.

Follow-ups: (1) a rule for the starter's example address, which would list the home page as pending from the first commit — the owner's call (plan doc, "Known limits"). (2) Reviewers marked the author's runs UNVERIFIABLE each round, since the template's packages are not installed in the checkout: 14 scenarios, 31 mutations (all caught and named), the full suite (61 passed, 1 pre-existing skip), the type check, and the browser observation that a range input given text reports `"50"`. The scripts and every round's raw reviewer output are kept, untracked, in the branch's worktree under `docs/local/review-raw-rendered-placeholder-gate/` until a pull request comment can carry them. The pull request's own `template-tests` run will be the first independent browser run.

Notes: Rounds 2–5 ran with one outside seat because ollama-cloud was at its weekly limit: degraded, not a chosen single seat; a second cross-model seat has not seen this change. Round 4 was earned by R3-1, round 5 by R4-1. Round 3's reviewer flagged a sentence in the prior-findings file ("Do not re-raise without new evidence") as an attempt to steer it; later files state dispositions only. The cost log could not be written (`~/.local/state/independent-review` is not writable from this session); the table above is the record. No final full read (Normal depth, not mostly a specification) and no wording pass (nothing but this file changed after round 5's head).
