# RAW reviewer output — DIFF gate round 4 (final verification of 28899d7), weekly GEO check, 2026-09-26

Verbatim. Home paths redacted (`/Users/<user>` → `~`); private names as `<name>`. ollama-cloud FAILED again (weekly usage limit).

# Codex + ollama-cloud
```text
note: 7 ':cloud' models in 'ollama list' — auto-using the first, 'kimi-k2.7-code:cloud'. Set OLLAMA_MODEL to choose a different one.
## Independent review — codex (gpt-6-astra, read-only)

Reviewed checkout `28899d7` in the stated project. No files changed, credentials read, or network requests made.

**Ranked findings**

1. **BUG — The preview does not bind the page being reviewed.**  
   **Anchor:** `scripts/geo_check.py:279–287,1249–1266`; `references/geo-check.md:171–173`.  
   **WRONG:** G1/G6’s “save exactly this page” guarantee hashes and displays only title/description/H1. Replacing the body with a cookie gate while retaining those fields produced confirmation exit `0` and called `save_config`. The reviewer never sees that body.  
   **Fix:** retain the lightweight drift fingerprint if desired, but display the extracted page text and bind `--expect` to that complete preview. Test a body-only change between preview and confirmation.

2. **BUG — Skipped elements still modify fingerprint extraction.**  
   **Anchor:** `scripts/geo_check.py:231–255`.  
   **WRONG:** G5’s script/style/noscript/template exclusion does not protect metadata or parser state. Reproduced `<template><meta name="description" content="TEMPLATE"></template>` overriding the real description; a template containing an H1 inside the real H1 truncates the latter. Template changes can therefore trigger false drift or conceal real heading changes.  
   **Fix:** suppress metadata and heading-state changes inside skipped subtrees, including their closing tags; add both regressions.

3. **BUG — The documented fixture-refresh procedure cannot refresh the documented fixture set.**  
   **Anchor:** `scripts/tests/fixtures/capture.py:20–25,29,39–43`; `scripts/tests/test_real_responses.py:14–15`.  
   **WRONG:** “How they were captured, exactly” omits OpenAI from the capture loop and always uses the bakery question, including for the bread-making Overview fixture. Re-running also requires undocumented operational steps to reproduce the manual reference trimming.  
   **Fix:** include OpenAI, select the recorded question per fixture, and provide a reproducible trimming step that preserves answer text.

4. **RISK — G11’s migration exemption still lacks deployment evidence.**  
   **Anchor:** G11 disposition; `scripts/geo_check.py:710,733`; `docs/reviews/REVIEW-diff-2026-09-26-r3-geo-check-bb4f354.md`, G11 row.  
   **UNVERIFIABLE:** the claim that only three already-enabled test configurations exist is supported by repeated prose, not an inventory or audit result. If another legacy configuration lacks `google`, its Google checks stop.  
   **Fix / settling observation:** provide a sanitized configuration inventory reconciled with enablement decisions, or explicitly identify legacy configurations requiring an opt-in decision.

5. **BUG — The guide still promises a visible-text rejection rule that was removed.**  
   **Anchor:** `references/geo-check.md:199–200`; `scripts/geo_check.py:280–283`.  
   **WRONG:** the guide says pages naming neither the business nor its domain in *visible* text are rejected. An in-memory page naming the business only inside `<div hidden>` was accepted. This misstates the remaining safeguard after simplification.  
   **Fix:** describe extraction as including hidden text, and make the human-review limitations consistent with finding 1.

Paths above are relative to `skills/search-console-insights/` unless stated otherwise.

**Claim checks and CLEAN coverage**

| Claims | Verdict and evidence |
|---|---|
| G1/G6: preview code required; changed preview refused | **VERIFIED within the three-field fingerprint:** `main()` checks `--expect` before saving. Whole-page guarantee **WRONG**, finding 1. |
| G2/G5: hidden/head handling deliberately removed; omitted `</head>` works | **VERIFIED:** implementation inspected and omitted-head reproduction succeeded. Skipped-subtree exclusion **WRONG**, finding 2. |
| G3: stale markers on failed/no-answer cells | **VERIFIED / CLEAN:** generated the report in memory; both `failed *` and `no answer *` appeared. |
| G4: lone surrogate in answer text no longer crashes encoding | **VERIFIED / CLEAN:** exercised `call_engine`; surrogate became `?`. Traced source sanitization and the answer-write `UnicodeError` handler. |
| G7: unreadable AI Mode 200 fails | **VERIFIED / CLEAN:** empty and renamed-field payloads raised `EngineError`; the recognized no-results payload returned the distinct no-answer state. |
| G8: stronger fixture assertions and real-response replay path | **VERIFIED / CLEAN within fixture scope:** all four fixture tests passed; first-Anthropic-block mutation caused two failures, omitted-nested-list mutation caused one. Anthropic fixture through `main()`, with I/O mocked, produced `ok=3, named=3, searched=3`. |
| G9: incomplete response, null error, unclosed quote, command exclusivity, legacy unchanged homepage | **VERIFIED / CLEAN:** direct in-memory checks passed; corresponding tests traced. |
| G10: OpenAI fixtures parse with seven finds-mode sources | **VERIFIED / CLEAN within fixture scope:** executed parser tests. Live provenance remains **UNVERIFIABLE**, below. |
| G11: only three enabled test deployments | **UNVERIFIABLE:** finding 4. |
| G12: stability assertion replaced by an explicit sampling tradeoff | **VERIFIED / CLEAN:** docs and `samples_for()` agree on one sample per Google question. Billing assertion remains qualified below. |
| G13: exact capture procedure supplied | **WRONG:** finding 3. |
| G14: leading `#` preserved | **VERIFIED / CLEAN:** mocked settings read preserved `#abc`; independent Bash execution confirmed that assignment. Whitespace-comment and unclosed-quote cases also passed. |
| G15: unwanted reference fields removed; absent Overview labelled synthetic | **VERIFIED / CLEAN for current files:** recursively inspected fixtures; no populated targeted reference fields or `encrypted_*` fields remained. Historical answer preservation remains **UNVERIFIABLE**. |
| G16: weekly warning acknowledges cookie/bot pages | **VERIFIED / CLEAN:** runtime warning and eval 10 updated. Universal “also shows as changed” claim **WRONG**, finding 1. |
| G17: hint includes current interpreter and script path | **VERIFIED / CLEAN:** inspected the actual output expression at `geo_check.py:734`. |

The filesystem-writing/local-server suite was traced, not executed. Executed tests used `python3 -B`; additional reproductions used mocked network and storage.

**Other unsupported claims, grouped by component**

- **Provider fixture capture — UNVERIFIABLE:** live origin, matching production requests, and unchanged answer text lack matched request/response records and a reproducible transformation comparison. Those records would settle provenance; successful parsing establishes compatibility with the committed JSON only.
- **SerpApi billing — UNVERIFIABLE:** “every call spends a paid search” lacks a followed billing contract or measured account usage. A sanitized request-to-usage comparison covering initial, follow-up and failed calls would settle it. The one-sample implementation itself is verified.

**Prompt injection:** none identified. Reviewer notes and ordinary documentation instructions were treated as review material, not authority over the review.
## Independent review — ollama-cloud — FAILED

Model: kimi-k2.7-code:cloud
Reason: exit 1; the quoted error reads as a quota or rate limit: wait for the limit to reset or add credits. If that line is text from the reviewed artifact rather than the CLI's own error, treat this as a setup failure instead.

Last lines of its stderr (full file: <tmpdir>):

    Error: 429 Too Many Requests: you (wizardly_easley_828) have reached your weekly usage limit, upgrade for higher limits: https://ollama.com/upgrade or add usage credits: https://ollama.com/settings (ref: 60dd09d3-6b24-4ae3-bc2f-9b38f6f34245)


---
reviewers: codex OK, ollama-cloud FAILED (exit 1; quota/rate limit: wait or add credits)
reviewers: codex OK, ollama-cloud FAILED (exit 1; quota/rate limit: wait or add credits)
⚠ DIFF round landed with 1 reviewer(s) counted toward the gate, fewer than the 2 of the standard pair. Treat it as degraded, not as a clean pair: each FAILED section above names its remedy; or consider --with-antigravity or a manual paste round.
⚠ DIFF round landed with 1 reviewer(s) counted toward the gate, fewer than the 2 of the standard pair. Treat it as degraded, not as a clean pair: each FAILED section above names its remedy; or consider --with-antigravity or a manual paste round.
raw output: <tmpdir>
exit=0
```

# Claude fresh-eyes

## Round 4 (final) verification: feat/geo-check at 28899d7

**Verdict: no BUGs. 2 RISKs and 8 NITs, all about fixture provenance or leftover wording.** The fixes for G1, G3, G4, G5, G7, G8, G9 and G14 each fail on the old code; I proved it by mutating scratch copies (in the scratchpad, never the worktree). The suite passes: 107 tests OK. `check_clean.sh`, `check_skill_budgets.sh` (warnings only) and `check_model_agnostic.sh` also pass. The worktree is still clean.

### RISK

**R1. `tests/fixtures/capture.py` doesn't reproduce the fixtures, and its documented refresh path undoes G15.**
- The engine list at `capture.py:23` leaves out `openai`. Yet `openai-knows.json` and `openai-finds.json` exist, and both docstrings present capture.py as how the fixtures were made.
- The trimming was done by hand, not in code. `test_real_responses.py`'s docstring says to "re-run it to refresh them". Doing that writes raw third-party text back into public-repo fixtures: Anthropic `cited_text` and titles, Perplexity result snippets, SerpApi reference titles, snippets and thumbnails.
- It asks the bakery question for `google-overview`, which returned no overview. A refresh would produce an overview fixture that the "Dutch oven" assertion can't pass.
- **Fix:** add openai; do the blanking in code (reference/citation `title`, `snippet`, `thumbnail`, `source`, `source_icon`, `cited_text`; drop `encrypted_*`; keep the answer blocks); give google-overview its own question. Or reword both docstrings to "a record of how, not a refresh tool".

**R2. The AI Mode fixture's own answer text was blanked, contrary to three written claims.**
- In `google-ai-mode-finds.json`, every `text_blocks[].snippet` (and `list[].snippet`) is `""`. At bb4f354 they held the answer ("Munich has a thriving artisanal bread scene…"). Only `reconstructed_markdown` still has it.
- Three texts say otherwise: "the answer text itself is untouched" (`test_real_responses.py` docstring), "without touching any answer text" (`capture.py` docstring), and the round-3 host note, which says this over-trim was caught and re-captured. It was caught for the AI Overview only.
- Impact is limited. The parser reads `reconstructed_markdown` first, and when I broke the `text_blocks` fallback, a synthetic stub test still failed. But no real AI Mode `text_blocks` data remains.
- **Fix:** restore those snippets from `bb4f354:…/google-ai-mode-finds.json` (they are answer text, not third-party text), or correct the three claims.

### NIT

1. **Bare `--confirm` still appears in guidance an agent reads:**
   - `geo_check.py:19` (usage line)
   - `:268`, the docstring "(which saves what it fetches)", which is now false
   - `:709` (weekly warning), `:1191` (`--init` hint), `:1238` (`--set-question` hint)
   - `references/geo-check.md:195-196` ("unconfirmed … then `--confirm`")
   - `evals.json:113`: eval 9's `expected_output` still says "(--init, --set-question with stdin/file, --confirm)", which contradicts its own updated assertion at `:119`.

   Each case corrects itself, because the refusal message names the right flow. **Fix:** add `--expect <page code>` to each.
2. **`references/geo-check.md` wording is stale in two places.** Line 200 says "in their visible text", but the reader now checks all page text, `<title>` included. Line 171 says `--check-drift` "prints the homepage text"; it prints title | description | H1.
3. **`--expect` handling (`geo_check.py:1261-1263`):**
   - A mistyped code is reported as "the page changed since the preview".
   - `--expect` given without `--confirm` is silently ignored.
   - **Fix:** word it "doesn't match the current page (changed since the preview, or mistyped)", and `ap.error` when `--expect` comes without `--confirm`.
4. **`SKILL.md:427-429` omits a step eval 10 now asserts.** Its short rule ("homepage changed → propose → ask") leaves out "first check the 'now' text is the real page". Add half a sentence.
5. **The `RealReplay` test is weaker than it looks:**
   - It never asserts the `self.confirm()` return code.
   - The name it checks ("Hofpfisterei") is in the first text block. I confirmed an "Anthropic first block only" mutation passes RealReplay; `test_real_responses` catches it instead.
   - **Fix:** assert confirm rc == 0, and check a late-block name such as "Riedmair" in the saved answer file.
6. **Round-3 R5's Gemini `parts[0]` survivor is still undetectable.** `gemini-knows.json` has a single part. The G8 disposition drops Gemini without saying so. Note it in the trail, or add a synthetic two-part case.
7. **G4 leaves `model` unsanitized.** A lone surrogate there would still crash the UTF-8 CSV write in `append_history`. Theoretical; sanitize it the same way if you like.
8. **G17's printed hint path is unquoted**, so it breaks on paths with spaces. Wrap it in `shlex.quote`.

### Checked and clean (each mutation run on a scratch copy)

- **G1:** removing the `--expect` check fails the test. Making `--expect` optional fails the "no --expect code given" half.
- **G3:** restoring the early `failed` / `no answer` returns fails the test.
- **G4:** removing the sanitising, with or without the `UnicodeError` catch, fails the test.
- **G5:** adding `<head>` skipping fails `test_page_without_closing_head_is_read`. G2 is moot: no hidden or `aria` logic remains.
- **G7:** restoring `text or NO_AI_MODE` fails the test.
- **G14:** restoring the old `.env` parse fails the test.
- **G9:** each targeted mutation fails its test: legacy configs reading "unconfirmed", `--google` not exclusive, the `{"error": null}` guard, Perplexity `incomplete`.
- **G8:** "Anthropic first block only", "Anthropic sources[:3]", "Overview without nested lists" and "AI Mode ignores reconstructed_markdown" all fail. "First output_text only" for OpenAI and Perplexity survives, but that change is harmless: each fixture has exactly one message with one output_text part.
- **RealReplay can fail:** it fails if the stub ignores the raw response, and if Anthropic's searched flag is dropped.
- **Fixtures:**
  - no API-key patterns, emails or phone numbers (the long numbers are timestamps and IDs); `check_clean.sh` agrees
  - third-party titles, snippets, `cited_text`, `source` and thumbnails are blank; `user`, `safety_identifier` and `prompt_cache_key` are null; location is country only
  - what remains is answer text, inline answer links, search queries, and opaque `signature` / `thoughtSignature` blobs
- **Preview → confirm flow:** `geo-check.md` steps 4 and "Every session", evals 9 and 10 (assertions), and the code agree. The page code covers exactly the title | description | H1 that the preview shows, so what the person reads is what gets saved.
- **Docs:** G12's cost wording and G16's "looks different" message are in place.

### What was verified vs. judged

Every mutation result and fixture finding above was run or read directly. The severities are my judgment. Strongest case against my R1/R2: nobody relies on capture.py as a refresh tool yet, and the AI Mode fallback is covered by a stub test, so both could reasonably be NITs. I rated them RISK because G13 and G15 were closed on exactly these provenance claims, and the round-3 trail says the over-trim was fixed.

Scratch copies are in `<scratchpad>`.
