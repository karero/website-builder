# REVIEW — DIFF gate round 2 (verification), weekly GEO check, 2026-09-26

**Reviewed:** the round-1 fix commit `3e22dc3..3b2239c` (trail excluded), with the round-1 table
D1–D25 as the verification checklist. Verbatim: `RAW-diff-2026-09-26-r2-geo-check-3b2239c.md`.

**Reviewers:** Codex OK (cross-model, satisfies the gate). ollama-cloud FAILED again (weekly usage
limit). Claude fresh-eyes OK. Owner's choice for this round, verbatim: "Codex + fresh-eyes now
(Recommended)".

**Owner decisions recorded this round (verbatim):**
- D24 (answers/reports never pruned): "Yes, later (Recommended)". **Waived** for v1; follow-up.
- D25 (juliet.space named in the public plan): "Keep it". **Closed.**

## Verification of round 1

Codex and fresh-eyes confirmed D1–D4, D6–D8, D10–D12 (before the simplification below), D14,
D15, D19–D23 as fixed. Two claims were wrong:
- **D9:** the regression test could not fail on the old code (fresh-eyes restored the old line and
  it still passed). Status was `locally_verified` in error. Now fixed with an end-to-end test
  (two runs, bumped detector, trend says "settings changed"); re-mutated: it fails on the old line.
- **D5:** half fixed (cards labelled, summary grid not). See E9.

## New findings (round 2) and dispositions

C = Codex, F = fresh-eyes.

| id | sev | src | finding | disposition |
|---|---|---|---|---|
| E1 | BUG | C1 | D13 containment incomplete: a non-string citation crashed after the call and lost the run's rows | fixed: `call_engine` keeps only strings before anything is counted. `test_malformed_citation_does_not_lose_the_run` |
| E2 | BUG | C2 | "visible text" included `<head>` and hidden elements, so a consent page with the name in its title or a hidden div passed | fixed: the extractor skips `<head>`, scripts/styles and hidden subtrees (`hidden`, `aria-hidden`, `display:none`, `visibility:hidden`). `test_consent_page_with_the_name_in_title_or_hidden_is_unreadable` (3 cases), `test_real_homepage_still_reads` |
| E3 | BUG | C3 | `KEY= # add later` loaded as the key `# add later` (bash: empty) | fixed. `test_commented_empty_key_is_empty` |
| E4 | BUG | F-B1 | Google AI Mode's normal "no results" became a weekly FAILED (the D6 refactor and the D7 fix collided) | fixed: "no AI Mode answer" is its own state, like "no AI Overview shown". `test_ai_mode_no_results_is_not_a_failure` |
| E5 | RISK | F-R4 | the challenge-page keywords rejected real pages ("IT-Security Check") and missed localized walls | **redesigned (convergence rule):** the homepage check has drawn findings in five rounds (P11 → Q14 → T8 → D12 → E5). Keyword guessing is removed. The code rejects only pages that fail to load or whose visible text names neither the business nor its domain; a strange page shows as "changed" (a warning, never a failure), and `--confirm` prints what it read so a person decides. geo-check.md now says so. `test_strange_page_is_shown_for_review_not_guessed`, `test_ordinary_page_with_security_check_headline_is_read` |
| E6 | RISK | F-R5 | configs confirmed before `confirmed_questions` existed always read "unconfirmed", masking real homepage changes | fixed: the fingerprint is compared first; a missing field means "no record", not "changed". `test_legacy_config_still_reports_homepage_changes`; the state is documented |
| E7 | RISK | F-R2 | D1 turns Google off on existing configs | refuted for users: the feature is new in this branch, and the only configs are today's three test sites, switched on with the owner's request (`--google on`). Onboarding asks before switching it on |
| E8 | RISK | F-R3 | the trend header counted switched-off engines as "checked" | fixed: it counts only engines on now ("engines on now: N of 6"). `test_trend_header_counts_only_engines_on_now` |
| E9 | RISK | F-R6 | the report's summary grid had no stale marker | fixed: `*` plus a footnote. Asserted in `test_report_labels_answers_to_an_earlier_question` |
| E10 | RISK | C4 | provider response contracts proven only by our own stub (D17) | **fixed for 5 of 6 engines:** real responses captured live (neutral question, no client), trimmed, key-checked, and saved as `tests/fixtures/*.json`; `test_real_responses.py` parses them (text, model, sources, searched flag, absent overview). **OpenAI stays OPEN**, blocked on a missing prerequisite (no account credit) |
| E11 | RISK | C5 | "wiggles are usually sampling noise" is still an unmeasured claim | fixed: reworded to advise comparing over several weeks, without attributing causes |
| E12 | NIT | F-N1…N8 | misleading "no key" line when only SerpApi is set; Perplexity `incomplete`; one write-error line per sample; `--google` combined with other flags; `{"error": null}`; unclosed quote; two bare `geo_check.py` commands; untested D13/D16/D21 | all fixed. `--google` is now in the exclusive command group; D16 has `test_slow_engine_does_not_starve_the_next`, D21/E8 and D13/E1 have tests |

## Status at close of round 2

- BUG series across rounds: 12 → 4. All round-2 BUGs are fixed with tests (`locally_verified`);
  the D9 test and three earlier fixes were mutation-checked.
- Open: E10 for OpenAI only (prerequisite missing: account credit). D24 waived by the owner.
- 99 tests pass (95 before the real-response tests).
- Round 3 (verification of the round-2 fixes) to run next.
