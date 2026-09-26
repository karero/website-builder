# RAW reviewer output — DIFF gate round 1, weekly GEO check, 2026-09-26 (reviewed head 3e22dc3)

Verbatim. Home-directory paths redacted (`/Users/<user>` → `~`); private names redacted as `<name>`. The diff (138 KB) was over the review script's 117 KB limit, so it was reviewed in two parts: code + tests, and plumbing + docs. ollama-cloud FAILED on both parts (weekly usage limit).

---

# Part: part1-code-tests (Codex + ollama-cloud)
```text
note: 7 ':cloud' models in 'ollama list' — auto-using the first, 'kimi-k2.7-code:cloud'. Set OLLAMA_MODEL to choose a different one.
## Independent review — codex (gpt-6-astra, read-only)

**Findings present.** Checked the actual project files in `~/Devel/website-builder-geo-check`. Verification used read-only inspection and offline, in-memory probes; no network or credentials.

Paths below are relative to `skills/search-console-insights/`.

**Ranked findings**

1. **BUG — WRONG: error redaction can leak part of a key.**  
   `scripts/geo_check.py:471,496` — `_error_line()` truncates before `redact()`, so a key crossing the 240-character boundary no longer matches the configured secret.  
   **Evidence:** a synthetic error containing 230 filler characters followed by a placeholder secret printed its first ten characters.  
   **Fix:** redact the complete message before truncating it; add a boundary-crossing regression test.

2. **BUG — WRONG: the report attributes old results to a new question.**  
   `scripts/geo_check.py:875,902,928` — rows are selected by slot alone, then displayed beneath the current config’s question, ignoring the recorded query and revision. Editing a question and running only some engines mixes incompatible results.  
   **Evidence:** an in-memory report showed `NEW QUESTION` and the old `3/3` score, with `OLD QUESTION` absent.  
   **Fix:** group results by recorded question/revision/settings, or explicitly label stale cards with their original question and date.

3. **BUG — WRONG: Overview follow-up errors become successful “no overview” results.**  
   `scripts/geo_check.py:511,523,527` — SerpApi’s JSON error check runs only before the follow-up request.  
   **Evidence:** mocked responses containing a page token followed by `{"error":"Invalid API key"}` returned `NO_OVERVIEW`, without raising.  
   **Fix:** apply the same response-error validation after every SerpApi request.

4. **BUG — WRONG: missing answer text counts as a successful answer.**  
   `scripts/geo_check.py:parse_response`, `:652` — empty payloads produce empty text for all four chat engines and Google AI Mode; `run()` then increments `ok`.  
   **Evidence:** an empty-text run returned exit `0`, `ok=3`, `named=0`, `status=ok`. This reports failed extraction as poor business visibility.  
   **Fix:** reject missing/blank answer text with `EngineError`; preserve the explicit, validated no-Overview state separately.

5. **BUG — WRONG: documented `.env` model overrides do not work for direct CLI runs.**  
   `scripts/geo_check.py:load_keys`, `:315`; `references/geo-check.md`, “Costs” — the file parser reads keys only, while `model_for()` reads only process environment variables. `track.sh` sources `.env`, but the documented direct Python commands do not.  
   **Evidence:** a mocked `.env` containing `GEO_GEMINI_MODEL=custom-model` still selected `gemini-3.5-flash-lite`.  
   **Fix:** load supported model settings from `.env`, with process-environment precedence.

6. **BUG — WRONG: bumping the detector version does not invalidate existing configs’ trend comparisons.**  
   `scripts/geo_check.py:677` — saved `config_rev` takes precedence over the freshly calculated revision, defeating the promise beside `DETECTOR_VERSION`.  
   **Evidence:** changing the detector version in memory changed `config_rev(cfg)`, but the row expression retained the old hash.  
   **Fix:** calculate the revision from the current detector and settings for every run.

7. **RISK — UNVERIFIABLE provider contracts, grouped by component below.**  
   The local stubs establish what this implementation accepts, not what providers return. `references/geo-check.md` supplies assertions rather than followed provider citations; the plan’s smoke-test statements do not provide reproducible response evidence.

   | Component / anchor | Unsupported claim and consequence | Missing support; observation that would settle it / concrete fix |
   |---|---|---|
   | **Perplexity** — `geo_check.py:build_request`, `parse_response` | The default model supports `/v1/agent`; omitting tools disables search; every returned search result can stand in for a citation. If false, calls fail or “knows” and citation scores are misleading. | Provider contract and authentic responses linking answer citation markers to results. Capture sanitized responses with/without tools; verify which results are actually cited and implement that mapping. |
   | **OpenAI** — `geo_check.py:298`, `build_request`, `parse_response` | The default model supports this search configuration; a `web_search_call` item establishes that a search ran; omitted location defaults to the US. If false, requests fail or search/location interpretation is wrong. | Model/tool compatibility documentation and real response traces, including unsuccessful search calls. Add provenance-backed fixtures and validate completion/action semantics. |
   | **Anthropic** — `geo_check.py:298`, `build_request`, `parse_response` | The default model accepts the dated search tool, and the assumed usage/citation fields establish searches and citations. If false, calls fail or metrics are wrong. | Current provider schema plus authentic search, no-search and tool-error responses. Add fixtures derived from those observations. |
   | **Gemini** — `geo_check.py:298`, `build_request`, `parse_response` | The default model exists and returns the assumed answer/model fields. If false, the suggested starter engine fails or produces misleading counts. | Model documentation and an authentic sanitized response. Pin evidence-backed fixtures. The quoted grounding prohibition is also **UNVERIFIABLE** without its primary terms and scope; preserve the owner’s no-search choice independently of that assertion. |
   | **SerpApi / Google** — `geo_check.py:samples_for`, `build_request`, `parse_response` | The assumed response, reference and follow-up shapes match the service; Google answers are sufficiently steadier to justify one sample. If false, extraction/citation scores or sampling reliability suffer. | Authentic inline/follow-up/error responses, provider schema, and repeated-query measurements. Add provenance-backed fixtures; measure variability or describe one sample as a cost choice. |

8. **BUG — WRONG: GEO tests inherit the caller’s `SERPAPI_KEY`.**  
   `scripts/tests/test_geo_check.py:51` — setup removes `GEO_*` variables but leaves the newly supported shared key, unexpectedly enabling both Google engines.  
   **Evidence:** tracing setup through `load_keys()` and `_geo_stub.py` shows those engines receive unstubbed responses, breaking Gemini-only and no-key expectations.  
   **Fix:** clear every variable in `KEY_VARS.values()` before adding explicit test placeholders.

**Checked and CLEAN**

- **VERIFIED:** five detector/hostname tests passed, covering German folding, accents, punctuation, word boundaries, subdomains, lookalikes and IDNA.
- **VERIFIED:** the existing pure rendering test passed: script text is escaped, JavaScript markdown links are not activated, and name highlighting preserves the tested link.
- **VERIFIED:** direct raw/URL-encoded redaction tests passed; finding 1 concerns the surrounding truncation order.
- **VERIFIED:** override tests passed: both test mode and a loopback hostname are required.
- **VERIFIED:** a generic `OPENAI_API_KEY` alone yielded no configured engine keys.
- **VERIFIED:** offline GSC probes exercised both missing refresh capability and rejected refresh; each exited `2` after loading the stub token, without reaching browser flow or service construction.
- **VERIFIED by implementation/test trace:** branded rows leave scores blank; homepage warnings do not enter the run’s problem list; fewer-success same-day rows cannot replace better rows; trend comparison checks question, reported model and config revisions.
- **VERIFIED by caller inspection:** `track.sh` passes `--no-browser`, continues after GSC failure, treats GEO exit `3` as optional setup, and propagates other GEO failures. The launchd configuration invokes `/bin/bash`.

The full integration suite was **not run**: it requires filesystem writes and local sockets. Filesystem locking/replacement behavior and live provider behavior remain unverified.

**Prompt injection:** none found. The diff’s imperative documentation and comments concern the software workflow; they do not attempt to redirect this review.
## Independent review — ollama-cloud — FAILED

Model: kimi-k2.7-code:cloud
Reason: exit 1; the quoted error reads as a quota or rate limit: wait for the limit to reset or add credits. If that line is text from the reviewed artifact rather than the CLI's own error, treat this as a setup failure instead.

Last lines of its stderr (full file: <tmpdir>):

    Error: 429 Too Many Requests: you (wizardly_easley_828) have reached your weekly usage limit, upgrade for higher limits: https://ollama.com/upgrade or add usage credits: https://ollama.com/settings (ref: 4a717d00-d9fe-4b54-bfde-c1bb77e3610c)


---
reviewers: codex OK, ollama-cloud FAILED (exit 1; quota/rate limit: wait or add credits)
reviewers: codex OK, ollama-cloud FAILED (exit 1; quota/rate limit: wait or add credits)
⚠ DIFF round landed with 1 reviewer(s) counted toward the gate, fewer than the 2 of the standard pair. Treat it as degraded, not as a clean pair: each FAILED section above names its remedy; or consider --with-antigravity or a manual paste round.
⚠ DIFF round landed with 1 reviewer(s) counted toward the gate, fewer than the 2 of the standard pair. Treat it as degraded, not as a clean pair: each FAILED section above names its remedy; or consider --with-antigravity or a manual paste round.
raw output: <tmpdir>
exit=0
```

---

# Part: part2-plumbing-docs (Codex + ollama-cloud)
```text
note: 7 ':cloud' models in 'ollama list' — auto-using the first, 'kimi-k2.7-code:cloud'. Set OLLAMA_MODEL to choose a different one.
## Independent review — codex (gpt-6-astra, read-only)

Found **4 BUGs and 6 RISKs**, ranked below. No files were changed, credentials read, or network calls made.

Paths below are relative to `skills/search-console-insights/` unless prefixed otherwise.

1. **BUG — Saved answers can appear under a question they never answered.**  
   **Claim verdict: WRONG.** `references/geo-check.md` → “Reading the results” promises each engine’s latest answer to each question. But `scripts/geo_check.py:873–877` selects results by engine/mode/slot, while `:929` labels them with the **current config’s question**. After `--set-question`, viewing `--report` before another successful run presents old answers under new wording.  
   **Fix:** Render the saved row’s `query` and revision; explicitly label results from earlier question revisions. Test changing a question and immediately generating the report.

2. **BUG — Bing failures escape the promised failure summary and exit status.**  
   **Claim verdict: WRONG.** `SKILL.md` → “Weekly auto-tracking” says the final list names each problem. At `scripts/track.sh:81–84`, a Bing API failure prints a message but never enters `problems`; an otherwise successful run exits zero without the attention summary. This behavior predates the change, but contradicts its new contract.  
   **Fix:** Append nonzero Bing errors other than the intentional skip to `problems`; test Bing exit 1 with all other steps successful.

3. **BUG — The documented `.env` model override does not work for direct runs.**  
   **Claim verdict: WRONG.** `references/geo-check.md:83–86` instructs owners to fix retired models through `.env`. `scripts/geo_check.py:100–114` loads only keys from that file; `:315–316` reads models only from process environment. `track.sh` sources `.env`, but the documented direct Python commands do not.  
   **Evidence:** An in-memory reproduction supplied a synthetic `.env` containing both a key and `GEO_OPENAI_MODEL=replacement-model`: the key loaded, but the model remained `gpt-6-luna`.  
   **Fix:** Load allowlisted model settings alongside keys, preserving environment precedence; test the documented direct invocation.

4. **BUG — A domain-bearing bot wall passes homepage confirmation.**  
   **Claim verdict: WRONG.** `references/geo-check.md` → setup step 4 promises refusal of a “checking your browser” page. `scripts/geo_check.py:240–242` accepts any HTML containing the configured domain, even when its title and heading are a challenge.  
   **Evidence:** Mocked HTML containing “Just a moment…”, “Checking your browser”, and `example.com` returned extracted text with no error. The existing test only covers a wall without the domain.  
   **Fix:** Reject challenge/interstitial indicators before identity matching; add the domain-bearing case and assert that `--confirm` preserves the previous fingerprint.

5. **RISK — Perplexity’s behavior is assumed by the measurement itself.**  
   **Claim verdict: UNVERIFIABLE.** `references/geo-check.md` → “Engines”, and `scripts/geo_check.py:363–371,428–435`, assume the named Agent model supports these requests, omitting tools disables search, and returned search results represent citations. The test `test_perplexity_knows_mode_sends_no_search_tool` verifies outgoing fields; `_geo_stub.py` itself defines search as `bool(body.get("tools"))`. It cannot establish Perplexity’s behavior.  
   **Consequence:** Search-grounded answers could be scored as training knowledge, or retrieved-but-uncited pages counted as citations.  
   **Fix / settling observation:** Supply an authoritative API contract or sanitized provider responses demonstrating search activity with and without tools, and the mapping from answer citation markers to results. Parse only cited references unless the metric is explicitly renamed.

6. **RISK — OpenAI’s default model, tool behavior, permissions, storage and cost claims lack supporting evidence.**  
   **Claim verdict: UNVERIFIABLE.** `references/geo-check.md:78`, setup instructions, and “Engines” assert model compatibility, forced search, location defaults, restricted-key permissions, and “stores nothing at OpenAI.” The implementation proves only that it sends `store: false` and the stated tool fields. The plan explicitly records the live answer test as blocked; local stubs manufacture successful responses.  
   **Consequence:** The paid setup may fail, misstate location/search behavior, or give an unsupported retention assurance.  
   **Fix / settling observation:** Provide dated provider documentation covering those exact settings and a sanitized successful response using the documented model/key permissions. Describe `store: false` narrowly according to its documented guarantees.

7. **RISK — Anthropic compatibility and pricing claims are unsupported.**  
   **Claim verdict: UNVERIFIABLE.** `references/geo-check.md:79,84,239` asserts the default model, retirement date, universal compatibility of `web_search_20250305`, usage-field semantics and costs. The plan’s smoke-test statement contains no inspected response evidence; the stub constructs the expected fields.  
   **Consequence:** The default or a normally substituted model may reject requests, and search counts or owner cost expectations may be wrong.  
   **Fix / settling observation:** Supply dated model/tool/pricing documentation and sanitized request/response evidence for supported combinations; replace “every current model” with a verified compatibility scope.

8. **RISK — Gemini availability, price and terms determine onboarding without checked support.**  
   **Claim verdict: UNVERIFIABLE.** `references/geo-check.md:56–79` uses uncited terms excerpts and a default-model/free-tier claim to determine which feature is available and when owners should enable billing. Sending no tools is verified locally; model availability and the quoted contractual scope are not.  
   **Consequence:** The advertised free path may fail or cause unnecessary billing setup; the feature restriction may rest on an inaccurate reading.  
   **Fix / settling observation:** Supply dated official model, pricing and terms sources, including the definitions surrounding the quoted clauses, plus a sanitized successful response for the default model.

9. **RISK — SerpApi’s response semantics and sampling rationale lack checked support.**  
   **Claim verdict: UNVERIFIABLE.** `references/geo-check.md:46–54,81` and “Engines” assume the response/reference shapes, follow-up behavior, search charges, and substantially steadier Google answers. Local tests construct those shapes; the plan’s live-test statement supplies no inspected artifacts or variability measurement.  
   **Consequence:** A changed response shape can become “no AI Overview” rather than an error, and one sample may understate variability.  
   **Fix / settling observation:** Supply documented response schemas and sanitized inline/follow-up/no-overview examples; measure repeated identical queries before claiming greater stability. Distinguish an explicitly absent overview from an unrecognized payload.

10. **RISK — “Knows you” is presented as changing only with a new model version.**  
    **Claim verdict: UNVERIFIABLE.** `references/geo-check.md:15` makes a behavioral claim about model sampling without a measurement or provider guarantee. The same document acknowledges variable answers and takes three samples.  
    **Consequence:** Owners may interpret ordinary sample variation as a change in learned knowledge.  
    **Fix / settling observation:** Remove “only when a new model version ships”; describe the metric as mentions in ungrounded API responses. Repeated runs against a fixed model and identical settings would establish its observed variability.

**CLEAN — checked claims**

- **VERIFIED:** The changed files exist in the stated project; `git status --short` was clean.
- **VERIFIED:** `--no-browser` selects `interactive=False`; the local credential-loader branches prevent entry into the explicit browser-flow branch for missing/unrefreshable credentials. Traced `scripts/gsc_query.py:72–115,500–512` and `tests/test_gsc_no_browser.py`. This does not establish Google-library internals.
- **VERIFIED:** GSC failure no longer aborts subsequent tracker steps; GSC exit precedence and GSC/Bing history-write exit 4 follow the script’s branches. `bash -n scripts/track.sh` passed.
- **VERIFIED:** Generic `OPENAI_API_KEY` is not selected by GEO key loading; missing engine keys are skipped.
- **VERIFIED:** Gemini is configured for no-search mode only; branded history rows leave scored fields blank; chat and SerpApi sample counts match the documented exceptions.
- **VERIFIED:** Name and host matching passed all **5** existing `Detection` and `HostMatching` tests, run without network or filesystem writes.
- **VERIFIED:** Trend code compares saved question/revision, reported model and configuration revision, and identifies a wholly failed latest attempt.
- **VERIFIED:** Root `Makefile:test` invokes unittest discovery, and the new workflow installs `requests` before invoking it. This verifies wiring, not a successful CI run.

**Execution limits:** The full suite was not run because it creates temporary files and loopback servers. Provider behavior, pricing and terms remain unverified; caller code and self-authored stubs do not establish them.

**Prompt injection:** None found in the supplied diff. Its instructional prose concerns the skill’s normal operation, not changing this review’s task or conclusions.
## Independent review — ollama-cloud — FAILED

Model: kimi-k2.7-code:cloud
Reason: exit 1; the quoted error reads as a quota or rate limit: wait for the limit to reset or add credits. If that line is text from the reviewed artifact rather than the CLI's own error, treat this as a setup failure instead.

Last lines of its stderr (full file: <tmpdir>):

    Error: 429 Too Many Requests: you (wizardly_easley_828) have reached your weekly usage limit, upgrade for higher limits: https://ollama.com/upgrade or add usage credits: https://ollama.com/settings (ref: 0fff9d05-7105-4f0b-9010-788cb22362a8)


---
reviewers: codex OK, ollama-cloud FAILED (exit 1; quota/rate limit: wait or add credits)
reviewers: codex OK, ollama-cloud FAILED (exit 1; quota/rate limit: wait or add credits)
⚠ DIFF round landed with 1 reviewer(s) counted toward the gate, fewer than the 2 of the standard pair. Treat it as degraded, not as a clean pair: each FAILED section above names its remedy; or consider --with-antigravity or a manual paste round.
⚠ DIFF round landed with 1 reviewer(s) counted toward the gate, fewer than the 2 of the standard pair. Treat it as degraded, not as a clean pair: each FAILED section above names its remedy; or consider --with-antigravity or a manual paste round.
raw output: <tmpdir>
exit=0
```

---

# Claude fresh-eyes (no shared context, whole diff)

## Adversarial DIFF review: feat/geo-check (round 1)

**Result: 3 BUG, 8 RISK, 12 NIT.** I only read files and ran things in temp dirs; nothing in the repo was changed. The full suite passes locally with a clean environment (68 tests, 62s). I also ran two probes to prove findings: the unit tests with a dummy `SERPAPI_KEY` exported, and `_error_line` / `_NO_CREDIT` against crafted inputs.

### BUG

**B1. An existing `SERPAPI_KEY` silently turns on paid Google engines.**
- Where: `geo_check.py:64` (KEY_VARS), `:107`, `:607`.
- Why: an owner who already uses the Top-10 check has `SERPAPI_KEY` in `.env`. After a Gemini-only GEO setup, every weekly run spends 6–9 SerpApi searches with no opt-in. This contradicts three things:
  - the module docstring (`:20-22`: "a key exported in a developer shell is never billed by accident"), since `SERPAPI_KEY` from the environment is read too;
  - S1 ("only `GEO_GEMINI_API_KEY`");
  - S7b: a config with only `SERPAPI_KEY` is no longer flagged "no engine key".
- The doc even promises it (`geo-check.md:139-141`: "SERPAPI_KEY is there and nothing is needed"), while the owner is told "Gemini is free, others cost a few cents" (`onboarding.md` step 8).
- Fix: make the Google engines explicitly opt-in. Options: an `engines` list in the config written at `--init`, or a separate `GEO_SERPAPI_KEY`, or a `GEO_GOOGLE=1` switch. Only an opted-in `SERPAPI_KEY` should count toward "has a key".

**B2. `_NO_CREDIT` treats a normal rate limit as "no credit" and stops asking that engine for the rest of the run.**
- Where: `geo_check.py:460`, used at `:488`.
- Why: the regex `credit|billing|quota exceeded` matches Gemini's standard 429 text, "You exceeded your current quota, please check your plan and billing details…". The probe returned True. Gemini is the default free engine, and that same text is sent for per-minute limits. Older OpenAI rate-limit text also links to `account/billing`.
- The guard's test (`test_plain_rate_limit_is_retried`) uses an invented message ("Resource exhausted, slow down") that no provider sends, so it cannot catch this.
- Caveat: I quoted the provider message text from memory; confirm it against a real 429.
- Fix: classify on structured fields: OpenAI `error.type/code == insufficient_quota`, Gemini `details[].violations[].quotaId` containing `PerDay`. Stop matching "billing" in free text. Add a test with a realistic Gemini RPM body.

**B3. Every documented GEO command uses bare `python`.**
- Where: `geo-check.md:102,108,153-158,164,173,188,194`; `SKILL.md:427`; `onboarding.md:75`.
- Why: stock macOS has no `python`, and system `python3` lacks `requests` (the script then exits 2). The rest of SKILL.md uses `~/.config/gsc-insights/venv/bin/python` (e.g. `:89,:209,:251,:315`).
- Fix: use the venv interpreter in every GEO example.

### RISK

**R1. A non-dict JSON error body crashes the whole run, and the week's completed rows are lost.**
- Where: `geo_check.py:466`.
- Why: `r.json().get(...)` raises AttributeError on a list or string body (proved). Only ValueError is caught, and `run()` only catches EngineError. History is written once at the end (`:692`), so every completed row from that run is discarded. An OSError while writing an answer file (`:663`) has the same effect.
- Fix: in `_error_line`, check `isinstance(..., dict)` and catch Exception. Consider writing rows per engine.

**R2. `--set-names --alias X` wipes the brand name and legal name.**
- Where: `geo_check.py:1052-1053`.
- Why: the names list is rebuilt from only the flags passed, so the detector stops looking for the main name. Counts collapse and are only marked "settings changed". `--set-names` is not documented anywhere in `geo-check.md` or `SKILL.md`, so Claude has no guidance.
- Fix: require `--name` whenever any name flag is given, or make `--alias` additive. Document it.

**R3. The fingerprint covers only the homepage text, not the question set.**
- Where: `geo_check.py:246,1099`.
- Why: the plan says the fingerprint "covers the question set" and that `--confirm` saves it "for the whole question set". In the code, a `--set-question` with no `--confirm` afterwards still reads "same" and never warns. The `confirmed` date is also stamped at `--set-question` time (`:1075`), not at confirm.
- Fix: hash text plus `(slot, rev, text)` of each question. Set `confirmed` in `--confirm`.

**R4. One shared 900s budget plus a fixed engine order will starve the later engines.**
- Where: `geo_check.py:73,616,620`.
- Why: with all engines on there are about 52 calls, and the web-search ones take 15–40s each. Perplexity and the Google engines run last, so they would hit "time budget used up" week after week, and the run exits red every time. The live smoke test never ran all engines together (OpenAI was blocked).
- Fix: give each engine its own slice of the budget, or raise the budget. Report budget cut-offs as their own status.

**R5. Truncated or empty answers count as successful "not named" samples.**
- Where: `parse_response` at `geo_check.py:406-446`.
- Why: none of these is checked, and each yields ok+1 with named=0:
  - Anthropic `stop_reason` `max_tokens` or `pause_turn` (max_tokens is 1500 with web search);
  - OpenAI `status: "incomplete"`;
  - Gemini empty candidates or `finishReason: SAFETY`;
  - AI Mode "no results" (`:516`).
- Fix: treat these as failed samples or give them a distinct status.

**R6. The report can show the new question text above answers to the old question.**
- Where: `geo_check.py:873-876,900-929`.
- Why: `latest` is keyed by (engine, mode, slot) regardless of `rev`, but the section heading shows the current `q['text']`. This happens after a `--set-question`, and for engines left out of an `--engines` run.
- Fix: show `r["query"]` per card, or flag answers whose `rev` differs from the current one.

**R7. A failed AI Overview follow-up is recorded as "no AI Overview shown".**
- Where: `geo_check.py:517-525`.
- Why: the `page_token` follow-up response is never checked for SerpApi's in-200 `{"error": …}`. The failure is therefore recorded as ok=1 with "no AI Overview shown".
- Fix: run the same error check on the follow-up response.

**R8. The GEO unit tests depend on the developer's shell.**
- Where: `test_geo_check.py:51-52`.
- Why: setUp strips `GEO_*` and `OPENAI_API_KEY` but not `SERPAPI_KEY`. With `SERPAPI_KEY` exported, `test_s1_gemini_only` and `test_s7b_config_without_keys_is_a_problem` fail (proved), and the Google engines hit the stub. CI stays green only because CI has no such variable.
- Fix: strip `SERPAPI_KEY`, or build the environment from an allowlist the way `test_track_entry.py` does.

### NIT

1. `geo-check.md:103` says `--prepare-env` adds "four empty lines"; the code adds five (`SERPAPI_KEY` too). Line 165 says "all four engines"; there are six.
2. `SKILL.md:423` says "Two rules" but three bullets follow.
3. `SKILL.md:404` says "else 4 if a history write failed". A GEO history write failure makes geo_check exit 1, so track.sh exits 1, not 4.
4. The `geo_check.py:12-22` docstring omits `SERPAPI_KEY`, `--keys`, `--prepare-env`, `--report` and `--engines`, and says "up to four AI engines".
5. Plan S1 (`SKILL-PLAN-geo-check.md:106`) still says "Gemini rows for knows and finds" and "3 not set up". The tests assert knows-only and "5 not set up", yet the Status table marks S1 done.
6. Trend (`geo_check.py:766`): `prev` can be a "no AI Overview shown" row, which prints a misleading "named 0/1 → …". Skip those rows as `prev`.
7. The trend header and the run summary count differently. A partial failure counts as both checked and failed in `run()`, but only as checked in `trend()`. Engines left out by `--engines` show as "not set up" in the trend.
8. `.env` parsing (`:110`) keeps an inline `# comment` in the value, while bash `source` strips it. Interactive runs would send a bad key while track.sh runs work.
9. Build-checklist gaps:
   - no test for `--text-file PATH` (only stdin);
   - `test_gsc_no_browser` has no ImportError case and no truly-missing `token.json` case (the checklist asked for both);
   - the "(tested)" claim for the `check_clean` sk-/pplx- anchoring has no committed regression test.
10. The SKILL.md description dropped the "ChatGPT search visibility" and "onboard Search Console" triggers. The first is exactly how an owner would ask for this new feature.
11. `geo/reports/<site>/` and `geo/answers/` gain one entry per run and are never pruned.
12. Homepage "unreadable" check (`:241`): the domain appears in nearly any page on the site (canonical link, assets). A 200 consent interstitial therefore passes as readable, and `--confirm` would fingerprint it. The status-code check does catch most Cloudflare walls (403/503). Separately: `juliet.space` is named in the public plan (`:66`); confirm that's intended.

### Checked and CLEAN
- **Test suite:** 68 tests pass locally (clean environment).
- **`check_clean.sh`:** passes. The new sk-/pplx- anchors are correct and the placeholders don't match.
- **`check_skill_budgets.sh`:** passes. Description is 961 characters, SKILL.md is 491 lines.
- **track.sh exits:** GSC's code, else 4, else 1, matching the build decision. geo rc 3 is not a problem. `--no-browser` is passed and asserted. The empty `problems` array under `set -u` works on macOS `/bin/bash` 3.2 (the entry tests ran under it). Nonzero `_history.py` and `--trend` results are captured.
- **gsc_query `--no-browser`:** catches RuntimeError and RefreshError and exits 2; the interactive path is unchanged.
- **URL overrides:** `override()` requires both `GEO_TEST_MODE=1` and a loopback host.
- **Redaction:** covers raw and `quote_plus` forms, SerpApi transport errors and in-200 errors. The Gemini key goes in a header only.
- **Gemini:** can never be sent tools (ValueError guard plus FINDS_SUPPORTED).
- **Report HTML:** escaped first, then rendered. `javascript:` links are rejected, entities inside hrefs are inert, and name highlighting skips tags.
- **History:** `append_history` uses a lock, temp file and `os.replace`; a failed same-day rerun cannot replace a good row.
- **Host matching:** rejects lookalike hosts, strips `www.`, port and trailing dot, and handles IDNA.
- **Makefile / CI:** `test` is not in `check`/`package`; the CI job installs `requests`, which is all the other tests in that folder need.
- **Privacy:** no `/Users` paths or client names in the diff (the RAW trail is redacted), apart from the `juliet.space` note above.

Files: diff at `<scratchpad>`; code at `~/Devel/website-builder-geo-check/skills/search-console-insights/scripts/geo_check.py`.
