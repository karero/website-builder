# Independent review — DIFF gate — round 1 — 2026-08-29

Artifact: the `skill/debloat` branch (commit `6ea6874`) — a markdown-only debloat of
the skill suite against the skill-creator sizing guidance: three SKILL.md files
restructured into `references/` (new-website, independent-review, astro-i18n-setup),
five frontmatter descriptions trimmed, TOCs added to three 300+-line reference
files. `search-console-insights` deliberately untouched (owned by a parallel
session). Review artifact: `git diff origin/main...HEAD -- . ':(exclude)docs/reviews/'`.

## Reviewers

| Seat | Tool | Model | Outcome |
|---|---|---|---|
| 1 (cross-model) | ollama cloud via `independent_review.sh` | `glm-5.3-flash:cloud` (auto-detected) | full review — raw in `RAW-diff-2026-08-29-r1-skill-debloat.md` |
| 2 (cross-model) | Codex CLI, same script run | config.toml default | **no review** — usage-limit error at request time; round 2 re-routed here after the quota reset |
| 2b (attempted) | Antigravity `agy --sandbox -p` (owner pre-approved the credit) | CLI default | **no review, no credit spent** — headless mode auto-denied a tool permission; the CLI's suggested `--dangerously-skip-permissions` is a danger flag this skill's Boundaries forbid for untrusted reviewers |
| 3 (fresh-eyes, same-family) | read-only host sub-agent, artifact + strict prompt only | host family | full review |
| host | `/code-review` protocol, 10 finder angles + consolidation | host family | full review |

Host: Claude Fable 5. Cross-model independence: satisfied by seat 1 (GLM / Z.ai
family vs. Anthropic host). Round 2 (verification) adds Codex as the second
cross-model seat.

Data check: diff grepped for secrets before leaving the machine — none (public-repo
doc content only). Owner consent in-session for Codex, ollama-cloud, and
Antigravity ("Not sure if CODEX it available … otherwise at least you ollama GLM 5.3
flash"; "You can also check Antigravity, If possible use 2").

## Findings and dispositions

~28 raw findings across all seats, consolidated to 15 (dedup by file+mechanism).
D1–D13 fixed in `e4aa3f9`; D14–D15 deferred as follow-up tasks with owner
visibility; R1–R4 refuted with evidence.

| id | Sev | Finding (source) | Disposition |
|---|---|---|---|
| D1 | BUG | source-guides.md Contents listed 8 of 12 sections (5 seats independently) | **fixed** `e4aa3f9` — all 12 listed |
| D2 | BUG | new-website guardrails pointer sat AFTER the §4 deploy steps it governs (angle E) | **fixed** — subsection moved above the checklist |
| D3 | BUG | Guardrails summary dropped the never-ANNOUNCE-before-Active half of the cached-404 rule (angle B) | **fixed** — restored to the summary |
| D4 | BUG | independent-review summary claimed BOTH preconditions invisible to reviewers; source claims it only for check 1 (angle A) | **fixed** — scoped to check 1 |
| D5 | BUG | Precondition summary dropped ephemeral-CI-URL anti-pattern, "Not started" exemption, prior-findings-list exclusion (angles B, E) | **fixed** — all three restored |
| D6 | BUG | astro-i18n SKILL.md §3 "this snippet's cluster replaces it" dangled after the code move (4 seats) | **fixed** — names the reference |
| D7 | BUG | heavy-path-code.md §3 comment "note below this snippet in SKILL.md §3" geometrically impossible (4 seats) | **fixed** — "SKILL.md §3's light-path note says what to delete" |
| D8 | BUG | §1 "(§2 / 'Partial translation' above)" — "above" wrong for §2 (GLM top finding; host seats confirmed "above" IS correct for Partial translation — origin/main's "below" was itself wrong) | **fixed** — direction bound to the right target only |
| D9 | RISK | Trimmed descriptions lost suite-unique triggers: "get a second model to review", "which review tool should I use", "set up codex, ollama, or antigravity for review", "do I need a second opinion on this" (fresh-eyes, B, D) | **fixed** — four phrases restored; "are any pages orphaned" / "set up a new web project" stayed cut (subsumed by surviving phrases) |
| D10 | NIT | plan-preconditions.md left "clerk procedure"/"Reviewer stack"/"item 3" unmapped; "a document reviewers read" premise stale post-move (A, B, E) | **fixed** — cross-ref key extended; premise reworded |
| D11 | NIT | launch-guardrails said confirm liveness "separately" though `npm run ship` self-verifies via `/build.txt` (reuse angle; verified against ship.sh:273–295) | **fixed** — reconciliation note added |
| D12 | NIT | In-language announcement rule (§1) separated from the templates it governs; CLOUDFLARE_FIRST_DEPLOY pointer sibling-relative vs skill-root convention (angle E, D) | **fixed** — rule stated in the reference; pointer normalized |
| D13 | NIT | New TOCs used an invented inline style vs the suite's `## Contents` bullet convention (5 existing files); "Also added:" changelog voice in §2; duplicated codified-date line; duplicated rationale in §1/§3 summaries (reuse, simplification, conventions) | **fixed** — convention adopted, voice fixed, duplicates trimmed |
| D14 | RISK | Deploy guardrails never ship to scaffolded sites — new-website is not in its own §3 copy list; pre-existing gap the move deepens by one hop (altitude) | **skipped** — pre-existing, out of scope; follow-up task offered to owner |
| D15 | RISK | No `make check` guard on description length / SKILL.md size; search-console-insights' description already 1627 chars vs the 1024-char skill-spec limit (altitude) | **skipped** — follow-up task offered; the over-limit file is owned by a parallel session and was not touched per owner instruction |
| R1 | RISK | GLM: German-draft delegation unverifiable — impressum/datenschutz headers might not carry the five-piece removal / swap steps | **refuted** — headers read in full: both carry every delegated step (verified twice: host pre-edit + fresh-eyes + angle B post-edit) |
| R2 | NIT | GLM: description pointers ("full copy list in §3", "phase gates state the options", "Review depth section") might dangle | **refuted** — every target verified present (three independent seats) |
| R3 | NIT | B: "never independent-review's own default of two" guard lost from description altitude | **refuted** — survives compressed ("owner-approved single external reviewer") in the same descriptions |
| R4 | NIT | Summary-restates-reference duplication (wrapper pattern itself) | **partially fixed** (rationale trims in D13); the remaining actionable-summary-plus-reference shape is deliberate — summaries must let routine paths run without loading the reference. Owner may overrule |

## Clean (checked, not assumed)

All three moves verified byte-identical to origin/main apart from intended
relocation adaptations (mechanical diff, three separate seats); frontmatter YAML of
all five trimmed descriptions parses (633–956 chars, under the 1024 limit); no
repo file outside `docs/reviews/` references the moved headings or trimmed phrases;
`package.sh`/`whats-new.sh --refresh`/`cp -R` all carry the new reference files;
both CI guards (`check_model_agnostic.sh` — which auto-scans the new
plan-preconditions.md — and `check_clean.sh`) green before and after the fixes; no
prompt-injection content in the artifact (GLM checked explicitly).

## Convergence

Round 1: ~28 raw → 15 consolidated (13 fixed, 2 deferred-with-owner-visibility,
4 refuted). Round 2 = Codex verification of `e4aa3f9` once its quota resets
(13:40) — confirms the fixes landed, checks they introduced nothing new. The r1
closing edits are `locally_verified` until then.
