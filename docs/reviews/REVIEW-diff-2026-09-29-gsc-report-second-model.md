# DIFF review — the Google report (#141), read by a second model after release — 2026-09-29

#141 was merged and released in 0.28 with Codex-only DIFF rounds (9, the last clean), because
ollama-cloud was out of credits and Antigravity's quota was spent. The owner chose to release
and have a second model read it once ollama had credits, with anything it found fixed in 0.29
("a second-model review of #141 once ollama has credits, with anything it finds fixed in 0.29").

Seat: ollama-cloud, `kimi-k2.7-code:cloud`, depth Normal, on `bbe4432^1..bbe4432` (the #141
merge) limited to `skills/` and the plan, which is the specification the code answers to. The
whole was 126 KB, over the script's 117 KB limit, so it ran as two halves, each with the plan:
**A** — `SKILL.md` and `search_report.py`; **B** — `geo_check.py`, `schedule_tracking.sh`,
`track.sh` and every test.

| Half | BUG / RISK / NIT | Held up |
|---|---|---|
| A | 2 / 4 / 3 | 4 (one BUG, two RISKs, one NIT) |
| B | 1 / 3 / 4 | 2 (two RISKs, both about what the tests could not catch) |

20 findings; 6 held up and are fixed here, 14 are refuted or declined below.

## Fixed, each with a test

- **A-BUG 1 → a real RISK.** The save of `google-data.json` sat inside the fetch's `try`, so a
  save that failed (full disk, a folder in the way) was handled as a failed fetch: the page
  showed the older saved numbers under "could not be refreshed" although Google had answered.
  The save now runs only after a successful fetch, and its failure keeps the fresh numbers and
  says a copy could not be saved.
- **A-RISK 1.** A page built from saved numbers labelled their key searches with *today's*
  source ("key searches from your request") rather than the one they were fetched with. The
  saved file now carries `from`; an older saved file without it falls back to today's label.
- **A-RISK 3.** The property was requested as typed (`sc-domain:Example.com`,
  `sc-domain:sc-domain:…`); it is now the bare lowercase domain, as everywhere else.
- **A-NIT 3.** A hand-edited record holding `"keywords": "a, b"` was read letter by letter, and a
  record that is not an object, or keywords of another type, crashed the page. A string is now
  read like `--keywords`; anything else counts as no key searches.
- **B-RISK 1.** The test Google answered any dates for the S6/S7 requests, so a wrong window
  would pass. A test now pins the last four complete weeks (it fails when the window moves).
- **B-RISK 3 (as a test).** `schedule_tracking.sh` and `track.sh` each write the site record,
  and nothing checked that the report reads the scheduler's copy as the weekly job's. A test now
  installs a job and reads the record through `resolve_settings` (it fails when the report stops
  treating it as the job's). A shared writer was not added: the two differ on purpose (below).

The four fixes' tests fail on the released code; the two coverage tests pass on it and fail when
the code they guard is broken.

## Refuted or declined

- **A-BUG 2 — refuted.** `html.escape` escapes `"` and `'` by default (`quote=True`); checked:
  `html.escape('a"b')` gives `a&quot;b`.
- **A-RISK 2 — declined.** `GSC_HISTORY_CSV` is this skill's one variable for the history file
  (`gsc_query.py`, `bing_query.py`, `insights.py`, `track.sh`); the report uses it only when no
  record and no flag name a file, exactly where the other tools would.
- **A-RISK 4 — refuted.** `load_credentials(interactive=False)` raises `RuntimeError` only for a
  missing or expired token, the sign-in case; `RefreshError` comes from the refresh. The
  `RuntimeError` stand-in applies only when `google.auth` is missing, and then
  `load_credentials` exits before anything is caught.
- **A-NIT 1 — declined.** "How people find you on Google" is the page's name (release notes, the
  AI page's link); it claims no count. The counts say "visits" and "times shown", as the plan
  requires; the plan's note is about the mock-up's counting words.
- **A-NIT 2 — declined.** S11 names the variant's settings "when they differ from today's"; the
  page has no tracker window of its own to compare, so the country is the one shared setting.
- **B-BUG 1 — declined, by design.** Install records no `bing`: the scheduler does not resolve
  `.env` (only `track.sh` does, and the report never re-evaluates it; DIFF rounds 1–4 found four
  ways re-evaluation went wrong). Until the first weekly run the page says "No Bing data for
  these searches yet. If Bing isn't connected, ask me 'connect Bing'" — true in both cases.
- **B-RISK 2 — refuted.** `geo_check.py` builds `site` with `normalize_site`, which lowercases.
- **B-NIT 1 — declined.** A renamed Bing heading makes those tests fail loudly, not pass wrongly.
- **B-NIT 2 — declined.** Both writers produce the same JSON with any Python 3; which one runs
  changes nothing in the file.
- **B-NIT 3 — declined** with B-RISK 3: the new round-trip test covers the drift risk without
  merging two writers that differ on purpose (install cannot know Bing; `track.sh` writes
  through a temporary file of its own).
- **B-NIT 4 — declined.** The plan's status table is the feature's required status record.
- **"Unverifiable" claims (both halves)** — Google's API behaviour, `gsc_query`, `bing_query`,
  `_history`: settled by the plan's probe on a real property and the two live runs, recorded in
  `SKILL-PLAN-gsc-report.md` and `REVIEW-diff-2026-09-27-gsc-report.md`.

## Evidence

- The skill suite: 172 tests pass (166 before, 6 new).
- The four fix tests fail against `origin/main`'s `search_report.py` (three FAIL, one ERROR);
  the two coverage tests fail when the S6/S7 window is moved a week and when the record is not
  treated as the job's.
