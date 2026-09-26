# REVIEW — DIFF gate round 1, weekly GEO check (feat/geo-check), 2026-09-26

**Reviewed:** `git diff origin/main...3e22dc3`, excluding `docs/reviews/` (about 2,500 lines).
The diff was over the review script's 117 KB single-argument limit, so the external reviewers got
it in two parts: `geo_check.py` + its tests, and track.sh / gsc_query.py / CI / check_clean + the
docs. The fresh-eyes pass read the whole diff. Verbatim output:
`RAW-diff-2026-09-26-r1-geo-check-3e22dc3.md`.

## Reviewers

| Seat | Result | Independence |
|---|---|---|
| Codex (read-only) | OK on both parts | cross-model: satisfies the gate |
| ollama-cloud | **FAILED** on both parts: "reached your weekly usage limit" | would have been the second cross-model seat |
| Claude fresh-eyes sub-agent | OK | same family |

The round therefore had **one** cross-model reviewer, not the standard pair. Consent for sending
this repo's content to Codex and Ollama Cloud was given in this session (see the PLAN trail).

## Findings and dispositions

Sources: C1 = Codex, code + tests part; C2 = Codex, plumbing + docs part; F = fresh-eyes.
Status `locally_verified` = the fix has a regression test that fails on the old code (three
of them were mutation-checked); none are `externally_reverified` yet (that is round 2).

| id | sev | src | finding | disposition |
|---|---|---|---|---|
| D1 | BUG | F-B1 | an existing `SERPAPI_KEY` silently turned on the paid Google engines | fixed: Google is opt-in per site (`--google on`); only opted-in engines count as "has a key". `test_serpapi_key_alone_does_not_switch_google_on` (mutation-checked) |
| D2 | BUG | F-B2 | the "no credit" regex matched Gemini's ordinary per-minute 429 ("plan and billing details") | fixed: classified from structured fields (OpenAI `insufficient_quota` / `credit_balance_exhausted`, Gemini `quotaId` …PerDay…). `test_gemini_per_minute_limit_is_retried…` (mutation-checked), `test_gemini_daily_quota_stops_that_engine` |
| D3 | BUG | F-B3 | docs used bare `python` (absent on stock macOS; system python3 lacks requests) | fixed: `~/.config/gsc-insights/venv/bin/python` in all 13 GEO commands |
| D4 | BUG | C1-1 | the error line was truncated before redaction, so part of a key could leak | fixed: redact, then truncate. `test_key_is_redacted_even_where_the_message_is_cut` |
| D5 | BUG | C1-2 C2-1 F-R6 | the report showed old answers under the current question | fixed: a card answering an earlier revision says so and quotes that question. `test_report_labels_answers_to_an_earlier_question` |
| D6 | BUG | C1-3 F-R7 | a failed AI Overview follow-up was recorded as "no AI Overview shown" | fixed: SerpApi's in-200 error check runs after every call. `test_follow_up_overview_error_is_a_failure` |
| D7 | BUG | C1-4 F-R5 | empty or cut-off answers counted as successful "not named" samples | fixed: blank text, Anthropic `max_tokens`/`pause_turn`/`refusal`, OpenAI `incomplete` and a non-STOP Gemini `finishReason` are failed samples; Anthropic `max_tokens` raised to 4000. `test_empty_or_cut_off…` (mutation-checked), `test_anthropic_answer_cut_at_max_tokens…` |
| D8 | BUG | C1-5 C2-3 | `GEO_*_MODEL` overrides in `.env` were ignored on direct runs | fixed: `setting()` reads the tool's own names from the environment, else `.env`. `test_model_override_from_env_file_with_inline_comment` |
| D9 | BUG | C1-6 | a saved `config_rev` masked a detector-version bump | fixed: rows always use the freshly computed `config_rev(cfg)`. `test_detector_version_bump_marks_the_trend` |
| D10 | BUG | C1-8 F-R8 | the GEO tests inherited the developer's `SERPAPI_KEY` | fixed: the test environment is an allowlist (PATH, LANG, TMPDIR) |
| D11 | BUG | C2-2 | Bing API errors stayed out of the new "needs attention" list | fixed: listed as `Bing: exit N` (resolves the Rule 7 conflict noted in the plan). `test_bing_api_error_is_listed_not_swallowed` |
| D12 | BUG | C2-4 F-N12 | a bot wall that contains the domain (canonical link, assets) passed as the real homepage | fixed: challenge-page titles/H1s are rejected, and the name/domain must be in the **visible** text. `test_bot_wall_that_mentions_the_domain…`, `test_domain_only_in_markup_is_not_enough` |
| D13 | RISK | F-R1 | a non-dict error body or an answer-file write error crashed the run and lost its rows | fixed: `_error_obj` tolerates any JSON; unexpected per-sample errors and file-write errors are recorded, not raised |
| D14 | RISK | F-R2 | `--set-names --alias X` wiped the main name | fixed: `--alias`/`--legal-name` add; `--name` replaces; documented. `test_set_names_alias_adds_and_name_replaces` |
| D15 | RISK | F-R3 | the fingerprint didn't cover the question set; "confirmed" was stamped at `--set-question` | fixed: `--confirm` records the question set and date; a changed set reads "unconfirmed". `test_new_question_without_confirm_is_flagged` |
| D16 | RISK | F-R4 | one shared 900 s budget starved later engines | fixed: 400 s per engine (`GEO_ENGINE_BUDGET`) |
| D17 | RISK | C1-7 C2-5…9 | provider response contracts are asserted by our own stubs, not proven | partly verified: live answers from Gemini, Anthropic, Perplexity, Google AI Mode and AI Overview were parsed and spot-checked against the saved text (plan status table). **OpenAI stays OPEN**: its account has no credit yet. Perplexity "cited" is documented as "among the search results it used". |
| D18 | RISK | C2-10 | "Knows you moves only when a new model ships" is an unmeasured claim | fixed: reworded as "expect it to move slowly; week-to-week wiggles are usually sampling noise" |
| D19 | NIT | F-N1 N2 N4 N5 N10 | doc counts ("four lines/engines", "Two rules"), docstring, plan S1 text, the dropped "ChatGPT search visibility" trigger | fixed |
| D20 | NIT | F-N3 | SKILL.md said "else 4 if a history write failed" | fixed: "a GSC or Bing history write" |
| D21 | NIT | F-N6 N7 | the trend compared against "no overview" rows; the header counted differently from the run | fixed: those rows are skipped as a comparison base; the header counts each engine's latest run |
| D22 | NIT | F-N8 | `.env` inline `# comments` were kept in values (bash strips them) | fixed: stripped for unquoted values, kept inside quotes; covered by the D8 test |
| D23 | NIT | F-N9 | checklist gaps: `--text-file PATH`, gsc ImportError, missing `token.json`; the "(tested)" check_clean claim | fixed: three tests added; the plan now says "checked by hand" |
| D24 | NIT | F-N11 | `answers/` and `reports/` grow by one entry per run, never pruned | waived for v1 pending owner sign-off: a few KB per site per week; logged as a follow-up |
| D25 | NIT | F-N12 | juliet.space is named in the public plan | left as is: it is the public product the owner cited as the inspiration; flagged to the owner |

## Status at close of round 1

- All BUGs fixed with regression tests (`locally_verified`); the suite has 86 tests, all passing.
- RISK D17 open for OpenAI only (blocked on account credit). NIT D24 awaits the owner's waiver.
- **Round 2 (verification) still to run.** ollama-cloud is out until its weekly limit resets, so
  round 2 can be Codex + fresh-eyes again; the owner may choose to wait for the pair.
