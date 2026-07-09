---
name: search-console-insights
description: >
  Pull and act on Google Search Console DATA for a verified site — the monitor &
  optimize step that sits downstream of search-console-setup (which only registers
  the property). Uses the free GSC Search Analytics API (OAuth desktop flow,
  read-only) to report where target keywords rank, striking-distance queries (avg
  position ~8-20 = fastest Top-10 wins), and high-impression/low-CTR pages that need
  title/meta rewrites. Optional free competitive-SERP layer (Serper, fallback SerpApi)
  shows who actually holds the Top 10 for a keyword you don't rank for yet, plus an
  optional Bing Webmaster Tools source (simple API key) as a Copilot/ChatGPT-visibility
  proxy. Ships Python scripts (scripts/gsc_query.py, scripts/serp_check.py,
  scripts/bing_query.py); needs one-time API creds. On first use it runs a guided
  ONBOARDING for non-technical owners — explains the benefit, walks the human-only
  Google-console clicks, confirms the connection, then teaches how to use it. Trigger
  phrases: "show my Search Console data", "GSC insights", "GSC data", "connect my
  Search Console", "connect GSC", "set up Search Console insights", "start tracking my
  rankings", "onboard Search Console", "top queries", "where do I rank", "where do we
  rank for", "striking distance keywords", "quick SEO wins", "why is my CTR low", "which
  pages to optimize", "competitor Top 10 for", "who ranks for", "am I in the Top 10
  for", "how do I rank on Bing", "Bing Webmaster data", "Copilot visibility", "ChatGPT
  search visibility", "track my rankings over time", "schedule weekly tracking", "track my
  SEO automatically", "weekly SEO report".
metadata:
  version: 1.3.0
---

# Search Console insights

`search-console-setup` is "set it up once" (verify the property, submit the sitemap,
turn on IndexNow). **This skill is "monitor + act, repeatedly"** — it reads the data
GSC has collected and turns it into the 2–3 highest-leverage moves.

## Capabilities at a glance

| Source | Script | Auth | What you get |
|---|---|---|---|
| **Combined (the default)** | `insights.py` | — | **Google + Bing side by side** per keyword + a nudge to connect any missing free source |
| **Google Search Console** | `gsc_query.py` | OAuth (one-time browser consent) | Real queries + exact avg position, impressions, clicks, CTR over a chosen window; striking-distance queries; high-impression/low-CTR pages. German-market/bilingual sites: pass `--country deu` (ISO alpha-3; also on `insights.py`) — default numbers are blended across every country, which can mask or fake German positions. Keyword matching folds umlauts/ß ("München" matches rows typed "muenchen") |
| **Live Google SERP** | `serp_check.py` | Serper key (free, optional) | The actual Top-10 for any keyword + where you sit — incl. keywords you don't rank for yet |
| **Bing Webmaster Tools** | `bing_query.py` | API key (free, optional) | Bing query **and page** stats — a Copilot/ChatGPT-visibility proxy; ~6-month aggregate |
| **Trend over time** | `track.sh` + `_history.py` | — | Appends each run to a CSV and prints week-over-week position movement (▲/▼) |
| **Weekly auto-tracking** | `schedule_tracking.sh` | — | Opt-in launchd job (per site) that runs the tracker weekly so history builds unattended |

All **read-only** and on **free tiers** (GSC + Bing free; Serper 2,500 searches free). Built
for a **low-volume** site — see the "Low-volume playbook" below. On first use the agent runs
a guided **onboarding** (next section), so a non-technical owner never touches the terminal.

> **Prerequisite:** the property must be verified in GSC (`search-console-setup`).
> GSC only collects data **forward from verification** — no historical backfill, and a
> ~2–3 day reporting lag. A freshly-verified site will be near-empty; `gsc_query.py`
> says so honestly rather than pretending there's nothing to optimize. Re-run weekly —
> Phase 1 is the part that compounds.

## Onboarding — the agent runs this wizard on first use

**When invoked and the user is NOT yet connected** (no token at
`~/.config/gsc-insights/token.json`), do **not** dump commands. Walk the user through
it like a friendly wizard, in the order below. Assume a non-technical site owner who
has never heard of an "API". Do the heavy lifting yourself; clearly flag the 3 things
only they can do.

### Step 1 — Sell the benefit FIRST (before asking for anything)
In 3–4 plain sentences, tell them what they get and why ~10 minutes is worth it:
- *"Google Search Console is **free** and shows the **real** words people typed into
  Google to find your site, exactly where you rank for each, and how often you get
  clicked — data no guesswork keyword tool has."*
- *"Once connected, I can tell you in seconds: the keywords you're **almost** on page 1
  for (your fastest wins), the pages that get seen but not clicked (a quick title fix),
  and — with a free add-on — who's beating you in the Top 10."*
- *"It's **read-only** and free. The one-time setup is ~10 minutes — I do most of it;
  you do three clicks inside Google's console that I'm not allowed to do for you."*

Then ask **"Want to connect it now?"** and only continue on a yes.

### Step 2 — Check what's already done; ask only for what's missing
So a returning user is never re-onboarded:
- token at `~/.config/gsc-insights/token.json` → **already connected**, skip to Step 5.
- `~/.config/gsc-insights/client_secret.json` exists → creds done; just venv + first run.
- venv at `~/.config/gsc-insights/venv` exists → deps done.

### Step 3 — The human-only steps ( 🧑 **you do this** )
You cannot click inside Google's console. Hand these over **one at a time** and wait —
do not paste all five at once. Reassure them it's one-time. **Console UI labels are
localized** — if the owner's Google account language isn't English, translate the
quoted labels for them (German: *APIs und Dienste → Bibliothek*, *Anmeldedaten →
Anmeldedaten erstellen → OAuth-Client-ID*, *Computeranwendung*, *Testnutzer*):
- 🧑 a. Open https://console.cloud.google.com → create or pick any project.
- 🧑 b. **APIs & Services → Library** → search & **enable "Google Search Console API"**.
- 🧑 c. **APIs & Services → Google Auth Platform → Audience** → add your Google email
       as a **Test user** (the "OAuth consent screen" was renamed Google Auth Platform).
- 🧑 d. **APIs & Services → Credentials → Create credentials → OAuth client ID →
       Desktop app → Create → Download JSON**.
- 🧑 e. Tell me where it downloaded (usually `~/Downloads`).

### Step 4 — Your steps ( 🤖 **I do this** )
- 🤖 Move their JSON to `~/.config/gsc-insights/client_secret.json`.
- 🤖 Build the venv + install deps (see "One-time setup" below).
- 🤖 Run `gsc_query.py` once — **a browser opens for their single consent click**, then
  the token caches and every future run is silent.

### Step 5 — Confirm the connection in plain words
After the first successful run: *"✅ Connected — Google confirms you own `<site>`
(access: `<permissionLevel>`)."* If the property is freshly verified and the report is
near-empty, **say so honestly** — data accrues over days; that's not a failure.

### Step 6 — THEN teach them how to use it (next section). Don't skip this.

## Once connected — how to use it

Tell the user they **never need the command line again**. From now on, in any normal
Claude session, they just ask:

- **Slash command:** `/search-console-insights`
- **Or plain language** (these trigger the skill):
  - *"show my Search Console insights for `<site>`"*
  - *"where do I rank for `<keyword>`?"*
  - *"what are my quick SEO wins?"* / *"striking-distance keywords"*
  - *"which pages get seen but not clicked?"*
  - *"who's in the Top 10 for `<keyword>`?"* (uses the free Serper add-on)
  - *"how do I rank on Bing?"* / *"my Copilot/ChatGPT visibility"* (uses the Bing add-on)
  - *"is my ranking improving?"* / *"track my rankings over time"* (runs the weekly tracker)
  - *"track my rankings automatically / every week"* (offers to schedule it, per site)

**Default behavior (agent):** for the slash command or a general "where do I rank" ask,
run the **combined** view —
`~/.config/gsc-insights/venv/bin/python scripts/insights.py --domain <site> --keywords "…"`.
It auto-detects which sources are connected, shows **Google + Bing side by side** per
keyword, and prints a nudge to connect any missing free source:
- only Google connected → show it + offer the ~2-min Bing key (Copilot/ChatGPT proxy);
- a source connected but the call failed → shown as "⚠️ fetch failed" (do **not** tell them
  to re-set-up — it's a transient error);
- no Serper key → suggest one (free 2,500/mo) for the competitor Top-10.

Run the single-engine scripts (`gsc_query.py` / `bing_query.py`) only when the user wants
one engine's full detail; run `serp_check.py` only when they ask for competitors (it spends
Serper quota); run `track.sh` for the over-time trend. After the first combined view for a
connected site, **offer weekly auto-tracking** (see "Weekly auto-tracking") so the trend
builds itself.

What comes back, in plain terms:
- **Default (free, instant):** Google + Bing position per keyword, side by side, plus
  connect-the-missing-source nudges.
- **Phase 1 (free, instant):** each keyword + its current Google position, the
  near-page-1 *quick wins*, and the *seen-but-not-clicked* pages to retitle.
- **Phase 2 (optional, free):** the live Top 10 for a keyword and where they sit — set
  up a free Serper key once (see Phase 2 below) to unlock it.
- **Bing (optional, free):** the same keyword/position report from Bing — a proxy for
  Copilot/ChatGPT visibility. Even simpler to connect (one API key) — see "Bing
  Webmaster Tools" below.

Re-running **weekly** is the whole point — rankings move, and this report is how they
watch the needle.

## One-time setup (human-in-the-loop)

The agent drafts these; the owner clicks (account + OAuth consent are owner actions).

1. **Enable the API + make an OAuth client** (once per Google account):
   - Google Cloud Console → create/pick a project → **APIs & Services → Library** →
     enable **Google Search Console API**.
   - **APIs & Services → Credentials → Create credentials → OAuth client ID** →
     Application type **Desktop app** → Create → **Download JSON** → save it as
     `client_secret.json` (point at it with `--client-secret` or `$GSC_CLIENT_SECRET`).
   - Add yourself as a **test user**: APIs & Services → **Google Auth Platform** (the
     2024+ name for the OAuth consent screen) → **Audience** tab → **Test users** → Add.
     Without this, consent is blocked for an external app in "Testing".
2. **Create a venv + install deps** (one-time, local — plain `pip install` fails on
   PEP-668 "externally-managed" Python, e.g. Homebrew/macOS). Use a stable home that
   matches where the OAuth token is cached:
   ```bash
   python3 -m venv ~/.config/gsc-insights/venv
   ~/.config/gsc-insights/venv/bin/pip install -r requirements.txt
   ```
   Save the downloaded `client_secret.json` to `~/.config/gsc-insights/client_secret.json`.
3. **(Phase 2, optional)** free Serper key at https://serper.dev →
   `export SERPER_API_KEY=...` (or a SerpApi key → `export SERPAPI_KEY=...`).

## Phase 1 — GSC data (free, high-signal)

```bash
~/.config/gsc-insights/venv/bin/python scripts/gsc_query.py \
  --site sc-domain:example.com \
  --days 90 \
  --keywords "AI Events Munich,AI Meetups Munich,AI Treffen München" \
  --client-secret ~/.config/gsc-insights/client_secret.json \
  --out report.md
```

- `--site` uses `sc-domain:<domain>` for a **Domain** property (what
  search-console-setup creates), or the full `https://…/` URL for a URL-prefix one.
- First run opens a browser for consent; the refresh token is cached at
  `~/.config/gsc-insights/token.json` (chmod 600) so later runs are silent.

The report leads with three actionable sections (then top-queries / top-pages tables):

1. **Target keywords — where we stand.** Best-matching query, avg position,
   impressions, clicks, CTR for each `--keywords` term (or "no impressions yet").
2. **Striking-distance queries** (avg position ~8–20): already on Google's radar,
   one push from the Top 10. Highest ROI — prioritise these.
3. **Good position, low CTR pages** (rank ≤10, CTR <2%): they're *seen* but not
   *clicked* → the title/meta-description is the bottleneck, not ranking.

## Phase 2 — competitive SERP (who actually ranks)

**What a SERP tool is for — and why GSC/Bing can't do it.** Search Console and Bing only
show **your own** data: queries *you already appear for*, and *your* position. They are blind
to everyone else and to any keyword you don't rank for yet. A **SERP API** fetches the **live
Google Top-10 for any keyword** — answering the questions your own data can't:

- **Who is beating me?** — the actual pages ranking 1–10 (your real competitors).
- **What's my true position** for a term I barely rank for, or am absent from?
- **What format does Google reward here?** — the highest-value read (see "How to use it").
- **Where is the competition weak?** — terms whose Top-10 is thin/aggregator-only = easier wins.

It turns owned data ("where am I?") into strategy ("where's the gap, and what beats it?").

```bash
set -a; . ~/.config/gsc-insights/.env; set +a    # loads the SERP key (keep it out of shell history)
~/.config/gsc-insights/venv/bin/python scripts/serp_check.py \
  --keywords "AI Events Munich,AI Meetups Munich,AI Treffen München" \
  --domain example.com            # --provider serper (default) | serpapi
```

Prints the live Top-10 per keyword, flags your own position (or absence), and logs how many
searches were spent so you never blow a free cap. The SERP language follows the target
country (`gl=de/at/ch` → `hl=de`, else `hl=en`; `--hl` overrides); `gl`
defaults to `de` (Munich). No key set → it exits cleanly; GSC/Bing are unaffected.

**How to use the output:**
1. **Read intent / format.** Top-10 is event aggregators (Meetup, Eventbrite, Luma) → Google
   wants a *current, structured listing*; it's listicle guides ("Top AI meetups in Munich") →
   a *guide page* wins. Build the format that ranks.
2. **Pick winnable terms.** Where the Top-10 is weak (thin pages, only aggregators, no real
   authority) you can break in — easier than the contested head term.
3. **Find your gap.** Compare the ranking pages to yours — what do they cover that you don't?
4. **Get listed.** If aggregators own the SERP, being *on* them (Meetup, Luma, dev.events) is
   half the battle, not just your own page.

**Provider-agnostic — Serper is today's default, not a hard dependency.** A SERP API is a
commodity; the script targets the *capability*, not one vendor, and free tiers shift over
time — so pick whatever's free/cheap when you set up:
- **Serper** — current default; ~2,500 free searches, then ~$0.30/1K.
- **SerpApi** — ~250 free/month; very clean parsing (already supported: `--provider serpapi`).
- **Others** (Scrape.do, Decodo, HasData) — similar free credits; **DataForSEO** is the paid
  backbone (no free tier, ~$0.0006/SERP) once you outgrow the free ones.

To add a provider: drop a `--provider <name>` branch into `serp_check.py` (its own API call →
the same `{position, title, link}` shape) and read its key from the `.env`. If your provider
ever kills its free tier, switch the flag — the rest of the skill is unchanged.

## Bing Webmaster Tools — optional second source (Copilot/ChatGPT proxy)

Bing's index feeds **Microsoft Copilot and ChatGPT search**, so Bing rankings are a
useful proxy for *AI-assistant* visibility — and connecting it is **far simpler than
Google: one API key, no OAuth, no browser**. Volume is much smaller than Google for
niche local queries, so treat it as a secondary signal.

**Connect (one-time, ~2 min, 🧑 human):** Bing Webmaster Tools
(https://www.bing.com/webmasters) → **Settings → API Access** → generate an **API key**
→ add it to `~/.config/gsc-insights/.env` as `BING_API_KEY=...`. (The site must already
be added to Bing — `search-console-setup` covers that via "Import from Google Search
Console".)

```bash
set -a; . ~/.config/gsc-insights/.env; set +a    # loads BING_API_KEY
~/.config/gsc-insights/venv/bin/python scripts/bing_query.py \
  --site https://example.com \
  --keywords "AI Events Munich,AI Meetups Munich,AI Treffen München" --out bing.md
```

Same report shape as Phase 1 (target keywords → striking distance → pages seen-but-not-
clicked → top queries/pages), from Bing — `GetQueryStats` + `GetPageStats`. Note: Bing
returns one **aggregate row per query over its last ~6 months**
(no date range), and `--site` must be the exact verified URL shown in Bing (https,
trailing slash as registered). No key set → it exits cleanly; GSC is unaffected.

## Track positions over time (weekly)

A single snapshot can't tell you if you're *improving*. `track.sh` pulls GSC + Bing for
your keywords, appends each run to a history CSV, and prints the movement since last run:

```bash
set -a; . ~/.config/gsc-insights/.env; set +a
bash scripts/track.sh example.com "AI Events Munich,AI Meetups Munich,AI Treffen München"
```

Output is a per-keyword trend (**lower position = better; ▲ = improved**). The first run
just seeds the history — re-run **every 1–2 weeks** to watch the needle. (Each query script
also takes `--csv <path>` to append on its own; `python scripts/_history.py <csv>` reprints
the trend without a new pull.)

## Weekly auto-tracking (opt-in, per site) — offer this

Good practice: once a site is connected and you've shown its first trend, **proactively
offer** to schedule the tracker weekly so the history builds itself (manual re-runs get
forgotten). Let the user choose **which sites** and a day/time — **never auto-install**, and
only on an explicit yes.

```bash
bash scripts/schedule_tracking.sh install example.com \
  "AI Events Munich,AI Meetups Munich,AI Treffen München" 1 9   # Mon 09:00 (weekday: 1=Mon…6=Sat, 0/7=Sun; hour 0-23)
bash scripts/schedule_tracking.sh list                  # what's scheduled
bash scripts/schedule_tracking.sh remove example.com
```

Each job runs `track.sh` weekly (GSC + Bing → the shared history CSV → trend), logging to
`~/.config/gsc-insights/logs/<domain>.log`. A month later, *"is my ranking improving?"*
answers from real data instead of a single snapshot.

- **macOS** uses **launchd** — one LaunchAgent per site, *never* cron. Per-site means each is
  enabled/removed independently; removal is one command.
- **Linux:** run the same `track.sh` from a **systemd user timer** (or cron) — identical effect.
- The job only *records* data. A natural future extension: alert on a big move (diff the latest
  two CSV rows and surface large position deltas) — not built yet.

## Acting on the report — hand off to existing skills

- **Low-CTR titles/descriptions** → `copywriting` (title) + `website-seo-geo` (the
  50–60 / 140–160 char limits and the og/canonical contract).
- **Striking-distance terms with no dedicated page** → a new page via the content
  skills (`website-content-guide`, `programmatic-seo` for many similar pages); for
  an events site, a city events guide + `Event` JSON-LD is the natural home.
- **Event rich results** → `schema-markup` (the `Event` type on event detail pages).
- **Bigger technical issues surfaced by coverage** → `seo-audit`.

## Low-volume playbook — 5 ways to use this when traffic is thin

Most SEO advice assumes lots of data. A niche/local site (like a Munich AI meetup) has
little — so the usual "wait for statistical significance" doesn't apply. Tell the user
to work it like this:

1. **Track position & impressions, NOT clicks.** At low volume clicks are ~0 and noisy;
   *average position* and *impressions* are the stable signals. A win is a target
   keyword's position trending up week-over-week — even while clicks stay at 0.
2. **Convert striking-distance queries (pos 8–20) one at a time.** Few keywords means you
   can hand-optimise each. Take the report's striking-distance list and thread that exact
   phrasing into the page's `<title>`, H1, and first paragraph. Moving one query 12→8 is a
   real, attributable win.
3. **Fix titles for queries you already rank for but nobody clicks.** Ranking ≤10 with ~0
   clicks = a *snippet* problem, not a ranking problem — and it's higher ROI at low volume
   than chasing new terms. Rewrite the title/meta (→ `copywriting` + `website-seo-geo`).
4. **Mine the queries you never targeted.** The top-queries table surfaces terms you
   *accidentally* rank for (speaker names, adjacent topics, "claude code munich"). On a
   thin site these are gold — real demand. Build or expand a section around the ones that
   fit your goal.
5. **Use the SERP + Bing layers to find weak-competition terms.** Your own data is sparse,
   so lean on `serp_check.py` (who's *actually* in the Top 10) and Bing to spot terms where
   the Top 10 is weak or aggregator-only — easier than the head term. Long-tail and
   other-language variants (e.g. German) are where a low-volume site wins *first*.

**Cadence:** re-measure every **1–2 weeks**, not daily (daily is noise at this volume).
Compare a 28-day window to the prior 28 days to see genuine movement.

## Scope notes

- **Read-only** GSC scope (`webmasters.readonly`); never writes to the property.
- This is data + analysis, **not** registration (`search-console-setup`), not the
  on-page metadata contract (`website-seo-geo`), not AI-answer optimisation (`ai-seo`).
- **Opt-in** skill: it needs API creds, so it is deliberately **not** in the
  `new-website` always-on copy set — copy it into a project only when wanted.
- Paid scale-up (not wired here): DataForSEO (no free tier, $50 min) is the option if
  you outgrow Serper/SerpApi and want a full keyword/SERP backbone — see
  `references/keyword-strategy.md`.
