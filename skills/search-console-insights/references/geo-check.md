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
| **Knows you** | no web search — the model answers from what it learned in training | Whether the AI already "knows" the business. The long-term goal. Moves slowly: only when a new model version ships. |
| **Finds you** | web search switched on | What a buyer actually gets today, and which sites the engine cited. Can move week to week. If it cites directories or review sites instead of the owner's site, that is the next job (see `business-listings-setup`). |

Each engine gets up to three questions:

- **broad**: the buyer's everyday question
- **narrow**: the same question with the niche or neighbourhood
- **branded**: *"What is <name>?"*, as a sanity check

Broad and narrow get 3 answers each per run, because AI answers vary. The branded question
gets one answer. It is **never scored**, because an answer repeats the name even when it
says "I don't know it". Read it instead to see whether the engine describes the business
correctly.

## The engines, and what each needs

| Engine | Knows you | Finds you | Key (in `~/.config/gsc-insights/.env`) | Cost |
|---|---|---|---|---|
| Gemini | ✓ | — (see below) | `GEO_GEMINI_API_KEY` | free key from Google AI Studio (see EU note) |
| OpenAI | ✓ | ✓ | `GEO_OPENAI_API_KEY` | paid, prepaid credit |
| Anthropic | ✓ | ✓ | `GEO_ANTHROPIC_API_KEY` | paid, prepaid credit |
| Perplexity | ✓ | ✓ | `GEO_PERPLEXITY_API_KEY` | paid, prepaid credit |

Every engine is optional. Without its key an engine is skipped with a one-line hint; the
report says e.g. "1 checked, 0 failed, 3 not set up". The script reads **only** these
`GEO_*` names, never a generic `OPENAI_API_KEY`, so a key someone exported for other work is
never billed by accident.

**Why Gemini has no "Finds you".** Google's terms for search-grounded Gemini answers say:
"You will not, and will not allow your end user or any third party to, cache, frame,
syndicate, resell, analyze, train on, or otherwise learn from Grounded Results". Counting
mentions and keeping the answers to compare week to week is exactly that, so Gemini is
only asked without search. Answers without search are not covered by that clause.

**The free path, and its limit.** A free Gemini key gives "Knows you" only. For "Finds you"
the owner needs one paid key. Perplexity or OpenAI are the cheapest at this volume; see Costs.

**EU / UK / Switzerland (a cautious reading, not legal advice).** Google's terms say: "You
may use only Paid Services when making API Clients available to users in the European
Economic Area, Switzerland, or the United Kingdom." Whether an owner running this script
for themselves counts is unclear. So tell owners there: **turn on billing for the Gemini
key**. At this volume that should cost next to nothing, but check the pricing page.

### Costs (rough, from the providers' price pages in September 2026 — recheck before quoting)

Per site per week: 3 broad + 3 narrow + 1 branded = 7 calls per mode per engine.

| Engine | Model (default) | Roughly per week |
|---|---|---|
| Gemini | `gemini-3.5-flash-lite` | free (outside the EU/UK/CH); fractions of a cent with billing |
| OpenAI | `gpt-6-luna` | ~$0.10: web search is $10 per 1,000 calls, tokens are tiny |
| Anthropic | `claude-sonnet-5` | ~$0.20–0.50: $10 per 1,000 searches, more per token |
| Perplexity | `perplexity/sonar` | ~$0.05: $2.50 per 1,000 searches |

Override any model with `GEO_<ENGINE>_MODEL=...` in `.env`. **Providers retire models**
(Claude Haiku 4.5 retires around 15 Oct 2026), and a retired model shows up as a weekly
"FAILED" line. The fix is to set a current model there. Changing a model marks the next
trend line "model changed".

## Setting it up (🧑 owner, 🤖 you)

Sell it first, in plain words, then ask:
*"Want to know if ChatGPT and other AI assistants mention your business when someone asks
for what you offer? I can check that every week, next to your Google rankings. Gemini is
free to start with; the others cost a few cents a week if you want them."*

1. 🤖 **Draft the questions.**
   - Read the live homepage and `POSITIONING.md` (if the site repo has one).
   - Write a **broad** and a **narrow** buyer question in the site's language, the way a real customer would type it.
   - For a **local** business, **name the place** in both: engines without location settings (Gemini) otherwise answer for anywhere. A business that sells everywhere (an app, an online shop) leaves the place out.
   - Never put the business name in them.
   - Also write the **branded** question.
   - Show all three to the owner and ask them to confirm or change the wording.
2. 🤖 **Prepare the key file**: run `python scripts/geo_check.py --prepare-env`, then
   `open -e ~/.config/gsc-insights/.env`. The first adds four empty lines (`GEO_GEMINI_API_KEY=`
   and so on) without touching anything already there. The second opens the file in TextEdit.
   Tell the owner where it lives in words they can use. The `.config` folder is hidden in Finder:
   **Go → Go to Folder…** (⇧⌘G), then `~/.config/gsc-insights`, or ⇧⌘. to show hidden files.
3. 🧑 **Get the keys — one engine at a time, Gemini first.** Hand over the steps for one engine,
   wait until the owner says it's done, run `python scripts/geo_check.py --keys` (it shows
   "set ✓" or "empty", never the key itself), and only then offer the next one. **Never ask for
   a key in the chat.** If a key is pasted there anyway, tell the owner to delete that key at
   the provider and make a new one.

   Button names below come from the providers' docs (checked 2026-09) and may be worded slightly
   differently on screen; say so.

   **Gemini (free to start)**
   1. aistudio.google.com → sign in with a Google account → **Get API key** → **Create API key**.
   2. It asks for a **project**: pick the one AI Studio already created (usually "Gemini API").
      A project is just the folder the key and its bills belong to. Limits and billing are per
      project, not per key.
   3. In the EU/UK/Switzerland: **Set up billing** for that same project (see the EU note above).
   4. Copy the key and paste it after `GEO_GEMINI_API_KEY=`, with no space and no quotes. Save (⌘S).

   **OpenAI (paid)**
   1. platform.openai.com → sign in. A ChatGPT login works, but the API is billed separately.
   2. **Settings → Billing**: add a payment method and a small credit (about $5).
   3. **Settings → Limits**: set a monthly budget, e.g. $5.
   4. **API keys → Create new secret key → Restricted**. Set **Model capabilities** (or
      "Responses") to **Write** and leave everything else, including Agents and Traces, at
      **None**. The check only sends questions; it stores nothing at OpenAI.
   5. Copy it right away (it is shown once) and paste it after `GEO_OPENAI_API_KEY=`.

   **Anthropic (paid)**
   1. console.anthropic.com → sign in. The key belongs to the owner's organization and bills its credit.
   2. **Settings → Billing**: buy a small credit. **Settings → Limits**: set a monthly spend limit.
      Optionally create a workspace called "AI check" first, so its use shows separately.
   3. **API Keys → Create Key**. Copy it right away and paste it after `GEO_ANTHROPIC_API_KEY=`.

   **Perplexity (paid)**
   1. perplexity.ai → sign in → **Settings → API** → add a small credit → **Generate API key**.
   2. Paste it after `GEO_PERPLEXITY_API_KEY=`.

   An empty line just skips that engine. Every paid engine is optional; "Knows you" with the free
   Gemini key alone is a real result.
4. 🤖 **Save the site and its questions** with the confirmed wording. Write each question to a
   small text file first. Never put it inside a shell command string: an apostrophe
   ("contacts' plans") breaks the quoting.
   ```bash
   python scripts/geo_check.py example.com --init --name "Bäckerei Example" \
       [--legal-name "..."] [--alias "..."] --lang de --country DE
   python scripts/geo_check.py example.com --set-question --slot broad   --text-file broad.txt
   python scripts/geo_check.py example.com --set-question --slot narrow  --text-file narrow.txt
   python scripts/geo_check.py example.com --set-question --slot branded --text-file branded.txt
   python scripts/geo_check.py example.com --confirm
   ```
   - `--name` comes from the site's `src/config.ts` (`SITE.name`); `--legal-name` from `SITE.legalName`.
   - Add an alias for each other spelling the owner uses ("ExampleCo" for "Example-Co").
   - `--domain` defaults to the site's domain.
   - `--confirm` prints what it read from the homepage. If that isn't the real page (a "checking your browser" wall), it refuses to save.
5. 🤖 **Run it once** (`python scripts/geo_check.py example.com`) and walk the owner through the
   result. It takes a few minutes with all four engines. If an engine shows FAILED, read its
   reason: "HTTP 401/403" means the key or its permissions; "HTTP 429" means rate limit or no credit.
6. 🤖 If the site isn't on weekly tracking yet, **ask** (SKILL.md "Weekly auto-tracking"). The AI check rides along with it.

## Every session: is the question still right?

The questions only mean something while they match what the business sells. **At the start
of any session that looks at this site's AI results, run
`python scripts/geo_check.py <domain> --check-drift`.** It prints the homepage's title,
description and main heading, and says whether they changed since the questions were confirmed.

- **State: same.** Go on.
- **State: changed.** Read the homepage and POSITIONING.md, then show the owner each saved question next to a proposed replacement. Ask: *"Your homepage changed. Should I keep asking the AI engines these questions, or switch to these?"*
  - **Switch:** `--set-question` for each changed slot, then `--confirm`.
  - **Keep:** `--confirm` only.
  - A changed question gets a new revision. Its next trend line is marked "question changed", because the old and new numbers aren't comparable.
- **Couldn't read the homepage.** Tell the owner, and don't `--confirm`.

The unattended weekly job never changes questions. On a changed homepage it runs the old
ones, keeps the week's data and logs a warning. Asking is this session's job.

## Reading the results

`python scripts/geo_check.py <domain> --trend` (track.sh prints it every week):

```
gemini     knows you broad   named 0/3 (2026-09-28) → 1/3 (2026-10-05) ▲
openai     finds you broad   named 1/3 (2026-09-28) → 3/3, cited 2/3 (2026-10-05) ▲
anthropic  finds you narrow  named 2/3 (…) → 2/3, cited 0/3, searched only 1/3 (…) →  ‡ model changed — not directly comparable
```

- **named 2/3**: the business was named in 2 of the 3 answers.
- **cited 2/3**: the owner's own site was among the cited sources in 2 of 3.
- **searched only 1/3**: the engine answered from memory in the other two, even with search on. Those answers are closer to "knows you".
- **‡ …**: a change that makes the two numbers not directly comparable: the question, the model, or the settings (names, domain, country).
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

- **Gemini:** `POST …/v1beta/models/{model}:generateContent`, key in the `x-goog-api-key` header; the answer is in `candidates[0].content.parts[].text` and the model in `modelVersion`. No tools (see the terms above).
- **OpenAI:** Responses API `POST /v1/responses`, `store: false`. For "finds": the `web_search` tool with `user_location: {type: "approximate", country}` (omitting it silently means United States) and `tool_choice: "required"`. Citations are `url_citation` annotations; a `web_search_call` output item means a search ran.
- **Anthropic:** `POST /v1/messages`, `anthropic-version: 2023-06-01`. For "finds": the `web_search_20250305` tool (works on every current model) with `user_location`. Citations are on the text blocks, and `usage.server_tool_use.web_search_requests` counts searches. An org admin can disable web search, which makes these calls fail with a 400.
- **Perplexity:** the Agent API `POST /v1/agent`, which replaced Sonar chat completions (retired 2026-09-27). The model is named directly (a preset keeps search on regardless). "Finds" adds the `web_search` tool with `user_location: {country}`. Sources are in `output[type=search_results].results[]`.

Tests: `scripts/tests/test_geo_check.py` (the pieces) and `test_track_entry.py` (the weekly
job, end to end), both against a local stub. No real engine is called.
