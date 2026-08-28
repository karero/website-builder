# DIFF review — new skill `business-listings-setup` + orchestrator wiring

Multi-round blocking gate applied to a new skill (`skills/business-listings-setup/SKILL.md`)
plus its wiring into `skills/new-website/SKILL.md` (pipeline table, §4a ask-gate, always-on copy
list, launch checklist) and `README.md`. Solo local change, no PR open — reported to the owner
directly rather than posted anywhere.

## Artifact
`git diff HEAD -- . ':(exclude)docs/reviews/'` plus the untracked new file
`skills/business-listings-setup/SKILL.md`, re-diffed fresh each round after fixes landed.

## Reviewers run (round-by-round)
| Round | Tier | Tool | Model | Sandbox |
|---|---|---|---|---|
| 1–5 | 1 (cross-model) | Codex CLI | gpt-5.6-sol | `codex exec -s read-only` |
| 1–5 | 2 (cross-model) | ollama cloud | glm-5.2:cloud | Ollama's own servers |

Standard pair only; Antigravity not requested. Host = Claude Code, so both tiers are cross-model —
gate satisfied every round. A house double-knuth pass (Pass 1 = `/code-review` on the diff, Pass 2
= completeness/cross-file consistency) ran once, before round 1, as the toolkit's own correctness
gate ahead of external review — not counted as a review round here.

Rounds 1–2 ran with the shell `cwd` at the wrong repo (`GenAI_site` instead of `website-builder`),
so Codex could not read real files and returned mostly UNVERIFIABLE verdicts for anything needing
file access. Caught before round 3; rounds 3–5 ran `cd website-builder &&` explicitly.

## Round-by-round summary

| Round | Findings | Headline |
|---|---|---|
| 1 | several, fixed | Frontmatter description trimmed (150→116 words) and de-scoped ("backlinks" / "get cited elsewhere" trigger phrases removed as overclaiming outreach the skill doesn't do); GBP eligibility gate added (§1 step 0 — a real address or in-person service, not just "named entity"); Bing's causal "feeds Copilot" claim softened. |
| 2 | several, fixed | Bing wording further softened (index Copilot draws on, not a guaranteed feed); §4 "what this skill is not" reworded to distinguish warm partner/sponsor asks from cold outreach; §5 completion criteria first loosened from a flat "200" bar to accommodate bot-blocked platforms; a false claim about a nonexistent "website-review AI-panel round" (carried over by mistake from a different repo) replaced with an honest "no dedicated Authoritativeness score" note. |
| 3 | 5 confirmed, fixed | Schema field confusion: `SITE.name` maps to `alternateName`, not `name` (`name` holds `COMPANY.legalName`) — verified directly against `Base.astro`. Link-classification retry: outgoing-link-audit's own documented convention ("re-check once, could be transient") wasn't being followed for 5xx — added. New REBRAND/MOVED-style case for a redirect to a different domain. §3 step 4's "steps 1 and 2" was locally ambiguous (read as this section's own steps) — made explicit. Orchestrator §4a's "named entity" gate conflated with the narrower GBP/Bing eligibility bar from §1 — decoupled. |
| 4 | 4 BUG + 2 NIT, fixed | §4a's "no separate name from its owner" wrongly excluded sole proprietors/consultants trading under their own name — reworded to "is there a business/practice to claim." A single retry on a 5xx still isn't proof of death (the *target's* server failing, not confirmation) — split 404/410 (unambiguous, dead) from 5xx (unverified, needs a human logged-out check). Launch checklist demanded directories for every named entity with no "none exist for this category" outcome — added, parallel to the existing GBP/Bing carve-out. Bing's fallback referenced "the same fields as step 1" where local step 1 was just "sign in" — pointed at the real field-drafting step. Plus two wording NITs (stale "three-way split" label, backwards "a 200 that redirects" phrasing). |
| 5 | 9 fixed, 2 refuted | Nothing checked for an *existing* GBP listing before creating one (duplicate-listing risk) — added a search-first step. "The agent drafts every value" overclaimed — `config.ts` has no address/phone field at all; softened and flagged those as owner-supplied. The skill told readers to classify links "using outgoing-link-audit's own conventions" while pointing at a script that treats 5xx as immediately dead — the opposite of what this skill says; reworded to "reuse the fetch mechanics, apply this section's own stricter policy." Completion criteria only mentioned bot-blocking in the manual-verification carve-out, not the 5xx/redirect cases round 4 added — broadened. "Shared organization account" read as recommending shared credentials — reworded to org-owned account with named managers. The skill's own header blockquote still said "no separate brand name" — the exact test round 4 rejected in the orchestrator — caught independently by both reviewers, fixed to match. "Always-on" labeling for a skill that's actually execution-gated by §4a was self-contradictory — one clarifying sentence added. Ambiguous "§1's own check" cross-reference in the launch checklist — made explicit. Scope note tightened ("not link building" → "not *cold* link building", matching the file's own existing carve-out for warm partner asks). |

## Round 5 refutations (checked against source, not just asserted)

- **"An automated 404/410 still isn't unambiguous proof of death"** (Codex) — the actual removal
  action in §3 step 3 is marked 🧑 (human), not automated; nothing deletes a `sameAs` entry without
  a person deciding to. Also the third round touching link-classification granularity (rounds 3, 4,
  5) — diminishing returns on the same finding-id, per this skill's own round-cap guidance.
- **"'Say so and skip silently' is self-contradictory"** (ollama) — not a defect introduced by this
  diff: the identical phrase already exists in the pre-existing §3a gate at
  `skills/new-website/SKILL.md:363` (verified by direct read), which the new §4a was explicitly
  written to mirror ("Gate it the same way as the outgoing-link sweep in §3a"). Fixing only the new
  instance would have broken the intentional parallel structure between the two sections.

## Stopping here

Five rounds. Findings narrowed from structural gaps (rounds 1–3: eligibility rules, schema field
mapping, scope boundaries) to wording/process-completeness issues (rounds 4–5: cross-references,
credential-sharing phrasing, an "always-on" label mismatch) and round 5 produced the review's first
two refutations. Presented the round 5 results and the cost (5 full rounds of the standard pair) to
the owner directly and asked whether to continue; owner chose to stop rather than run a 6th round.
`git diff --check` clean after every round's fixes. Not independently re-verified by a 6th round —
noted here per this skill's convention for deferring verification without deferring the fix itself.
