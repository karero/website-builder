# REVIEW — DIFF gate, readable GEO report (feat/geo-report-readable), 2026-09-26

**Reviewed:** `origin/main...29c9a27` (the report redesign, owner instructions, run-ID fix).
Verbatim: `RAW-diff-2026-09-26-r1-geo-report-readable-29c9a27.md`.
**Reviewers:** Codex OK (cross-model). ollama-cloud FAILED (weekly usage limit). Claude fresh-eyes OK.
**Gate depth:** one round, as the owner directed ("independent code-review round, then the PR").
This follows PR #121, which went through the full PLAN + DIFF gates. The fixes below are
`locally_verified` (tests, all mutation-checked) and **not externally re-verified**.
**Visual review:** owner (UI is theirs to judge); rendered on the owner's three real sites,
checked at desktop/phone width and in light/dark.

## Findings and dispositions

C = Codex, F = fresh-eyes.

| id | sev | src | finding | disposition |
|---|---|---|---|---|
| R1 | BUG | C1 F1 | the headline overstated: 1-of-3 counted as "every question", and failed/no-answer questions were dropped before "every" was judged ("…your website is doing its job") | fixed by one explicit rule, stated in `build_report`'s docstring: only answers to the current question, from an assistant that is on now, that came back, count. "At least once" = named in one such answer; "every answer to every question" = all current questions answered and named in every answer. The causal claim is removed. `test_headline_counts_only_what_really_answered`, `test_headline_sometimes_is_not_every_time`, `test_headline_all_and_none`, `test_no_google_answer_is_not_a_miss` |
| R2 | BUG | C2 | "when they look things up" although an engine may not search | fixed: "with web search on" throughout; the "it only searched N of M times" note stays |
| R3 | BUG | C3 F7 | "Does AI *recommend* you?" but the check counts mentions ("I don't know X" counts) | fixed: "Do AI assistants name you?"; the page says it checks whether the name appears, not whether it is recommended |
| R4 | BUG | C4 | branded answers to an older question lost their stale note | fixed: the same "* Answer from … to an earlier version" note as the scored questions |
| R5 | BUG | C5 F8 | partial failures hidden ("✓ Named" for 1 answer of 3 with 2 failed) | fixed: chat engines always show the count, plus "N of M answers failed" |
| R6 | BUG | C6 | run IDs could still tie within one microsecond | fixed: strictly increasing within a process (a tie moves one microsecond on); microseconds across processes. `test_run_ids_sort_in_the_order_they_were_made` |
| R7 | BUG | F2 | the page said it "is refreshed"; each run writes a new file | fixed: "Each weekly check writes a new page like this one"; the guide says an older page is not updated |
| R8 | RISK | F3 | the branded-never-scored test could not fail | fixed: rewritten so counting the branded row would spoil "every question"; mutation-checked |
| R9 | RISK | F4 | most cell states and headline branches untested | fixed: `test_every_cell_state_reads_plainly` (15 states, through `--report`) and the headline tests above. The eight mutations the reviewer ran all fail now |
| R10 | RISK | F5 | "3 times" hard-coded | fixed: built from `SAMPLES`; the test asserts against `SAMPLES` |
| R11 | RISK | F6 | removed engines and answers to old questions were counted | fixed: counts only engines on now and answers to current questions. `test_answers_to_an_old_question_or_from_a_removed_engine_do_not_count` |
| R12 | RISK | C7 | model-behaviour claims unmeasured ("new answer every time", "reliably", "changes with new versions") | fixed wording: "can write a different answer each time", "named in every answer", "changes slowly" |
| R13 | RISK | C8 | the Gemini reason is "unverified" | refuted: the clause was read on Google's own terms page on 2026-09-26 and quoted verbatim in PR #121 (`FINDS_SUPPORTED` comment, geo-check.md) |
| R14 | NIT | F9–F15 | "some already know you" wording; "young business"; Google line when Google is off; retry promise on fatal errors; legend gaps; run-ID docstring; description headroom | fixed: count-based memory sentence; "most small businesses"; the Google line only when a Google engine is on; "the weekly log says why"; legend lists every state; docstring corrected; description 1015 → 998 chars (dropped the "who ranks for" trigger; "competitor Top 10" still covers it) |

## Final state

119 tests pass; `check_clean` and `check_skill_budgets` pass. Nothing open.
