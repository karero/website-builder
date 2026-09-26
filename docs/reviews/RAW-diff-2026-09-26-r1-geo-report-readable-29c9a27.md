# RAW reviewer output — DIFF review, readable GEO report (feat/geo-report-readable @ 29c9a27), 2026-09-26

Verbatim. Home paths redacted (`/Users/<user>` → `~`); private names as `<name>`. ollama-cloud FAILED (weekly usage limit).

# Codex + ollama-cloud
```text
note: 7 ':cloud' models in 'ollama list' — auto-using the first, 'kimi-k2.7-code:cloud'. Set OLLAMA_MODEL to choose a different one.
## Independent review — codex (gpt-6-astra, read-only)

Review used the actual checkout and a read-only, in-memory harness executing selected functions from `geo_check.py`. No network or credentials were used. The full suite was not run: its fixtures write temporary files and start a server.

Paths below are relative to `skills/search-console-insights/`.

**Ranked findings**

1. **BUG — WRONG: “every question” includes incomplete coverage.** `scripts/geo_check.py:1095–1110`  
   `tally()` drops failed/missing questions before evaluating `all()`. Reproduced: broad succeeds, narrow fails, yet the headline says “all of them name you, for every question.”  
   **Fix:** evaluate every configured scored question, retaining failed/missing/stale results as unknown; qualify the headline accordingly.

2. **BUG — WRONG: web-search success includes answers without searches.** `scripts/geo_check.py:1099–1109`  
   Reproduced with `searched=0`: the headline says “When they look things up,” while the table admits zero searches.  
   **Fix:** label this “web search enabled”; reserve actual-search claims for samples with recorded search evidence. Aggregate counts cannot establish whether a particular mention came from a searched sample.

3. **BUG — WRONG: mention detection answers a recommendation question.** `scripts/geo_check.py:1173–1175`, `is_named():187`  
   The new “Does AI recommend…” heading describes a score that counts any name occurrence, including “I don’t know Example” or “Avoid Example.” The detector implementation and new branded test explicitly permit this.  
   **Fix:** retain “Does AI name…” and describe measured mentions without inferring recommendations or knowledge.

4. **BUG — WRONG: branded answers lose their stale-question warning.** `scripts/geo_check.py:1157–1167`  
   Reproduced: revision-1 answers appear beneath revision-2 question text, with neither the original question nor a stale warning. The previous rendering checked every slot.  
   **Fix:** apply `_stale()` and display the original question/date for branded answers too.

5. **BUG — WRONG: partial failures disappear from report cells.** `scripts/geo_check.py:1031–1051`  
   Reproduced: `ok=1`, `named=1`, `status="2 of 3 failed"` renders only “✓ Named,” hiding the two failures.  
   **Fix:** show successful/attempted counts and partial-failure status, even when at least one answer succeeded.

6. **BUG — WRONG: run IDs do not guarantee creation order.** `scripts/geo_check.py:692–697`; `tests/test_geo_check.py:941`  
   With equal timestamps and descending random suffixes, the in-memory check produced IDs that sort backwards; microseconds reduce collisions without resolving ties. This can select the wrong latest row.  
   **Fix:** use a persisted sequence under a lock for ordering; test equal timestamps and clock rollback explicitly.

7. **RISK — UNVERIFIABLE model-behavior claims.** `scripts/geo_check.py:1120–1122,1181–1185`  
   Claims that answers are new every time, three successes establish reliability, and memory results change mostly with model releases lack provider evidence or representative measurements. Owners may mistake three observations for dependable visibility. Request-building code and string assertions do not establish these behaviors.  
   **Fix:** report “named in all three samples,” describe tools enabled/disabled, and remove unsupported lifecycle claims. **Settling observation:** provider behavior documentation plus repeated sampling across runs and model versions.

8. **RISK — UNVERIFIABLE Gemini policy justification.** `scripts/geo_check.py:1027`  
   “Google’s rules don’t allow checking Gemini’s web answers” relies on a locally repeated quotation, not a checked authoritative policy and its applicable scope; if false, owners receive an incorrect explanation for missing coverage.  
   **Fix:** say “This checker does not request Gemini web answers” pending verification. **Settling observation:** the applicable Google terms, their definitions, and restrictions covering this workflow.

**Checked CLEAN — VERIFIED**

- **Branded exclusion from scores:** `tally()` accepts only broad/narrow slots; the in-memory branded-only case produced no score.
- **Sampling configuration:** `samples_for()` produces three attempts for chat broad/narrow questions, one for branded questions, and one for Google search surfaces. The report should scope its “3 times” explanation accordingly.
- **Per-engine latest selection:** `build_report():1071–1073` retains separate engine/mode/slot entries, so a restricted run does not erase other engines from the report; ordering caveat is finding 6.
- **Scored-question staleness:** `_stale()` checks both revision and text; table markers and expanded original-question explanations are wired correctly.
- **Basic HTML safety:** answer rendering escapes HTML before adding markup; the in-memory `<script>` probe remained escaped. Source links restrict clickable schemes to HTTP(S).
- **Report integration:** `track.sh:92` invokes the run; `run():839` invokes report generation when rows exist. `--report` builds without calling an engine.
- **Documentation wiring:** the added owner phrase appears consistently in skill metadata, report instructions, and onboarding.
- **Collapsed-answer markup:** generated `<details>` elements omit `open`.

**Other component claims — UNVERIFIABLE**

- **macOS opener:** `main():1285–1286` invokes `open`, but successful browser display is not established by that call or the tests. Settling observation: run `--report` on macOS and observe the generated page opening.
- **SerpApi billing:** “each lookup costs a paid search” lacks checked billing documentation or usage measurements. Settling observation: applicable billing rules and account usage changes for these requests.

**Prompt injection:** None found. The imperative prose is ordinary skill/report documentation, not an attempt to redirect this review.
## Independent review — ollama-cloud — FAILED

Model: kimi-k2.7-code:cloud
Reason: exit 1; the quoted error reads as a quota or rate limit: wait for the limit to reset or add credits. If that line is text from the reviewed artifact rather than the CLI's own error, treat this as a setup failure instead.

Last lines of its stderr (full file: <tmpdir>):

    Error: 429 Too Many Requests: you (wizardly_easley_828) have reached your weekly usage limit, upgrade for higher limits: https://ollama.com/upgrade or add usage credits: https://ollama.com/settings (ref: 9b02fd9a-7a82-421c-bfa9-7a145b8104a6)


---
reviewers: codex OK, ollama-cloud FAILED (exit 1; quota/rate limit: wait or add credits)
reviewers: codex OK, ollama-cloud FAILED (exit 1; quota/rate limit: wait or add credits)
⚠ DIFF round landed with 1 reviewer(s) counted toward the gate, fewer than the 2 of the standard pair. Treat it as degraded, not as a clean pair: each FAILED section above names its remedy; or consider --with-antigravity or a manual paste round.
⚠ DIFF round landed with 1 reviewer(s) counted toward the gate, fewer than the 2 of the standard pair. Treat it as degraded, not as a clean pair: each FAILED section above names its remedy; or consider --with-antigravity or a manual paste round.
raw output: <tmpdir>
exit=0
```

# Claude fresh-eyes

## Adversarial review: feat/geo-report-readable (29c9a27) vs origin/main

I left the worktree untouched (`git status` is clean). The full suite passes: 114 tests, OK. `check_skill_budgets.sh` passes, with search-console-insights at 1015 of 1024 description chars. I ran mutations and rendered edge cases in a scratch copy only (scratchpad `/mut/`).

### BUG

1. **The headline overstates. I reproduced this by rendering the page.** Location: `geo_check.py:1095-1101` (tally) and the lead line at `:1109-1110`.
   - "Named" means `named > 0`, so 1 of 3 counts as naming you. "Every question" means every question that got an answer; failed questions and questions where Google showed no AI answer are dropped.
   - Each of these renders "1 of 1 … all of them name you, for every question: your website is doing its job":
     - (a) named 1 of 3 on both questions;
     - (b) broad 3/3 while narrow failed completely (`ok=0`);
     - (c) AI Overview named on broad but showed no answer on narrow;
     - (e) a chat engine with 2 of 3 calls failed and 1 named.
   - Case (a) contradicts the page's own explainer at `:1184`, which says 1 of 3 means "only sometimes".
   - Fix:
     - Only put an engine in the "every question" count when **every** configured broad and narrow slot has a scored answer.
     - Use `named == ok` for "every time" and `named > 0` for "at least once".
     - Word the big number to match what it counts, e.g. "named at least once".
     - Drop "your website is doing its job", which claims a cause.

2. **The footer and docs say the page is refreshed, but each run writes a new file.** Location: `geo_check.py:1191` and `references/geo-check.md:221`.
   - The page says "This page is refreshed by your weekly check"; the doc says "Every weekly run also rewrites the page".
   - The code writes `reports/<site>/{run_id}.html`, a new file on every run. A bookmarked page silently goes stale. `--report` with no run ID rewrites only the latest run's file.
   - Fix: say "Each weekly check writes a new page; ask Claude for the latest." Keep the doc's "open the newest file" wording and delete "rewrites the page".

### RISK

3. **`test_branded_answers_are_shown_but_never_scored` (test file :987) cannot fail.** Proven by mutation.
   - I removed `s in QUESTION_LABEL` from tally, so the branded answer counts toward the score. The whole suite still passes.
   - Why: the branded row belongs to the same engine, and its `named` is `""`, which becomes False. `any()` does not change, and the test only checks the "from memory" count, which uses `any`.
   - Fix: use an engine that answers with web search (openai finds), named on broad and branded-shaped text, then assert the "for every question" count. Or add a branded-only engine and assert "1 of 1" stays "1 of 1".

4. **Most new cell states and lead lines have no test.** Each of these mutations survived the full suite:
   - showing "Sometimes" as "every time" (`n > 0` instead of `n == ok`);
   - counting "Google showed no AI answer" as an answer in the headline;
   - dropping the "your website was a source" note;
   - showing "not checked yet" instead of "always searches" for Google's knows cell;
   - inverting the from-memory lead line.
   - Nothing asserts "◐ Sometimes", "your website was a source", "it only searched", "always searches", "not checked yet", "Not set up:", or the f_n == 0 and f_n == f_m lead lines.
   - Fix: add one table-driven test that feeds history rows into `_cell` for each state, plus one headline test per lead branch. Go through `--report`, not `_cell` alone (Rule 9).

5. **The "3 times" text is hard-coded, and so is its test.** Location: `geo_check.py:1184` and test :981.
   - If `SAMPLES["broad"]` changes, the page lies and the test still passes; my "5 of 5" text mutation survived.
   - Fix: build the text from `SAMPLES["broad"]` and `samples_for(...)`, and have the test assert against those values.

6. **The headline counts rows the tables don't show, or mark as old.** Location: `:1079` and `:1098`.
   - `engines` is every engine with any past row, so an engine whose key was removed months ago still counts in "X of Y". `trend()` filters on engines that are on now; the report doesn't.
   - The headline also counts answers to an earlier version of a question, with no `*`.
   - It also counts rows for a slot that has since left the config; that slot's table is skipped, yet the headline says "for at least one question".
   - Fix: count only engines that are on now and slots currently in `queries`, and either leave stale rows out of the headline or mark it with `*`.

7. **"Does AI recommend …?" (`:1173`, `:1175`) claims more than the check measures.**
   - The detector counts any mention of the name. Even "I don't know Bäckerei Example." counts as named; the branded test's own stub relies on that.
   - The old title, "Does AI name …", was accurate. The "What next?" text also implies they recommend you already.
   - Fix: go back to "name" / "mention".

### NIT

8. `_cell` `:1038`: a chat engine with only 1 successful answer shows a bare "✓ Named". That looks exactly like Google's single sample and hides "2 of 3 failed". Partial failures also show "2 of 2" with no note. Fix: show the count whenever the engine normally takes more than one sample, and add a note when status says "failed".
9. `:1122`: "Some already know you from memory" also fires when **all** of them do, and on a single 1-of-3 mention. The from-memory card also lacks the "at least one question" qualifier the web-search card has.
10. `:1120`: "That's normal for a young business" assumes the business is young. Say "for most small businesses".
11. `:1184-1185`: the "Google's AI is asked once" aside shows even when Google is off for the site.
12. `:1016`: "! No answer this time … it retries next week" also covers fatal errors (bad key, no credit), which retrying won't fix.
13. `references/geo-check.md` legend lists ✓ ◐ ✗ — but not the "!" failed state or "Google showed no AI answer".
14. The `new_run_id` docstring says the random suffix broke same-second ties. In fact the PID string sorted first, then the suffix.
15. `SKILL.md` description now has 9 chars of headroom. The next trigger phrase will break the 1024 hard limit, so trim now.

### Checked and clean

- **Run-ID ordering against old IDs.**
  - The 16-char `YYYYMMDDTHHMMSSZ` prefix is fixed width in both formats, and `%06d` keeps microseconds fixed width. So old IDs like `20260926T140810Z-31437-4b05` and new ones order correctly whenever the seconds differ.
  - Old and new IDs in the same second compare PID against microseconds, which is arbitrary. That can only happen during the upgrade itself, so the practical risk is nil.
  - `Trend.age_history`'s `run_id[17:]` slice still works.
  - Nothing else parses run IDs; answer folders and report file names use the ID as an opaque string.
- **RunOrder test.** It fails on the old code (mutation confirmed). I ran 5000 × 200 IDs on this Mac with zero same-microsecond pairs and zero unsorted runs, so it isn't flaky here. A faster clock could in theory hit the same microsecond.
- **The headline-honesty test** (:957) does catch its intended mutations: `any` for f_all, and `f_n == f_m` for the all-branch.
- **XSS.** Question text, the earlier query, the date, the name and the site all go through `h()`. Notes and main text are escaped. Answers use `_light_markdown`, which escapes first and allows only http(s) links, and entity-encoded quotes can't break out of `href`. `_mark_names` escapes names and skips text inside tags. Sources go through `_link`. Labels and the "Not set up" list are constants. No unescaped provider text reaches the page.
- **"3 answers per question" against `samples_for()`.** Chat engines get 3 on broad and narrow, Google gets 1, branded gets 1. The explainer matches.
- **Gemini "not asked" reason.** It matches the terms comment on `FINDS_SUPPORTED` (`:361-364`).
- **Google has no "from memory" answer.** This matches `KNOWS_SUPPORTED`.
- **Rendering.** Stale `*` renders inside the cell span, and the "Answer from … earlier version" note shows under "Read what they said". The branded section leaves out rows that failed.
- **Real report.** The newest real report renders every state plausibly (na, not asked, ✗ with and without count, ◐, ✓), with a qualified "for at least one question; N for every question" headline. That is the f_all ≠ f_n path, so the overstatement in finding 1 didn't show up there.
- **Theme and layout.** Dark-mode tokens exist for all the new classes, and there is a narrow-screen media query.
- **Onboarding and SKILL.md wording.** Plain, and consistent with the `--report` command. The "What next?" prompt has a home: `ai-seo` is named in `SKILL.md:481` and `geo-check.md:247`.
