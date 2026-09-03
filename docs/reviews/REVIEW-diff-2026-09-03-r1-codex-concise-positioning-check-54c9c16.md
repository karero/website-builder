# Review trail — DIFF, round 1 (single external reviewer, owner-chosen)

- **Branch**: `codex/concise-positioning-check` — adds `website-positioning-check`
  (Codex-authored f207adc) plus the in-house revision 54c9c16 after two live test runs.
- **Artifact**: full branch diff `origin/main...54c9c16` (196 lines).
- **Reviewer**: ollama `kimi-k3:cloud`, one shot via `ollama_review.sh --diff`, named
  explicitly by the owner. **Not** the standard two-seat independent-review gate: one
  seat, no clerk round. Lighter gate chosen because the change is prompt-only (one new
  SKILL.md, two-line boundary edit, README/package.sh/new-website bookkeeping) — no code
  path a site recipient runs.
- **Raw verbatim output**: RAW-diff-2026-09-03-r1-codex-concise-positioning-check-54c9c16.md.
- **Verdict**: 1 BUG (docs, pre-existing but on a line this diff edited), 3 RISK, 4 NIT.

## Findings (8)

| id | sev | finding | disposition |
|----|-----|---------|-------------|
| K1 | RISK | "`npm run build` writes only the gitignored `dist/`" stated as universal; other stacks' builds touch more, undermining the read-only promise | **fixed** (this round): scoped to a kit-built site (verified: the template's build writes `dist/` + `dist/build.txt`, both under `.gitignore`), and the skill now confirms `git status` stays clean and says so if not |
| K2 | BUG | README lists the sibling chain as content-guide → design-system → seo-geo and puts `permissions` inside "run in order"; `new-website/SKILL.md` and its `cp` block say seo-geo → design-system and keep `permissions` outside the chain | **fixed** (this round): README now mirrors SKILL.md and moves `permissions` + `positioning-check` outside the chain. Note: both `website-seo-geo` and `website-design-system` describe themselves as "step 5", so the two orders were never contradictory in the pipeline itself — only in the two docs' prose |
| K3 | RISK | "twenty-two" bumped in one place; other enumerations may be stale, no evidence shown | **refuted**: `cp -RL` block counted (22 entries); `grep` across README, docs/, scripts/, templates/ finds no other enumeration of the sibling set; `check_skill_budgets.sh` derives its count from `skills/*/SKILL.md` (29) |
| K4 | RISK | Reciprocity is one-way: only `website-positioning` points at the check; `website-review`/`website-qa`/`website-content-guide` don't | **owner-waived (recommended)**: routing rests on the check's own trigger phrases + "Do not use for" clause; adding boundary lines to three more skills for a diagnostic is more surface than it earns. The one plausible overlap ("we sound too technical" vs content-guide's tone triggers) is covered by the check's negative clause naming `copywriting`, and content-guide's own description scopes it to voice. Owner may reverse |
| K5 | NIT | `package.sh` REQUIRED gains one arbitrary skill file; the list's stated criterion (legal notices, install path, orchestrator, architecture doc) doesn't cover it | **fixed** (this round): line removed. The skill still ships — `zip -r skills` bundles every skill, and `check_skill_budgets.sh`'s MIN_SKILLS floor guards the set |
| K6 | NIT | "Return exactly this shape" vs the optional Core line | **fixed**: "Return this shape" |
| K7 | NIT | Fallback chain is npm/Astro-centric; other generators dead-end | **fixed** (folded into K1): "read the homepage source (`src/pages/` on a kit site)" |
| K8 | NIT | "the optional `website-positioning-check`" inside the always-on enumeration reads self-contradictory before the always-copied ≠ always-run definition lands | **refuted**: the definition is two sentences earlier in the same paragraph (new-website/SKILL.md:259–262) |

CLEAN list from the reviewer (name/path agreement, count arithmetic, pipeline placement,
handoff chain, frontmatter) checked and agrees with the in-house pass.

## Round closure

One round. K1, K2, K5, K6, K7 fixed locally; K3, K8 refuted with evidence; K4 waived
pending owner. Fixes are docs/prompt-only and were not re-sent — same stop rule as the
2026-08-29 trail: a round with no behavior-level BUG/RISK closes on local verification.
Validators after fixes: `check_clean`, `check_model_agnostic`, `check_skill_budgets`,
`check_template_coverage` all OK.

Addendum: the owner reversed the K4 waiver; the reciprocal pointers were implemented in
PR #96.
