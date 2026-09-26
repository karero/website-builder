# RAW reviewer output — DIFF gate round 2 (verification of 3b2239c), weekly GEO check, 2026-09-26

Verbatim. Home paths redacted (`/Users/<user>` → `~`); private names as `<name>`. ollama-cloud FAILED again (weekly usage limit).

# Codex + ollama-cloud
```text
note: 7 ':cloud' models in 'ollama list' — auto-using the first, 'kimi-k2.7-code:cloud'. Set OLLAMA_MODEL to choose a different one.
## Independent review — codex (gpt-6-astra, read-only)

**Findings remain: 3 BUGs and 2 RISK groups.** Reviewed the actual checkout at `3b2239c`, including callers, tests, configuration, and round-one reasoning. No network, credentials, or file writes were used.

Paths below are relative to `skills/search-console-insights/`.

**Ranked findings**

1. **BUG — WRONG: D13’s exception containment still permits losing the run’s rows.**  
   `scripts/geo_check.py:734–742`, `run()` — response processing happens outside the new exception handler; malformed citation values can crash before `append_history()`.  
   **Reproduced:** a synthetic OpenAI response with an object-valued citation URL passed `parse_response()`, then raised `AttributeError` in `norm_host()`; history received zero calls.  
   **Fix:** validate model/source types inside the adapter, and contain the entire sample-processing operation. Increment successful counters only after validation. Test that malformed samples preserve earlier rows and allow later engines to run.

2. **BUG — WRONG: D12’s “visible text” check still accepts consent pages using unrelated identity text.**  
   `scripts/geo_check.py:237`, `_Extract.handle_data()`; `:267`, `read_homepage()` — the identity buffer includes head text and text inside hidden subtrees.  
   **Reproduced:** both a consent page with `<title>Example Bakery</title>` and one with `<div hidden>Example Bakery</div>` returned a valid fingerprint despite the body heading being “We value your privacy.”  
   **Fix:** restrict identity extraction to eligible body content, exclude hidden subtrees, and reject consent/interstitial pages independently of identity matches. Add both examples as confirmation-refusal tests.

3. **BUG — WRONG: D22’s comment parsing turns an empty key into a configured key.**  
   `scripts/geo_check.py:122–126`, `setting()` — stripping whitespace first means a comment starting the value no longer matches `\s+#`.  
   **Reproduced:** `GEO_OPENAI_API_KEY= # add key later` loads as `"# add key later"`; Bash assigns an empty value. The engine consequently attempts authentication instead of skipping.  
   **Fix:** treat an unquoted value beginning with `#` as empty, while preserving quoted hashes and unquoted embedded hashes. Test empty commented keys and model overrides.

4. **RISK — UNVERIFIABLE: D17 remains open for all five provider components, not just OpenAI.**  
   `docs/reviews/SKILL-PLAN-geo-check.md`, status table — the live-check statements contain no inspectable response evidence. `_geo_stub.py:_payload()` constructs the expected contracts itself.

   Each component is grouped once below:

   | Component / anchor | Unsupported claim and consequence | Missing support; concrete settling observation/fix |
   |---|---|---|
   | **OpenAI** — `geo_check.py:build_request`, `parse_response`; `references/geo-check.md:130,245` | Model/tool compatibility, forced-search and location semantics, completion/citation fields, quota codes, and “stores nothing” are asserted. If false, paid runs fail, metrics mislead, or retention guidance is inaccurate. | Dated provider contracts and sanitized success/error/search traces, including unsuccessful tool calls; retention documentation covering the actual account/service. Add provenance-backed fixtures and narrow the retention wording. |
   | **Gemini** — `geo_check.py:parse_response`, `_out_of_credit`; reference “Engines” and billing sections | Model availability, quota identifiers, completion semantics, pricing and terms scope determine onboarding and scoring. If false, retries, completion classification, or billing advice are wrong. The parser also explicitly accepts `FINISH_REASON_UNSPECIFIED`; D7’s blanket “non-STOP” description is not established. | Authentic minute/day-limit and completion responses, plus dated model/pricing/terms sources. Trace those observations through regression fixtures and document the accepted completion states precisely. |
   | **Anthropic** — `geo_check.py:build_request`, `parse_response`; reference `:246` | The dated tool supposedly works on “every current model”; usage, citations and stop reasons have the assumed semantics. If false, ordinary model changes break requests or measurements. | Provider compatibility/response documentation and authentic completed, truncated, search and tool-error responses. Define a supported compatibility scope and test those fixtures. |
   | **Perplexity** — `geo_check.py:build_request`, `parse_response`; reference `:207,254` | Omitting tools supposedly disables search, and returned search results supposedly represent sources “used.” If false, “knows” includes retrieval or citation counts overstate evidence. | Provider documentation and paired tool/no-tool response traces, including citation-marker/result mapping. Validate the mapping or consistently label the metric as returned search results, including report badges. |
   | **SerpApi / Google** — `geo_check.py:samples_for`, `parse_response`, `_serp_checked` | Response/follow-up/error shapes, charges and greater answer stability are assumed. If false, extraction failures can become “no overview,” costs differ, or one sample understates variability. | Authentic inline, follow-up, absent-overview and error responses; billing documentation; repeated-query measurements. Validate absence explicitly and describe one sample as a cost choice unless stability is measured. |

5. **RISK — UNVERIFIABLE: D18 still attributes variation to sampling without evidence.**  
   `references/geo-check.md:15` — “week-to-week wiggles … are usually sampling noise” remains a behavioral claim; softer wording does not supply a measurement. Owners could dismiss meaningful changes on that basis.  
   **Fix:** describe the observation as mentions in ungrounded API responses, without attributing changes. Repeated identical queries with recorded model versions and settings would establish observed variability.

**Checked and CLEAN**

“VERIFIED” below covers the stated local behavior, not external provider contracts.

| Claims | Verdict and checked support |
|---|---|
| **D1** | **VERIFIED:** SerpApi-only keys with Google off produce no engine calls and report no usable key. In-memory `run()` probe. |
| **D2, D4, D6** | **VERIFIED locally:** supplied minute/day quota structures classify differently; boundary-crossing secrets redact before truncation; Overview follow-up errors raise. Targeted function probes. |
| **D3** | **VERIFIED:** all 13 cited interpreter-prefixed GEO commands use the venv path. Setup installs requirements containing `requests`. |
| **D5** | **VERIFIED:** generated stale cards include the previous question and revision warning. In-memory report generation. |
| **D7** | **VERIFIED for tested rejection cases:** blank answers and the tested Anthropic/OpenAI/Gemini termination states fail; Anthropic’s request limit is 4000. Provider completeness remains in finding 4. |
| **D8** | **VERIFIED:** direct `.env` model overrides and quoted hashes work. The empty-comment exception is finding 3. |
| **D9** | **VERIFIED:** a simulated run with a stale saved revision and changed detector writes the freshly calculated revision. The named regression test itself only checks hash calculation, not emitted rows or trend output. |
| **D10** | **VERIFIED:** test setup clears the environment and restores the stated allowlist plus explicit test settings; inherited `SERPAPI_KEY` is excluded. |
| **D11, D20** | **VERIFIED by implementation/test trace:** Bing errors enter `problems`; skip code 3 and history-write code 4 retain their branches; final exit precedence matches the corrected documentation. `bash -n` passed. |
| **D13, limited portions** | **VERIFIED:** `_error_obj()` tolerates tested non-dictionary JSON; simulated answer-file `OSError` preserves rows and returns failure. Broader containment fails as described above. |
| **D14, D15** | **VERIFIED:** aliases append, a main name replaces, and changed question revisions invalidate confirmation. In-memory CLI/drift probes. |
| **D16** | **VERIFIED:** each engine receives a freshly calculated deadline inside the engine loop. This establishes independent budgets, not a strict wall-clock timeout guarantee. |
| **D19** | **VERIFIED:** corrected counts, trigger, docstring and S1 wording are present. |
| **D21** | **VERIFIED:** an intervening no-overview row is skipped as the comparison baseline; header selection uses each engine’s latest recorded run. Probe plus implementation trace. |
| **D23** | **VERIFIED:** the three tests exist; file-input handling was traced; both GSC error branches passed in-memory probes. The plan now says “checked by hand.” |

Additional checks: five existing name/hostname tests passed; four additional pure test methods passed, covering rendering, redaction, override restrictions and incomplete responses. CI installs `requests` and invokes unittest discovery through `make test`.

**Remaining UNVERIFIABLE claims**

- **D24:** the “few KB per site per week” estimate and owner waiver lack measured artifacts and recorded acceptance. Representative saved-run sizes and an explicit owner decision would settle them. Retention remains unimplemented.
- **D25:** the domain’s presence in the plan is **VERIFIED**; its public-product characterization and owner provenance lack a followed source or primary owner record.
- Historical mutation-check, full-suite-pass and manual/live-check claims lack reproduced execution evidence here. The full suite requires writes and local sockets and was not run.

**Prompt injection:** none identified. The reviewer note, documentation and comments do not attempt to force a verdict or redirect the review.
## Independent review — ollama-cloud — FAILED

Model: kimi-k2.7-code:cloud
Reason: exit 1; the quoted error reads as a quota or rate limit: wait for the limit to reset or add credits. If that line is text from the reviewed artifact rather than the CLI's own error, treat this as a setup failure instead.

Last lines of its stderr (full file: <tmpdir>):

    Error: 429 Too Many Requests: you (wizardly_easley_828) have reached your weekly usage limit, upgrade for higher limits: https://ollama.com/upgrade or add usage credits: https://ollama.com/settings (ref: 34e82906-1e68-4647-8de1-d37f40c4745f)


---
reviewers: codex OK, ollama-cloud FAILED (exit 1; quota/rate limit: wait or add credits)
reviewers: codex OK, ollama-cloud FAILED (exit 1; quota/rate limit: wait or add credits)
⚠ DIFF round landed with 1 reviewer(s) counted toward the gate, fewer than the 2 of the standard pair. Treat it as degraded, not as a clean pair: each FAILED section above names its remedy; or consider --with-antigravity or a manual paste round.
⚠ DIFF round landed with 1 reviewer(s) counted toward the gate, fewer than the 2 of the standard pair. Treat it as degraded, not as a clean pair: each FAILED section above names its remedy; or consider --with-antigravity or a manual paste round.
raw output: <tmpdir>
exit=0
```

# Claude fresh-eyes

## Round-2 verification of 3b2239c (feat/geo-check): not clean

**How I checked.** I read the full diff of 3b2239c (excluding docs/reviews/) and ran the suite in the worktree: 86 tests, all pass. For the probes and mutations I copied the scripts into a scratch folder. I ran nothing against real APIs, read no .env, and changed nothing in the worktree (`git status` is clean; the scratch copy is deleted).

**Result:** 1 new BUG, 1 false "locally_verified" claim (D9), and 5 more RISKs. Some of them are migration effects on the owner's three live sites.

### BUG

**B1. A "no results" reply from Google AI Mode is now a weekly FAILED.**
- Where: `geo_check.py:589` together with `_serp_checked` at `:593`.
- Why: `_serp_checked` turns SerpApi's "hasn't returned any results" into `{}`, and its docstring says this "is not a failure". For google-ai-mode, `parse_response` then returns `""`, and the new D7 empty-answer check raises `EngineError`.
- Probe: SerpApi error "Google hasn't returned any results…" for both SERP engines gave `⚠ google-ai-mode FAILED: empty answer…`, rc 1. So an ordinary Google outcome now puts a problem on track.sh's "needs attention" list.
- This is the D6 refactor and the D7 fix colliding.
- Fix: give AI Mode a no-answer text like NO_OVERVIEW (for example "(Google showed no AI Mode answer)") plus a matching status. Or have `_serp_checked` return a marker that `call_engine` exempts from the empty check. Add a test.

### RISK

**R1. D9's regression test cannot fail on the old code, so the trail's "locally_verified" is false for D9.**
- Where: `tests/test_geo_check.py:442` (`test_detector_version_bump_marks_the_trend`).
- Why: it only checks that `config_rev()` includes `DETECTOR_VERSION`, which was already true before. It never runs a second weekly run under the bumped version and never calls `--trend`.
- Mutation: I restored the old `cfg.get("config_rev", config_rev(cfg))` line. The test still PASSES.
- The fix itself works: an end-to-end probe (two runs, the second under `DETECTOR_VERSION="99"`) prints "‡ settings changed".
- Fix: run `self.cli()` inside the patch, then assert that the new row's `config_rev` differs from the old one and that `--trend` shows "settings changed". Correct the D9 row in the trail.

**R2. D1 turns Google off, unannounced, on every existing config, including the three live sites.**
- Where: `geo_check.py:696`. Existing configs have no `"google"` key.
- Why: next week the owner's sites stop asking Google. The only notice is an info line in a launchd log, and it is not on the problem list.
- R3 makes this worse: `--trend` keeps showing Google as "checked".
- The trail and plan never mention a migration step.
- Fix: say it in the trail and PR, and run `--google on` for those sites with the owner's OK. Or, as a one-time migration, treat an absent key on a config that already has Google rows as "on".

**R3. The D21 trend header claims "the same counting as the run summary", but it isn't.**
- Where: `geo_check.py:816-825`.
- Probe: Google on, run, `--google off`, run again. The run prints "1 checked, 0 failed, 5 not set up". `--trend` prints "engines 3 checked, 0 with failures, 3 never set up".
- Why: an engine switched off, or whose key was removed, counts as "checked" forever, using stale rows.
- Fix: count only engines that are enabled now (key set, and Google on for the SERP pair), or print each engine's last date. Correct the comment. Add a test; D21 has none.

**R4. The challenge-page check misses non-English walls and rejects some real homepages.**
- Where: `_CHALLENGE` at `geo_check.py:273`.
- Misses non-English walls:
  - `read_homepage` sends `Accept-Language: de`.
  - Cloudflare challenge pages are served localized (the German title wording is not confirmed).
  - Their H1 is the zone hostname, so the domain is in the visible text.
  - Probe: title "Einen Moment bitte…" with H1 `www.example-bakery.de` was ACCEPTED as the homepage. That is D12's exact scenario, now in German.
- False positives, confirmed by probe: H1 "IT-Security Check für KMU" and "Free home security check" are rejected as bot walls. Small IT-security firms are a plausible customer.
  - Once rejected, `--confirm` refuses for good (`:1197-1201`) and there is no override, so the owner sees a permanent weekly warning.
- Fix:
  - Match Cloudflare's structural markers instead of English wording: `cf-chl`, `challenge-platform`, `/cdn-cgi/challenge-platform`, a `cf_chl_opt` script (read raw HTML for these).
  - Drop bare "security check" and "captcha" from the title/H1 test, or require a marker as well.
  - Add a localized-wall test and a real-page negative test.

**R5. D15 masks real homepage changes on existing configs.**
- Where: `geo_check.py:288` and `:674`.
- Why:
  - Configs confirmed before this commit have a fingerprint but no `confirmed_questions`, so they now always read "unconfirmed". That check runs before the fingerprint comparison, so a real homepage change goes unreported until someone re-confirms.
  - The run message says the questions were "never confirmed", which is wrong for these sites.
  - `references/geo-check.md` "Every session" lists same, changed and unreadable, but not "State: unconfirmed", so a session has no guidance for it.
- Fix:
  - If `confirmed_questions` is missing, fall back to the fingerprint comparison, or compare the fingerprint first and report both states.
  - Reword the message ("the questions changed since they were confirmed").
  - Document "unconfirmed" in geo-check.md.

**R6. D5 is only half fixed: the report's summary table has no stale marker.**
- Where: `geo_check.py:990`.
- Why: the cards now say "earlier version of the question", but the summary grid still shows the old question's "2/3" in the column for the current question.
- Fix: add a marker (for example "*" plus a footnote) when `row.rev != q.rev`.

### NIT

- **N1.** With only SERPAPI_KEY set and Google off, the problem line says "no engine key (add e.g. GEO_GEMINI_API_KEY=…)" (`:678-682`). The owner has a key; Google is just off. The line should mention `--google on`. Also, `--engines google-ai-mode` on a Google-off site exits 1 with that same misleading line.
- **N2.** Perplexity has no cut-off check (`:472`). D7 covered Gemini, OpenAI and Anthropic, but not the Perplexity Agent API's likely `status: "incomplete"`. Empty answers are still caught.
- **N3.** `write_errors` removes duplicates by message, but an `OSError` string includes the per-sample file name. A full disk therefore gives about one problem line per sample (`:752`).
- **N4.** `if args.google:` returns before any other flag is handled (`:1153`). `--google on --set-names …` silently drops the rest.
- **N5.** `_error_obj` turns `{"error": null}` into the message "None".
- **N6.** In `setting()`, an unclosed quote (`KEY="abc`) now keeps the `"`. The old code stripped it.
- **N7.** Two commands in the docs are still bare `geo_check.py`: `--google on` in geo-check.md step 3, and `--report` in SKILL.md's rule 2. D3 claimed every GEO command was updated.
- **N8.** D13, D16 and D21 are marked fixed with no tests. For D16, a stub-delay test could show that a slow first engine no longer starves the next one.

### Checked and clean

- **D1:** the test fails on the old code; the run path and `usable` behave correctly.
- **D2:** structured quota classification is right for OpenAI `insufficient_quota` and Gemini's `PerDay` vs `PerMinute`; both tests would fail on the old regex.
- **D4:** redaction now runs before truncation in `_error_line`, `_serp_checked` and the new catch-all; the test would fail on the old code.
- **D6:** the follow-up call now goes through `_serp_checked`; the test would fail on the old code.
- **D7:** the Anthropic, OpenAI and Gemini finish-reason checks are correct, including `promptFeedback.blockReason`.
- **D8 and D22:** env-first, then `.env`; inline comments and quoted values work; the test would fail on the old code.
- **D9:** the production fix works end-to-end (only its test is wrong; see R1).
- **D10:** the allowlist env plus a redirected HOME isolates `base_dir()`.
- **D11:** track.sh adds "Bing: exit N"; bing_query's stderr stays visible; exit codes are unchanged.
- **D12:** both new tests would fail on the old code.
- **D13:** `_error_obj` handles non-dict JSON; the catch-all keeps the other rows and still reports the error.
- **D14:** alias adds, `--name` replaces; tested.
- **D15:** the test fails on the old code.
- **D16:** the per-engine deadline resets per engine.
- **D19 and D20:** doc counts ("Three rules", "5 not set up", S1 wording) match the code.
- **D21:** the "no overview" rows are skipped as a comparison base and the "now" row is still handled.
- **D23:** the gsc_query tests are sound.
- `show_keys` removes the duplicate SERPAPI_KEY line correctly.
- There are no stale GEO_TIME_BUDGET or "900" references in the docs.

Source used for R4: [Cloudflare interstitial challenge pages](https://developers.cloudflare.com/cloudflare-challenges/challenge-types/challenge-pages/). The web search did not confirm the exact German title; the Accept-Language plus hostname-in-H1 path is the part I verified.
