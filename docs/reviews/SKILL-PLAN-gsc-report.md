# Plan — a visual Google & Bing report in search-console-insights

Draft 1: requirements and open decisions only. No design is fixed and no code is written until
the owner has answered the decisions below and checked the scenarios.

## Status

| Step | State | Evidence |
|---|---|---|
| Requirements as scenarios (this document) | draft, for the owner to check | — |
| Decisions D1–D6 | **open, owner** | — |
| Mock-up page with invented numbers, for a visual check | not started (after D1–D6) | — |
| PLAN gate (Codex; ollama-cloud when it has credit) | not started | — |
| Build | not started | — |
| DIFF gate | not started | — |
| Live check on a real site | not started | — |
| PR | not started | — |

## Context

Today an owner sees their Google and Bing results only as text: a Markdown report
(`gsc_query.py` / `insights.py --out report.md`) and, over time, a text trend with ▲/▼ per key
search (`track.sh` → `_history.py`). The one page an owner can simply open and read is the AI
report (`geo_check.py --report`, PR #122): one plain answer at the top, simple tables, detail
folded away. Owners asked for that page "in their own words" and it works; this plan gives
Google and Bing the same kind of page, with pictures of how things change over time.

What data exists:

- **Local history** (`~/.config/gsc-insights/history.csv`): one row per key search per run —
  date, site, source (`gsc`, `bing`, …), keyword, query, position, impressions, clicks, window,
  country. It builds up only as the tracker runs (weekly, if the owner opted in).
  It holds **no site-wide totals**.
- **Google, live**: the Search Console API returns daily clicks, impressions and position for
  up to 16 months (`dimensions: ["date"]`, or `["date", "query"]` per search), about 2–3 days
  behind. So a chart does not have to wait for local history to build up.
- **Bing, live**: Bing Webmaster Tools gives roughly a 6-month aggregate, not a daily series; its
  trend comes from local history.

## Requirements — scenarios

Each is written so the owner can check it without reading code. "The owner asks" means any
wording, e.g. *"show me my Google report"*, *"how is my site doing on Google?"*.

**S1 — First look, no history yet.** A site has been connected to Search Console for months, but
the tracker was only set up today. The owner asks for the report. **Then** the page opens at
once and already shows, from Google directly: people who came from Google per week over the
last 16 months, and how often the site was shown. Each key search shows its position over the
last 3 months. A short note says that Bing and the weekly history start today.

**S2 — The headline.** The owner opens the page in October. **Then** the first line answers
"how am I doing?" in one sentence, for example: *"412 people came from Google in the last 4
weeks, 18% more than the 4 weeks before. 3 of your 5 key searches moved up."* No jargon: no
"impressions", "CTR" or "SERP" in the headline (the page explains "shown" once, lower down).

**S3 — A key search over time.** "bakery near the station" was at position 14 in August and is
at 8 now. **Then** its small chart shows the line moving towards the top (position 1 is the top
of the chart, so better is up), with "14 → 8, up 6 places" beside it.

**S4 — Too little data to read.** A key search was shown only 4 times last week. **Then** that
week's point is marked as "too few searches to tell" and no "up" or "down" is claimed for it
(the tracker's existing threshold: under 10 impressions is noise).

**S5 — Measured differently.** The owner changed the country filter in September. **Then** the
charts mark that date ("measured differently from here") instead of drawing one line across
the change as if it were a real move — the same ‡ rule the AI report uses.

**S6 — Almost on page 1.** Two searches sit at positions 11 and 13 with the site shown often.
**Then** a short table lists them as "almost on page 1", with the page that shows up for each,
as the text report already does.

**S7 — Shown but rarely clicked.** A page is shown 900 times and clicked 3 times. **Then** it is
listed as "worth a look", not as "rewrite the title": the existing rule is to check the live
search result first.

**S8 — Bing.** If Bing is connected, **then** a Bing section shows the same key searches from the
weekly history. If it is not, **then** one line says so and how to ask for it — never an empty
chart.

**S9 — Google sign-in expired.** The weekly run finds Google's sign-in expired. **Then** the page
still builds from the local history, says plainly at the top that Google's latest numbers could
not be fetched and what to do, and never hangs waiting for a browser (the `--no-browser` rule).

**S10 — A brand-new site.** Search Console was verified two days ago. **Then** the page says
Google needs a few days to report and shows no empty or zero-filled charts.

**S11 — Private, and readable everywhere.** The page is one local file: no outside scripts,
fonts or trackers, nothing uploaded. It reads well in light and dark mode and at phone width.
Every chart has its numbers available as text (for screen readers, and for anyone who prefers
numbers).

**S12 — Kept fresh.** After each weekly run, the page is rebuilt, so the owner's saved link
always shows the latest week.

## Decisions for the owner (each with a recommendation)

- **D1 — Where the trends come from.** (a) Google's own 16-month daily data, fetched when the page
  is built, plus the local history for Bing — charts are full on day one (S1). (b) Local history
  only — simpler, but charts stay empty for weeks. *Recommended: (a).*
- **D2 — One page or two.** (a) A separate "Google & Bing report", linked to and from the AI
  report. (b) One combined page. *Recommended: (a)* — each page keeps one plain answer at the
  top; one page with two headlines answers neither well.
- **D3 — Default time span.** *Recommended:* site-wide chart over 16 months, key searches over the
  last 3 months (weekly points), because 16 months of daily position lines would be noise.
- **D4 — What the headline counts.** (a) Visitors from Google (clicks), with key searches moved
  as the second half of the sentence. (b) Positions first. *Recommended: (a)* — visitors are what
  an owner cares about; positions explain them.
- **D5 — How charts are drawn.** (a) Plain SVG written by the Python script: no JavaScript, no
  download, works offline and in any browser. (b) A JavaScript chart library: hover details,
  but an outside script (conflicts with S11). *Recommended: (a).*
- **D6 — How the owner gets it.** (a) Rebuilt after every weekly run (S12) and on request.
  (b) Only on request. *Recommended: (a).*

## Judgment calls (not verified facts)

- That owners will read a chart of positions correctly with position 1 at the top. The mock-up
  step exists to test exactly this with the owner before anything is built.
- That 3 months is the right default for key searches: long enough to show a direction, short
  enough to stay readable.

## To verify before design

- The Search Console API's `date` dimension together with the tracker's existing country
  filter returns what S1 needs, within the current quota.
- Whether Bing's API offers anything beyond the ~6-month aggregate that the tracker uses today.

## Out of scope

- Comparing against competitors (the optional SERP add-on stays separate).
- Email or scheduled delivery of the page; the owner opens it or asks for it.
- Merging with the AI report (see D2).
