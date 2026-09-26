# Plan — weekly GEO check ("Does AI name you?") in search-console-insights

Revision 4, the plan to build from. It went through three PLAN review rounds: Codex, an ollama-cloud model and a Claude fresh-eyes pass. After round 3 the owner chose to redesign the two components that kept producing findings (exit codes, homepage drift) and then build, with no fourth plan round. The DIFF gate re-checks everything below against the code. Trail: `REVIEW-plan-2026-09-26-r3-geo-check-*.md` and `RAW-plan-2026-09-26-geo-check-*.md` in this folder.

## Status

| Step / scenario | State | Evidence |
|---|---|---|
| PLAN gate (3 rounds, then owner redesign decision) | done | `4268689` |
| S1 Gemini-only run | done (stub) | `test_s1_gemini_only`, `test_s1_green_run_with_gemini_only` |
| S2 counts named / cited | done (stub) | `test_s2_counts` |
| S3 name detection | done | `Detection` tests |
| S4 homepage changed | done (stub) | `test_s4_changed_warns_but_never_fails`, `test_s4_homepage_changed_stays_green` |
| S4b homepage unreadable | done (stub) | `test_s4b_unreadable_warns_and_confirm_refuses`, `test_s4b_unreadable_homepage_stays_green` |
| S5 interactive re-confirm | done (stub) | `test_s5_check_drift_then_keep_or_change`, `test_s5_question_change_is_marked_per_slot` |
| S6 model changed | done (stub) | `test_s6_model_change_is_marked` |
| S7 not set up | done (stub) | `test_s7_not_set_up`, `test_s7_not_set_up_keeps_the_old_green` |
| S7b set up without key | done (stub) | `test_s7b_config_without_keys_is_a_problem`, `test_s7b_set_up_without_key_is_red` |
| S8 engine failed | done (stub) | `test_s8_failed_engine_is_a_problem_and_redacted`, `test_s8_failed_engine_is_red` |
| S9 GSC token dead | done (stub) | `test_gsc_no_browser.py`, `test_s9_dead_gsc_signin_does_not_cost_the_ai_week` |
| Live smoke test (real engines) | done, OpenAI pending | 2026-09-26, three real sites: Gemini, Anthropic, Perplexity answered and parsed (detector spot-checked against saved answers); OpenAI blocked by no account credit, which exposed the retry waste fixed in `47568d3` |
| Google AI Mode + AI Overview (SerpApi), owner request | done (stub + live) | `335c146`; live on three real sites 2026-09-26 |
| Readable report page (`--report`), owner request | done (stub + browser check) | `94d34a4` |
| OpenAI live answer | blocked | the owner's OpenAI account has no credit yet (key and restricted permissions confirmed fine) |
| DIFF gate | round 1 done, fixes in; round 2 pending | round 1: Codex (both halves) + Claude fresh-eyes; ollama-cloud FAILED (weekly usage limit). Trail: `REVIEW-diff-2026-09-26-r1-geo-check-*.md` |
| PR | not started | — |

"done (stub)" = passing against the local stub server; the commit that carries these tests is
the one after `4268689` on this branch. The live smoke test is the first contact with real APIs.

## Build decisions (after the plan gate)

- **Gemini answers only without search ("knows you").** Build-time research found Google's
  grounding terms: "You will not, and will not allow your end user or any third party to,
  cache, frame, syndicate, resell, analyze, train on, or otherwise learn from Grounded
  Results". Counting mentions is analysis. Owner decision, verbatim: "Gemini = Knows you only
  (Recommended)". The free path therefore gives "knows you" only; "finds you" needs a paid key.
  This supersedes the plan text below wherever it says Gemini "finds".
- **Perplexity fills both columns.** Its Agent API searches only when the `web_search` tool is
  sent with a directly named model (no preset), so "knows" mode is possible after all.
- **Default models:** `gemini-3.5-flash-lite`, `gpt-6-luna`, `claude-sonnet-5` (Haiku 4.5 retires
  around 2026-10-15), `perplexity/sonar`. All overridable via `GEO_<ENGINE>_MODEL`.
- **New `searched` column.** Only OpenAI can force a search (`tool_choice: "required"`); the
  others may answer from memory with search on. The row counts how many answers actually
  searched, and the trend says "searched only N/M" when not all did.
- **OpenAI always gets `user_location`** (`{"type": "approximate"}` plus the country): omitted,
  it silently searches as if from the United States.
- **track.sh keeps exit 4 for a history-write gap** (as before) instead of folding it into 1:
  final exit = GSC's code if GSC failed, else 4 if a history write failed, else 1.
- **check_clean key patterns** start at a word boundary: an unanchored `sk-` with hyphens
  flagged ordinary prose like "risk-free-and-easy-to-use" (checked by hand on sample strings;
  there is no committed test harness for check_clean.sh).
- **Google is opt-in per site** (`--google on`, DIFF review round 1): an owner who has
  `SERPAPI_KEY` for the Top-10 check must not start paying for Google AI checks unasked.
- **Google's AI answers via SerpApi** (owner request, 2026-09-26): AI Mode and AI Overview as two
  more engines, "finds" only, 1 sample per question (Google's answers are steadier, and each
  call is a paid search), reusing the skill's existing `SERPAPI_KEY`. "No AI Overview shown" is
  its own state.
- **Report page** (owner request, 2026-09-26): after the owner couldn't tell where results live,
  `--report` renders each engine's latest answers as one HTML page; every weekly run writes it.
- **Key setup redone** (owner feedback, 2026-09-26: "Even I am lost now"): `--prepare-env`,
  `--keys`, and a one-engine-at-a-time walkthrough in geo-check.md.
- **Process deviation:** geo_check.py was written before its tests, not tests-first. Mitigation:
  four deliberate breaks (no `--no-browser`, GEO rc 3 treated as a problem, German folding
  removed, the good-row guard removed) each turned the matching tests red.

## Context

Buyers increasingly ask AI engines instead of Google. juliet.space shows this on its teardown report ("The AI engines" chapter). It asks four engines a buyer-style question that does not name the business, plus one question that does. Then it shows verbatim, per engine, whether the business was named. We want the same check here, run every week alongside the existing Google + Bing tracker so the owner sees a trend, not a one-off.

**What exists today (verified in the repo):**
- `skills/search-console-insights/` has a weekly tracker:
  - `track.sh` pulls GSC, then Bing, and appends rows to a history CSV. That CSV is shared and keyed by site by default, with optional per-site files via `GSC_HISTORY_CSV`.
  - `_history.py` prints a position-focused trend.
  - `schedule_tracking.sh` installs one launchd job per site.
- Keys live in `~/.config/gsc-insights/.env`.
- Exit codes today:
  - `bing_query.py`: 3 = no key (skipped), 4 = history write failed. Any other Bing error is swallowed by track.sh.
  - `gsc_query.py`: 1, 2 and 4 only.
- No alert on big moves exists (SKILL.md:398).
- The tracker makes no AI-visibility calls. The only AI calls in the repo are independent-review's reviewer CLIs.
- `ai-seo` suggests a manual monthly check (SKILL.md:350).
- **Existing bug found in review.** `track.sh` → `gsc_query.py` → `load_credentials(interactive=True)`:
  - With no `token.json`, it opens `run_local_server()` and waits for a browser, so an unattended run can hang.
  - A rejected refresh raises `RefreshError`, and nothing catches it.
  - `interactive=False` raises `RuntimeError`, which `main()` doesn't catch either.

**Decisions made with the maintainer:**
1. The owner's own API keys are used, never the maintainer's, and every engine is optional. **Gemini is the suggested default** (see the EEA note). OpenAI, Anthropic and Perplexity are paid add-ons, skipped with a one-line hint when their key is absent.
2. Each engine gets two columns:
   - **"Knows you"**: no web tools, the model's own knowledge, the long-term goal.
   - **"Finds you"**: web search on, moves weekly, cited sites captured.
3. Claude drafts the search questions from the site and the owner confirms them. **Every interactive run starts by checking whether the homepage still matches the saved questions**, and asks the owner if not. The unattended job only warns.
4. A branded question ("What is <name>?") runs as a sanity check. It is reported separately and never scored.

**Incognito.** "Bare question" means no system prompt, no chat history and no account memory. The API parameters the mode needs (tools on/off, location, `store: false`) are still sent. Memory and history are consumer-app features, so this keeps personalization low and the check repeatable. It is not a guarantee about provider-side behaviour. It is also why the logged-in CLIs aren't used: run from a site repo, they load CLAUDE.md / AGENTS.md / memory that describe the business. The Claude session drafts questions and never answers them. For manual spot checks, the docs point owners to ChatGPT "Temporary chat", Claude "Incognito chat" and Gemini with activity off.

**Perplexity (checked 2026-09-26).** Perplexity's docs say "Sonar will be supported until September 27, 2026." v1 targets the Agent API (`/v1/agent`), which returns `search_results`. Its docs don't say whether search can be switched off, so Perplexity fills only "Finds you" unless that is confirmed at build time.

**EEA note (judgment on an unclear term).**
- Google's Gemini API terms require Paid Services when API clients are made available to users in the EEA, Switzerland or the UK. It is unclear whether an owner running a script for themselves falls under that. The docs say: in the EU/UK/CH, turn on billing to be safe.
- Elsewhere the free key works. The default model is the cheapest Flash-Lite model whose **free** tier includes Google Search grounding. Verify both its requests-per-day limit and its grounding limit at build time: every run makes 14 Gemini requests.
- "About €0" covers Gemini only. The other engines link to their pricing.

## Requirements — scenarios (acceptance tests run on stub servers; the live smoke test is separate)

| # | Given | When | Then |
|---|---|---|---|
| S1 | A bakery site in Munich, GSC connected, only `GEO_GEMINI_API_KEY` set | the weekly job runs | Gemini "knows" rows land in `geo_history.csv` (no "finds": see Build decisions). The log says "skipped: no GEO_OPENAI_API_KEY (add it to ~/.config/gsc-insights/.env)", the same for Anthropic and Perplexity, and the two Google engines are off for the site. The GEO trend prints under the keyword trend; the run says "engines: 1 checked, 0 failed, 5 not set up". track.sh exits 0. |
| S2 | The broad question is "Where can I buy sourdough bread in Munich-Schwabing?" | a stubbed Gemini "finds" names the bakery in each of 3 samples, each citing a source on `www.example-bakery.de` | ok=3, named=3, cited_own=3 |
| S3 | The names are "Bäckerei Example", "Café Müller", "Bäckerei Café" and "Luigi's Pizza" | the answers say "Baeckerei Example", "BÄCKEREI EXAMPLE", "Bäckerei-Example", "Cafe Mueller", "Cafe Muller", "CAFE MUELLER", "Baeckerei Cafe", "Luigi’s Pizza" (curly ’) | all named. "Examples" is not named (the genitive-s limitation is documented). |
| S4 | The homepage's title / meta description / H1 changed since confirmation, and the page still contains a configured name or domain | the unattended job runs | The questions still run. The log shows ⚠ "homepage changed since your questions were confirmed" with the old and new text. **The exit code is unaffected.** |
| S4b | The homepage times out, returns non-200, or returns a page containing none of the configured names/domains (bot wall, consent page) | the job runs | ⚠ "couldn't read your homepage (<reason>)". The engines still run and the exit code is unaffected. The stored fingerprint is untouched. |
| S5 | S4 has happened, and the owner opens a Claude session | the skill runs `geo_check.py <domain> --check-drift` | Claude reads the current homepage (and POSITIONING.md if present), shows every saved question next to its proposed replacement, and asks. Yes → `--set-question` per changed slot, then `--confirm`. No → `--confirm` only. Both paths print the fetched text first. The next trend line for a changed slot shows ‡ "question changed". |
| S6 | The API reports a different model id than last week | the trend prints | ‡ "model changed". Only **reported** ids count; the docs say silent updates are invisible. |
| S7 | No GEO config for the domain | track.sh runs | "AI check: not set up (ask Claude: 'set up the weekly AI check')". GSC and Bing are unaffected, and track.sh's exit is unchanged. |
| S7b | A GEO config exists but no `GEO_*` key is set | track.sh runs | ⚠ "AI check is set up but has no engine key", listed as a problem → nonzero exit |
| S8 | The Gemini key is revoked or over quota | the job runs | Gemini FAILED with the reason and the key redacted. Other engines run. The row has ok=0, is never allowed to replace an earlier same-day row with ok>0, and the trend shows "latest attempt failed" next to the last successful comparison and its date. Nonzero exit. |
| S9 | The GSC token is missing, or its refresh is rejected | the job runs | GSC prints its re-auth message and exits 2 (no browser, no traceback). Bing and GEO still run. track.sh exits 2. |

## Design

**Where it lives:** `skills/search-console-insights/`. It shares the venv, `.env`, launchd job and logs. No new skill, no second schedule. GEO without GSC is out of scope.

**Per-site config** at `~/.config/gsc-insights/geo/<normalize_site(domain)>.json`. Only `geo_check.py` writes it.

| Field | Content |
|---|---|
| `names` | brand, legal name, aliases |
| `domains` | lowercased, IDNA-normalized, with `www.`, trailing dot and port stripped |
| `lang` | the site's language |
| `country` | ISO alpha-2, validated; never taken from `GSC_COUNTRY`, which is alpha-3 |
| `queries` | `[{slot: broad\|narrow\|branded, rev, text, confirmed}]` |
| `fingerprint` | covers the question set, plus the extracted text it was made from |
| `config_rev` | a hash of names, domains, lang, country and the detector version |

**`scripts/geo_check.py <domain> [command]`** (Python, `requests`, `csv`):

| Command | Does |
|---|---|
| (none) | the weekly run |
| `--init --name … [--legal-name …] [--alias …]… --domain … --lang … --country …` | creates the config; its first question is set with `--set-question` |
| `--set-names …` | updates names/domains/lang/country; bumps `config_rev` |
| `--set-question --slot broad\|narrow\|branded --text-file <path>\|-` | writes the text (read from a file or stdin, never interpolated into a shell string) and bumps that slot's rev. It does not fingerprint. |
| `--check-drift` | fetches and extracts the homepage, prints same / changed / unreadable with the texts; no engine calls |
| `--confirm` | fetches the homepage and prints the extracted text. It refuses to save if the page is unreadable (S4b). Otherwise it saves the fingerprint for the whole question set. |
| `--trend` | prints the GEO trend |

**Keys:**
- Only `GEO_GEMINI_API_KEY`, `GEO_OPENAI_API_KEY`, `GEO_ANTHROPIC_API_KEY` and `GEO_PERPLEXITY_API_KEY` are read: from the environment, or else parsed from the `.env` file. Generic `OPENAI_API_KEY` etc. are never read.
- The Gemini key goes in the `x-goog-api-key` header. OpenAI requests set `store: false`.
- Base-URL overrides (`GEO_<ENGINE>_BASE_URL`, `GEO_HOMEPAGE_URL`) are honoured only when `GEO_TEST_MODE=1` **and** the host is loopback.
- All configured key values are redacted from any printed error (URL, header, body).

**Weekly run:**
1. **Homepage check (warning only).**
   - Fetch with a browser-like User-Agent and a fixed Accept-Language. Extract the title, meta description and first H1, then normalize (entities, whitespace, case).
   - If the page contains none of the configured names or domains, it is "unreadable". Otherwise compare with the fingerprint.
   - Outcomes are same / changed (S4) / unreadable (S4b) / not confirmed yet. All of them print, none changes the exit code, and none writes anything.
2. **Calls.**
   - Loop over each engine with a key × mode × slot: sequentially, with a per-call timeout, a total time budget, a short pause between calls and bounded backoff on 429.
   - Samples: 3 per unbranded slot, 1 for the branded slot.
   - **Finds mode:** Gemini + Google Search grounding; OpenAI Responses + `web_search`; Anthropic Messages + `web_search`; Perplexity Agent API.
   - **Knows mode:** no tools. Perplexity is omitted unless no-search is confirmed.
   - `user_location` is sent in alpha-2 where supported. Gemini has none, so the drafting guidance makes questions name the place.
   - Calls cut off by the time budget count as failed samples.
3. **Detection (code, never an LLM).**
   - Forms: `strip(fold(x))` and `strip(casefold(x))`, applied to both name and answer. `fold` is `_lang_normalize.fold`; `strip` = NFKD accent removal, curly quotes and ʼ → `'`, hyphens and dashes → space, whitespace collapsed.
   - A hit in either form counts, matched with `(?<!\w)…(?!\w)` around `re.escape(name)`.
   - `cited_own` counts samples whose sources include a host that equals a configured domain or ends with "." + that domain (both sides normalized as in the config). It is blank in knows mode.
   - For Gemini, the host comes from the grounding chunk's title/domain field (its URIs are redirects). Build a fixture from a real response.
4. **Evidence first.**
   - Answers go to `~/.config/gsc-insights/geo/answers/<domain>/<run_id>/<engine>-<mode>-<slot>-<n>.txt`, each with a header line giving the reported model.
   - `run_id` = `%Y%m%dT%H%M%SZ` UTC + pid + 4 random hex.
   - The CSV row is written only after the answers.
5. **History.**
   - File: `~/.config/gsc-insights/geo/geo_history.csv`, shared and keyed by site, with its own lock + temp file + `os.replace`. This copies the pattern of `_history.append_rows`, not the function, which is hardwired to the keyword schema.
   - Columns: `date (UTC), run_id, site, engine, mode, slot, rev, query, model_requested, models_reported, config_rev, ok, named, cited_own, cited_domains, status`. The sets are `|`-joined.
   - `named` and `cited_own` count successful samples only; blank on branded rows.
   - Dedupe on (date, site, engine, mode, slot, rev, config_rev). A same-day rerun replaces the row **unless** the new row has fewer successful samples.
6. **Trend.**
   - Grouped by site × engine × mode × slot and ordered by `run_id`.
   - Per group: the latest attempt's status, then the comparison between the two latest rows with ok>0, with their dates, as the ratio named/ok ("named 1/3 → 3/3 ▲").
   - A change in rev, models_reported, config_rev or query text prints ‡ plus the cause in words. The keyword trend above uses ‡ for window/country changes.
   - Branded rows are listed apart ("see answer file").
   - Header: engines checked / failed / not set up.
7. **Exit (weekly run).**
   - **0**: no problems.
   - **3**: not set up (no config).
   - **1**: one or more problems (an engine failed, no keys for an existing config, history write failed). Every problem prints as a ⚠ line first.
   - Homepage warnings are not problems.

**`track.sh` (simplified):**
- It keeps a list of problems.
  - GSC is called with `--no-browser`; a nonzero rc adds "GSC: exit <rc>" and remembers the rc.
  - Bing keeps today's handling: 3 = skip, 4 = problem, other errors = printed but swallowed (unchanged, noted as a follow-up).
  - `geo_check.py` rc 3 = the S7 line, not a problem. Any other nonzero rc, including a crash, = "AI check: exit <rc>".
  - `_history.py` and `geo_check.py --trend` are each captured with `|| rc=$?`; nonzero adds a problem.
- At the end it prints the list and exits 0 if the list is empty, GSC's rc if GSC failed, otherwise 1.
- `schedule_tracking.sh` is unchanged. launchd starts one instance per job label, the CSV write is locked, and answer directories are per run.

**`gsc_query.py --no-browser`:** calls `load_credentials(interactive=False)`. `main()` catches `RuntimeError` and `google.auth.exceptions.RefreshError`, prints the re-auth guidance and exits 2. Interactive behaviour without the flag is unchanged.

**Judgment work (Claude, interactive only):**
- drafting the question ladder (broad → narrow, naming the place, in the site's language) from the homepage + POSITIONING.md
- the start-of-session homepage/question check (S5)
- reading branded answers for accuracy
- after ~4 weeks with no mention on broad, suggesting a focus on narrow (the owner decides)

## Files

| File | Change |
|---|---|
| `docs/reviews/SKILL-PLAN-geo-check.md` | this file (status table updated per step) |
| `skills/search-console-insights/scripts/geo_check.py` | new |
| `skills/search-console-insights/scripts/tests/test_geo_check.py`, `test_track_entry.py`, `test_gsc_no_browser.py` | new |
| `skills/search-console-insights/scripts/gsc_query.py` | `--no-browser` + the catch in `main()` |
| `skills/search-console-insights/scripts/track.sh` | problem list, GEO block, `--no-browser`, guarded trends |
| `skills/search-console-insights/references/geo-check.md` | new: setup (Gemini first, the EEA billing note), question drafting, the session-start check, incognito, manual spot-check modes, reading results, costs per engine, updating default model ids, the "Testing" OAuth app's refresh-token expiry (see follow-ups) |
| `skills/search-console-insights/references/onboarding.md` | an optional GEO step (🧑/🤖). Scope "free / read-only" to GSC + Bing + Serper. |
| `skills/search-console-insights/SKILL.md` | the opening cost/data paragraph (lines 38–45) separates the free read-only calls from the optional paid GEO calls. "Track positions" and "Weekly auto-tracking" describe the new track.sh behaviour. A short GEO section → geo-check.md. Description: add "does AI name my business" and "weekly AI check", and cut ≥45 chars of existing wording so it stays ≤1024 (991 today). Version 1.7.0, <500 lines. |
| `skills/search-console-insights/evals/evals.json` | the S5 flow and GEO onboarding |
| `skills/ai-seo/SKILL.md` | one line in "DIY Monitoring" → the automated check |
| `scripts/check_clean.sh` | catch `sk-ant-…`, `sk-proj-…` and `pplx-…` |
| `Makefile` | a `test` target (`PYTHON ?= python3`), added to `.PHONY` and the help text; not a dependency of `check`/`package` |
| `.github/workflows/clean.yml` | a new job: `actions/setup-python` → `pip install requests` → `make test`. Update the header comment. |

Test fixtures use obvious placeholder keys that the widened patterns don't match. All examples use example.com or a fictional bakery.

## Build checklist (review findings the tests must cover)

- `--no-browser`: a missing token, a rejected refresh and an ImportError are distinct cases. Assert the message text, and that `from_authorized_user_file` was called.
- The track.sh entry test runs once per scenario (S1, S4, S4b, S7, S7b, S8, S9, a GEO crash, and a keyword `_history.py` failure together with a GSC failure). The shim records argv (asserting `--no-browser`) and execs the real interpreter for everything but gsc/bing. The test asserts the shim reached `geo_check.py`.
- The S3 matrix, host matching (`example.com.evil.test`, `?url=example.com`, `www.`/port/trailing dot/IDNA), ‡ causes with both unbranded slots present, a failed rerun not replacing a good row, and UTC date dedupe.
- `--confirm` refuses an unreadable page. `--set-question` reads stdin/file. Overrides are ignored without test mode, and for non-loopback hosts.
- `check_skill_budgets.sh`, `check_clean.sh` (with the private denylist present locally) and `make test` all green.

## Judgment calls (not verified facts)

- **3 samples per unbranded question** (14 calls per engine per week).
- **The homepage check never fails the unattended run.** The counter-argument: a stale question can run for weeks. The mitigation is that every interactive session checks and asks first, which is where the owner wanted the question asked.
- **The EEA reading** (turn on billing to be safe) is a reading of unclear terms, not legal advice.
- **GEO requires GSC setup.** geo_check.py runs standalone, so GEO-only is easy later.
- **GSC no longer aborts track.sh**, and the exit still carries GSC's code.
- **Strongest counter-argument to the whole design:** API answers are not the consumer apps' answers. A mention via the API is evidence, not proof.

## To verify at build time

- Gemini: the grounding response shape, the reported model field, the default Flash-Lite model with free grounding, and both its requests-per-day and grounding limits
- Perplexity Agent API: the shape, and whether search can be switched off
- Google's grounding display/storage terms
- whether Anthropic web search needs Console enablement
- the OpenAI and Anthropic `user_location` shape
- the default model ids

## Out of scope (follow-ups)

- the full weekly report (striking-distance/CTR deltas, alerts on big moves)
- README doesn't mention search-console-insights
- Bing API errors are swallowed in track.sh (conflicts with fail-loud)
- the OAuth app left in "Testing" may get refresh tokens that expire weekly (unverified): document publishing the app or the re-auth cadence
- the independent-review Codex tier fails outside a git repo (filed separately)
