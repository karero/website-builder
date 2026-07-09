# DIFF review — PR #35 (fix/og-card-width-check)

Full independent-review pass (Fable model, adversarial, empirical) — the German-capability
series' PR2, closing audit finding g3 (MAJOR).

## Artifact
`templates/astro/scripts/generate_og_cards.py` (`fit_title` width check + fail-loud) +
`skills/og-images/SKILL.md`.

## Reviewers
| Tier | Model | Scope | Result |
|------|-------|-------|--------|
| Fable (re-derived pre-fix behavior, re-ran all reproduction strings, generated + visually inspected a real card) | claude-fable | algorithm correctness, edge cases, adjacent code paths | 0 BUG / 2 RISK / 2 NIT |

## Findings → dispositions (fixed in 85a2747)
1. **RISK** identical silent-clip bug in the SUBTITLE path (86-char German subtitle =
   1256px, rendered cut mid-word — demonstrated on a generated card) → same fail-loud
   guard at the fixed 30pt subtitle size.
2. **RISK** >3-line titles at 52pt shipped silently past the card bottom (6 lines →
   y=654 > 630), SKILL.md sentence overpromised → fallback exits loud on line-count
   overflow too; SKILL.md lists all three overflow cases.
3. **NIT** `__pycache__/` committable via `git add -A` → removed + gitignored.
4. **NIT** stale "wraps to ≤ 3 lines" PAGES comment → true again post line-count exit;
   no change needed.

## Verified clean by the reviewer
Pre-fix overflow re-derived (1123px accepted at 84pt); all reproduction cases
(76pt/68pt/84pt/SystemExit); real card visually clean (rightmost title pixel x=1074 of
1200); no partial files on exit; empty/whitespace titles safe; wrap() greedy invariant ×
width-check boundary consistent; umlaut rendering; SKILL.md accuracy post-fix.

## Post-fix state
All original cases pass; 40-word title exits loud; long German subtitle exits loud;
normal cards generate fine.
