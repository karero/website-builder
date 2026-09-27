# Plan — a visual Google & Bing report in search-console-insights

Draft 6: requirements, the owner's decisions D1–D6, the counting rules and a design, revised
after PLAN rounds 1 (Codex: 3 BUG, 6 RISK; fresh-eyes: 5 BUG, 4 RISK, 1 NIT), 2 (Codex: 5 BUG,
3 RISK), 3 (Codex: 2 BUG, 1 RISK), 4 (Codex: 1 BUG), 5 (Codex: clean) and the final full read
(Claude Opus: 4 BUG, 7 RISK, 5 NIT) — dispositions at the end. No product code yet.

## Status

| Step | State | Evidence |
|---|---|---|
| Requirements as scenarios (this document) | draft 6 | this document |
| Decisions D1–D6 | **decided** (owner, 2026-09-27: all as recommended) | this document |
| Mock-up page with invented numbers, for a visual check | done; owner's visual check 2026-09-27: "looks right" | `docs/reviews/gsc-report-mockup/mockup.html` (from `make_mockup.py`); checked in light and dark mode, at phone and desktop width |
| PLAN gate (Codex only: ollama-cloud out of credits until ~2026-09-28; plus a fresh-eyes pass in round 1) | **closed** 2026-09-27: 7 rounds + final full read; round 7 had no BUG, its one RISK fixed locally (tie-break, not externally re-verified beyond the wording pass) | round 1 on `d29b3de`, 2 on `e9090ea`, 3 on `946d5ae`, 4 on `3d3cdf4`, 5 and the final read on `d595cb5` |
| Probe of the real Google responses (see "To verify before build") | not started | — |
| Build | not started | — |
| DIFF gate | not started | — |
| Live check on a real site | not started | — |
| PR | not started | — |

## Context

Today an owner sees their Google and Bing results only as text: a Markdown report
(`gsc_query.py --out report.md`, `bing_query.py --out …`; `insights.py` prints to the screen)
and, over time, a text trend with ▲/▼ per key search (`track.sh` → `_history.py`). The one page
an owner can simply open and read is the AI report (`geo_check.py --report`, PR #122): one plain
answer at the top, simple tables, detail folded away. This plan gives Google and Bing the same
kind of page, with pictures of how things change over time.

What data exists:

- **Local history** (`~/.config/gsc-insights/history.csv`): one row per key search per run —
  date, site, source (`gsc`, `bing`, …), keyword, query, position, impressions, clicks, window,
  country. `gsc_query.py`, `bing_query.py` and `insights.py` append to it on every run with
  `--keywords` (the weekly `track.sh` job among them). Each row is a snapshot over its `window`
  (28 days for the tracker), not a weekly total. It holds **no site-wide totals**.
- **Google, live**: the Search Console API returns clicks, impressions and position per day
  (`dimensions: ["date"]`, or `["date", "query"]`), about 2–3 days behind, reportedly back 16
  months. `gsc_query.py` already fetches the query and page lists (for striking distance and
  low-CTR pages) and can drill one query, given with `--query`, down to its pages; looping that
  drill-down over every listed query is new work.
- **Bing**: the tracker uses Bing Webmaster Tools' roughly 6-month rolling aggregate
  (`SKILL.md`, Bing section); its trend on this page comes from local history.
- **The weekly job** (`schedule_tracking.sh`) passes the domain, the key searches, the history
  file and the country filter to `track.sh`, which queries the domain property
  `sc-domain:<domain>` over 28 days.

## Counting rules (these decide every number on the page)

- **Visits** = Search Console clicks (someone clicked the site in Google's results). The page
  says "visits from Google", not "people": one person can visit twice.
- **Weeks** run Monday–Sunday in the time zone Google reports dates in (to verify; reportedly
  Pacific Time). The data range starts at the **first date that has any row** in the `["date"]`
  response (not the requested start: Google sends no row for a day without data) and ends at the
  **latest date Google has finished** (from the API's data-freshness answer, or today minus the
  lag — settled by the probe; not the last row, since quiet days have none). A day inside that
  range without a row counts as 0. A week counts only when it is **complete**: all seven days
  lie inside that range. A partial week at either end is never drawn or counted. No row at all
  in the whole range is S10; with a country filter set, the page adds the note the text report
  already gives for that case. The headline follows
  the number of complete weeks: none → S10's "a few days" message; 1–3 → the visits over those
  weeks, named as such ("23 visits in the last 2 weeks"); 4–7 → the last 4 weeks, without a
  comparison; 8 or more → the comparison below.
- **Weekly values:** visits and times shown are the sums of the week's daily values; a weekly
  **position** is the average of the daily positions **weighted by impressions** (as
  `bing_query.py` already does for Bing), never a sum.
- **"The last 4 weeks"** everywhere on the page = the last 4 complete weeks; "before" = the 4
  complete weeks before those. One window for the headline, the key-search moves and both tables.
- **A key search on Google** is one exact query text, fetched with **one request per key
  search** (`query()` joins all its filters with "and", so several key searches in one request
  would match nothing). The text is sent lowercased, because Search Console appears to report queries in
  lowercase (a probe item);
  whether its exact-match operator is case-sensitive is a probe item, and no case rule is claimed
  until the probe answers it. The variant grouping the text report uses (`_lang_normalize.py`) is
  not used for Google charts, so a Google chart always shows one fixed search. An owner who cares
  about a variant adds it as its own key search.
- **A key search on Bing** comes from the history: one point per run date (each row is a
  rolling ~6-month snapshot, not a week), taking that date's row whose window and country match
  the latest row, and, when a date has no such row, that date's row with the most impressions
  (the text trend, `_history.print_trend`, likewise falls back to a differing row). Where the
  window or country differs from the previous point, the line breaks with a ‡ (the text trend's
  ‡ rule). Each run stored the variant
  Bing matched best (`query` column); when it changes between runs, the line breaks there and the
  card names the query each part measures (the text trend's ≠ rule). A Bing card shows the line
  and the latest position and **claims no move**: the weekly rules below are for Google's daily
  data only.
- **A week with too little data** for a key search (under 10 impressions, the tracker's existing
  threshold) is drawn hollow and never used for a move.
- **"Moved up / down"** for a key search compares its weighted position over the last 4 weeks
  with the 4 before, using only weeks that are not hollow; each side needs at least 2 such weeks.
  Positions shown on the page are whole numbers (the weighted averages rounded); a move is
  measured as d = rounded before − rounded now (positive = better). It counts when d is at least
  1 place either way: "up d places" for d > 0, "down |d| places" for d < 0, so a card's numbers
  always agree with each other. Otherwise (d = 0) "no clear change"; too few weeks is "too
  little data to tell". The card and the headline use this same rule, **for Google only**.
- **The headline percentage** appears only when both 4-week sides have at least 20 visits;
  otherwise the sentence gives the two numbers without a percentage ("12 visits in the last 4
  weeks, 7 the 4 weeks before"); with none before, "12 visits in the last 4 weeks, none in the 4
  weeks before"; with none in either, "no visits from Google in the last 8 weeks". The second
  half of the headline counts every outcome that occurred, Google key searches only, and leaves
  out only the ones with a count of 0: "3 of your 5 key searches moved up, 1 moved down, 1 had
  too little data to tell"; "none of your 5 key searches moved: 3 no clear change, 2 too little
  data to tell".
- **Settings:** Google charts are re-fetched whole on every build with **today's** settings
  (property, country filter), so a changed setting redraws the whole chart consistently; the page
  states the settings ("Counting: searches from Switzerland"). The country filter applies to
  Google only: Bing history is always stored worldwide over Bing's rolling period, so Bing
  lines do not break when it changes. A ‡ break on a Bing line marks only a change in Bing's
  own stored `window` or `country`.
- **Property:** the domain property `sc-domain:<domain>`, as the tracker uses. If Google refuses
  it, the report lists the account's properties (`sites().list`) and uses a URL-prefix property
  for the same domain if there is one, saying on the page which address it counts.

## Requirements — scenarios

"The owner asks" means any wording, e.g. *"show me my Google report"*.

**S1 — First look, no history yet.** A site has been in Search Console for months; the tracker
was set up today. **Then** the page opens at once with visits and times shown per complete week
over up to 16 months, and each key search's position over the last 3 months — all from Google
directly. One line says the Bing section fills in from next week.

**S2 — The headline.** **Then** the first line answers "how am I doing?" in one sentence, per the
counting rules: *"412 visits from Google in the last 4 weeks, 18% more than the 4 weeks before.
3 of your 5 key searches moved up, 1 moved down, 1 had too little data to tell."* No "impressions", "CTR" or "SERP" in it.

**S3 — A key search over time.** A search averaged position 12 over the 4 weeks before and 8
over the last 4. **Then** its chart shows the line moving towards the top (position 1 at the
top) and the card says "about 8 now, up 4 places from the 4 weeks before".

**S4 — Too little data.** A key search was shown 4 times in a week. **Then** that week is hollow;
if too few weeks remain, the card says "too little data to tell" and the headline counts it as
such.

**S5 — A changed setting.** The owner changed the country filter in September. **Then** every
Google chart is redrawn with the new filter from the start and the page names the filter; the
Bing section is unaffected (Bing is always counted worldwide).

**S6 — Just below page 1.** Searches (any, not only key searches) averaging a position above 10
and up to 20 over the last 4 weeks, shown at least 5 times. **Then** a table lists each with the
page Google shows most for it, plus "+N more" when there are several. Positions up to 10 are on
page 1 and are not listed here, although the text report's striking-distance range (8–20)
includes 8–10. With fewer than 4 complete weeks, the table says "not enough complete weeks yet"
(so does S7's).

**S7 — Shown often, rarely clicked.** A page on page 1 (position ≤ 10) shown at least 20 times in
the last 4 weeks, with under 2% of those showings clicked (the text report's existing rule).
**Then** it is listed as "worth a look", with the instruction to check the live result first,
not as "rewrite the title".

**S8 — Bing.** If Bing is connected, a Bing section shows the key searches from the history, with
the note that the tracker records Bing as a rolling ~6-month average, so its lines move slowly;
where Bing matched a different variant from one week to the next, the line breaks there. If not, one line
says so and how to ask for it — never an empty chart.

**S9 — Google sign-in expired.** A build saves what it fetched from Google next to the page (a
small data file), together with the settings it used (property, country, key searches), the
dates it covers and when it was fetched — and replaces the saved file only when every **required**
Google request of that build succeeded: the site-wide dates, each key search, and the S6 query
and S7 page lists. The S6 page drill-downs are optional: a failed one is saved as "page unknown"
and does not hold the refresh back. Reaching Google through the URL-prefix fallback counts as
success. **When** a later fetch fails, the page is rebuilt from the saved
data, shown with the settings and dates it was fetched with, and the top says what happened:
for a sign-in failure (the credentials path `gsc_query.py` already recognises), "Google's
numbers could not be refreshed; these are from <date>. Say *reconnect Google*"; for any other
failure (a refused property, a quota limit), "Google's numbers could not be refreshed (<short
reason>); these are from <date>" with no reconnect advice. With no saved data yet, the Google
charts are left out and the same two messages say "could not be loaded" instead. A failed page
drill-down for one S6 search does not count as a failed build: that row shows "page unknown",
as the text report already degrades. Nothing waits for a browser (`--no-browser`).

**S10 — A brand-new site.** Search Console was verified two days ago. **Then** the page says Google
needs a few days to report, with no empty or zero-filled charts.

**S11 — A key search with no data at all.** Google returns no rows for it in 3 months. **Then**
its card says "No data from Google for this search in the last 3 months" instead of a chart —
not "you are not shown": Google leaves out rare searches for privacy, so an empty answer does
not prove the site never appeared. If the history shows Google matching a variant of it
(`query` column, `gsc` rows), the card names that variant as a past match, with its date and, when they
differ from today's, its settings, and offers to track it: "Your check on 12 Sept matched 'ai
treffen münchen' — say *track it* to add it." It never claims the site is shown for it now.

**S12 — No key searches known.** The owner asks for the report, and neither the request, the
weekly job nor the history names any key search for this site. **Then** the page shows the
site-wide charts and tables and says: "Tell me the searches that matter to you and I'll track
them here."

**S13 — Several sites.** An owner tracks two sites. **Then** each has its own page and data file,
and asking for "my Google report" with more than one site asks which one.

**S14 — Private, and readable everywhere.** One local file: no outside scripts, fonts or trackers,
nothing uploaded. Readable in light and dark mode and at phone width. Every chart has its numbers
as a text table.

**S15 — Kept fresh.** When weekly tracking is on, `track.sh` rebuilds the page after each weekly
run under the same file name, so a saved link shows the latest week. Otherwise it is rebuilt
whenever the owner asks.

**S16 — An older weekly job.** A job installed before per-site settings existed (commit
`0b8a84e`) has no country entry in its job file, and the owner's `.env` says
`GSC_COUNTRY=deu`. **Then** an on-demand report counts only searches from Germany, exactly as the
weekly job does — a missing entry means "use `.env`", an empty entry means "none".

## Decisions (owner, 2026-09-27: every one as recommended)

- **D1 — Where the trends come from:** Google's own data, fetched at build time; Bing from local
  history.
- **D2 — One page or two:** a separate "Google & Bing report", linked to and from the AI report.
- **D3 — Time span:** site-wide charts over up to 16 months; key searches over the last 3 months
  (weekly points).
- **D4 — Headline:** visits from Google first, key-search moves second.
- **D5 — Charts:** plain SVG written by the script; no JavaScript, works offline in current
  browsers.
- **D6 — Delivery:** rebuilt after every weekly run and on request.

## Design

- **Command:** a new `search_report.py <domain>`, the same shape as `geo_check.py <domain>
  --report` (`insights.py` requires `--domain` and `--keywords`; a report asked for in plain
  words must not).
- **Site settings file:** `schedule_tracking.sh` also writes
  `~/.config/gsc-insights/sites/<site>.json` (key searches, country, history file) when it
  creates or changes a weekly job, so an on-demand build knows the job's settings. A job created
  before this change has no such file; its settings live only in its launchd job file
  (`~/Library/LaunchAgents/`, named by `schedule_tracking.sh`'s `plist_for`), so an on-demand
  build reads that file read-only as the next fallback: the full domain in its arguments must
  equal the requested domain after the scheduler's own lower-casing (so `Example.COM` matches
  `example.com`, and two domains whose file names collide do not), and its keywords,
  `GSC_HISTORY_CSV` and `GSC_COUNTRY` are used exactly as `track.sh` would use them: an entry that
  is **missing** (jobs from before `0b8a84e` have none) falls back to `.env`, and an entry that is
  **empty** means the default history file and no country filter (S16). Settings, in order of
  precedence: command-line flags; else the settings file; else the matching launchd job file;
  else, from the history: take the latest date with `gsc` rows for the site, group that date's
  rows by (window, country), and pick one group deterministically — window 28 first (the
  tracker's default, a preference, not proof of the tracker), then the most distinct keywords,
  then the shorter window (a blank or legacy window last), then the country code in
  alphabetical order (a blank country first), so every tie ends in exactly one group; the keywords **and** country both come from that one group
  (named on the page as "from your last check on <date>"); else S12. `track.sh` passes its own settings explicitly.
  `schedule_tracking.sh remove` deletes the site's settings file along with the job.
- **Output:** `~/.config/gsc-insights/reports/<site>/google.html` (stable name, S15) and
  `google-data.json` beside it (S9). It prints the path and opens nothing; the skill has the
  assistant open it.
- **Google fetches** (reusing `gsc_query.py`'s authenticated `query()`):
  - site-wide charts: one `["date"]` request for up to 16 months;
  - key-search cards: one `["date", "query"]` request per key search, 3 months;
  - S6: one `["query"]` request for the last 4 weeks, then one `["page"]` request filtered to each
    listed query (a new loop over the existing single-query drill-down);
  - S7: one `["page"]` request for the last 4 weeks; no drill-down.
  `query()` gains `startRow` paging (new; it has none today) for any response that reaches the
  row limit.
- **Page:** headline; "How to read this"; visits per week; times shown per week as its own chart
  (never two scales on one chart); one card per key search on one shared position scale; the
  S6 and S7 tables; Bing section or its one line; a link to the newest AI report page found at
  build time (`geo/reports/<site>/`, one file per run) or, if the AI check is not set up, one line
  saying so; the settings line.
- **AI report link back:** `geo_check.py`'s report page gains a relative link to
  `reports/<site>/google.html` when that file exists (a change to `geo_check.py`). Because AI
  pages are static files written per AI run, `search_report.py`, after writing `google.html`,
  rebuilds the newest AI page locally with `geo_check.build_report(domain)` — from the saved AI
  history, with no AI request — so the link appears without waiting for the next AI check. It
  skips this when the AI check is not set up.
- **`track.sh`:** the report step runs after `geo_check.py` (so the AI link is current); its exit
  status goes into the existing `problems` list like every other step and never replaces the
  Google step's status or the history exit code 4.
- **Charts:** SVG from the script, one colour, 2px lines, end-point labels, a wide and a narrow
  drawing per chart swapped by a CSS media query, the browser's own tooltip (SVG `<title>`) per
  week, and "See the numbers" tables.
- **The mock-up** shows the layout the owner approved; its counting (`movement()`, the headline
  sum) and its wording ("people came from Google", "How people find you on Google") predate these
  rules and are not the specification: the page says "visits".

## To verify before build (a short probe on one real site, read-only, with the owner's OK)

- The `["date"]` and `["date", "query"]` responses for this property: how far back they go,
  the latest date, the time zone of the dates, whether queries come back in lowercase, whether the exact-match query filter is
  case-sensitive,
  how to read the latest finished date (the API's data-freshness answer or a fixed lag), and whether a key search known to be rare comes back empty (the privacy omission
  behind S11). Record the answers here; if 16 months or exact matching does not hold, adjust
  S1/D3.
- Whether the row limit is reached for 16 months of `["date"]` (unlikely: about 480 rows).

## Judgment calls (not verified facts)

- That owners read a position chart with 1 at the top correctly (the owner judged the mock-up
  "looks right").
- The 20-visit floor for a percentage and the 1-place threshold for a move: small numbers swing,
  and a percentage on 3 → 6 visits would say "100% more" about three extra visits.
- Exact-match key searches over variant groups: steadier charts, at the cost of the owner naming
  variants separately.

## Out of scope

- Competitor comparison (the SERP add-on stays separate); email or scheduled delivery; merging
  with the AI report (D2).

## PLAN round 1 — dispositions

| # | Source | Finding | Disposition |
|---|---|---|---|
| C1 | Codex BUG | fetches cannot populate S6/S7 (no pages, only key queries) | fixed: Design adds the query list, per-query page drill-down and page list |
| C2 | Codex BUG | summing daily positions | fixed: counting rules (impression-weighted) |
| C3 | Codex RISK | Google API assumptions; clicks ≠ people | fixed: "visits" wording; probe step before build |
| C4 / F3 | Codex RISK, fresh-eyes BUG | incomplete weeks | fixed: complete weeks only |
| C5 | Codex RISK | country change vs refetched data | fixed: Google refetched with today's settings; ‡ only for history lines (S5) |
| C6 | Codex RISK | keyword identity changes | fixed: exact-match key searches |
| C7 | Codex RISK | history alone cannot configure the command | fixed: precedence list; S12 |
| C8 / F4 | Codex RISK, fresh-eyes BUG | low-data endpoints still produce moves; "moved up" undefined | fixed: counting rules; the mock-up is not the spec |
| C9 | Codex BUG | wrong claims: `insights.py --out`, history writers, ‡ location | fixed in Context and S5 |
| F1 | fresh-eyes BUG | S9 vs no site-wide totals in history | fixed: saved data file (S9) |
| F2 | fresh-eyes BUG | headline divide-by-zero, tiny numbers | fixed: 20-visit floor |
| F5 | fresh-eyes BUG | "almost on page 1" reused 8–20 | fixed: 11–20 (S6) |
| R1 | fresh-eyes RISK | two properties | fixed: domain property, as the tracker |
| R2 | fresh-eyes RISK | Bing lines look flat | fixed: note in S8 |
| R3 | fresh-eyes RISK | key search with no data | fixed: S11 |
| R4 | fresh-eyes RISK | time zones | fixed: counting rules + probe |
| N1 | fresh-eyes NIT | three windows unreconciled | fixed: one "last 4 weeks" |
| — | Codex UNVERIFIABLE | Bing API granularity; browser/tooltip behaviour; approvals | Bing: stated as the tracker's current source, not an API limit; browser: checked by rendering (Status); approvals: quoted with dates |

## PLAN round 2 — dispositions

| # | Source | Finding | Disposition |
|---|---|---|---|
| C2-1 | Codex BUG | partial leading weeks still count | fixed: all seven days inside the fetched range; <8 weeks = no comparison |
| C2-2 | Codex BUG | S5 promised a Bing break the country filter cannot cause | fixed: country applies to Google only; ‡ only for Bing's own window/country |
| C2-3 | Codex BUG | Bing history switches variants; "one fixed search" too broad | fixed: exact match scoped to Google; Bing line breaks on a stored-query change (≠ rule) |
| C2-4 | Codex RISK | on-demand settings undefined | fixed: `sites/<site>.json` from `schedule_tracking.sh`; precedence list |
| C2-5 | Codex RISK | saved data relabelled with new settings; partial failures | fixed: saved with its settings and dates; replaced only after every request succeeds |
| C2-6 | Codex RISK | empty response ≠ never shown | fixed: S11 wording; probe covers the privacy omission |
| C2-7 | Codex BUG | Context overstated the drill-down | fixed: single `--query` today; the loop is new work |
| C2-8 | Codex BUG | "first visits" wrong for 0/0 or earlier visits | fixed: explicit wording for none-before and none-at-all |

## PLAN round 3 — dispositions

| # | Source | Finding | Disposition |
|---|---|---|---|
| C3-1 | Codex BUG | "last 4 weeks" promised with 1–3 complete weeks | fixed: headline branches by complete weeks (0 / 1–3 / 4–7 / 8+) |
| C3-2 | Codex RISK | existing weekly jobs have no settings file | fixed: read-only fallback to the matching launchd job file, exact domain match |
| C3-3 | Codex BUG (outside scope) | S9 with no saved data promised a date | fixed: its own "could not be loaded" message |

## PLAN round 4 — dispositions

| # | Source | Finding | Disposition |
|---|---|---|---|
| C4-1 | Codex BUG | exact domain equality misses a job set up with other capitals | fixed: compare after the scheduler's lower-casing; empty values keep `track.sh`'s meaning |

## PLAN round 5 — clean (Codex). Final full read (Claude Opus) — dispositions

| # | Source | Finding | Disposition |
|---|---|---|---|
| FR-B1 | final read BUG | a missing job-file entry was read as "none"; `track.sh` falls back to `.env` | fixed: missing vs empty in Design; S16 |
| FR-B2 | final read BUG | several key searches in one request match nothing (`query()` joins filters with "and"); case sensitivity | fixed: one request per key search, lowercased; case is a probe item, no rule claimed |
| FR-B3 | final read BUG | weeks before the site had data counted as zeros; "latest date" undefined | fixed: range from the first row to the finished date; empty days inside are 0; no rows = S10 |
| FR-B4 | final read BUG | Bing points and moves undefined | fixed: one point per run date, same-config row; no Bing moves; headline counts Google only |
| FR-R1 | final read RISK | every failure said "reconnect"; one bad drill-down blocked every refresh; URL-prefix detection | fixed: sign-in vs other messages; drill-down degrades; `sites().list` |
| FR-R2 | final read RISK | the AI report has no stable file; link back needs a `geo_check.py` change | fixed: newest AI page at build time; `geo_check.py` change listed |
| FR-R3 | final read RISK | `track.sh` placement and failure handling | fixed: after `geo_check.py`; into `problems`; never masks other statuses |
| FR-R4 | final read RISK | drill-down named twice; several pages per query | fixed: one sentence per table; top page plus "+N more" |
| FR-R5 | final read RISK | headline hid searches that moved down | fixed: names up, down and too-little-data |
| FR-R6 | final read RISK | exact match empty while the text trend shows a variant | fixed: S11 names the variant and offers to track it |
| FR-R7 | final read RISK | history fallback ignored the rows' country and ad-hoc runs | fixed: rows' country; prefer 28-day tracker rows |
| FR-N1 | final read NIT | tables with fewer than 4 complete weeks | fixed: "not enough complete weeks yet" |
| FR-N2 | final read NIT | header and status drift | fixed |
| FR-N3 | final read NIT | mock-up wording says "people" | fixed: Design says it is superseded |
| FR-N4 | final read NIT | 10–11 gap; rounding | fixed: "above 10, up to 20"; whole-number rule for moves |
| FR-N5 | final read NIT | `remove` left the settings file | fixed: deleted with the job |

## PLAN round 6 — dispositions

| # | Source | Finding | Disposition |
|---|---|---|---|
| C6-1 | Codex BUG | "N ≥ 1" excluded every downward move | fixed: signed d, counts when \|d\| ≥ 1 |
| C6-2 | Codex BUG | Bing selection dropped differing rows, so ‡ could never show | fixed: fallback to the date's row with most impressions; ‡ where the config differs |
| C6-3 | Codex RISK | one failing drill-down blocked the cache forever | fixed: only required requests gate the refresh; drill-downs are optional |
| C6-4 | Codex RISK | the first Google page got no AI link back | fixed: rebuild the newest AI page locally, no AI request |
| C6-5 | Codex RISK | history fallback could mix two configurations of one day | fixed: deterministic group; keywords and country from that group |
| C6-6 | Codex RISK | "none moved clearly" hid too-little-data | fixed: counts every non-zero outcome |
| C6-7 | Codex RISK | a past variant match presented as current | fixed: dated past match, never "shown now" |

## PLAN round 7 — dispositions

| # | Source | Finding | Disposition |
|---|---|---|---|
| C7-1 | Codex RISK | history group selection could still tie | fixed locally: distinct keywords, then shorter window (blank last), then country (blank first); round 7 had no BUG, so no further round; checked by the wording pass only |

**Gate cost:** 7 Codex rounds, 1 fresh-eyes (Sonnet) pass, 1 final full read (Opus), 1 wording pass;
findings per round (BUG/RISK/NIT): r1 8/10/1 (Codex + fresh-eyes), r2 5/3/0, r3 2/1/0, r4 1/0/0,
r5 0/0/0, final read 4/7/5, r6 2/5/0, r7 0/1/0.
