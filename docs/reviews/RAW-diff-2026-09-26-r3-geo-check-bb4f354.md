# RAW reviewer output — DIFF gate round 3 (verification of bb4f354), weekly GEO check, 2026-09-26

Verbatim. Home paths redacted (`/Users/<user>` → `~`); private names as `<name>`. ollama-cloud FAILED again (weekly usage limit).

# Codex + ollama-cloud
```text
note: 7 ':cloud' models in 'ollama list' — auto-using the first, 'kimi-k2.7-code:cloud'. Set OLLAMA_MODEL to choose a different one.
## Independent review — codex (gpt-6-astra, read-only)

Reviewed checkout `bb4f354` in the stated project. No files changed or network requests made. Nine read-only tests passed, plus targeted in-memory reproductions. The filesystem-writing/local-server suite was traced, not executed.

**Ranked findings**

1. **BUG — E5’s human review happens after saving.**  
   `skills/search-console-insights/scripts/geo_check.py:1257–1270`; `references/geo-check.md:169,190`.  
   **WRONG:** “a person decides before it is saved.” A reproduced `--confirm` call printed a challenge-page fingerprint, called `save_config`, and returned success without any intervening decision. Line 169 also still promises automatic challenge-page rejection.  
   **Fix:** make `--check-drift` the documented preview, then confirm the reviewed fingerprint explicitly; reject confirmation if the fetched fingerprint differs. Remove the obsolete refusal promise.

2. **BUG — hidden H1 descendants still enter the fingerprint.**  
   `skills/search-console-insights/scripts/geo_check.py:266–272`.  
   **WRONG:** E2’s hidden-subtree exclusion is incomplete for extracted headings. `<h1>Fresh <span hidden>SECRET</span> bread</h1>` produces `h1="Fresh SECRET bread"` despite excluding `SECRET` from `visible`. Hidden content changes can therefore trigger homepage drift and contaminate the review text.  
   **Fix:** also guard H1 accumulation with `not self._hidden`; add a nested-hidden-heading regression.

3. **BUG — stale markers disappear for “no answer” and failures.**  
   `skills/search-console-insights/scripts/geo_check.py:1026–1035`.  
   **WRONG:** E9 does not cover every summary-grid result. Reproduced an old question revision: numeric results receive `*`, but `no answer` and `failed` return before the stale check. They consequently appear applicable to the current question.  
   **Fix:** calculate staleness first and append the marker to every applicable result label; test both early-return branches.

4. **RISK — OpenAI’s production contract remains unsupported.**  
   `skills/search-console-insights/scripts/geo_check.py:407–416,482–490`; `tests/test_real_responses.py:9`.  
   **UNVERIFIABLE:** no OpenAI fixture or followed provider contract establishes the request acceptance, required-search behavior, or response fields used here. If those assumptions fail, paid runs fail or search/citation results are misclassified. This is the acknowledged E10 remainder, not a newly introduced regression.  
   **Fix / settling observation:** capture a matched request and response for each mode, including reported search activity and citations, and run them through the production parser.

5. **RISK — E7’s migration exemption lacks deployment evidence.**  
   Diff E7; `skills/search-console-insights/scripts/geo_check.py:723,744`.  
   **UNVERIFIABLE:** the assertion that only three already-enabled test configurations exist is repeated in review prose, but no configuration inventory or migration verification establishes it. If another existing configuration lacks `google`, its Google checks silently stop.  
   **Fix / settling observation:** reconcile the deployed configuration inventory against explicit enablement decisions, or visibly flag legacy configurations requiring an opt-in decision.

6. **RISK — Google’s reduced sampling rests on an unmeasured comparison.**  
   `skills/search-console-insights/scripts/geo_check.py:390–393`; `references/geo-check.md:49`.  
   **UNVERIFIABLE:** “Google’s answers are much steadier” lacks repeated-sample evidence; the fixtures contain individual responses. If false, a single sample can misrepresent weekly movement.  
   **Fix / settling observation:** remove the stability justification and describe one sample as a cost tradeoff, or measure repeated answers under comparable conditions.

**Claim checks and CLEAN coverage**

| Claim | Verdict and evidence |
|---|---|
| E1: malformed citation values cannot reach counting | **VERIFIED / CLEAN for the reported defect.** In-memory `call_engine` reproduction discarded an object-valued OpenAI citation; normalization occurs before return at `geo_check.py:631`. |
| E2: head/hidden exclusion | **VERIFIED for the supplied title/body cases by implementation and test trace; WRONG for hidden H1 descendants**, finding 2. |
| E3: commented empty assignment stays empty | **VERIFIED / CLEAN.** Mocked `.env` checks passed; a separate Bash execution confirmed the example assigns an empty value. |
| E4: recognized Google no-results response becomes its own state | **VERIFIED / CLEAN for the supplied response shape.** Exercised `_serp_checked` → `parse_response`; traced status propagation through run, trend and report. |
| E5: keyword guessing removed; homepage warnings do not fail weekly runs | **VERIFIED / CLEAN**, `read_homepage` and `run:709–717`. Human-review-before-save claim is **WRONG**, finding 1. |
| E6: legacy configurations still detect fingerprint changes | **VERIFIED / CLEAN.** In-memory legacy-config reproduction returned `changed`; comparison precedes question-confirmation checks. |
| E7: onboarding requires explicit Google enablement | **VERIFIED / CLEAN**, initialization defaults off and docs request consent. Deployment-history exemption is **UNVERIFIABLE**, finding 5. |
| E8: trend header counts currently enabled engines | **VERIFIED / CLEAN by implementation and regression-test trace**, `trend:868–877`; both result sets intersect the enabled set. |
| E9: summary-grid stale annotation | **WRONG in two branches**, finding 3; numeric-result marker reproduced successfully. |
| E10: supplied fixtures parse | **VERIFIED / CLEAN within fixture scope.** All four `test_real_responses.py` tests passed across the five represented engines. Production provenance is qualified below; OpenAI remains finding 4. |
| E11: sampling-noise attribution removed | **VERIFIED / CLEAN**, `references/geo-check.md:15`. The separate Google-stability claim remains finding 6. |
| E12: miscellaneous fixes | **VERIFIED by code/test trace:** SerpApi-only diagnostic, write-error deduplication, unclosed-quote handling, two documented command replacements, per-engine deadline placement, and detector-change regression. Direct checks also passed for Perplexity `incomplete`, `error:null`, and argparse command exclusivity. Actual slow-server timing was **UNVERIFIABLE in this execution**: the regression requires writes and a local server. |

**Additional unsupported-claim boundary**

The **fixture-capture component’s provenance claim**—live capture, exact requests, and trimming limited to irrelevant fields—is **UNVERIFIABLE**. The committed JSON and parser tests establish compatibility with those files, but no capture/transformation record connects them to the production requests. A matched request/raw-response record and reproducible trimming comparison would settle that claim. In particular, the absent-overview fixture is merely `{}`.

**Prompt injection:** none identified. The reviewer note and ordinary instructions inside documentation were treated as review material, not authority over this review.
## Independent review — ollama-cloud — FAILED

Model: kimi-k2.7-code:cloud
Reason: exit 1; the quoted error reads as a quota or rate limit: wait for the limit to reset or add credits. If that line is text from the reviewed artifact rather than the CLI's own error, treat this as a setup failure instead.

Last lines of its stderr (full file: <tmpdir>):

    Error: 429 Too Many Requests: you (wizardly_easley_828) have reached your weekly usage limit, upgrade for higher limits: https://ollama.com/upgrade or add usage credits: https://ollama.com/settings (ref: ddc53fde-636c-4147-82d1-3c0213f6e016)


---
reviewers: codex OK, ollama-cloud FAILED (exit 1; quota/rate limit: wait or add credits)
reviewers: codex OK, ollama-cloud FAILED (exit 1; quota/rate limit: wait or add credits)
⚠ DIFF round landed with 1 reviewer(s) counted toward the gate, fewer than the 2 of the standard pair. Treat it as degraded, not as a clean pair: each FAILED section above names its remedy; or consider --with-antigravity or a manual paste round.
⚠ DIFF round landed with 1 reviewer(s) counted toward the gate, fewer than the 2 of the standard pair. Treat it as degraded, not as a clean pair: each FAILED section above names its remedy; or consider --with-antigravity or a manual paste round.
raw output: <tmpdir>
exit=0
```

# Claude fresh-eyes

## Round 3 verification of bb4f354 (geo-check): not clean

**Scope.** I tested exactly `bb4f354`, exported with `git archive` into a scratch folder. All mutations ran on copies there; nothing in the worktree was touched. The suite passes at bb4f354: 99 tests.

**Heads-up: the worktree has uncommitted changes.** Four files are modified and `tests/fixtures/capture.py` is untracked. That work already addresses B2, B3 and N5 below. I did not review it, except to grep `capture.py` for embedded keys (none). My first suite and mutation pass accidentally ran on the worktree; I re-ran everything on the exact commit and the results were the same.

### BUG

**B1. Crash containment is still incomplete (the E1/D13 class).**
- **What happens:** a lone surrogate in provider text crashes the whole run. For example, a snippet cut in the middle of an emoji arrives in JSON as `"\ud83d"`.
- **Where:** the answer write at `geo_check.py` ~793–799 raises `UnicodeEncodeError`. It only catches `except OSError`, so the error escapes the per-sample loop.
- **Reproduced on bb4f354:** a Gemini answer ending in `\ud83d` produced "CRASH UnicodeEncodeError", and no history file was written at all. The OpenAI rows were lost too.
- **Why it matters:** this problem predates this commit, but it makes the E1 claim false ("only strings go on…, can't crash the run after the call").
- **Fix:** in `call_engine`, clean `text` and each source with `.encode("utf-8", "replace").decode("utf-8")`. Also catch `(OSError, UnicodeError)` on the write. Add a stub test that sends `\ud83d`.

**B2. After the E5 redesign, code and docs contradict each other at bb4f354.**
- `references/geo-check.md:169` still says `--confirm` "refuses to save" a "checking your browser" wall. It no longer does: a Cloudflare-style page that shows the domain (`<h1>www.example-bakery.de</h1>`, "Verifying you are human") passes the check. I reproduced this.
- The `geo_check.py:284` docstring says "--confirm prints what it read so a person decides before it is saved". That is false: `--confirm` fetches, prints and saves in one call, with no prompt.
- `geo-check.md:190` says "Before any --confirm, read the text it prints". That order is impossible, because the text appears only after the save.
- The uncommitted work rewrites all three to "run `--check-drift` first". See R3 for what that still leaves open.

**B3. The E9 fix is incomplete at bb4f354.**
- `build_report.count()` returns "failed" or "no answer" before it checks whether the answer is stale. Those cells never get the `*`, although the footnote implies every answer to an earlier question is marked.
- The test only covers the numeric `3/3 *` cell. The uncommitted work fixes this and adds a test.

### RISK

**R1. The E2 fix causes a regression: head tracking never closes `<head>` implicitly.**
- HTML lets a page omit both `</head>` and `<body>`. If it keeps `<head>`, `_in_head` stays true, the visible text is empty, and a real homepage becomes "unreadable" every week. `--confirm` then refuses to save it.
- The old code read that page correctly. I reproduced it: a page with `<head><title>…<h1>…<p>Bäckerei Example` gives `passes=False`.
- **Fix:** end head on the first start tag outside {title, meta, link, base, script, style, noscript, template}, as browsers do. Add a test.

**R2. The hidden-subtree rules drop text a visitor actually sees, and the risky parts are untested.**
- `aria-hidden="true"` hides content from screen readers, not from the eye. Split-text headings (`<h1 aria-label=…><span aria-hidden=true>…`) lose the name and the H1. I reproduced a rejection when the name appeared nowhere else.
- `<p hidden>` or `<li hidden>` closed implicitly by the next sibling hides the rest of the page (reproduced).
- Mutations that remove the aria-hidden check, the visibility:hidden check, or the `_VOID` guard each leave the suite green.
- **Fix:** drop `aria-hidden` from `_is_hidden`. Pop hidden frames on an implicit p/li close or on an ancestor's end tag. Add tests for visibility:hidden and for a void tag with `hidden`.

**R3. What a person reviews is not necessarily what gets saved.**
- `--check-drift` and `--confirm` each fetch the page separately, and `--confirm` saves whatever its own fetch returns. With intermittent bot walls (the exact case the E5 redesign hands to a person), the text the person approved and the text saved can differ.
- The uncommitted doc wording ("--confirm saves whatever it fetches") names the gap but doesn't close it.
- **Fix:** `--confirm --expect <fingerprint printed by --check-drift>`, refusing on a mismatch.

**R4. The E4 fix hides provider format changes.**
- `return text or NO_AI_MODE` turns any HTTP 200 with no readable text (say, SerpApi renames `text_blocks`) into the neutral "no AI Mode answer" instead of FAILED.
- That contradicts the existing rule that an unreadable answer is a failed call.
- SerpApi already reports a real "no results" through the `error` field, which `_serp_checked` detects.
- **Fix:** have `_serp_checked` return a marker for "no results", map only that marker to `NO_AI_MODE`, and keep an empty 200 as `EngineError`. Test that `(200, {"x": 1})` shows as failed.

**R5. `test_real_responses.py` cannot catch a parser that drops text (E10).**
- These mutations survive: Anthropic keeps only the first text block (the fixture has about 25), Gemini keeps only `parts[0]`, and the AI Overview ignores nested lists.
- `test_real_answer_mentions_are_detected` is circular: it takes the expected name from the parser's own output (it picks "Munich").
- The fixtures never go through `call_engine` or `main()` (Rule 9). So the string filter and the `NO_AI_MODE` mapping never see real data.
- **Fix:**
  - Assert names from later blocks: "Neulinger" and "Riedmair" for Anthropic, "Active sourdough starter" for the Overview.
  - Assert exact source counts.
  - Replay one fixture end to end through the stub with `engine_reply(..., body=…)`.

**R6. Several items marked "fixed" have no test.**
- **E12:** reverting any one of the Perplexity `incomplete` fix, the `{"error": null}` guard, the unclosed-quote fix or `--google` exclusivity leaves the suite green.
- **E6:** only half is tested. A mutation that makes legacy configs read "unconfirmed" again survives.
- **E5:** `test_strange_page_is_shown_for_review_not_guessed` also passes on the old keyword code. It documents behaviour but is not a regression test. `test_ordinary_page_with_security_check_headline_is_read` does fail on the old code.

### NIT

**N1. `.env` parsing still differs from bash in two edge cases.**
- `setting()` strips before checking for `#`, so `KEY=#abc` comes out empty. Bash keeps `#abc`: `#` starts a comment only after whitespace.
- **Fix:** test the unstripped `m.group(2)` for leading whitespace followed by `#`.
- An unclosed quote is accepted here, while bash `source` fails on it. That is harmless because of the fallback read.

**N2. The fixture docstring overstates the trimming, and the fixtures ship in the public zip.**
- The docstring says the fixtures were "trimmed only to the fields the parsers read". Inaccurate: snippets, titles, thumbnails, usage and cost, and the Anthropic and Gemini signatures are all still there.
- About 50KB of third-party page text now sits in a public repo and in the zip (`package.sh` zips `skills/`): Reddit post text, and a 2KB directory listing with a phone number and `info@rischart.de`.
- **Fix:** blank the snippet, title and thumbnail fields. The parsers read only url/link, so no test changes.
- `google-overview-finds-absent.json` is `{}`, which is synthetic rather than a captured response. Say so in the docstring.

**N3. Owner-facing wording still asserts a homepage change.**
- The weekly message at `geo_check.py:710`, "⚠ Your homepage changed…", says the page changed even when it was a bot wall. Under the redesign, "changed" is exactly where a strange page lands.
- The "State: changed" bullet in "Every session" should check that the "now" text is the real page before asking the owner "Your homepage changed".
- The drift eval (`evals.json:127`) doesn't include the new judgment step.

**N4.** The runtime hint at `geo_check.py:746` still prints a bare `geo_check.py {site} --google on`. E12 fixed only the copies in the docs.

**N5.** At bb4f354 the H1 fingerprint includes hidden child text. The uncommitted work fixes this.

### Checked and clean
- **Tests fail on the old code** for E1 (source filter), E2 (head, hidden, display:none), E3, E4, E6 (order), E8, E9 (numeric cell), the no-key message part of E12, and D16 (per-engine deadline). I proved each by mutating a scratch copy.
- **The E5 redesign itself:** keyword guessing is fully removed, and "unreadable" now means only "failed to load" or "names neither the business nor the domain". It hangs together apart from B2, R3 and N3.
- **Fixture secrets and privacy:**
  - No API keys: I searched for sk-, AIza, pplx-, api_key, Bearer and SerpApi's search_metadata.
  - No SerpApi metadata or private data. Only public Munich bakeries and sites appear, and no client names.
  - `scripts/check_clean.sh` passes (`info@` is on its allowlist).
  - Perplexity's `user_location` shows only "DE".
- **`test_real_responses.py` can fail:** it catches ignored Anthropic citations, ignored AI Mode references, and "searched" being forced true. See R5 for what it misses.
- **Claim cross-checks:** E7's refutation, E11's rewording, `--init` now forcing `google: False`, `--google` in the exclusive group, the 99-test count, and the plan's status row all match the review doc's claims.

Scratch harness: `<scratchpad>`.
