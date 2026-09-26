# REVIEW — DIFF gate round 4 (final), weekly GEO check, 2026-09-26 — GATE CLOSED

**Reviewed:** the round-3 fix commit `bb4f354..28899d7` (trail and fixture JSON excluded;
`capture.py` included). Verbatim: `RAW-diff-2026-09-26-r4-geo-check-28899d7.md`.
**Reviewers:** Codex OK (cross-model). ollama-cloud FAILED (weekly usage limit, all four rounds).
Claude fresh-eyes OK.

## Convergence

| Round | BUG | RISK | NIT |
|---|---|---|---|
| 1 | 12 | 6 | 7 |
| 2 | 4 | 8 | NITs grouped as E12 |
| 3 | 4 | 10 | 4 |
| 4 | Codex 4 (small; H1 refuted); **fresh-eyes 0** | 2 + 1 | 8 |

Fresh-eyes proved every round-3 fix by mutating scratch copies (G1, G3, G4, G5, G7, G8, G9, G14).

**Owner decision closing the gate** (verbatim): **"Fix these, close, no 5th round (Recommended)"**.
The round-4 fixes below are therefore `locally_verified` (tests, and mutation checks where
marked) and **not externally re-verified: last round not re-verified.**

## Round-4 findings and dispositions

C = Codex, F = fresh-eyes.

| id | sev | src | finding | disposition |
|---|---|---|---|---|
| H1 | BUG | C1 | the preview "does not bind the page body" | **refuted:** the saved fingerprint is, by design, the title + description + main heading, the same three things the preview shows. If a cookie gate keeps those three identical, what is saved is identical to the real page's fingerprint, so nothing wrong is stored. F independently: "the page code covers exactly the title, description and H1 that the preview shows". The wording "save exactly this page" did overclaim, and is fixed |
| H2 | BUG | C2 | a `<meta>`/`<h1>` inside `<template>`/`<noscript>` changed the fingerprint | fixed: nothing inside a skipped subtree touches parser state. `test_template_contents_do_not_change_the_fingerprint`, mutation-checked (the first version of this test could not fail; it was reordered until it did) |
| H3 | BUG→RISK | C3 F-R1 | `capture.py` did not reproduce the fixtures (no OpenAI, one question for all, trimming done by hand, and a re-run would undo it) | fixed: capture.py covers every engine, picks the recorded question per fixture, and trims in code (`trim()`). Applied to the committed fixtures, `trim()` changes nothing, so they match the documented method |
| H4 | RISK | C4 | the "only the owner's test configs exist" claim lacked evidence | closed with evidence: `ls ~/.config/gsc-insights/geo/*.json` on the only machine with this branch lists exactly three configs, the owner's three test sites (names withheld: private), each with `google: true`. The feature exists only on this unmerged branch |
| H5 | BUG | C5 F-N2 | the guide still said "visible text" | fixed: "anywhere in their text (including the title and hidden elements)"; the preview is described as title, description and main heading |
| H6 | RISK | F-R2 | **the AI Mode fixture's own answer blocks had been blanked**, contrary to three written claims (two docstrings and the round-3 trail) | **author's error, fixed:** the hand trim hit `text_blocks[].snippet`; the round-3 trail said only the Overview was affected. Restored from the untrimmed capture at `bb4f354` and re-trimmed by `trim()`, which never touches answer blocks. Docstrings now say what happened |
| H7 | NIT | F-N1 | bare `--confirm` in the usage line, a docstring, three runtime hints, the guide and eval 9 | fixed: all name `--check-drift` then `--confirm --expect <page code>` |
| H8 | NIT | F-N3 | a mistyped code was reported as "page changed"; `--expect` without `--confirm` was ignored | fixed: "does not match the current page (it changed since the preview, or the code was mistyped)"; `--expect` alone is an error. `test_expect_without_confirm_is_an_error` |
| H9 | NIT | F-N4 | SKILL.md's rule omitted "first check the new text is the real page" | fixed |
| H10 | NIT | F-N5 | RealReplay never checked the confirm result, and its name was in the first block | fixed: asserts `rc == 0`, and that "Riedmair" (a late block) is in the saved answer file |
| H11 | NIT | F-N6 | Gemini's multi-part answers had no test (the fixture has one part) | fixed: `test_gemini_answer_in_several_parts_is_read_whole` (synthetic, labelled) |
| H12 | NIT | F-N7 F-N8 | `model` not UTF-8-sanitized; the hint path was unquoted | fixed: sanitized like the text; `shlex.quote` |
| H13 | RISK | C (other) | SerpApi billing per call is unmeasured; the fixtures' live provenance has no request/response records | accepted as documented judgment: the docs call one sample per Google question "a cost choice"; `capture.py` now makes the capture repeatable |

## Final state

- 110 tests pass. `check_clean`, `check_skill_budgets` and `check_model_agnostic` pass.
- Open: nothing. D24 (answer/report pruning) is waived by the owner for v1 and logged as a follow-up.
- **Gate verdict: closed by owner decision after convergence; the round-4 fixes are
  locally verified, not externally re-verified.** The standard pair never ran complete
  (ollama-cloud hit its weekly limit), so every round had one cross-model reviewer (Codex).
