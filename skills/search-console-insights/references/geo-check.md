# Does AI name you? — the weekly GEO check

More and more buyers ask an AI assistant instead of searching Google: *"Where can I buy
sourdough bread in Schwabing?"* This check asks the AI engines exactly that kind of
question every week, **without naming the business**, and counts how often the business
comes up in the answer. It is the AI-age twin of "where do I rank on Google".

Script: `scripts/geo_check.py`. The weekly `track.sh` runs it after Google and Bing.
The design and its review: `docs/reviews/SKILL-PLAN-geo-check.md` in the website-builder repo.

## What it measures — two columns per engine

| Column | How it asks | What it tells the owner |
|---|---|---|
| **Knows you** | no web search — the model answers from what it learned in training | Whether the AI already "knows" the business. The long-term goal. Judge it over several weeks, not from one week to the next: a single run is only 3 answers per question. |
| **Finds you** | web search switched on | What a buyer actually gets today, and which sites the engine cited. Can move week to week. If it cites directories or review sites instead of the owner's site, that is the next job (see `business-listings-setup`). |

Each engine gets up to three questions:

- **broad**: the buyer's everyday question
- **narrow**: the same question with the niche or neighbourhood
- **branded**: *"What is <name>?"*, as a sanity check

Broad and narrow get 3 answers each per run, because AI answers vary. The branded question
gets one answer. It is **never scored**, because an answer repeats the name even when it
says "I don't know it". Read it instead to see whether the engine describes the business
correctly.

## The engines, and how to pay for them

**The simple way (the default): one OpenRouter key.** OpenRouter is a service that passes
the questions on to ChatGPT, Claude, Gemini and Perplexity, and bills all four from **one
prepaid balance**. It uses each assistant's **own** web search, so "ChatGPT with web search on"
is what a ChatGPT user gets. The owner tops up once (5 or 10 USD/EUR is plenty to start; see
Costs for how long that lasts) and adds one key. They pay what the AI companies charge, plus
a top-up fee (5.5%, at least $0.80); OpenRouter says it doesn't store the questions or answers
by default.

| Assistant | From memory | With web search on | Key (in `~/.config/gsc-insights/.env`) |
|---|---|---|---|
| ChatGPT, Claude | ✓ | ✓ | `GEO_OPENROUTER_API_KEY` (or a direct key, below) |
| Gemini | ✓ | — (see below) | `GEO_OPENROUTER_API_KEY` (or a free direct key) |
| Perplexity | — via OpenRouter; ✓ with a direct key | ✓ | `GEO_OPENROUTER_API_KEY` (or a direct key) |
| Google AI Mode, AI Overview | — | ✓ | `SERPAPI_KEY` (optional, the same key as the Top-10 check) |

- **With an OpenRouter key, it is used for all four chat assistants.** Direct keys
  (`GEO_GEMINI_API_KEY`, `GEO_OPENAI_API_KEY`, `GEO_ANTHROPIC_API_KEY`,
  `GEO_PERPLEXITY_API_KEY`) are only used when there is no OpenRouter key. The report says which
  route each assistant went through, and a switch between routes is marked in the trend.
- **Through OpenRouter, the web searches don't know the site's country.** OpenRouter has no way to
  pass it on (checked 2026-09-26), while the direct keys send it. For a local business this
  barely matters, because its questions name the place ("… in Munich-Schwabing"). A business that
  sells everywhere gets search results without a country, which can lean towards the US; if that
  matters, use direct keys or name the market in the question.
- **Perplexity through OpenRouter only answers "with web search on".** Its model always searches
  by itself, so there is no "from memory" answer to collect on that route (checked: even "What is
  2 + 2?" came back with 20 web sources).
- **A free start:** a direct Gemini key from Google AI Studio costs nothing (outside the EU/UK/CH)
  and gives Gemini's "from memory" column. Everything else needs a paid route.

Every engine is optional. Without a key an engine is skipped with a one-line hint; the report
says e.g. "1 checked, 0 failed, 5 not set up". The script reads **only** these names, never a
generic `OPENAI_API_KEY`, so a key someone exported for other work is never billed by accident.
`--engines google-ai-mode,gemini` asks only the listed engines for one run.

**Google's own AI answers** come through SerpApi: **AI Mode** (Google's chat-style answer) and
the **AI Overview** (the box above the normal results). Both are live Google search by nature,
so they only have "finds you", and each question is asked **once** per run rather than three
times. That is a cost choice (every call spends a paid SerpApi search), and it makes Google's
line a thinner signal: judge it over several weeks. Google doesn't show an AI Overview for every question; when it shows none, the
line says "Google showed no AI Overview". That is useful to know in itself, and it isn't the
same as "not named". SerpApi collects Google's results automatically, and the risk under
Google's terms is SerpApi's business model (this skill already relies on it for the Top-10
check); the Gemini clause above covers only the Gemini API.

**Why Gemini has no "Finds you".** Google's terms for search-grounded Gemini answers say:
"You will not, and will not allow your end user or any third party to, cache, frame,
syndicate, resell, analyze, train on, or otherwise learn from Grounded Results". Counting
mentions and keeping the answers to compare week to week is exactly that, so Gemini is
only asked without search. Answers without search are not covered by that clause.

**The free path, and its limit.** A free Gemini key gives "Knows you" only. For "Finds you"
the owner needs one paid key: one OpenRouter key covers all four assistants; see Costs.

**EU / UK / Switzerland (a cautious reading, not legal advice).** Google's terms say: "You
may use only Paid Services when making API Clients available to users in the European
Economic Area, Switzerland, or the United Kingdom." Whether an owner running this script
for themselves counts is unclear. So tell owners there: **turn on billing for the Gemini
key**. At this volume that should cost next to nothing, but check the pricing page.

### Costs (measured 2026-09-26 through OpenRouter; prices change, so recheck on openrouter.ai)

A full weekly check for **one site** asks ChatGPT, Claude, Gemini and Perplexity 42 times in total.
Through OpenRouter it cost **$0.72 a week per site**. The top-up fee comes on top when buying credit:
5.5%, at least $0.80, so a $5 top-up costs $5.80 and a $10 top-up $10.80.

| Prepaid once | Lasts for one site | For three sites |
|---|---|---|
| 5 USD/EUR | about 6 weeks | about 2 weeks |
| 10 USD/EUR | about 13 weeks | about 4 weeks |

Where the money goes: nearly all of it is ChatGPT's and Claude's **web search** answers (about
$0.05 each: the pages they read count as input). Answers from memory cost fractions of a cent;
Perplexity's searches about half a cent. OpenRouter's **Activity** page shows every call and its
cost, and each weekly run prints its own total ("cost of this run via OpenRouter").

Google AI Mode and AI Overview (if switched on) come on top: 6–9 SerpApi searches per site per
week, from the SerpApi plan's monthly allowance.

Override any model with `GEO_<ENGINE>_OPENROUTER_MODEL=...` (OpenRouter route) or
`GEO_<ENGINE>_MODEL=...` (direct keys) in `.env`. **Providers retire models**
(Claude Haiku 4.5 retires around 15 Oct 2026), and a retired model shows up as a weekly
"FAILED" line. The fix is to set a current model there. Changing a model marks the next
trend line "model changed".

## Setting it up (🧑 owner, 🤖 you)

Sell it first, in plain words, then ask:
*"Want to know if ChatGPT and other AI assistants mention your business when someone asks
for what you offer? I can check that every week, next to your Google rankings. You prepay
once, 5 or 10 dollars or euros, and that covers the checks for weeks."*

1. 🤖 **Draft the questions.**
   - Read the live homepage and `POSITIONING.md` (if the site repo has one).
   - Write a **broad** and a **narrow** buyer question in the site's language, the way a real customer would type it.
   - For a **local** business, **name the place** in both: engines without location settings (Gemini) otherwise answer for anywhere. A business that sells everywhere (an app, an online shop) leaves the place out.
   - Never put the business name in them.
   - Also write the **branded** question.
   - Show all three to the owner and ask them to confirm or change the wording.
2. 🤖 **Prepare the key file**: run `~/.config/gsc-insights/venv/bin/python scripts/geo_check.py --prepare-env`, then
   `open -e ~/.config/gsc-insights/.env`. The first adds the empty lines (`GEO_GEMINI_API_KEY=`
   and so on) without touching anything already there. The second opens the file in TextEdit.
   Tell the owner where it lives in words they can use. The `.config` folder is hidden in Finder:
   **Go → Go to Folder…** (⇧⌘G), then `~/.config/gsc-insights`, or ⇧⌘. to show hidden files.
3. 🧑 **Get the key — usually just one.** Explain the choice in plain words first:
   *"The simplest way is one account at OpenRouter: you prepay once, 5 or 10 dollars or euros,
   and it pays ChatGPT, Claude, Gemini and Perplexity for you from that balance, for weeks. If you'd
   rather start free, a Gemini key costs nothing but only shows what Gemini knows from memory."*
   Hand over the steps, wait until the owner says it's done, then run
   `~/.config/gsc-insights/venv/bin/python scripts/geo_check.py --keys` (it shows "set ✓" or
   "empty", never the key itself). **Never ask for a key in the chat.** If a key is pasted there
   anyway, tell the owner to delete it at the provider and make a new one.

   Button names come from the providers' pages (checked 2026-09) and may be worded slightly
   differently on screen; say so.

   **OpenRouter (the default: one key for all four)**
   1. openrouter.ai → sign in (a Google login works).
   2. **Credits → Add credits**: 5 or 10 USD/EUR. That is a one-time top-up, not a subscription;
      it lasts for weeks (see Costs). OpenRouter's fee is 5.5%, at least $0.80, so $10 is the better value.
   3. **Keys → Create Key**, name it "AI check". Setting a **credit limit** on the key (for
      example the amount just added) means it can never spend more. Don't set it below a
      few dollars, or calls get refused.
   4. Copy the key and paste it after `GEO_OPENROUTER_API_KEY=`, with no space and no quotes. Save (⌘S).
   5. Later, **Activity** on openrouter.ai shows every call and what it cost.

   **Gemini direct (free, "from memory" only; optional)**
   1. aistudio.google.com → **Get API key** → **Create API key**; pick the project AI Studio already
      created (usually "Gemini API").
   2. In the EU/UK/Switzerland: **Set up billing** for that project (see the EU note).
   3. Paste it after `GEO_GEMINI_API_KEY=`. With an OpenRouter key set, OpenRouter is used instead.

   **Direct keys per provider (advanced; only used without an OpenRouter key)**: OpenAI
   (platform.openai.com → Billing → API keys → Create, restricted to "Model capabilities: Write"),
   Anthropic (console.anthropic.com → Billing → API Keys), Perplexity (perplexity.ai → Settings →
   API). Each needs its own prepaid credit. The only reason to prefer them: Perplexity's "from
   memory" column, which OpenRouter can't provide.

   **SerpApi (Google's AI answers, optional)**: if the owner already set up the Top-10 check,
   `SERPAPI_KEY` is already there. Otherwise: serpapi.com → sign up → Dashboard → copy "Your
   Private API Key" → paste it after `SERPAPI_KEY=`. Either way, Google is **off until the owner
   switches it on for the site**, because it spends paid searches: ask first, then run
   `~/.config/gsc-insights/venv/bin/python scripts/geo_check.py <domain> --google on`.
4. 🤖 **Save the site and its questions** with the confirmed wording. Write each question to a
   small text file first. Never put it inside a shell command string: an apostrophe
   ("contacts' plans") breaks the quoting.
   ```bash
   ~/.config/gsc-insights/venv/bin/python scripts/geo_check.py example.com --init --name "Bäckerei Example" \
       [--legal-name "..."] [--alias "..."] --lang de --country DE
   ~/.config/gsc-insights/venv/bin/python scripts/geo_check.py example.com --set-question --slot broad   --text-file broad.txt
   ~/.config/gsc-insights/venv/bin/python scripts/geo_check.py example.com --set-question --slot narrow  --text-file narrow.txt
   ~/.config/gsc-insights/venv/bin/python scripts/geo_check.py example.com --set-question --slot branded --text-file branded.txt
   ~/.config/gsc-insights/venv/bin/python scripts/geo_check.py example.com --check-drift
   # read the homepage text it prints with the owner, then save exactly that page:
   ~/.config/gsc-insights/venv/bin/python scripts/geo_check.py example.com --confirm --expect <page code>
   ```
   - `--name` comes from the site's `src/config.ts` (`SITE.name`); `--legal-name` from `SITE.legalName`.
   - Add an alias for each other spelling the owner uses ("ExampleCo" for "Example-Co").
   - To change names later: `--set-names --alias "..."` **adds** an alias; `--set-names --name "..."`
     replaces the whole list (name, then any `--legal-name` / `--alias` given with it). Either
     marks the next trend line "settings changed".
   - `--domain` defaults to the site's domain.
   - `--check-drift` prints the homepage's title, description and main heading, and a **page code**. Read them with the owner;
     only if it is the real homepage (not a cookie banner or a "checking your browser" page) run
     `--confirm --expect <page code>`. It saves only if the page still matches that preview.
5. 🤖 **Run it once** (`~/.config/gsc-insights/venv/bin/python scripts/geo_check.py example.com`), then open the report
   (`--report`) and walk the owner through it. It takes a few minutes with every engine on. If an engine shows FAILED, read its
   reason: "HTTP 401/403" means the key or its permissions; "HTTP 429" means rate limit or no credit.
6. 🤖 If the site isn't on weekly tracking yet, **ask** (SKILL.md "Weekly auto-tracking"). The AI check rides along with it.

## Every session: is the question still right?

The questions only mean something while they match what the business sells. **At the start
of any session that looks at this site's AI results, run
`~/.config/gsc-insights/venv/bin/python scripts/geo_check.py <domain> --check-drift`.** It prints the homepage's title,
description and main heading, and says whether they changed since the questions were confirmed.

- **State: same.** Go on.
- **State: changed.** Read the homepage and POSITIONING.md, then show the owner each saved question next to a proposed replacement. Ask: *"Your homepage changed. Should I keep asking the AI engines these questions, or switch to these?"*
  - **Switch:** `--set-question` for each changed slot, then `--confirm --expect <page code>`.
  - **Keep:** `--confirm --expect <page code>` only.
  - First check that the "now" text really is the homepage: under this design a cookie or bot
    page also lands in "changed". If it isn't, don't ask about questions; say the page couldn't
    be read properly this time.
  - A changed question gets a new revision. Its next trend line is marked "question changed", because the old and new numbers aren't comparable.
- **Couldn't read the homepage.** Tell the owner, and don't `--confirm`.
- **State: unconfirmed.** A question was changed (or never checked) since the last `--confirm`.
  Review the questions against the homepage with the owner, then `--confirm --expect <page code>`.
- **`--confirm` always needs `--expect <page code>` from a `--check-drift` you and the owner
  just read.** If that text isn't the business's real homepage (a cookie banner, "checking your
  browser", a login wall), don't confirm: tell the owner and try again later. The code rejects only pages that fail to load or name neither the business nor its
  domain anywhere in their text (including the title and hidden elements); everything else is your judgment.

The unattended weekly job never changes questions. On a changed homepage it runs the old
ones, keeps the week's data and logs a warning. Asking is this session's job.

## Reading the results

**The owner's way in:** they ask *"Show me my AI report for example.com"* (or "how is my
business doing with AI?"). Run `~/.config/gsc-insights/venv/bin/python scripts/geo_check.py <domain> --report`: it builds
one page from each assistant's latest answers and opens it in the browser. The page is written
for the owner, so let it speak first, then add two or three sentences of your own:

- **At the top:** how many assistants named the business at least once with web search on, and
  how many from memory, with one plain sentence each. Only answers that count go into these
  numbers: to the current question, from an assistant that is on now, that actually came back.
  "In every answer to every question" means exactly that; a 1-of-3 is "at least once".
- **"How to read this":** what was asked (and that it checks whether the name appears, not
  whether the assistant recommends it), what "with web search on" and "from memory" mean, and why
  each question is asked 3 times: an assistant can write a different answer each time.
- **One table per question:** ✓ named in every answer, ◐ sometimes, ✗ not named, ! no answer this
  time (the weekly log says why), — Google showed no AI answer, — not asked (with the reason),
  plus whether their own website was a source and how many answers failed. `*` marks an answer
  to an earlier version of the question. The answers are folded away under "Read what they said".
- **"Do they describe you correctly?":** the branded answers, to read, never counted.

Each weekly run writes a new page in `~/.config/gsc-insights/geo/reports/<domain>/`; an older
page is not updated. If the owner wants the latest without asking you, it is the newest file
in that folder.

For the week-over-week movement, `~/.config/gsc-insights/venv/bin/python scripts/geo_check.py <domain> --trend` (track.sh prints
it every week):

```
gemini     knows you broad   named 0/3 (2026-09-28) → 1/3 (2026-10-05) ▲
openai     finds you broad   named 1/3 (2026-09-28) → 3/3, cited 2/3 (2026-10-05) ▲
anthropic  finds you narrow  named 2/3 (…) → 2/3, cited 0/3, searched only 1/3 (…) →  ‡ model changed — not directly comparable
```

- **named 2/3**: the business was named in 2 of the 3 answers.
- **cited 2/3**: the owner's own site was among the cited sources in 2 of 3. (For Perplexity
  this means "among the search results it used": its API doesn't say which of them it quoted.)
- **searched only 1/3**: the engine answered from memory in the other two, even with search on. Those answers are closer to "knows you".
- **‡ …**: a change that makes the two numbers not directly comparable: the question, the model, the settings (names, domain, country), or the route (direct key ↔ OpenRouter).
- **latest attempt failed**: the last run for that line didn't get an answer. The numbers shown are the last good ones, with their dates.

Every answer is saved verbatim with its sources under
`~/.config/gsc-insights/geo/answers/<domain>/<run>/`. Quote from those files when explaining a
result, and read the branded answers for accuracy.

When the broad question has named nobody for about four weeks, suggest the owner focus on
the narrow one. The owner decides.

How to **improve** these numbers is `ai-seo`'s job (and `business-listings-setup` for
the directories an engine cites). This check only measures.

## Why the engines are asked "blind"

The script sends the bare question. No system prompt, no chat history, no account memory: those
are features of the consumer apps, not the APIs. That keeps it repeatable and close to a
first-time buyer. It is not proof of what the ChatGPT app would say to a particular person;
a mention via the API is good evidence, not a guarantee.

**Never answer the questions yourself, and never run them through a coding assistant in the
site's repo.** Those see CLAUDE.md, memory and the conversation, which all describe the
business.

For a manual spot check in the apps, use a private mode: ChatGPT "Temporary chat", Claude
"Incognito chat", Gemini with activity turned off.

## Engines — request shapes (for maintenance)

Checked against the providers' docs on 2026-09-26:
- **OpenRouter (the default route):** `POST https://openrouter.ai/api/v1/chat/completions`, `Authorization:
  Bearer`, models `google/gemini-3.5-flash-lite`, `openai/gpt-6-luna`, `anthropic/claude-sonnet-5`,
  `perplexity/sonar`. "Finds" adds `plugins: [{"id": "web", "engine": "native"}]` (the provider's own
  search; Perplexity's Sonar gets no plugin, it always searches and has no native option there).
  `max_tokens: 4000` (without it OpenRouter reserves credit for 65k tokens and refuses small
  balances) and `usage: {"include": true}` (the reply carries its real cost). Citations are
  `choices[0].message.annotations[type=url_citation]`, else the top-level `citations` (some
  replies list their sources only there).
  "No credit" arrives as HTTP 402 and stops the whole route for that run.

- **Gemini:** `POST …/v1beta/models/{model}:generateContent`, key in the `x-goog-api-key` header; the answer is in `candidates[0].content.parts[].text` and the model in `modelVersion`. No tools (see the terms above).
- **OpenAI:** Responses API `POST /v1/responses`, `store: false`. For "finds": the `web_search` tool with `user_location: {type: "approximate", country}` (omitting it silently means United States) and `tool_choice: "required"`. Citations are `url_citation` annotations; a `web_search_call` output item means a search ran.
- **Anthropic:** `POST /v1/messages`, `anthropic-version: 2023-06-01`. For "finds": the `web_search_20250305` tool (works on every current model) with `user_location`. Citations are on the text blocks, and `usage.server_tool_use.web_search_requests` counts searches. An org admin can disable web search, which makes these calls fail with a 400.
- **Google AI Mode / AI Overview (SerpApi):** `GET https://serpapi.com/search` with
  `engine=google_ai_mode` (answer in `reconstructed_markdown` or `text_blocks[]`, sources in
  `references[].link`) or `engine=google` (the `ai_overview` block, whose `page_token` sometimes
  requires a second call with `engine=google_ai_overview` within ~4 minutes). `no_cache=true`,
  `gl` = country, `hl` = language. The key is a query parameter, so errors are redacted. SerpApi
  also reports failures inside an HTTP 200 `{"error": ...}`.
- **Perplexity:** the Agent API `POST /v1/agent`, which replaced Sonar chat completions (retired 2026-09-27). The model is named directly (a preset keeps search on regardless). "Finds" adds the `web_search` tool with `user_location: {country}`. Sources are in `output[type=search_results].results[]`.

Tests: `scripts/tests/test_geo_check.py` (the pieces) and `test_track_entry.py` (the weekly
job, end to end), both against a local stub. No real engine is called.
