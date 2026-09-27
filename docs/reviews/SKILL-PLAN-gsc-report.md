# Plan — a visual Google & Bing report in search-console-insights

Draft 3: requirements, the owner's decisions D1–D6, the counting rules and a design, revised
after PLAN round 1 (Codex: 3 BUG, 6 RISK; fresh-eyes: 5 BUG, 4 RISK, 1 NIT — dispositions at
the end). No product code yet.

## Status

| Step | State | Evidence |
|---|---|---|
| Requirements as scenarios (this document) | draft 3 | this document |
| Decisions D1–D6 | **decided** (owner, 2026-09-27: all as recommended) | this document |
| Mock-up page with invented numbers, for a visual check | done; owner's visual check 2026-09-27: "looks right" | `docs/reviews/gsc-report-mockup/mockup.html` (from `make_mockup.py`); checked in light and dark mode, at phone and desktop width |
| PLAN gate (Codex only: ollama-cloud out of credits until ~2026-09-28; plus a fresh-eyes pass) | round 1 done (19 findings, all addressed below); round 2 next | `a433630`…`d29b3de` reviewed; this draft answers it |
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
  months. `gsc_query.py` already fetches striking-distance queries, a page for each (its
  per-query `["page"]` drill-down), and low-CTR pages.
- **Bing**: the tracker uses Bing Webmaster Tools' roughly 6-month rolling aggregate
  (`SKILL.md`, Bing section); its trend on this page comes from local history.
- **The weekly job** (`schedule_tracking.sh`) passes the domain, the key searches, the history
  file and the country filter to `track.sh`, which queries the domain property
  `sc-domain:<domain>` over 28 days.

## Counting rules (these decide every number on the page)

- **Visits** = Search Console clicks (someone clicked the site in Google's results). The page
  says "visits from Google", not "people": one person can visit twice.
- **Weeks** run Monday–Sunday in the time zone Google reports dates in (to verify; reportedly
  Pacific Time). A week counts only when it is **complete**: its Sunday is on or before the
  latest date Google has data for. The unfinished current week is never drawn or counted.
- **Weekly values:** visits and times shown are the sums of the week's daily values; a weekly
  **position** is the average of the daily positions **weighted by impressions** (as
  `bing_query.py` already does for Bing), never a sum.
- **"The last 4 weeks"** everywhere on the page = the last 4 complete weeks; "before" = the 4
  complete weeks before those. One window for the headline, the key-search moves and both tables.
- **A key search** is the exact query text (case-insensitive exact match in the API request).
  The variant grouping the text report uses (`_lang_normalize.py`) is not used for charts: a
  chart always shows one fixed search, so a move never compares two different searches. An owner
  who cares about a variant adds it as its own key search.
- **A week with too little data** for a key search (under 10 impressions, the tracker's existing
  threshold) is drawn hollow and never used for a move.
- **"Moved up / down"** for a key search compares its weighted position over the last 4 weeks
  with the 4 before, using only weeks that are not hollow; each side needs at least 2 such weeks.
  A change of at least 1 whole place counts as a move; less is "no clear change"; too few weeks
  is "too little data to tell". The card and the headline use this same rule.
- **The headline percentage** appears only when both 4-week sides have at least 20 visits;
  otherwise the sentence gives the two numbers without a percentage ("12 visits in the last 4
  weeks, 7 the 4 weeks before"), and with 0 before it says these are the first visits. Searches
  with too little data are named as such, not counted as moved ("3 of your 5 key searches moved
  up; 1 had too little data to tell").
- **Settings:** Google charts are re-fetched whole on every build with **today's** settings
  (property, country filter), so a changed setting redraws the whole chart consistently; the page
  states the settings ("Counting: searches from Switzerland"). The ‡ break applies only to
  history-based lines (Bing), where rows were measured with different windows or countries.
- **Property:** the domain property `sc-domain:<domain>`, as the tracker uses. If only a
  URL-prefix property is available, the page says which address it counts.

## Requirements — scenarios

"The owner asks" means any wording, e.g. *"show me my Google report"*.

**S1 — First look, no history yet.** A site has been in Search Console for months; the tracker
was set up today. **Then** the page opens at once with visits and times shown per complete week
over up to 16 months, and each key search's position over the last 3 months — all from Google
directly. One line says the Bing section fills in from next week.

**S2 — The headline.** **Then** the first line answers "how am I doing?" in one sentence, per the
counting rules: *"412 visits from Google in the last 4 weeks, 18% more than the 4 weeks before.
3 of your 5 key searches moved up."* No "impressions", "CTR" or "SERP" in it.

**S3 — A key search over time.** A search averaged position 12 over the 4 weeks before and 8
over the last 4. **Then** its chart shows the line moving towards the top (position 1 at the
top) and the card says "about 8 now, up 4 places from the 4 weeks before".

**S4 — Too little data.** A key search was shown 4 times in a week. **Then** that week is hollow;
if too few weeks remain, the card says "too little data to tell" and the headline counts it as
such.

**S5 — A changed setting.** The owner changed the country filter in September. **Then** every
Google chart is redrawn with the new filter from the start (the page names the filter); a Bing
line built from older history shows a ‡ break at the change instead of one line across it.

**S6 — Just below page 1.** Searches (any, not only key searches) averaging position 11–20 over
the last 4 weeks, shown at least 5 times. **Then** a table lists each with the page Google shows
for it (the existing per-query page drill-down). Positions 8–10 are already on page 1 and are
not listed here, although the text report's striking-distance range includes them.

**S7 — Shown often, rarely clicked.** A page on page 1 (position ≤ 10) shown at least 20 times in
the last 4 weeks, with under 2% of those showings clicked (the text report's existing rule).
**Then** it is listed as "worth a look", with the instruction to check the live result first,
not as "rewrite the title".

**S8 — Bing.** If Bing is connected, a Bing section shows the key searches from the history, with
the note that Bing reports a rolling ~6-month average, so its lines move slowly. If not, one line
says so and how to ask for it — never an empty chart.

**S9 — Google sign-in expired.** Every build first saves what it fetched from Google next to the
page (a small data file). **When** a later fetch fails, the page is rebuilt from that saved data,
and the top says plainly: "Google's numbers could not be refreshed; these are from <date>. Say
*reconnect Google*." With no saved data yet, the Google charts are left out with the same
message. Nothing waits for a browser (`--no-browser`).

**S10 — A brand-new site.** Search Console was verified two days ago. **Then** the page says Google
needs a few days to report, with no empty or zero-filled charts.

**S11 — A key search with no data at all.** Google has never shown the site for it in 3 months.
**Then** its card says "not showing up for this search yet" instead of a chart.

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
  words must not). Key searches, in order of precedence: `--keywords`; else what the weekly job
  passes (`track.sh` calls it with the job's keywords, history file and country); else the key
  searches of the site's most recent tracker run in the history, named on the page; else S12.
- **Output:** `~/.config/gsc-insights/reports/<site>/google.html` (stable name, S15) and
  `google-data.json` beside it (S9). It prints the path and opens nothing; the skill has the
  assistant open it.
- **Google fetches** (reusing `gsc_query.py`'s authenticated `query()`): `["date"]` for up to 16
  months; `["date", "query"]` with the key searches as exact-match filters for 3 months; and, for
  the last 4 weeks, the query list (S6), a page per listed query (the existing drill-down) and
  the page list (S7). Paged with `startRow` if a response hits the row limit.
- **Page:** headline; "How to read this"; visits per week; times shown per week as its own chart
  (never two scales on one chart); one card per key search on one shared position scale; the
  S6 and S7 tables; Bing section or its one line; a link to the AI report; the settings line.
- **Charts:** SVG from the script, one colour, 2px lines, end-point labels, a wide and a narrow
  drawing per chart swapped by a CSS media query, the browser's own tooltip (SVG `<title>`) per
  week, and "See the numbers" tables.
- **The mock-up** shows the layout the owner approved; its counting (`movement()`, the headline
  sum) predates these rules and is not the specification.

## To verify before build (a short probe on one real site, read-only, with the owner's OK)

- The `["date"]` and `["date", "query"]` responses for this property: how far back they go,
  the latest date, the time zone of the dates, and whether an exact-match query filter behaves as
  assumed. Record the answers here; if 16 months or exact matching does not hold, adjust S1/D3.
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
