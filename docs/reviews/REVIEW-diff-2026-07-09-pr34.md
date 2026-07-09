# DIFF review — PR #34 (fix/impressum-template)

Full independent-review pass (Fable model, adversarial, legal + code scope) — the
German-capability series' PR1, closing audit finding g4 (MAJOR).

## Artifact
`templates/astro/src/pages/impressum.astro` (new § 5 DDG Impressum draft) + footer link,
checklist rewrite, PAGES/llms.txt/OWN_CARD_EXEMPT gate entries.

## Reviewers
| Tier | Model | Scope | Result |
|------|-------|-------|--------|
| Fable (cross-checked statute text + ODR status + built dist/) | claude-fable | legal completeness, German language quality, gate mechanics, deviation soundness | 3 BUG / 4 RISK / 7 NIT |

## Findings → dispositions (all fixed in 4bf9b3d)
1. **BUG** missing § 5 Abs. 1 Nr. 5 lit. c field (berufsrechtliche Regelungen + access) → fixed.
2. **BUG** Nr. 6 W-IdNr. alternative ignored ("no VAT ID → delete" wrong since W-IdNr.
   auto-assignment late 2024) → fixed, both lines with keep-one guidance.
3. **BUG** documented deletion path (3 items) turned llms-coverage red → five-item list
   in impressum comment, Base.astro comment, and SKILL.md checklist.
4. **RISK** German copy under `lang="en"` (WCAG 3.1.1; wrong og:locale; English tone rules)
   → `lang="de"`, verified against the real German tone gate.
5. **RISK** DE/AT/CH scoping wrong both directions (establishment vs audience; AT/CH own
   statutes) → reworded everywhere + ECG/MedienG/UWG pointers.
6. **RISK** Nr. 3 licensed-activity duty conflated with chamber professions → comment split.
7. **RISK** description ceiling at 23-char SITE.name → trimmed, window holds to 36 chars.
8. **NITs** (7) → all fixed: stale seo.spec comment, POSITIONING_EXEMPT, sole-proprietor
   placement, PartG/GenR register variants, statute-vs-case-law wording + umlauts,
   `.site-footer` flex/gap, obfuscation-in-Impressum caveat documented.

## Verified clean by the reviewer
- ODR-link omission CORRECT (platform discontinued 20 Jul 2025, Reg. (EU) 2024/3228 —
  references must be removed; shipping the link would be the error).
- Active-in-PAGES deviation sound (sitemap-drift alarm forces it; matches privacy model).
- § 36 VSBG formula verbatim-standard; § 18 Abs. 2 MStV correct; ECJ C-298/07 two-channel
  contact rule satisfied; German language quality lawyer-grade; email obfuscation passes
  email.spec on raw HTML; gate mechanics (sitemap/PAGES/llms/OWN_CARD_EXEMPT) consistent.

## Post-fix state
Template suite 35 passed / 1 skipped; built page `lang="de"` + `og:locale de_DE`;
description window verified at name lengths 7/23/35/36.
