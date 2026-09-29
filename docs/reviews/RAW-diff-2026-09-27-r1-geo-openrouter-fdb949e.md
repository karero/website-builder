# RAW reviewer output — DIFF review, OpenRouter as the default route (feat/geo-openrouter), 2026-09-26/27

Verbatim. Home paths redacted (`/Users/<user>` → `~`); private names as `<name>`. This round had the full pair (Codex + ollama-cloud) plus Claude fresh-eyes.

# Codex + ollama-cloud
```text
note: 7 ':cloud' models in 'ollama list' — auto-using the first, 'kimi-k2.7-code:cloud'. Set OLLAMA_MODEL to choose a different one.
## Independent review — codex (gpt-6-astra, read-only)

Reviewed the actual files under `skills/search-console-insights/`, which differ from the supplied diff. No network, credentials, or filesystem writes were used.

Ranked findings:

1. **RISK — OpenRouter claims lack support.** `references/geo-check.md:32–36,84–97,143–145`; `scripts/geo_check.py:410–442`. **UNVERIFIABLE:** Native search equals consumer ChatGPT/Claude behavior; citations prove search execution; Sonar always searches; default retention, credit-limit guarantees, and the quoted weekly cost. The stub implements these assumptions; the fixtures establish response parsing, not those guarantees. If false, visibility scores, privacy expectations, or budget promises mislead owners. **Fix:** Describe API-model measurements and citation presence accurately; qualify retention and spending claims; retain supporting provider documentation and measured billing records. **Settling observations:** Provider routing/tool traces and corresponding app comparisons; documented retention and limit semantics; a complete 42-call billing record. The six fixture costs multiplied by seven equal **$0.75174995**, which does not reproduce the claimed **$0.72** measurement.

2. **BUG — Switching to OpenRouter silently drops the configured country.** `scripts/geo_check.py:445–447`. **WRONG:** The routes preserve equivalent request context. The OpenRouter branch discards `cfg`; direct search requests include its country. An in-memory comparison produced identical OpenRouter payloads for `DE` and `US`, removing the configured geographic signal. **Fix:** Forward location through a supported, verified mechanism, or explicitly include the intended geography in the question and disclose the route difference.

3. **BUG — Old Perplexity memory results remain in the current OpenRouter report.** `scripts/geo_check.py:1171–1173,1205–1213,1244–1245`. **WRONG:** Switching routes removes Perplexity’s unsupported memory column from current scoring. Latest rows are selected independently per mode, so a previous direct `knows` row survives indefinitely; `_cell` checks route eligibility only when the row is absent. An in-memory report retained the old “1 of 1” memory score and omitted “always searches.” **Fix:** Exclude modes unsupported by the current route from current scores and cells; show historical results separately with their route and date.

4. **BUG — Existing installations miss the route-change warning.** `scripts/geo_check.py:1012`. **WRONG:** Route switches are consistently marked. Pre-change CSV rows have no `route`, and the condition requires both routes to be populated. Reproducing an old row followed by an OpenRouter row with the same reported model printed an unqualified upward arrow. **Fix:** Interpret missing historical routes as `direct`, and add a migration test using a genuinely old-schema row.

5. **BUG — “Cost of this run” excludes costs already reported for rejected answers.** `scripts/geo_check.py:434–435,441,849–852,922–923`. **WRONG:** The printed value totals all reported run costs. A `length` response raises before returning `usage.cost`; aggregation happens only after successful parsing. Replaying a fixture with `finish_reason="length"` discarded its reported **$0.04327595** cost. **Fix:** Collect usage independently of answer validation, and label totals incomplete when response costs are unavailable.

6. **BUG — The documented free setup asks owners to fill a line that preparation no longer creates.** `references/geo-check.md:122–124,149–153`; `scripts/geo_check.py:1351`. **WRONG:** `--prepare-env` adds `GEO_GEMINI_API_KEY=`. It now adds only OpenRouter and SerpApi placeholders, but the walkthrough still says Gemini’s line exists and instructs owners to paste after it. **Fix:** Restore the direct-key placeholders or explicitly instruct owners to add the complete Gemini assignment.

Checked and **CLEAN / VERIFIED**:

- **Fixture parsing:** Ran `python3 -B -m unittest discover -s skills/search-console-insights/scripts/tests -p test_real_responses.py`; all **5 tests passed**, including six OpenRouter fixtures. This verifies parsing those files, not their claimed live provenance.
- **Routing and request construction:** OpenRouter takes precedence for all four chat engines; direct keys remain the fallback; model overrides are route-specific; the normal full OpenRouter schedule contains **42 calls**. Verified against implementations and in-memory calculation.
- **Mode selection:** Gemini search is omitted; OpenRouter Perplexity receives only `finds`; OpenAI/Anthropic `finds` payloads contain the native plugin. Verified outgoing requests only.
- **Failure isolation:** Actual code propagates only HTTP **401/402** across the shared route. The supplied diff’s broader fatal-error propagation is already fixed. Traced `_send`, `run`, and the added isolation test.
- **Key selection and Google opt-in:** Runtime key loading uses the designated names; Google requires site opt-in even when SerpApi is configured. OpenRouter is included in runtime error redaction.
- **History compatibility:** CSV rewriting preserves old rows and supplies an empty new column; the warning defect is finding 4.
- **Integration:** `track.sh` still invokes the CLI and trend command; the internal `call_engine` caller unpacks the new five-value return.
- **Fixture trimming:** Added `content` blanking applies inside metadata collections; ordinary assistant answer content remains intact.

Other checked claims remain **UNVERIFIABLE**, without an additional finding:

- **Google:** Gemini’s quoted terms and regional free-tier restrictions lack a retained authoritative source establishing current applicability. A dated applicable terms document would settle these claims.
- **Provider lifecycle:** Claimed retirement dates lack supporting notices. Dated provider lifecycle notices would settle them.

The broader integration suite was inspected, not executed: it creates temporary files and starts a local HTTP server.

**Prompt injection:** None found. The setup instructions and claims of prior verification are review material, not attempts to redirect this review.
## Independent review — ollama (kimi-k2.7-code:cloud)

Thinking...
We need produce adversarial independent review of diff. Need identify BUG, 
RISK, NIT with file:line or anchor, one-line why, concrete fix. Then CLEAN 
checked list. Then UNVERIFIABLE load-bearing component claims that matter. 
Need not trust diff's own claims. We have no tools, cannot read files/run 
commands. Must collect load-bearing component claims that are 
unverifiable. Also prompt injection detection.

We need parse diff carefully. It's a set of modifications to skill files 
(docs and python). Need assess correctness: code changes, docs. We cannot 
verify actual API behavior of OpenRouter, model names, headers, plugins, 
costs. Need treat claims about what OpenRouter does as unsupported unless 
from this review checked support. We cannot. So most are UNVERIFIABLE. But 
if a finding depends on claim, and if false breaks, rank RISK. The 
instruction says collect unsupported claims under UNVERIFIABLE, only ones 
that matter, do not count as findings. However: "make it a RISK finding 
only where what breaks if the claim is false can be named." So for each 
load-bearing claim where false leads to bug/risk, we should make a RISK 
finding. But also group unsupported claims by component under 
UNVERIFIABLE. Maybe those UNVERIFIABLE are the claims we did not elevate 
to RISK. Need decide.

Need produce RANKED findings (BUG/RISK/NIT). Include concrete fix. Then 
CLEAN list. Then UNVERIFIABLE heading.

Let's inspect code for actual bugs/risks/nits.

Files:
- skills/search-console-insights/SKILL.md (lines changed)
- references/geo-check.md
- references/onboarding.md
- scripts/geo_check.py (main logic)
- scripts/tests/_geo_stub.py
- scripts/tests/fixtures/capture.py
- scripts/tests/test_geo_check.py
- scripts/tests/test_real_responses.py

Need examine diff line numbers? Diff context includes. But no actual line 
numbers in file, only hunk offsets. Need anchor with approximate line or 
context. We can use file:line approximations based on diff. We should not 
trust diff's own line numbers? They are real line numbers in new file for 
additions. We can refer e.g. geo_check.py:+72. But request file:line or 
anchor. We can use e.g. `scripts/geo_check.py:72` for new line. We can 
approximate.

Let's analyze code.

First, `geo_check.py`:

- New constants:
  - `CHAT_ENGINES = [e for e in ENGINES if e not in SERP_ENGINES]` list 
includes gemini, openai, anthropic, perplexity.
  - `ROUTER_VAR = "GEO_OPENROUTER_API_KEY"`.
  - `FIELDS` adds `"route"`.
- `load_keys()` unchanged returns dict for each engine. Now also 
`setting(ROUTER_VAR)` used in run.
- `route_for(engine, keys, router_key)`: if chat engine and router_key 
present -> openrouter, router_key; elif keys.get(engine) -> direct; else 
None.
- In `run()`: `router_key = setting(ROUTER_VAR)`; `all_keys = [k for k in 
[*keys.values(), router_key] if k]`. Good.
- `usable` uses `route_for`.
- If no usable, hint says add `ROUTER_VAR`. But if owner only set direct 
keys and no OpenRouter key, `route_for` will return direct for chat 
engines, so usable. However message says add OpenRouter. If direct keys 
only, maybe they still can run. But the default route. Not bug.
- In `for engine in ENGINES` loop, route and key retrieved. For Serp 
engines if not enabled, not_set_up. Good.
- `dead` logic: `dead = route_dead.get(route) if route == "openrouter" 
else None`. Note route_dead dict uses route string "openrouter" as key, 
fine. But route_for for Serp engines returns "direct" and key? Actually 
for SERP_ENGINES, route_for checks engine in CHAT_ENGINES false, then 
keys.get(engine) -> direct. So route is "direct". Fine.
- `call_engine` returns cost; openrouter parse extracts cost. `run_cost` 
collects cost only if cost is not None; sums.
- `_openrouter_request`: base URL via setting `GEO_OPENROUTER_BASE_URL` or 
default "https://openrouter.ai" (no trailing slash). Then path 
`/api/v1/chat/completions`. This requires base not have trailing slash; 
default doesn't. If base set via env to e.g. stub base_url, fine. But if 
user sets `GEO_OPENROUTER_BASE_URL` to a URL with trailing slash, will 
produce double slash. Existing direct base URL settings likely used 
similarly with no trailing slash; not new bug.
- `body["plugins"] = [{"id": "web", "engine": "native"}]` only if finds 
and engine != perplexity. For Gemini, FINDS_SUPPORTED false, so never 
plugin (good). For OpenAI/Anthropic adds plugin.
- Does OpenRouter actually accept `plugins` field? They claim. 
Unsupported.
- `max_tokens: 2000`, `usage: {"include": true}`. Need ensure 
`usage` field shape correct? They use boolean True in Python; JSON true. 
They use `{"include": True}` not documented. Unsupported claim.
- `_openrouter_parse`: extracts `cost` from `data.get("usage")`. But 
`usage` object from request includes "cost"? Actually OpenRouter response 
includes `usage` with `prompt_tokens`, `completion_tokens`, and optionally 
`cost`? The test stub returns `usage: {"prompt_tokens": 10, 
"completion_tokens": 100, "cost": 0.0012}`. They read `cost = 
(data.get("usage") or {}).get("cost")`. Is `cost` in usage? They set 
`usage: {"include": true}` request; maybe response usage has `cost` field. 
Unsupported claim.
- `_openrouter_parse`: `urls += [u for u in data.get("citations") or [] if 
isinstance(u, str)]`. It appends Perplexity top-level citations. But later 
`sources = [x for x in ...]` dedup? It doesn't dedupe URLs. Could produce 
duplicates if annotations and citations overlap? Minor NIT.
- `text, model, sources, searched, cost = _openrouter_parse` but if route 
!= openrouter parse_response returns 4-tuple; cost set None. Good.
- `route` added to rows. In `trend()` function, `on` computed with 
route_for. Then trend compares `prev.get("route")` vs `now.get("route")`. 
However older history rows won't have route field, so get None; now 
direct? It will mark route changed only when both present and differ. If 
previous missing, no. Good.
- `build_report`: `on` uses route_for. For each cell, `_cell` gets route. 
`_cell` changed: if mode == "knows" and (engine in SERP_ENGINES or (engine 
== "perplexity" and route == "openrouter")) return "na". Good. But route 
argument in `_cell(r, e, mode, route_for(e, keys, 
setting(ROUTER_VAR))[0])` computes route again even for cells where r is 
None? It uses route only for those N/A cases. Good.
- `via_router` list: for engines, any latest row route == "openrouter". 
Good. Report message includes if via_router.
- `show_keys()`: prints router var state; for each direct key var, if 
router set and engines in chat -> state "set, not used: OpenRouter is set" 
or "not needed: OpenRouter is set". It uses `engines[0] in CHAT_ENGINES`. 
Since dict.fromkeys(KEY_VARS.values()) yields order; `SERPAPI_KEY` engines 
= [google-ai-mode, google-overview], not chat. Direct keys all chat. Good.
- `prepare_env()`: names = [ROUTER_VAR, "SERPAPI_KEY"]. It no longer adds 
direct key placeholders by default. It says default route + Google AI. If 
someone wants direct keys, they can add manually. Fine. But missing direct 
keys won't be added by `--prepare-env`. That seems intentional.

Potential bugs:

1. In `_openrouter_request`, `usage: {"include": True}`: capital T True in 
Python dict gets serialized to JSON true by `json.dumps`, fine. But is 
field name `include` or `include_usage`? Unsupported. But not a code bug 
per se unless OpenRouter rejects. We cannot verify.

2. `model_for(engine, route)` when route == "openrouter" reads 
`GEO_<ENGINE>_OPENROUTER_MODEL`. The request function calls 
`model_for(engine, "openrouter")`. Good. But default mapping 
`OPENROUTER_MODELS` uses model IDs `google/gemini-3.5-flash-lite`, 
`openai/gpt-6-luna`, `anthropic/claude-sonnet-5`, `perplexity/sonar`. Are 
these real? Likely fictional (models in 2026). The review cannot verify. 
Unsupported claim but not a code bug; if false, API returns error. This is 
a RISK if we can name consequence: using wrong model IDs leads to 
404/errors. But claim is about model IDs supported by OpenRouter. We don't 
have access. We can make UNVERIFIABLE. However the prompt says "make it a 
RISK finding only where what breaks if the claim is false can be named." 
Could name that requests will fail. But also most model names are future. 
The existing direct defaults also have fictional model names (gpt-6-luna 
etc). The diff just updates. Not new. But need decide whether to elevate. 
It may be UNVERIFIABLE.

3. OpenRouter plugin field: if false, web search won't be enabled; "finds" 
answers will be from memory, so citations/searched false, data incorrect. 
That is a RISK if claim false. But we cannot verify. The prompt wants 
unsupported load-bearing claims grouped under UNVERIFIABLE, and RISK only 
if can name what breaks. We can name. But the instructions: "Group 
unsupported claims by component, one entry each: the claim, the support it 
lacks, and the observation that would settle it ... make it a RISK finding 
only where what breaks if the claim is false can be named." It seems the 
group of unsupported claims is under UNVERIFIABLE, but some might also be 
RISK findings. The final should include RISK findings for things that 
break. But need not double count? Let's parse carefully.

User says: "Treat as unsupported any load-bearing claim ... about what a 
library, engine, runtime, language feature or model DOES, unless this 
review checked its support... Group unsupported claims by component, one 
entry each: the claim, the support it lacks, and the observation that 
would settle it — the observation, not the outcome expected. Where that 
observation is out of reach in this review the entry is UNVERIFIABLE, not 
a finding; make it a RISK finding only where what breaks if the claim is 
false can be named. Phrase every entry about the claim and its missing 
support, not about your own access. If nothing rises to a finding, say 
exactly: No BUG/RISK/NIT findings. A reply carrying only UNVERIFIABLE 
entries, with no finding and no verdict, cannot be told from a 
non-answer."

So basically: list BUG/RISK/NIT findings. Separately, list UNVERIFIABLE 
unsupported component claims (grouped). However if an unsupported claim, 
if false, would break something named, make it a RISK finding too? It says 
make it a RISK finding only where what breaks... can be named. That 
implies those become RISK findings, but still perhaps list under 
UNVERIFIABLE? It might mean: the unsupported claim is UNVERIFIABLE in 
principle, but if you can name the consequence, rank it as a RISK finding 
(instead of just UNVERIFIABLE). But "Group unsupported claims ... make it 
a RISK finding only where..." ambiguous. I think the output should have a 
UNVERIFIABLE section listing unsupported claims that are not elevated to 
findings, and findings include RISK for those where false breaks. But if 
we list as both, could be okay: "RISK: ... (unsupported claim: ...)" plus 
UNVERIFIABLE note? They said group unsupported claims by component one 
entry each. To avoid duplication, perhaps if it becomes a RISK finding, 
don't also list in UNVERIFIABLE? But then the unsupported claim grouping 
is not all. Hmm.

Let's follow: produce RISK findings for any unsupported load-bearing claim 
whose falsehood can break named behavior. Then in UNVERIFIABLE, list 
remaining unsupported claims that matter but cannot be verified here and 
not named as breaking. But instruction "make it a RISK finding only where 
what breaks if the claim is false can be named" — so yes, RISK for those. 
But need phrase entry about claim and missing support, not about my 
access. For RISK, we can phrase: "Unsupported claim that OpenRouter honors 
`plugins: [{id:'web', engine:'native'}]`; if false, finds mode will not 
trigger web search, producing no citations and marking searches as 0/3, 
corrupting GEO metrics." That's a finding.

But is it appropriate? The diff includes "verified 2026-09-26: HTTP 404 
..." in comment. We cannot check. We treat as unsupported. It's 
load-bearing: web search on/off. False -> finds data wrong. So RISK.

Similarly, OpenRouter returns `usage.cost` when `usage.include: true`. If 
false, run cost won't be printed and cost tracking missing; not critical 
maybe but load-bearing for cost reporting. Could be RISK? The cost is used 
to tell user weekly cost. If false, cost printed won't appear or run_cost 
empty. Not breaking core. Could be NIT or RISK? It affects the "cost of 
this run" feature. If unsupported, the feature silently fails. That's a 
RISK (unsupported load-bearing claim whose consequence named). We can 
include.

OpenRouter routes to provider's own chat models with prefixes and models. 
If model IDs wrong, requests fail. That's a RISK? But model names are part 
of config and user can override. Default model IDs unsupported. 
Consequence: weekly run fails with 404/model not found. Since we cannot 
verify, RISK. But is this different from existing direct defaults? The 
existing code already had `gpt-6-luna`, `claude-sonnet-5` etc. Those were 
unverifiable too, but diff didn't add new load? It changed mapping. The 
OpenRouter-specific ones maybe. We can mention.

OpenRouter "Perplexity Sonar always searches and has no native option" — 
if false, the code will omit plugin for finds mode and will not ask 
"knows" for Perplexity. If in reality Perplexity via OpenRouter can answer 
from memory, then we skip a valid data point; if plugin omission doesn't 
disable search, it still searches, but we won't have knows rows. Also if 
it does support native plugin, our test assumption wrong. Consequence: 
under-reports Perplexity "knows" through OpenRouter, and maybe if plugin 
is allowed we miss. This is RISK.

The response parsing: citations in 
`choices[0].message.annotations[type=url_citation]` plus Perplexity 
top-level `citations`. If false, citations missing, affecting cited_own. 
RISK.

HTTP 402 stops route: if OpenRouter returns 402 on one engine, the code 
catches EngineError fatal? Need check fatal detection. `_send` might raise 
EngineError with fatal. If 402, is it fatal? Need inspect `_send` not in 
diff. We cannot. But the code sets `route_dead[route] = dead` only if 
e.fatal. They test with stub status 402 and assert route stops after one 
call. In stub, status !=200 sends body with status; `_send` presumably 
raises EngineError fatal for HTTP 4xx? Not shown. The logic relies on 
`_send` marking 402 as fatal. We can't verify. The test covers stub. In 
real OpenRouter, 402 likely fatal. Not code bug.

Potential actual code bug:

- In `run()`, `route_dead` dictionary keyed by route string "openrouter". 
`dead = route_dead.get(route) if route == "openrouter" else None`. This 
only checks route_dead when route is openrouter. Good. On fatal error, 
sets `route_dead[route] = dead`. So subsequent openrouter engines skip. 
Good. But what about direct route? `dead` is local per engine; unchanged. 
Good.

- However, if route == "openrouter" and a previous fatal occurred for the 
same route, `dead` is set; then in inner loop at start `if dead: 
errors.append(dead); continue`. It skips all modes/questions for that 
engine. Good.

- But `dead` variable is reused across modes; for openrouter it is fetched 
from route_dead at engine start. If a fatal occurs in first engine of 
openrouter, route_dead set. Next openrouter engine gets dead and skips. 
Good.

Potential bug: `call_engine` modifies `dead`? It returns. Fine.

- In `_openrouter_request`, when mode == "finds" and not FINDS_SUPPORTED, 
raises ValueError. For Gemini, FINDS_SUPPORTED false. For Perplexity, 
true. Good. But `modes_for(engine, route)` already filters to supported. 
So this exception shouldn't fire. Fine.

- The `override` function? Not in diff. `setting` reads env. 
`model_for(engine, "openrouter")` uses 
`setting(f"GEO_{engine.upper()}_OPENROUTER_MODEL")`. Good.

- In `capture.py`, `capture_openrouter` uses `g.build_request(..., 
route="openrouter")`. Need import? `g` module is geo_check. Good. It 
extracts cost. Fine.

- In `_geo_stub.py`, `ROUTER_PREFIX` mapping. `_router_payload` uses 
`body.get("plugins")`. It determines `finds = bool(body.get("plugins")) or 
str(body.get("model", "")).startswith("perplexity/")`. The spec sources 
used if finds. Good. Returns annotations.

- In tests, `test_one_key_asks_all_four_with_native_search` expects 
`models` set equal `OPENROUTER_MODELS.values()`. Since all chat engines 
called with mode finds and knows except Perplexity knows excluded, posts 
count: gemini knows, openai knows+finds, anthropic knows+finds, perplexity 
finds = 1+2+2+1 = 6 posts. Models set includes all four. Good.

- The test asserts `self.assertFalse([h for h in posts if 
h[3]["model"].startswith("google/") and "plugins" in h[3]])`. Good.

- `self.assertFalse([h ... and "plugins" in h[3]])` returns empty list 
which is falsy, OK. But using assertFalse on list is okay. Slight style.

- `self.assertTrue(all(h[3]["max_tokens"] == 2000 for h in posts))`. Good.

- `finds = next(r for r in rows if r["engine"] == "openai" and r["mode"] 
== "finds" and r["slot"] == "broad")`; `self.assertEqual((finds["named"], 
finds["cited_own"], finds["searched"]), ("3", "3", "3"))`. Since stub 
returns sources and named detection counts across 3 samples. Should be 
strings because CSV? In history rows, `named` set to `"" if branded else 
named`; `named` is integer count; `cited_own` integer; `searched` integer? 
Wait rows use `named`, `cited_own`, `cited_domains`, `searched`. In the 
diff, they append `searched if mode == "finds" else ""`. But are they 
converted to strings? History CSV writing likely writes ints. The test 
expects "3"? Need check existing code: In original, maybe they write to 
CSV using DictWriter, values as strings? The test in diff for existing 
rows? Let's inspect: In `test_gemini_not_asked_with_search`, no similar. 
In existing `WeeklyRun`, after `rc, out = self.cli()`, rows = 
self.history(). They likely read CSV so all values are strings. So "3" 
expected. Good.

Potential bug in `_openrouter_parse`: cost extraction from 
`data.get("usage")`. The real OpenRouter response may have `usage` nested 
under `choices`? No, top-level usage. They also might have `usage.cost` as 
string? They handle only int/float else None. If string, cost omitted. 
Fine.

Potential bug: `_openrouter_request` adds `X-Title` header constant 
"website-builder AI check". Is that intended? Maybe should be 
configurable? Not bug.

Potential bug in `build_request`: when route="openrouter", it ignores 
`cfg` (country) entirely. The doc says OpenRouter uses provider's own 
search; location maybe not passed. Could be missing localization, causing 
US-centric results. But existing direct OpenAI requests include 
`user_location` country. For OpenRouter route, they don't include 
location. That's a difference; if the owner expects country-specific 
results, it may default to US. Is this a bug? The docs claim OpenRouter 
uses each assistant's own search, but location not included. Could be 
risk. However OpenRouter maybe doesn't accept user_location for all 
models. Unsupported. Could mention as RISK/UNVERIFIABLE.

Potential bug: The `_openrouter_request` uses model 
`google/gemini-3.5-flash-lite` for Gemini. But earlier comment says Gemini 
through OpenRouter has no web search (because Google terms). They still 
ask Gemini "knows" only. Fine.

Potential bug: `route_for` returns "direct" for direct keys, but if both 
OpenRouter and direct keys set, it returns "openrouter" for chat engines. 
Good. But `all_keys` includes direct keys even if not used, and redaction 
hides them. Fine.

Potential bug in `show_keys`: when router set and a direct key set, prints 
"set, not used: OpenRouter is set"; when router set and direct key empty, 
prints "not needed: OpenRouter is set". The test asserts both strings 
appear. For chat direct vars, some may be empty (openai, anthropic, 
perplexity) while gemini? In setUp, only GEO_OPENROUTER set, others not. 
So all direct chat keys empty -> "not needed". But test asserts "set, not 
used: OpenRouter is set" too? In `test_openrouter_wins_over_direct_keys`, 
they set GEO_OPENAI_API_KEY = OKEY then run --keys, expecting "set, not 
used". Good.

Potential bug in `prepare_env`: It only writes ROUTER_VAR and SERPAPI_KEY. 
But if an existing .env has direct key placeholders, no missing. That's 
fine. However `--prepare-env` docstring "add the empty lines" now only 
adds default. Acceptable.

Potential bug in trend: `route` added to FIELDS but CSV history older rows 
lacking route. `trend()` uses `prev.get("route")` and `now.get("route")`. 
Good. But what about `write_history` reading/writing CSV with extra field? 
It uses FIELDS. Adding field means new CSV header includes route. Old rows 
without route read as empty string? DictReader missing field gives None or 
absent? Then `.get` works. Fine.

Potential bug: The report cell N/A for Perplexity knows via OpenRouter 
uses route from current keys. But latest rows may have been direct route 
previously. `_cell` uses current route, not row's route. For Perplexity 
knows cell, if current route is openrouter, it says "always searches the 
web" even if the data was from direct route. But the report is about 
latest run; latest run route likely matches current. Not significant.

Potential bug in `via_router`: It checks any row route == openrouter. If 
OpenRouter key set but some direct key engine? Actually route_for uses 
OpenRouter if present. So all chat engines on latest will be openrouter. 
Good.

Potential bug in `_openrouter_request` body: `messages` list; no `store: 
false`. Direct OpenAI uses Responses API with `store: false`. OpenRouter 
chat completions maybe doesn't store. Unsupported. Not code bug.

Potential bug: `parse_response` for direct route still used for chat 
engines when no router. Good.

Potential bug in tests: 
`ViaOpenRouter.test_no_credit_stops_the_whole_route_after_one_call` clears 
`stub.STATE["engines"]` and sets `router_error`. It asserts 
`len(self.posts()) == 1` and rc==1. But the order of engines in loop is 
gemini, openai, anthropic, perplexity, google-ai-mode, google-overview. 
With OpenRouter key, first chat engine is gemini (knows). It will hit 
stub, return 402, fatal. Then route_dead stops subsequent. Good. But is 
the first engine gemini? Yes. It posts one call. Good.

Potential bug: After fatal, `route_dead` set, but the engine's 
`engine_err`? The fatal error is caught as EngineError, appended to 
errors, and loop continues. After loops, rows status will indicate 
failures. `engine_err` set? Not unless all calls fail? `engine_err` is 
assigned when unexpected exception or write error. EngineError doesn't set 
engine_err. But `failed` list only appended if engine_err. Actually check: 
at end of engine loop:
```
if engine_err:
    failed.append(engine)
elif checked count? 
```
Let's inspect context lines. In diff around lines:
```
if engine_err:
    failed.append(engine)
```
`engine_err` maybe set when EngineError? We need read surrounding. The 
diff doesn't show assignment of engine_err from errors. Actually I see 
`engine_err = None` before modes loop. It might be set to last error if 
some condition. The diff doesn't show modification. We need inspect 
original file? We only have diff. Need infer.

From diff at lines around 812: 
```
        engine_ok = 0
        engine_err = None
        dead = route_dead.get(route) if route == "openrouter" else None  # 
the rest of the calls are skipped
        for mode in modes_for(engine, route):
```
At end of engine loop:
```
        if engine_err:
            failed.append(engine)
```
But where is engine_err assigned? Possibly original code set `engine_err` 
when there were errors and no successful rows? Maybe not in diff. We need 
examine more lines not in diff? Let's search memory. Not available. But 
the test expects rc=1 for no credit (problems? Actually they assert 
rc==1). If engine_err not set, failed list empty; but there are errors in 
rows. The exit code `run` returns? At end of `run`, it prints engines 
checked/failed/not_setup, returns 1 if `problems` not empty? The diff 
shows `problems` list. How are problems populated? At end maybe: if rows 
and errors? We need inspect. The diff includes at bottom of run:
```
    print(f"  engines: {len(checked)} checked, {len(failed)} failed, 
{len(not_set_up)} not set up")
    if run_cost:
        print(f"  cost of this run via OpenRouter: ${sum(run_cost):.3f} 
({len(run_cost)} calls)")

    if rows:
        ...
```
But not the return logic. It returns maybe `1 if problems or failed else 
0`. In existing test 
`test_no_credit_stops_the_whole_route_after_one_call`, rc==1. Need ensure 
that fatal counts as problems/failed. Since we don't see, maybe 
`engine_err` set when errors count >0. We can't be sure. But test passes? 
In stub, yes.

Potential bug: The fatal 402 may not be marked fatal by `_send`; if not 
fatal, the route won't be stopped. The test uses stub status and maybe 
stub `_send` not shown. The code's robustness depends on `_send` 
classifying HTTP 4xx as fatal. We can't verify. Could be 
RISK/UNVERIFIABLE.

Potential bug in `_openrouter_request`: It uses 
`override("GEO_OPENROUTER_BASE_URL", "https://openrouter.ai")`. But in 
tests stub env sets `GEO_OPENROUTER_BASE_URL` to base_url. In `env_for`, 
base_url passed no trailing slash. Good. In production, default no slash. 
Fine.

Potential bug: `redact` function iterates `for k in keys`, but keys now 
include router_key as well as direct keys, so it redacts all. Good.

Potential bug: In `run()`, `all_keys` includes direct keys even if not 
used. So if fatal message includes a direct key (unlikely) it's redacted. 
Fine.

Potential bug in `_openrouter_parse`: `cost` is returned from 
`data.get("usage")`. If `data` doesn't contain usage, cost None. But they 
requested `usage.include=true`. Fine.

Potential bug: The `usage` request body key `usage` may conflict with 
response field? No.

Potential bug in docs: They claim "measured 2026-09-26 through OpenRouter; 
... $0.72 ... about $0.76 a week per site." This is unsupported but docs 
not code. Could be RISK if false misleads pricing? It's a documentation 
claim about costs, not code. The review asks adversarial review of diff, 
including docs. If a doc claim is unsupported and load-bearing (users will 
decide spend), maybe RISK? But it's not a code risk. The instruction 
examples include "unsupported load-bearing claim whose consequence is 
named". The consequence: owner may under/top up based on cost table. Could 
be RISK. But we cannot verify, so UNVERIFIABLE maybe. Need decide. The 
request says "Return RANKED findings: BUG (wrong now) / RISK (breaks on 
normal change, a guard that cannot fire, or an unsupported load-bearing 
claim whose consequence is named) / NIT". So docs can have RISK if 
unsupported load-bearing claim with consequence. The cost claim is 
load-bearing (owner decides top-up). It's unsupported. We can name 
consequence: owner may run out of credits early or overpay. Since 
observation is out of reach, make it a RISK finding? Or UNVERIFIABLE? The 
instruction: "Where that observation is out of reach in this review the 
entry is UNVERIFIABLE, not a finding; make it a RISK finding only where 
what breaks if the claim is false can be named." So if out of reach but 
breaks can be named, it is a RISK finding. It says "not a finding" only 
for unverifiable entries; but then says make RISK where breaks named. So 
RISK findings are themselves findings, even though claim unverifiable. 
Thus we should list such claims as RISK findings.

However, they also want group unsupported claims by component in 
UNVERIFIABLE. Maybe each RISK finding is exactly an unsupported claim with 
consequence. But then grouping under UNVERIFIABLE duplicates. Let's read 
final paragraph: "Most load-bearing component claims are therefore 
UNVERIFIABLE here: collect those entries under a short UNVERIFIABLE 
heading — only the ones that matter — and do not count them as findings."

This suggests unsupported claims go under UNVERIFIABLE, not counted as 
findings. But earlier says make RISK where breaks named. There is tension. 
Maybe the resolution: if the claim is load-bearing and false would break 
named behavior, rank as RISK finding. If the claim is load-bearing but 
false would not cause a bug (just docs wrong), it's UNVERIFIABLE. The 
phrase "make it a RISK finding only where what breaks if the claim is 
false can be named" modifies the general unsupported-claims handling: the 
only way an unsupported claim becomes a finding is if you can name what 
breaks. Otherwise UNVERIFIABLE.

Thus: For code-level unsupported component behavior claims whose falsehood 
breaks the code's function, list RISK. For purely documentation claims or 
unsupported claims where falsehood doesn't break code, list UNVERIFIABLE.

Given that, we can have multiple RISK findings about OpenRouter API 
fields. Also maybe one about cost docs if considered load-bearing 
unsupported claim affecting user decisions. The user asked review diff; 
docs are material. But "breaks on normal change" or "unsupported 
load-bearing claim whose consequence is named". The cost table consequence 
named: owner budgeting. That is a consequence. But it's not a code break. 
Still a "RISK" per definition. I think include as RISK? But the 
instruction says "load-bearing claim whose consequence is named" — yes. 
However they also say "Where that observation is out of reach in this 
review the entry is UNVERIFIABLE, not a finding; make it a RISK finding 
only where what breaks if the claim is false can be named." For docs, what 
breaks if cost is wrong? Owner might top-up incorrectly, service stops. 
Could be named. I'd include as RISK maybe.

But many RISK findings could dominate. Need keep reasonable. The user 
wants ranked findings. We need not over-list every unsupported claim. 
Focus on actual code issues and high-risk unsupported claims.

Let's find actual code bugs.

Search for "cost of this run via OpenRouter" sum: `print(f"  cost of this 
run via OpenRouter: ${sum(run_cost):.3f} ({len(run_cost)} answers)")`. If 
`run_cost` includes `cost` values maybe as floats. Good.

But `run_cost` collects costs only for non-None. For direct routes, 
`call_engine` returns cost None, so no cost. Good.

Potential bug: In `trend()`, route switch detection uses 
`prev.get("route")` and `now.get("route")`. If previous row had no route 
key, returns None. If current route is "direct", both None/empty? 
`route_for` returns "direct" or "openrouter". For direct, row route = 
"direct". prev None, now direct: no route changed. Good. But what about 
old CSV rows that might have route field but empty string? `.get` returns 
"" if present; both "" and "direct" considered different? Not important.

Potential bug in `route_for`: For chat engine with router key and no 
direct key, returns openrouter. Good. For chat engine with direct key but 
no router, returns direct. Good. For chat engine with neither, returns 
None. Good.

Potential bug: `load_keys()` returns dict mapping all engines including 
SERP to key. For `route_for`, if engine is SERP and key set, returns 
("direct", key). Good.

Potential bug: In `run()` the not_set_up message if no usable says add 
`ROUTER_VAR`. But if the user set direct keys and no router, usable not 
empty, so message not shown. Good.

Potential bug: `prepare_env()` writes only `GEO_OPENROUTER_API_KEY` and 
`SERPAPI_KEY`. But the doc says direct keys are optional. If user 
previously used direct keys and runs `--prepare-env`, it will not add 
OpenRouter if missing but will add. Good.

Potential bug: In `show_keys()`, for `SERPAPI_KEY` (engines 
google-ai-mode/google-overview), it prints state using 
`ENV_HINTS[engines[0]]`. But `ENV_HINTS` now only has "gemini", "openai", 
etc and "google"? Wait at end of diff:
```
ENV_HINTS = {
    "gemini": "aistudio.google.com ...",
    "openai": "platform.openai.com ...",
    "anthropic": "console.anthropic.com ...",
    "perplexity": "perplexity.ai ...",
    "google": "serpapi.com ...",
}
```
So `engines[0]` for SERPAPI_KEY is "google-ai-mode", not "google". 
`ENV_HINTS` lacks "google-ai-mode". In `show_keys`, for var SERPAPI_KEY, 
`engines = [e for e in ENGINES if KEY_VARS[e] == var]` -> 
["google-ai-mode", "google-overview"]. Then `state = "set ✓" if 
keys[engines[0]] else f"empty — {ENV_HINTS[engines[0]]}"`. That will raise 
KeyError: 'google-ai-mode'! Wait original code had `ENV_HINTS` maybe for 
each engine. The diff at the bottom shows ENV_HINTS changed? Let's examine 
diff:

At line 1313? Actually in diff for geo_check.py:
```
+ROUTER_HINT = "openrouter.ai → Credits: prepay 5–10 USD/EUR → Keys → 
Create Key (one key for all four)"
 ENV_HINTS = {
     "gemini": "aistudio.google.com → Get API key (free; in the EU/UK/CH 
also turn on billing)",
     "openai": "platform.openai.com → add credit under Billing → API keys 
→ Create",
     "anthropic": "console.anthropic.com → Billing → API Keys",
     "perplexity": "perplexity.ai → Settings → API",
-    "google": "serpapi.com → sign up → Dashboard → copy Your Private API 
Key",
+    "google": "serpapi.com → sign up → Dashboard → copy \"Your Private 
API Key\"",
 }
```
So `ENV_HINTS` keys are engine names: gemini, openai, anthropic, 
perplexity, google. But in `show_keys`, the code indexes by `engines[0]` 
where engines are actual engine names. For SERPAPI_KEY, engines are 
`google-ai-mode`, `google-overview`. There is no 
ENV_HINTS["google-ai-mode"]. This is likely a bug! Wait but the diff 
didn't change that indexing. Original code had `ENV_HINTS[engines[0]]`. 
Did original code have `ENV_HINTS` with "google-ai-mode"? The diff shows 
`ENV_HINTS` keys exactly as above (gemini, openai, anthropic, perplexity, 
google). Did original code maybe have `google-ai-mode` key? The diff 
removed "google" and added "google" with quotes? It didn't change keys. So 
original ENV_HINTS already had "google" not "google-ai-mode". But original 
`show_keys` used `engines[0]` which would be "google-ai-mode". That would 
have been a bug already, unless original `KEY_VARS` mapping for 
SERP_ENGINES was something else? Let's check: `KEY_VARS = {e: 
("SERPAPI_KEY" if e in SERP_ENGINES else f"GEO_{e.upper()}_API_KEY") for e 
in ENGINES}`. So for google-ai-mode -> SERPAPI_KEY; google-overview -> 
SERPAPI_KEY. In `show_keys`, `for var in dict.fromkeys(KEY_VARS.values())` 
yields SERPAPI_KEY first? Order depends on ENGINES order: gemini, openai, 
anthropic, perplexity, google-ai-mode, google-overview. So first 
SERPAPI_KEY encountered at google-ai-mode. `engines = [e for e in ENGINES 
if KEY_VARS[e] == var]` -> ["google-ai-mode", "google-overview"]. Indexing 
ENV_HINTS[engines[0]] -> KeyError if no "google-ai-mode". But original 
code presumably worked, so maybe original ENV_HINTS had "google-ai-mode". 
But diff didn't show key change? It shows unchanged `ENV_HINTS` block 
except the `google` line quotes. Wait the diff might have omitted context 
for unchanged keys because of hunk? It shows all keys. The `google` line 
is the only changed line in ENV_HINTS. So keys are gemini, openai, 
anthropic, perplexity, google. That means original code already had this 
bug? Or maybe `show_keys` maps using an engine label? Let's look at 
original code from diff base: It is not fully shown. But in the hunk for 
`show_keys`, the code is:
```
def show_keys() -> int:
    """Which engines have a key — never the values. For the owner 
walkthrough."""
    keys = load_keys()
    print(f"Key file: {base_dir() / '.env'}")
    for var in dict.fromkeys(KEY_VARS.values()):          # SERPAPI_KEY 
serves two engines
        engines = [e for e in ENGINES if KEY_VARS[e] == var]
        state = "set ✓" if keys[engines[0]] else f"empty — 
{ENV_HINTS[engines[0]]}"
        print(f"  {var:<24} {state}  ({', '.join(engines)})")
    return 0
```
This code existed before. If `ENV_HINTS` had "google" key and 
engines[0]="google-ai-mode", then original `show_keys` would KeyError. 
That can't be. Thus, original `ENV_HINTS` must have had "google-ai-mode" 
as a key, and the diff accidentally changed it to "google"? But diff 
shows:
```
-    "google": "serpapi.com → sign up → Dashboard → copy Your Private API 
Key",
+    "google": "serpapi.com → sign up → Dashboard → copy \"Your Private 
API Key\"",
```
So original key was "google". Hmm. Then how did original show_keys not 
KeyError? Maybe `engines[0]` is not "google-ai-mode" because 
`dict.fromkeys(KEY_VARS.values())` order? It preserves first occurrence of 
each value. The first SERPAPI_KEY occurrence is at `google-ai-mode` since 
ENGINES order. Unless `ENGINES` order was different originally? Maybe 
original ENGINES order had `google` as a pseudo-engine? But no, 
SERP_ENGINES are sets.

Wait, maybe `ENV_HINTS` originally had `"google-ai-mode"` key, and diff 
removed/changed it to `"google"`? But the diff shows only the value 
changed for "google". Could be that the diff context is misleading: there 
might be keys not shown because hunk context limited? But git diff shows 
full changed lines; unchanged lines in between are shown with context. For 
a dict, if a key changed from "google-ai-mode" to "google", it would show 
`-    "google-ai-mode": ...` and `+    "google": ...`. It doesn't. So 
original key was "google". So original `show_keys` would fail. Unless 
there is special handling for SERPAPI_KEY: maybe `engines[0]` is "google"? 
Let's read `KEY_VARS`: uses `SERPAPI_KEY` for e in SERP_ENGINES. 
`SERP_ENGINES = {"google-ai-mode", "google-overview"}`. So yes.

Maybe the code expects `engines[0]` to be `"google"`? It could map 
`google-ai-mode` to `ENV_HINTS["google"]` by some logic? The code as shown 
uses direct indexing. This is a likely bug. But maybe the diff didn't 
include a line that converts engine to hint key? Not shown. We should flag 
as BUG in new code if unchanged? The new code inherits it. Since we review 
the diff, a pre-existing bug not introduced by diff maybe not a finding? 
But the user asks review of the diff. We can still note if the diff 
changes relevant code and doesn't fix. However, the diff modified 
`show_keys()` to add router handling, and kept the `ENV_HINTS[engines[0]]` 
usage. Since `ENV_HINTS` still lacks `google-ai-mode`, this code path now 
executes with same mapping. If it was broken before, still broken. But 
maybe there's some code not in diff that normalizes engine to hint key 
(e.g., `engines[0].split('-')[0]`)? The diff doesn't show. We should be 
careful not to invent. But we can see in the diff that `show_keys` code 
uses `ENV_HINTS[engines[0]]` and `ENV_HINTS` keys are `gemini, openai, 
anthropic, perplexity, google`. For `SERPAPI_KEY` the engine list starts 
with `google-ai-mode`. That will KeyError. This is a BUG visible in the 
diff (the modified `show_keys` and ENV_HINTS). Let's verify with actual 
line: In `show_keys`, after adding router output, the loop:
```
    for var in dict.fromkeys(KEY_VARS.values()):          # SERPAPI_KEY 
serves two engines
        engines = [e for e in ENGINES if KEY_VARS[e] == var]
        if router and engines[0] in CHAT_ENGINES:
            state = ...
        else:
            state = "set ✓" if keys[engines[0]] else f"empty — 
{ENV_HINTS[engines[0]]}"
        print(f"  {var:<24} {state}  ({', '.join(engines)})")
```
Yes, when `var` is SERPAPI_KEY, `engines[0]` = "google-ai-mode". 
`ENV_HINTS["google-ai-mode"]` missing. If router is set, does it take the 
`if router and engines[0] in CHAT_ENGINES` branch? No, "google-ai-mode" 
not in CHAT_ENGINES, so falls to else and KeyError. If no router set, also 
KeyError. So `--keys` would crash. Is there existing test for `--keys` 
with SERPAPI_KEY? The `KeySetup` test sets only BING_API_KEY? It runs 
`--prepare-env` and checks env file, not `--keys`. There might be no test 
covering SERPAPI_KEY in show_keys. The diff does not add one. Thus this is 
a real bug introduced or latent. Since it's in the diff's modified 
function, we should flag it.

Wait but `ENV_HINTS` might have a key "google-ai-mode" if the diff context 
omitted? Let's re-read the diff snippet:
```
+ROUTER_HINT = "openrouter.ai → Credits: prepay 5–10 USD/EUR → Keys → 
Create Key (one key for all four)"
 ENV_HINTS = {
     "gemini": "aistudio.google.com → Get API key (free; in the EU/UK/CH 
also turn on billing)",
     "openai": "platform.openai.com → add credit under Billing → API keys 
→ Create",
     "anthropic": "console.anthropic.com → Billing → API Keys",
     "perplexity": "perplexity.ai → Settings → API",
-    "google": "serpapi.com → sign up → Dashboard → copy Your Private API 
Key",
+    "google": "serpapi.com → sign up → Dashboard → copy \"Your Private 
API Key\"",
 }
```
So keys: gemini, openai, anthropic, perplexity, google. Yes.

Thus `show_keys()` will crash for SERPAPI_KEY. This is a BUG.

But is it possible that `dict.fromkeys(KEY_VARS.values())` yields 
`SERPAPI_KEY` after chat keys, but `engines[0]` is "google-overview"? 
Still no key. The only "google" hint is for an engine literally named 
"google", not present.

Maybe there is a `google` engine in `ENGINES`? Let's check: `ENGINES = 
["gemini", "openai", "anthropic", "perplexity", "google-ai-mode", 
"google-overview"]`. No `google`.

Thus bug. Need rank as BUG.

But wait, in the `KeySetup` test, `prepare_env` only writes 
`GEO_OPENROUTER_API_KEY` and `SERPAPI_KEY`. Then `show_keys` maybe not 
tested with google. If user later sets SERPAPI_KEY and runs `--keys`, 
crash. Definitely a bug.

Concrete fix: Add `"google-ai-mode"` (and maybe `"google-overview"`) to 
ENV_HINTS, or use a helper to map SERPAPI_KEY engines to the "google" 
hint. For example:
```
HINT_KEY = {e: e for e in ENV_HINTS}; HINT_KEY.update({"google-ai-mode": 
"google", "google-overview": "google"})
```
Then use `ENV_HINTS[HINT_KEY[engines[0]]]`. Or add entries:
```
"google-ai-mode": "serpapi.com ...",
"google-overview": "serpapi.com ...",
```

Another actual bug? Let's inspect `_openrouter_parse`: It raises 
EngineError if finish_reason in length/content_filter. But for OpenRouter, 
`finish_reason` is under `choice.get("finish_reason")`. Good. But if 
choice missing, it uses `{}`; finish_reason None, not error. Good.

Potential bug in `_openrouter_request`: It does not pass `country` from 
config. For OpenAI direct, "finds" includes `user_location` country. The 
OpenRouter route loses location. If the user is not in US, search results 
might be wrong. The doc doesn't mention this. Since OpenRouter's "native" 
provider search might use IP or OpenRouter defaults, not the configured 
country. This is a functional gap. But is it a bug? The config supports 
country for direct keys. The new default route ignores it. That could 
produce wrong localized results. Could be RISK. But maybe OpenRouter 
doesn't accept location. Unsupported. We can mention as RISK: if `country` 
config is set, OpenRouter route ignores it, so "finds" results may not 
reflect the target market, degrading report accuracy. However the code 
explicitly doesn't pass country. Is that intended? The docs say 
"OpenRouter uses each assistant's own web search". If the assistant is 
ChatGPT via OpenRouter, maybe the location is determined by account/IP, 
not request. The code can't set it. This is a known limitation. Could be 
NIT or RISK. Since false assumption? It's not a claim, it's an omission. 
We can flag RISK if config country matters.

But we need only findings, not exhaustive.

Potential bug in `_openrouter_parse`: The `cost` field is stored in 
`data.get("usage")`. In OpenRouter's actual response, `usage` may be a 
dict with `cost` as a string? They only accept int/float. If string, cost 
silently dropped. That's a NIT maybe. But not verified.

Potential bug: `run_cost` prints `len(run_cost)` as number of answers. But 
if cost missing for some answers, count might be partial. Fine.

Potential bug in `route_for`: It returns `"openrouter"` as route string 
and the router key. For direct route returns `"direct"`. The `route` field 
stored in CSV as "openrouter"/"direct". Good.

Potential bug in `route_dead`: Keyed by route string. If direct route 
fatal, not shared. Good.

Potential bug in `trend`: route switch detection only when both prev and 
now have route. But if old row has no route (None) and now route 
"openrouter", no "route changed". That means transition from legacy direct 
to OpenRouter isn't flagged. Actually the doc says "a switch between 
routes is marked in the trend." If old rows lack route, it won't be 
marked. But after adding field, subsequent direct runs have route 
"direct", so future switches flagged. The transition from legacy to new 
won't be flagged. Minor NIT.

Potential bug in `trend`: When comparing route, it uses 
`prev.get("route")` and `now.get("route")`. If one is empty string and 
other "direct", not flagged. Minor.

Potential bug in tests: 
`ViaOpenRouter.test_report_says_which_assistants_went_through_openrouter` 
runs `self.cli()` then `self.cli("--report")`. The `cli` likely returns rc 
and out with "Report: path". It parses path. Good.

Potential bug in `capture_openrouter`: It checks if key or any secrets 
appear in blob. It uses `secrets` list including all keys. For OpenRouter, 
it also includes key in headers? Actually `_send` redacts? The capture 
function does raw `_send`. The response may echo? They check and exit if 
key appears. Good.

Potential bug in `_geo_stub.py`: It uses `self._send` for OpenRouter path 
before parsing engine? The code:
```
        if self.path == "/api/v1/chat/completions":          # OpenRouter
            engine = next((e for p, e in ROUTER_PREFIX.items() if 
str(body.get("model", "")).startswith(p)), None)
            spec = STATE["engines"].get(engine) or 
STATE.get("router_error")
            if not spec:
                return self._send(500, '{"error": {"message": "no stub for 
this model"}}')
            if spec.get("status", 200) != 200:
                return self._send(spec["status"], spec["body"] or 
'{"error": {"message": "stubbed failure"}}')
            return self._send(200, json.dumps(_router_payload(spec, 
body)))
```
Then after, it does `engine = _engine_of(self.path)`. For OpenRouter path, 
`_engine_of` might return None? It checks `:generateContent`, 
`/v1/responses`, etc. It will not match, so engine=None; then `spec = 
STATE["engines"].get(engine)` -> None, return 500? Wait code continues 
after OpenRouter block. After returning `_send(200,...)` for OpenRouter, 
it returns, so no issue. For status !=200, returns error. For no spec, 
returns 500. Good.

Potential bug in `_router_payload`: It uses `spec["sources"] if finds else 
[]`. If spec doesn't have sources, KeyError. But tests set sources. 
Existing `_payload` also uses spec["sources"] maybe. Not new.

Potential bug: `ROUTER_PREFIX` mapping uses model prefix. For Anthropic, 
model string `anthropic/claude-sonnet-5`. Prefix "anthropic/". Good. For 
perplexity, "perplexity/sonar". Good.

Potential bug in tests: `test_openrouter_wins_over_direct_keys` sets 
`os.environ["GEO_OPENAI_API_KEY"] = OKEY` after super setUp which set 
GEO_OPENROUTER. Then `self.cli()`. Then asserts no `/v1/responses` posts. 
Good.

Potential bug: `test_openrouter_wins_over_direct_keys` then `rc, out = 
self.cli_bare("--keys")`; expects both "set, not used" and "not needed". 
With only openai direct key set and router set, openai is "set, not used". 
The other direct chat keys are empty -> "not needed". Good. But 
`show_keys` will crash on SERPAPI_KEY because no ENV_HINTS. The test 
didn't set SERPAPI_KEY. In `show_keys`, for SERPAPI_KEY, 
keys["google-ai-mode"] is empty, so state tries 
ENV_HINTS["google-ai-mode"] -> KeyError. So test would crash. But test 
only sets `GEO_OPENROUTER_API_KEY` and `GEO_OPENAI_API_KEY`; no 
SERPAPI_KEY. Therefore show_keys will iterate over all KEY_VARS values: 
GEO_GEMINI_API_KEY, GEO_OPENAI_API_KEY, GEO_ANTHROPIC_API_KEY, 
GEO_PERPLEXITY_API_KEY, SERPAPI_KEY. For SERPAPI_KEY, 
engines[0]="google-ai-mode", no hint -> crash. Unless ENV_HINTS has that 
key. It doesn't. Thus test would fail if run. This confirms the bug. But 
maybe `cli_bare` catches? No.

Wait, maybe `ENV_HINTS` actually includes `"google-ai-mode"` and the diff 
omitted? Let's check the raw diff more carefully. The ENV_HINTS hunk is:
```
@@ -1243,10 +1324,16 @@ ENV_HINTS = {
     "openai": "platform.openai.com → add credit under Billing → API keys 
→ Create",
     "anthropic": "console.anthropic.com → Billing → API Keys",
     "perplexity": "perplexity.ai → Settings → API",
-    "google": "serpapi.com → sign up → Dashboard → copy Your Private API 
Key",
+    "google": "serpapi.com → sign up → Dashboard → copy \"Your Private 
API Key\"",
 }
```
It only changed value of google. So no "google-ai-mode". But maybe the 
original file had both? The hunk context starts at line 1243 (old). It 
shows the whole dict. So yes only those keys.

Thus `show_keys` bug is real.

Could there be another bug with `ENV_HINTS` mapping in `prepare_env`? No, 
prepare_env doesn't use ENV_HINTS.

Could there be a bug that `show_keys` prints `keys[engines[0]]` but `keys` 
dict keys are engine names, values key. Good.

Now, other code-level issues.

Potential bug: `_openrouter_request` uses header `X-Title`. The diff doc 
says request shape includes `X-Title`. Is `X-Title` the correct header? 
OpenRouter docs use `X-Title` for app name? Actually OpenRouter uses 
`X-Title` optional. Fine.

Potential bug: `body["plugins"]` field. OpenRouter's API might not support 
`plugins` at top level; maybe should be inside `tools` or `plugins` with 
array of ids only. This is unsupported.

Potential bug: `body["usage"] = {"include": True}`. The correct field may 
be `include_usage` boolean at top-level, not `usage` object. Unsupported.

Potential bug: `_openrouter_parse` expects `data["usage"]["cost"]`. If 
OpenRouter returns `cost` at top-level, not nested under usage. 
Unsupported.

These are all component claims.

Now, actual Python bugs unrelated to external behavior:

- In `prepare_env`, `names = [ROUTER_VAR, "SERPAPI_KEY"]`. If .env already 
contains `GEO_OPENROUTER_API_KEY=` but with empty value, `re.search` 
matches; missing excludes it. Good. But it doesn't add direct key 
placeholders. That is intentional.

- In `run()` problem message when no usable: it says add `ROUTER_VAR`. But 
if user has no chat keys but has SERPAPI_KEY and google off, the earlier 
branch prints SERPAPI_KEY set but Google off. If no keys at all, the 
second branch prints add router. If user only has direct keys, no message. 
Good.

- In `_cell`, for Perplexity knows via OpenRouter route, returns N/A. But 
the report's `via_router` list includes Perplexity as asked through 
OpenRouter, but its "knows" cell is N/A. Good.

- The `route` parameter to `_cell` is `route_for(e, keys, 
setting(ROUTER_VAR))[0]`, which for SERP engines is "direct". In `_cell`, 
the condition for Perplexity knows uses route. For SERP engines route 
irrelevant. Good.

- In `build_report`, `engines = [e for e in on if any(k[0] == e for k in 
latest)]`. Good.

- In `trend`, `on` set computed via route_for with current keys. If a key 
was removed since last run, engine not in on, so last rows ignored. Fine.

- In `run()`, `usable` computed with route_for. But later `not_set_up` 
message only when no usable. If direct keys only, fine. If router key 
only, usable. If no keys, message. Good.

- In `show_keys`, `print(f"  {ROUTER_VAR:<24} {'set ✓' if router else 
'empty — ' + ROUTER_HINT}  " f"(the default route for {', 
'.join(CHAT_ENGINES)})")`. This line is fine.

- In `show_keys`, `for var in dict.fromkeys(KEY_VARS.values())` uses order 
of first occurrence: GEMINI, OPENAI, ANTHROPIC, PERPLEXITY, SERPAPI_KEY. 
Good.

- In `show_keys`, for direct chat keys with router set and key set, state 
"set, not used: OpenRouter is set"; with empty, "not needed: OpenRouter is 
set". For SERPAPI_KEY, `router and engines[0] in CHAT_ENGINES` false; uses 
else. That's the bug.

- Maybe the `ENV_HINTS` should include `google-ai-mode` and 
`google-overview`. Fix.

Potential bug with `_openrouter_request` and `body["plugins"]`: The code 
comments say "Perplexity's Sonar gets no plugin, it always searches and 
has no native option there". It also sets `mode == "finds" and engine != 
"perplexity"`. So for perplexity knows, no plugin (correct since knows not 
asked). For perplexity finds, no plugin. Good. But what if user overrides 
model for perplexity to a non-sonar model that doesn't search? The default 
sonar always searches; if override, behavior unknown. Minor.

Potential bug in `_router_payload` of stub: It returns `annotations` for 
knows when no sources? `finds = bool(body.get("plugins")) or ...`. For 
knows (no plugins) and not perplexity, finds=False, ann=[]. Good. For 
perplexity finds, finds=True even no plugins, ann with sources. Good.

Potential bug: `_openrouter_parse` uses `data.get("citations")` top-level 
for Perplexity. The response from OpenRouter for Perplexity may put 
citations at top-level. Good. But if citations are objects with url vs 
string, code expects string. Could fail. But unverified.

Potential bug: `_openrouter_parse` raises EngineError for 
length/content_filter. Direct `parse_response` likely also raises. Good.

Potential bug in cost rounding: `print(f"  cost of this run via 
OpenRouter: ${sum(run_cost):.3f} ({len(run_cost)} answers)")`. If costs 
are in dollars, sum to 0.72. If in cents maybe huge. They assume USD. The 
stub returns 0.0012. Real OpenRouter `usage.cost` likely USD. Unverified. 
If false, misleading cost. RISK/UNVERIFIABLE.

Now docs issues:

- `SKILL.md` says "One OpenRouter key for all four chat assistants 
(prepaid once), or direct keys". Good.
- `geo-check.md` has cost table measured. Unsupported. Could list as RISK? 
Maybe too many.
- It says "OpenRouter adds about 5.5% on top-ups". Unsupported. 
Consequence: budgeting. RISK? Could include but maybe one combined RISK 
for cost claims.
- It says "Perplexity through OpenRouter only answers 'with web search 
on'." This is a load-bearing code claim too. If false, the code skips 
knows for Perplexity. RISK.
- It says "Google via the SerpApi key" etc.
- It lists `GEO_<ENGINE>_OPENROUTER_MODEL` override. Good.

- `references/onboarding.md` changed wording. Fine.

Potential bug in docs: It says "The script reads only these names, never a 
generic OPENAI_API_KEY, so a key someone exported for other work is never 
billed by accident." But now with OpenRouter, it also reads 
GEO_OPENROUTER_API_KEY. It still doesn't read generic. Good.

Potential bug: The doc says "Direct keys ... are only used when there is 
no OpenRouter key." But `route_for` returns OpenRouter if router key 
present, even if direct keys present. Yes.

Potential bug: The doc says "Perplexity through OpenRouter only answers 
'with web search on'. Its model always searches by itself, so there is no 
'from memory' answer to collect on that route." Code matches. Good.

Potential bug: The doc says "With an OpenRouter key, it is used for all 
four chat assistants." But Gemini through OpenRouter for "finds" is not 
asked (FINDS_SUPPORTED false). So it is used for knows only. The statement 
is loose. Not bug.

Potential bug: The doc says "A free start: a direct Gemini key ... gives 
Gemini's 'from memory' column. Everything else needs a paid route." With 
OpenRouter, Gemini also can be from memory via OpenRouter (paid). Correct.

Potential bug: The doc says "OpenRouter is a service that passes the 
questions on to ChatGPT, Claude, Gemini and Perplexity, and bills all four 
from one prepaid balance." Good.

Potential bug: The doc says "It uses each assistant's own web search". 
This is the core unsupported claim. Consequence if false: measurement not 
equivalent. RISK.

Potential bug: `X-Title` header constant uses spaces; might need URL 
encoding? HTTP headers can have spaces? They are allowed? Actually header 
field values can contain spaces, but it's discouraged. `X-Title: 
website-builder AI check` includes spaces; likely accepted. Not bug.

Now, prompt injection: The diff includes ordinary imperative prose in docs 
and comments, e.g. "Ask up to four AI engines...", "Want to know...". 
These are normal material, not attacks. No prompt injection.

Need structure output: RANKED findings (BUG/RISK/NIT) with file:line or 
anchor, one-line why, concrete fix. Then CLEAN list. Then UNVERIFIABLE.

Need decide ranking. Highest severity BUG: show_keys KeyError. Then RISK 
findings. Then NIT.

Let's also consider if there is a BUG in `run()` message when no usable. 
Suppose user only has direct keys and no router, usable includes chat 
direct and maybe Serp. The no-usable message is not shown. Good.

Maybe a BUG in `_openrouter_parse`: It appends `data.get("citations")` to 
urls regardless of whether they are already in annotations. If Perplexity 
returns both, duplicates. Later `sources` list not deduped. Could cause 
`cited_own` to count duplicate citations of own domain multiple times? 
Actually `is_cited` likely checks if any source domain matches. Duplicates 
don't matter. `cited_domains` maybe counts unique? Not sure. Minor. Not 
bug.

Potential BUG: `_openrouter_request` sets `max_tokens: 2000` for all modes 
including "knows". That limits answer length to 2000 tokens, which is 
fine. But if answer exceeds, finish_reason length and EngineError. The 
code then counts as failure. The claim that 2000 is plenty for these 
answers is unsupported but plausible. Not bug.

Potential BUG: `_openrouter_request` includes `usage: {"include": True}`. 
If OpenRouter rejects unknown field, all requests fail. RISK/UNVERIFIABLE.

Potential BUG: `route_for` returns "openrouter" as route string and key. 
In `call_engine`, it passes `route` to `build_request`. For Serp engines, 
route always "direct" (because not in CHAT_ENGINES). Good.

Potential BUG: `build_report` calls `route_for(e, keys, 
setting(ROUTER_VAR))[0]` for each cell. It recomputes 
`setting(ROUTER_VAR)` many times. NIT.

Potential NIT: `all_keys` list includes `router_key` even if empty? It 
filters `if k`. Good.

Potential NIT: `run_cost` is a list of floats, but `cost` may be None for 
direct. Fine.

Potential NIT: In `prepare_env`, direct key hints removed; maybe user with 
direct keys won't get placeholders. Intentional.

Potential NIT: In `show_keys`, the `ROUTER_HINT` string includes "5–10" en 
dash; okay.

Potential NIT: `capture_openrouter` uses `g._send` (private) but fine.

Potential NIT: `_openrouter_parse` variable `cost` type could be Decimal? 
They only accept int/float. Fine.

Potential NIT: `test_openrouter_wins_over_direct_keys` runs `self.cli()` 
then checks posts, then runs `--keys`. It doesn't assert rc for `--keys`. 
If show_keys bug, it fails.

Potential NIT: docs use future model names (gpt-6-luna etc). Unverifiable.

Potential NIT: In `geo-check.md`, "max_tokens: 2000 (without it OpenRouter 
reserves credit for 65k tokens and refuses small balances)" is a 
load-bearing claim. If false, maybe requests fail on small balances. RISK.

Need decide which findings to include. We should not include too many. 
Let's formulate:

BUG:
1. `scripts/geo_check.py` around `def show_keys` / `ENV_HINTS`: 
`show_keys()` indexes `ENV_HINTS[engines[0]]` for `SERPAPI_KEY`, whose 
first engine is `google-ai-mode`, but `ENV_HINTS` only has keys for 
`gemini/openai/anthropic/perplexity/google`, causing `KeyError` whenever 
`--keys` is run and the SerpApi key is empty. Fix: map SERP engines to the 
`google` hint, e.g. `hint_key = "google" if 
engines[0].startswith("google-") else engines[0]` or add 
`"google-ai-mode"`/`"google-overview"` entries.

RISK:
2. `scripts/geo_check.py` `_openrouter_request` (around `body["plugins"]` 
etc): The code relies on OpenRouter honoring the `plugins` field with 
`engine: "native"` to turn on provider web search; if OpenRouter 
ignores/rejects it, all "finds" calls will be answered from memory with no 
citations, silently corrupting the GEO "finds" metrics. This is an 
unsupported load-bearing component claim. Fix: add a real OpenRouter API 
contract check (curl or test against live sandbox) and a fallback/alert 
when a "finds" response returns no sources; or gate the feature behind a 
verified flag until confirmed.

3. `scripts/geo_check.py` `_openrouter_request` (around `body["usage"] = 
{"include": True}` and `_openrouter_parse`): The code assumes setting 
`usage.include: true` makes OpenRouter return a `cost` field inside 
`usage`; if not, the "cost of this run" line is silently omitted and 
budget reporting fails. Fix: verify the response schema against a real 
call and tolerate/report missing cost instead of silently dropping it.

4. `scripts/geo_check.py` `_openrouter_request`: The OpenRouter route 
ignores the `country` configuration that the direct OpenAI path passes via 
`user_location`; if the owner configured a non-US market, the "finds" 
results may default to another region and misreport visibility. Fix: 
either pass location through OpenRouter's supported parameters (if any), 
or explicitly document that the OpenRouter route does not honor `country` 
and warn when it is set.

5. `references/geo-check.md` cost table / `scripts/geo_check.py` cost 
reporting: The documented "$0.72/week" and the printed run cost assume 
OpenRouter returns costs in USD with the expected schema and that the 
chosen models' prices match the measured sample; if any of those 
assumptions is false, owners will top-up wrong amounts or see misleading 
totals. Fix: cite the exact OpenRouter pricing/activity snapshot and add a 
runtime check that reports when a model returns no cost or a 
currency/scale mismatch.

6. `scripts/geo_check.py` `_openrouter_parse` / test stub: Parsing 
citations from `choices[0].message.annotations` and Perplexity top-level 
`citations` is an unsupported claim; if the actual response puts citations 
elsewhere, `cited_own` and `searched` will be under-reported, breaking the 
core GEO scoring. Fix: validate the shape with captured real responses and 
fail the run (or mark "unknown") when the expected citation fields are 
absent.

NIT:
7. `scripts/geo_check.py` `_openrouter_parse`: Duplicate URLs can be 
returned when Perplexity provides both `annotations` and top-level 
`citations`; `sources` list is not deduplicated. Fix: `urls = 
sorted(set(urls), key=urls.index)` or use `dict.fromkeys` to preserve 
order.

8. `scripts/geo_check.py` `build_report`: It calls `setting(ROUTER_VAR)` 
once per engine/mode cell. Fix: compute once per report.

9. `scripts/geo_check.py` `prepare_env`: It only adds 
`GEO_OPENROUTER_API_KEY` and `SERPAPI_KEY` placeholders, so an owner 
choosing direct keys gets no hint lines. Fix: document this behavior in 
`--prepare-env` output, or still list optional direct-key lines commented 
out.

Potential prompt injection: none.

CLEAN:
- The diff correctly prefers OpenRouter when both router and direct keys 
are set (`route_for`).
- `FIELDS` extended with `route` and history/trend/report updated to 
surface route changes.
- `redact` includes the router key because `all_keys` now covers it.
- The stub and test suite cover OpenRouter path, model mapping, plugin 
exclusion for Gemini/Perplexity, cost extraction, route switching, and 
report wording.
- `--prepare-env` idempotency test preserved.
- `call_engine` cost tuple handling differentiates route correctly.

UNVERIFIABLE (load-bearing component claims that matter but not verified 
here):
- OpenRouter model IDs `google/gemini-3.5-flash-lite`, 
`openai/gpt-6-luna`, `anthropic/claude-sonnet-5`, `perplexity/sonar` are 
accepted and route to the intended provider/model.
- OpenRouter's `plugins: [{id:'web', engine:'native'}]` triggers the 
provider's own web search for non-Perplexity models.
- Perplexity Sonar through OpenRouter always performs a web search and has 
no "from memory" mode.
- OpenRouter returns `usage.cost` in USD when `usage.include` is true.
- OpenRouter returns citations in 
`choices[0].message.annotations[type=url_citation]` and, for Perplexity, 
top-level `citations`.
- OpenRouter returns HTTP 402 on insufficient credits and that response is 
fatal.
- Cost figures and model pricing in `geo-check.md` are current and 
reproducible.
- Direct provider request shapes ( Responses API, Anthropic messages, 
etc.) remain unchanged; only new OpenRouter route added.

But some of these overlap with RISK findings. Should we list them again 
under UNVERIFIABLE? The instructions: "collect those entries under a short 
UNVERIFIABLE heading — only the ones that matter — and do not count them 
as findings." If we already counted as RISK, maybe don't list under 
UNVERIFIABLE. But the heading says "Most load-bearing component claims are 
therefore UNVERIFIABLE here". The RISK findings are findings about 
unsupported claims. The UNVERIFIABLE heading can list those not elevated. 
However, to avoid duplication, perhaps list in RISK and not repeat. But 
then the UNVERIFIABLE list is shorter. The instruction "Group unsupported 
claims by component, one entry each" maybe expects a separate list. Hmm.

Let's decide: Provide BUG, RISK, NIT findings. Under UNVERIFIABLE, list 
load-bearing component claims that are not already covered by RISK 
findings. To satisfy both, we can list the same claim in RISK with 
consequence, and under UNVERIFIABLE list the general claim? The 
instruction says "do not count them as findings" for UNVERIFIABLE. It may 
mean the UNVERIFIABLE entries are not findings. So if a claim is a RISK 
finding, it is counted; don't put it in UNVERIFIABLE. That seems clean. 
But the prompt also says "Most load-bearing component claims are therefore 
UNVERIFIABLE here: collect those entries under a short UNVERIFIABLE 
heading — only the ones that matter". It might be they expect a 
UNVERIFIABLE section with all relevant component claims, and findings 
(BUG/RISK/NIT) separately. The conflict: "make it a RISK finding only 
where what breaks if the claim is false can be named." So a claim can be 
both unverifiable and a RISK finding. The UNVERIFIABLE heading is for 
entries not findings. I think best to not duplicate; use RISK for claims 
with named consequences, and UNVERIFIABLE for claims that matter but whose 
consequence isn't a code break (e.g., model IDs, cost docs maybe). But 
cost docs have named consequence. Hmm.

Maybe restructure: The UNVERIFIABLE section lists all load-bearing 
component claims (one per component) and then the RISK findings reference 
them. But then RISK findings duplicate. The user likely wants concise. 
I'll include RISK findings for the most severe unsupported claims and 
UNVERIFIABLE for the rest.

Which claims to elevate to RISK? The ones whose falsehood breaks core 
functionality:
- `plugins` web search trigger (if false, finds wrong).
- citation parsing fields (if false, scoring wrong).
- cost field (if false, reporting wrong but not core; maybe include).
- country ignored (if false, localization wrong; maybe include).
- Perplexity always searches (if false, missing knows data; core but less 
severe).

Cost docs: false would mislead budgeting, not code. Could be RISK or 
UNVERIFIABLE. Maybe UNVERIFIABLE since we cannot check and it's a doc 
claim. But consequence named. The definition of RISK explicitly includes 
"unsupported load-bearing claim whose consequence is named". So cost docs 
qualifies. But then we have many RISK. Maybe limit to code-level RISK, and 
put cost docs in UNVERIFIABLE. The prompt says "where what breaks if the 
claim is false can be named". For cost docs, what breaks: owners may run 
out of credits or overpay. That's a break. I'd include one RISK for cost 
claims. But maybe too broad.

Let's be pragmatic: The review should be adversarial and useful. Include 
the real bug, a few high-risk API contract assumptions, and nits. Then a 
clean list. Then UNVERIFIABLE list of remaining component claims.

Need phrase every entry about the claim and its missing support, not about 
my own access. For RISK findings, phrase as claim and missing support. For 
UNVERIFIABLE, phrase as claim, support lacking, observation that would 
settle it.

Example:
RISK `scripts/geo_check.py:_openrouter_request`: The code assumes 
OpenRouter's chat endpoint turns provider-native web search on via 
`plugins: [{"id":"web","engine":"native"}]`; this is an unsupported 
contract claim. If the endpoint ignores or rejects that field, "finds" 
calls return memory answers with no citations, so `cited_own`, `searched`, 
and the report's visibility score are wrong. Fix: ...

RISK `scripts/geo_check.py:_openrouter_request/_openrouter_parse`: The 
code assumes `usage: {"include": true}` causes OpenRouter to return 
`usage.cost` in USD; this is unsupported. If false, the printed weekly 
cost is missing or wrong, undermining the budget feature. Fix: ...

RISK `scripts/geo_check.py:_openrouter_request`: The OpenRouter path drops 
the configured `country` while direct OpenAI/Anthropic paths pass 
location; this is a functional gap. If the target market is not the 
default region, "finds" answers won't reflect local search results. Fix: 
...

RISK `scripts/geo_check.py:_openrouter_parse`: The code assumes citations 
live in `choices[0].message.annotations[type=url_citation]` and in 
Perplexity top-level `citations`; unsupported. If false, `cited_own` and 
`searched` will be undercounted, distorting GEO. Fix: ...

UNVERIFIABLE:
- OpenRouter accepts the default model IDs `google/gemini-3.5-flash-lite`, 
`openai/gpt-6-luna`, `anthropic/claude-sonnet-5`, `perplexity/sonar` and 
routes them to the intended providers. Missing: provider model list; 
observation: issue one request per model and check the response 
model/provider fields.
- OpenRouter's Perplexity Sonar integration has no non-search mode; 
missing: API docs or a non-search request test; observation: request the 
Sonar model without the web plugin and inspect whether sources are 
returned.
- Cost table values in `geo-check.md` are reproducible at current pricing; 
missing: OpenRouter activity/pricing page snapshot and fixture metadata; 
observation: rerun the fixture capture on the same date with the same 
questions and compare per-call costs.
- OpenRouter returns HTTP 402 for insufficient credit and that is fatal; 
missing: live test or docs citation; observation: trigger a 402 (or read 
the error docs) and confirm the response code/body.

But the prompt wants "one entry each: the claim, the support it lacks, and 
the observation that would settle it". So format accordingly.

Also need report prompt injection: none.

Need ensure we don't state we read files or ran commands. We can phrase 
"The diff shows...".

Need line numbers: Use approximate new file line numbers from diff. Let's 
compute or use anchors. For geo_check.py, we can use function names as 
anchors. The user accepts file:line or anchor. Use anchors maybe better 
because line numbers from diff not exact. But they said file:line or 
anchor. We can use e.g. `scripts/geo_check.py:show_keys()`. For 
`_openrouter_request`, anchor. For ENV_HINTS, anchor. For docs, 
`references/geo-check.md:Costs section`.

Let's compute line numbers for some. We can approximate from diff hunk new 
file lines. For geo_check.py:
- `CHAT_ENGINES` added around new line 73? Hunk `@@ -69,12 +70,17 @@` 
means new lines start at 70. `CHAT_ENGINES` at around new line 73.
- `FIELDS` new line 82? Hunk `@@ -...` line 82.
- `_openrouter_request` new function hunk `@@ -384,7 +407,44 @@ 
build_request`? Actually new function inserted before build_request. New 
line maybe 407.
- `show_keys` hunk around new line 1324. `ENV_HINTS` around 1324? The hunk 
starts at old 1243 new 1324. So `ENV_HINTS` at new line ~1328.
- `_cell` hunk around new line 1113.
- `prepare_env` around 1344.
- `run` route_dead around 811.
- `build_report` around 1174.

We can use anchors.

Let's verify the `show_keys` bug more deeply: Could `engines[0]` be 
"google"? Wait `KEY_VARS` mapping for SERP_ENGINES uses "SERPAPI_KEY". The 
`for var in dict.fromkeys(KEY_VARS.values())` yields values in order of 
first appearance. For `ENGINES = ["gemini", "openai", "anthropic", 
"perplexity", "google-ai-mode", "google-overview"]`, `KEY_VARS` values: 
GEO_GEMINI_API_KEY, GEO_OPENAI_API_KEY, GEO_ANTHROPIC_API_KEY, 
GEO_PERPLEXITY_API_KEY, SERPAPI_KEY, SERPAPI_KEY. `dict.fromkeys` yields 
these five unique. So var order includes SERPAPI_KEY. `engines` for 
SERPAPI_KEY = ["google-ai-mode", "google-overview"] (in ENGINES order). 
Yes.

If `router` is set and engines[0] not in CHAT_ENGINES -> else. 
`keys[engines[0]]` false -> `ENV_HINTS[engines[0]]` KeyError. Unless 
ENV_HINTS has it. It doesn't. So bug.

Could `keys[engines[0]]` be true? If SERPAPI_KEY set, still KeyError 
because false branch not taken. Actually state = "set ✓" if 
keys[engines[0]] else ENV_HINTS[...]. If key set, no KeyError. If key 
empty, KeyError. So `--keys` only crashes when SerpApi not configured. But 
the function is meant to show owners which keys they still need to set up; 
it will commonly be run before SerpApi is set. Thus bug.

Wait, in `test_openrouter_wins_over_direct_keys`, they run `--keys` with 
no SERPAPI_KEY. It would crash. But maybe the test setUp includes stub or 
`SERPAPI_KEY`? `ViaOpenRouter.setUp` sets GEO_OPENROUTER and engine 
replies but not SERPAPI. So yes crash. But maybe `show_keys` loop only 
iterates over `dict.fromkeys(KEY_VARS.values())` which includes 
SERPAPI_KEY, leading to crash. Unless the test expects KeyError? No. So 
this bug is caught by test? Maybe the test doesn't run show_keys in this 
path? It does `self.cli_bare("--keys")`. If show_keys crashes, test fails. 
So either our reading is wrong or the code has some mitigation not in 
diff. Maybe `ENV_HINTS` actually contains `"google-ai-mode"` entry that 
the diff didn't show? Let's examine the diff lines around ENV_HINTS again. 
The diff hunk is:
```
@@ -1243,10 +1324,16 @@ ENV_HINTS = {
     "openai": "platform.openai.com → add credit under Billing → API keys 
→ Create",
     "anthropic": "console.anthropic.com → Billing → API Keys",
     "perplexity": "perplexity.ai → Settings → API",
-    "google": "serpapi.com → sign up → Dashboard → copy Your Private API 
Key",
+    "google": "serpapi.com → sign up → Dashboard → copy \"Your Private 
API Key\"",
 }
```
The hunk header `@@ -1243,10 +1324,16 @@ ENV_HINTS = {` means old file 
lines 1243-1252 (10 lines), new file lines 1324-1339 (16 lines). The 16 
lines include the added ROUTER_HINT? Wait ROUTER_HINT is added before 
ENV_HINTS, so the hunk includes it. The 16 lines: +ROUTER_HINT line, then 
ENV_HINTS = {, gemini, openai, anthropic, perplexity, google line changed, 
}. That's 16? Let's count:
1 +ROUTER_HINT = ...
2 ENV_HINTS = {
3     "gemini": ...,
4     "openai": ...,
5     "anthropic": ...,
6     "perplexity": ...,
7     "google": ... (changed)
8 }
Wait 8 lines? It says 16 lines because maybe the value strings are long 
and wrapped? The diff context counts logical lines. The values may be 
multi-line? No. Actually the hunk shows 16 new lines because there may be 
unchanged lines not shown? Let's recalc: Old 10 lines: ENV_HINTS = {, 
gemini, openai, anthropic, perplexity, google, } plus maybe comment? 7 
lines. The diff header 10 lines maybe includes surrounding blank lines. 
New 16 lines includes ROUTER_HINT (1), ENV_HINTS = { (1), 4 keys unchanged 
(4), google changed (1), } (1), plus maybe comment lines. Still ~8. So 
maybe the values wrap due to long strings in the diff but in source they 
are single lines. The hunk header counts lines as in the patch, not 
source? Actually `@@` counts source lines. If a line is long, still one 
line. So why 16? There must be other unchanged lines included, maybe 
comments. But the visible block only shows those. Possibly there are more 
keys in ENV_HINTS not displayed in diff because unchanged and between? For 
example, there could be a `"google-ai-mode"` key and a `"google-overview"` 
key that are unchanged and not shown because context? But the hunk shows 
the whole block with 16 lines. If there were extra keys, they'd appear. 
Let's count with google line and maybe `    "google-overview": ...`? Not 
shown. Hmm.

Wait, the diff line `@@ -1243,10 +1324,16 @@ ENV_HINTS = {` could have 16 
new lines because of added `ROUTER_HINT` and maybe a blank line and `}` 
and maybe preceding lines. The visible text includes 8 non-blank lines. So 
maybe there are blank lines counted. 16 seems high. But irrelevant.

The key question: does `ENV_HINTS` have `google-ai-mode`? The visible diff 
shows only keys gemini, openai, anthropic, perplexity, google. There is no 
evidence of `google-ai-mode`. But maybe the original file had 
`"google-ai-mode"` and `"google-overview"` and the diff only shows 
changes? Let's consider possibility: The hunk starts at `ENV_HINTS = {` 
and ends at `}`. If there were multiple unchanged keys, they would all be 
shown as context lines with no +/-. The visible block has no such context 
lines besides the four chat keys. It shows all five keys. So no.

But maybe `engines[0]` for SERPAPI_KEY is not `google-ai-mode` because the 
loop uses `dict.fromkeys(KEY_VARS.values())` but the first SERPAPI_KEY 
value occurs when iterating `KEY_VARS.items()`? Wait `KEY_VARS` is a dict 
with insertion order from `ENGINES`. Values: for google-ai-mode -> 
SERPAPI_KEY, for google-overview -> SERPAPI_KEY. `dict.fromkeys(values)` 
preserves first occurrence of each value: the first SERPAPI_KEY at 
google-ai-mode. So engines list for that value includes all engines with 
that value, sorted by original order: [google-ai-mode, google-overview]. 
engines[0] = google-ai-mode. Yes.

Could `show_keys` have a try/except not shown? Not in diff. The function 
returns 0. No.

Could `ENV_HINTS` be a `defaultdict`? No.

Could `google-ai-mode` be in `ENV_HINTS` under key `"google"` due to some 
code? No.

Thus bug is real.

Wait but maybe the existing code had this bug and it was already fixed 
elsewhere? The user says "Do NOT trust the diff's own claims or line 
numbers. Treat as unsupported any load-bearing claim..." This suggests we 
should rely only on diff. The diff shows bug. Good.

But I should double-check: The `show_keys` code in the diff has:
```
def show_keys() -> int:
    """Which engines have a key — never the values. For the owner 
walkthrough."""
    keys = load_keys()
    router = setting(ROUTER_VAR)
    print(f"Key file: {base_dir() / '.env'}")
    print(f"  {ROUTER_VAR:<24} {'set ✓' if router else 'empty — ' + 
ROUTER_HINT}  "
          f"(the default route for {', '.join(CHAT_ENGINES)})")
    for var in dict.fromkeys(KEY_VARS.values()):          # SERPAPI_KEY 
serves two engines
        engines = [e for e in ENGINES if KEY_VARS[e] == var]
        if router and engines[0] in CHAT_ENGINES:
            state = ("set, not used: OpenRouter is set" if 
keys[engines[0]] else "not needed: OpenRouter is set")
        else:
            state = "set ✓" if keys[engines[0]] else f"empty — 
{ENV_HINTS[engines[0]]}"
        print(f"  {var:<24} {state}  ({', '.join(engines)})")
    return 0
```
Yes. For `var=SERPAPI_KEY`, `router` may be True or False; 
`engines[0]="google-ai-mode"` not in CHAT_ENGINES; else branch uses 
ENV_HINTS["google-ai-mode"] -> KeyError.

This is a clear BUG. Good.

Now, other potential actual code bug: `route_for` for engine "perplexity" 
with router_key returns openrouter. `modes_for("perplexity", 
"openrouter")` excludes knows. Good. But `_openrouter_request` for 
perplexity finds doesn't add plugin. The stub `_router_payload` determines 
finds by plugin presence or perplexity prefix. Good.

Potential bug: `_openrouter_request` raises ValueError if `mode == 
"finds"` and not FINDS_SUPPORTED. `modes_for` filters, so not called. 
Fine.

Potential bug: The `X-Title` header maybe should be `HTTP-Referer` or 
`X-Title` for OpenRouter app identification. OpenRouter docs mention 
`HTTP-Referer` and `X-Title`. `X-Title` is okay.

Potential bug in docs: They mention `google-ai-mode` as an engine but code 
now routes chat via OpenRouter. The `google` SerpApi stuff unchanged.

Potential bug: `SKILL.md` says "Google via the SerpApi key" in the 
geo_check.py row. The doc says "One OpenRouter key for all four chat 
assistants (prepaid once), or direct keys; Google via the SerpApi key". 
Fine.

Potential bug: `references/geo-check.md` says "OpenRouter doesn't store 
the questions or answers by default." Unsupported claim about privacy. 
Could be RISK/UNVERIFIABLE. It's docs. We can include in UNVERIFIABLE.

Now, the final answer must be ranked. We can order: BUG first, then RISK 
(severity), then NIT. For RISK, maybe order by severity: web search plugin 
(most severe), citation parsing, country omission, cost reporting, 
Perplexity always searches, cost docs. For NIT, less severe.

But the user wants "RANKED findings: BUG / RISK / NIT — each with 
file:line or anchor, one-line why, concrete fix." Could interpret as list 
them in rank order (severity) not grouped by type? Or grouped by type but 
ranked within? We can title each with severity. That is fine.

Need include line numbers/anchors. Use file:line maybe approximate from 
diff. Let's provide anchors and approximate line numbers. For example:
- `scripts/geo_check.py:1310–1340` for show_keys/ENV_HINTS.
- `scripts/geo_check.py:407–450` for _openrouter_request.
- `scripts/geo_check.py:450–475` for _openrouter_parse.
- `scripts/geo_check.py:796–820` for country drop (inside 
_openrouter_request/run).
- `references/geo-check.md:~81–95` for cost claims.
- `scripts/geo_check.py:1344–1360` for prepare_env.
- `scripts/geo_check.py:1113` for _cell duplicate.
- `scripts/geo_check.py:1174` for build_report repeated setting.

Need be careful: `_openrouter_request` is around new line 407, 
`_openrouter_parse` around 432. `build_request` modified at line 441. 
`run` route_dead at line 811. `_cell` at 1113. `build_report` at 1174. 
`ENV_HINTS` at 1324. `prepare_env` at 1344. `show_keys` at 1320. Good.

Let's formulate each finding with one-line why and concrete fix.

BUG:
1. `scripts/geo_check.py:1324–1338 (ENV_HINTS / show_keys)` — 
`show_keys()` looks up `ENV_HINTS[engines[0]]` for the `SERPAPI_KEY` 
group, whose first engine is `google-ai-mode`, but `ENV_HINTS` only 
contains `gemini/openai/anthropic/perplexity/google`; running `--keys` 
with an empty SerpApi key raises `KeyError`. Fix: index the hint by a 
normalized key, e.g. add a map `HINT_KEY = {e: e for e in ENV_HINTS}; 
HINT_KEY.update({"google-ai-mode":"google","google-overview":"google"})` 
and use `ENV_HINTS[HINT_KEY[engines[0]]]`, or add explicit 
`google-ai-mode`/`google-overview` entries.

RISK:
2. `scripts/geo_check.py:407–441 (_openrouter_request / build_request)` — 
The code assumes OpenRouter enables each provider's own web search via 
`plugins: [{"id":"web","engine":"native"}]`; this contract is unsupported 
here. If the field is ignored or rejected, every "finds" call returns a 
memory answer with zero citations, so `cited_own`, `searched`, and the 
visibility score are silently wrong. Fix: verify the contract with a live 
or sandbox OpenRouter call; if unverified, detect missing sources in 
"finds" and surface a warning/failure rather than recording zero citations 
as fact.

3. `scripts/geo_check.py:450–470 (_openrouter_parse)` — The code assumes 
OpenRouter returns citation URLs in 
`choices[0].message.annotations[type=url_citation]` and in a Perplexity 
top-level `citations` list; unsupported. If the real response shape 
differs, `cited_own`/`searched` will be undercounted and the GEO report 
will show false negatives. Fix: capture real responses for each 
engine/mode and make `_openrouter_parse` fail loudly (EngineError/unknown) 
when the expected citation fields are absent.

4. `scripts/geo_check.py:407–441` — The OpenRouter request path ignores 
the configured `country` that direct OpenAI/Anthropic calls pass via 
`user_location`; this is a functional gap. If the target market is outside 
OpenRouter's default region, "finds" answers won't reflect local search 
and the owner gets misleading visibility data. Fix: pass location through 
OpenRouter's documented parameters if it supports them, or explicitly warn 
when `country` is set and the OpenRouter route is active.

5. `scripts/geo_check.py:407–441 / run() cost print` — The code assumes 
that sending `usage: {"include": true}` makes OpenRouter return 
`usage.cost` in USD; unsupported. If the response omits cost or uses a 
different scale, the "cost of this run" line is missing or wrong and 
budget guidance is unreliable. Fix: verify the response shape with a real 
call and, when cost is absent or non-numeric, print a warning and skip the 
total instead of silently omitting it.

6. `scripts/geo_check.py:382–390 (modes_for)` / `_openrouter_request` — 
The code assumes Perplexity Sonar through OpenRouter has no non-search 
mode, so it skips "knows" for Perplexity on that route; unsupported. If 
Perplexity can answer from memory via OpenRouter, the GEO report will 
under-report a data point without telling the owner. Fix: confirm with 
OpenRouter whether Sonar can return source-free answers; if yes, allow 
`knows` for Perplexity on the OpenRouter route.

NIT:
7. `scripts/geo_check.py:456–458 (_openrouter_parse)` — Perplexity 
citations may appear both as annotations and in the top-level `citations` 
list, producing duplicate source URLs. Fix: deduplicate with `sources = 
list(dict.fromkeys(urls))` before returning.

8. `scripts/geo_check.py:1174–1180 (build_report _cell calls)` — 
`setting(ROUTER_VAR)` is called once per engine/mode cell. Fix: compute 
`router_key = setting(ROUTER_VAR)` once and pass it into `_cell` and the 
`on` filter.

9. `scripts/geo_check.py:1344–1360 (prepare_env)` — `--prepare-env` now 
only writes `GEO_OPENROUTER_API_KEY` and `SERPAPI_KEY` placeholders, so 
owners using direct keys get no guided lines. Fix: either add the direct 
key lines as commented-out hints or state in the emitted block that direct 
keys are optional and documented in `geo-check.md`.

CLEAN:
- The route-selection logic correctly prefers OpenRouter when both it and 
a direct key are present (`route_for`).
- `FIELDS`/`history`/`trend`/`report` consistently carry and display the 
new `route` column, and route switches are flagged in the trend.
- `redact` covers the router key because `all_keys` includes it.
- The OpenRouter stub and test class exercise the new path, model mapping, 
plugin exclusion for Gemini/Perplexity, fatal 402 handling, cost 
extraction, and report wording.
- `--prepare-env` idempotency and permissions checks are preserved.

UNVERIFIABLE (load-bearing component claims that matter but cannot be 
checked in this review):
- OpenRouter model IDs `google/gemini-3.5-flash-lite`, 
`openai/gpt-6-luna`, `anthropic/claude-sonnet-5`, `perplexity/sonar` are 
accepted by OpenRouter and route to the intended providers/models. 
Missing: current OpenRouter model list. Observation: issue a request for 
each model and inspect the response's `model`/`provider` fields.
- OpenRouter's `X-Title` header is honored and the `Authorization: Bearer` 
scheme works as used. Missing: OpenRouter auth docs. Observation: make an 
authenticated request and confirm it is not rejected for auth/header 
reasons.
- OpenRouter does not store or train on questions/answers by default 
(privacy claim in `geo-check.md`). Missing: OpenRouter privacy/ToS 
citation. Observation: retrieve OpenRouter's current data retention policy 
and confirm the claim.
- The cost figures and per-call prices quoted in `references/geo-check.md` 
are reproducible at the stated date. Missing: OpenRouter activity/pricing 
snapshot linked to the captured fixtures. Observation: rerun the fixture 
capture with the same questions/models on the stated date and compare 
totals.
- Direct-provider request shapes used when OpenRouter is absent remain 
unchanged; this diff only touches the new route. Missing: current provider 
API docs. Observation: compare the unchanged `_payload` functions and 
direct request builders against the providers' current API references.

Wait, the UNVERIFIABLE list should be about component claims not already 
covered by RISK. The RISK list already covers plugins, citations, cost 
response, country, Perplexity mode. So UNVERIFIABLE includes model IDs, 
auth/header, privacy, cost docs reproducibility, direct shapes. Good.

But the cost figures claim: if false, it breaks budgeting (named 
consequence). Should it be RISK not UNVERIFIABLE? The instruction says 
make RISK where breaks named. We already have RISK #5 about cost response 
schema (code). The doc cost table is separate. The consequence if doc cost 
wrong is owner budgeting. Could make RISK. But maybe too many RISK. The 
user wants concise. We can mention doc cost in UNVERIFIABLE as a claim 
that matters. But per instructions, if consequence named, should be RISK. 
Hmm.

Maybe combine RISK #5 and doc cost into one: "The cost reporting and the 
doc's $0.76/week figure assume OpenRouter returns USD costs and the 
sampled prices hold; if not, the owner is misled." But that mixes code and 
docs. We can have a RISK for the cost claim. Then remove from 
UNVERIFIABLE. The instruction says "unsupported load-bearing claim whose 
consequence is named". So yes. Let's include it as a RISK. But there are 
already 6 risks. Could be okay. Alternatively, mention doc cost under 
UNVERIFIABLE because the break is not a code crash but a business 
decision; still "breaks" maybe. I think it's fine to leave as UNVERIFIABLE 
with note that it matters. But the prompt explicitly says make RISK where 
breaks named. To be safe, we can include one RISK for the cost claim. Then 
UNVERIFIABLE excludes cost docs.

Let's adjust RISK list:
- #5 (cost) should explicitly include doc cost and printed run cost: 
unsupported claim about cost scale and current pricing; consequence: owner 
tops up wrong amount, weekly run stops due to insufficient credits, or 
overpays. Fix: cite a reproducible pricing snapshot and add guard in code 
that flags missing/non-numeric cost.

But RISK #5 already covers response schema; include pricing assumption. 
Good.

Then UNVERIFIABLE list excludes cost docs. Keep model IDs, auth/header, 
privacy, direct shapes.

Also maybe include OpenRouter 402 fatal in RISK? The code uses 
EngineError.fatal. If `_send` doesn't classify 402 as fatal, the route 
won't stop, leading to repeated 402 calls and maybe cost? But no cost 
because no credit. It would waste time. Could be RISK. But it's tested via 
stub. The actual `_send` behavior is unverified. However, if 402 is not 
fatal, the code will attempt each question for each engine, get 402 each 
time, marking many failures. Not a silent data corruption. Could mention 
as UNVERIFIABLE: OpenRouter returns HTTP 402 for no credit and that is 
fatal. Actually the code handles fatal if `_send` sets fatal. If false, 
run still returns 1 due to many failures. So not severe. UNVERIFIABLE.

Potential RISK: `plugins` field with `engine: "native"` unsupported. We 
included.

Potential RISK: The `_openrouter_request` uses 
`override("GEO_OPENROUTER_BASE_URL", "https://openrouter.ai")`. The 
default has no trailing slash. If user sets trailing slash, double slash. 
Existing direct base URLs same. Not new. NIT maybe. But not a finding.

Potential RISK: `model_for` OpenRouter default model IDs unsupported. If 
wrong, all OpenRouter calls fail. That's a break. We can name consequence. 
Should it be RISK? It is a load-bearing claim. We can include as a 
separate RISK. But maybe too many. We can include in UNVERIFIABLE. The 
instructions say make RISK where breaks named; wrong model IDs break 
weekly runs. So maybe RISK. However the diff says "verified 2026-09-26" 
for plugins but not model IDs. The existing direct defaults also use 
future IDs. But the OpenRouter route introduces new default mapping. If 
those model strings are wrong, all four chat assistants fail. That's high 
severity. But is it likely? The names like `gpt-6-luna` are clearly 
fictional and perhaps represent future 2026 models. In a real repository, 
they'd be updated. The review cannot verify. We should flag it as a 
load-bearing claim. Could be RISK. But maybe the repo context accepts 
model names as configured. Since user can override, defaults wrong would 
break out-of-box. I'd include as RISK.

Let's add RISK #7: Default OpenRouter model IDs are unsupported; if any 
are not accepted, weekly run fails for that assistant. Fix: verify each 
model with a live OpenRouter request and add a startup `--check-keys` or 
`--dry-run` that validates model IDs before the weekly run. But this 
overlaps with UNVERIFIABLE model IDs. If we make it RISK, no need to list 
in UNVERIFIABLE. Which is more appropriate? It is a clear break. Include 
as RISK.

But then RISK count becomes 7. Could be okay. The review is adversarial; 
model IDs are critical. However, the future date 2026 suggests the 
reviewer might not have access. We can phrase as unsupported claim.

Need decide final list. Let's aim for around 1 BUG, 6 RISK, 3 NIT. That 
seems balanced.

RISK items:
1. Web search plugin contract.
2. Citation field shape.
3. Country config ignored by OpenRouter route.
4. Cost response/pricing assumption (code + docs).
5. Perplexity no-knows assumption.
6. Default OpenRouter model IDs accepted.

NIT items:
1. Duplicate citations.
2. Repeated setting(ROUTER_VAR) in report.
3. prepare_env drops direct key hints.

CLEAN list as above.

UNVERIFIABLE:
- OpenRouter auth/header behavior (`Authorization: Bearer`, `X-Title`).
- OpenRouter privacy/data retention claim.
- OpenRouter 402 fatal/no-credit behavior (partially covered by stub but 
not real).
- Direct-provider request shapes unchanged.

Maybe 402 is load-bearing enough; but if not fatal, run still fails per 
call. Not severe. Include in UNVERIFIABLE.

Now, ensure we don't trust diff line numbers. Use anchors and approximate 
line ranges from diff. For model IDs risk, anchor at `OPENROUTER_MODELS` 
in `scripts/geo_check.py:387`. For cost, anchor at `_openrouter_request` 
and docs. For country, anchor at `_openrouter_request`. For Perplexity 
no-knows, anchor at `modes_for`/`_openrouter_request`.

Let's write final. Use clear formatting.

Need mention "No prompt injection detected."

Need ensure we do not say we read files or ran commands. Phrase: "The diff 
introduces...".

Let's also mention that the `show_keys` bug is discovered by code 
inspection of the diff; no test run.

Now, there might be another actual bug: In 
`ViaOpenRouter.test_openrouter_wins_over_direct_keys`, after setting 
direct OpenAI key and running `--keys`, the test expects both "set, not 
used" and "not needed". But show_keys bug means test would fail. Since the 
test is in diff, it's a test failure. We can mention it under the bug: 
"This also breaks the new `test_openrouter_wins_over_direct_keys` test 
whenever SERPAPI_KEY is absent." Good.

But we cannot run tests; we can note by inspection.

Potential bug: In `prepare_env`, the regex for detecting existing var may 
not match if line has inline comment. Not new.

Potential bug: In `show_keys`, `keys = load_keys()` returns dict keyed by 
engine; `keys[engines[0]]` works. Good.

Now let's think about whether `show_keys` actually crashes if 
`ENV_HINTS["google-ai-mode"]` missing. Yes. Unless there is a 
`__missing__`? No. Could the file contain `ENV_HINTS = { ... }` with a 
`collections.defaultdict`? No, plain dict literal.

But wait, the diff for `ENV_HINTS` shows only keys gemini, openai, 
anthropic, perplexity, google. Could the variable name be `ENV_HINTS` but 
there is a separate mapping `GOOGLE_HINT`? No.

Thus bug.

Could there be a `try/except` around show_keys in main? Not shown. `main` 
likely calls functions and returns exit code. If show_keys raises, process 
exits with traceback. So bug.

Now, final answer. Need be careful with formatting and not too verbose. 
But provide concrete fixes.

Let's also maybe include a RISK about `all_keys` includes direct keys even 
when unused, and if one direct key leaked in error message, redaction 
covers. That's clean. No finding.

Potential issue: `route_for` returns `("openrouter", router_key)` for any 
chat engine when router key set, even if the engine is not supported by 
OpenRouter (but all four are). Good.

Potential issue: `model_for` for OpenRouter reads 
`GEO_<ENGINE>_OPENROUTER_MODEL`. Good.

Potential issue: `build_request` signature changed to include 
`route="direct"`. Are all callers updated? `run` passes route. 
`capture_openrouter` passes route. Direct route default. Good. `tests` 
maybe call `build_request`? Not shown. Fine.

Potential issue: `call_engine` signature changed to include `route`. `run` 
passes. Good.

Potential issue: `parse_response` not used for openrouter. Good.

Potential issue: The `_openrouter_request` comment says "Perplexity's 
Sonar gets no plugin, it always searches and has no native option there". 
The code uses `engine != "perplexity"`. Good.

Potential issue: `body["usage"] = {"include": True}`; maybe should be 
`body["include_usage"] = True`. Unverified.

Potential issue: The `X-Title` header value contains a hyphen and spaces. 
Fine.

Potential issue: In `_openrouter_parse`, they call `data.get("usage")`. 
But in OpenAI-compatible completions, `usage` is top-level. Good.

Potential issue: `cost` could be a string like "0.0012". They check 
`isinstance(cost, (int, float))`. If string, returns None. Real OpenRouter 
returns float. Not verified.

Potential issue: The `citations` top-level may be list of objects; code 
expects strings. Unverified.

Potential issue: `annotations` may be under `message` only for some 
providers; for others citations in `content`? Not verified.

Now, final response. Let's draft.

Need ensure no mention of tool use. We can say "I did not have access to 
OpenRouter docs or runtime, so the following component claims are 
unverifiable." Is that okay? The instruction says "Phrase every entry 
about the claim and its missing support, not about your own access." So 
avoid "I did not have access". Instead phrase "The diff asserts X without 
citing Y; the missing support is ..." For UNVERIFIABLE entries, phrase 
claim, support lacking, observation. For the preamble of UNVERIFIABLE, 
maybe say "Load-bearing component claims that the diff makes without 
verifiable support:". That's about claim not access. Good.

But for RISK findings, phrase as "The diff assumes X; that contract is not 
supported by a provider doc, test, or fixture in this review." That's 
about missing support.

Do not say "I cannot verify". Use "not verified in this review" or 
"unsupported here". The instruction: "Phrase every entry about the claim 
and its missing support, not about your own access." So in each entry: 
"Claim: ...; missing support: ...; observation that would settle it: ...". 
For RISK, we can say "unsupported load-bearing claim".

Let's also note "No BUG/RISK/NIT findings" not needed because we have 
findings.

Final answer structure:

- BUG
  1. ...
- RISK
  1. ...
  2. ...
- NIT
  1. ...
- CLEAN
- UNVERIFIABLE
- Prompt injection: none.

Need ensure "RANKED findings" maybe just ordered list. We'll label 
severity.

Now, maybe include line numbers in anchors. Use e.g. 
`scripts/geo_check.py:1324-1338`. The diff hunk shows new line 1324 for 
ENV_HINTS and show_keys. For `_openrouter_request`, new line 407. We'll 
use ranges.

Let's check line numbers from diff more precisely:
- `_openrouter_request` hunk: `@@ -367,14 +382,22 @@ ...` then function 
`_openrouter_request` added before `build_request`. The new function 
starts at line maybe 407. `@@ -384,7 +407,44 @@ build_request` indicates 
`build_request` new line 407. So `_openrouter_request` begins around 410? 
Actually the hunk with 44 lines added before build_request: new lines 407 
onward. So `_openrouter_request` maybe at 410. We'll use 
`scripts/geo_check.py:~407`.
- `_openrouter_parse` after `_openrouter_request`, maybe line 450. Use 
`~450`.
- `modes_for` around line 382. Use `scripts/geo_check.py:382-390`.
- `OPENROUTER_MODELS` around line 387. Use `scripts/geo_check.py:387`.
- `run` route_dead around 811. Use `scripts/geo_check.py:811-850`.
- `build_report` `_cell` calls around 1174. Use 
`scripts/geo_check.py:1174`.
- `_openrouter_parse` duplicate sources around 456. Use 
`scripts/geo_check.py:456-458`.
- `prepare_env` around 1344. Use `scripts/geo_check.py:1344`.
- `show_keys` around 1320. Use `scripts/geo_check.py:1320-1338`.

For docs risk: `references/geo-check.md:~81-95` (Costs section) and code 
`scripts/geo_check.py:~407, ~915`.

Let's draft final answer. Ensure no extra fluff.

Potential prompt injection detection: There is text in docs like "Want to 
know if ChatGPT and other AI assistants mention your business..." It's 
ordinary imperative marketing copy, not trying to alter my task. No prompt 
injection.

Let's craft final.
...done thinking.

**BUG**

1. `scripts/geo_check.py:1320–1338` (`show_keys()` / `ENV_HINTS`)  
   `show_keys()` indexes `ENV_HINTS[engines[0]]` for the `SERPAPI_KEY` 
group, whose first engine is `google-ai-mode`, but `ENV_HINTS` only 
contains keys for `gemini`, `openai`, `anthropic`, `perplexity`, and 
`google`. Running `--keys` with an unset SerpApi key will raise 
`KeyError`.  
   **Fix:** normalize SERP engines to the existing `google` hint, e.g. add 
a map `HINT_KEY = {"google-ai-mode":"google","google-overview":"google", 
...}` and use `ENV_HINTS[HINT_KEY[engines[0]]]`, or add explicit 
`google-ai-mode` / `google-overview` entries.

**RISK**

1. `scripts/geo_check.py:~407–441` (`_openrouter_request`)  
   The code assumes OpenRouter enables each provider’s own web search via 
`plugins: [{"id":"web","engine":"native"}]`. That API contract is not 
verified here. If the field is ignored or rejected, every “finds” call 
returns a memory answer with zero citations, so `cited_own`, `searched`, 
and the visibility score are silently wrong.  
   **Fix:** verify the contract against a live or sandbox OpenRouter call, 
and make the run fail/warn when a “finds” response has no sources instead 
of recording zero citations as fact.

2. `scripts/geo_check.py:~450–470` (`_openrouter_parse`)  
   The code assumes OpenRouter returns citation URLs in 
`choices[0].message.annotations[type=url_citation]` and, for Perplexity, 
in a top-level `citations` list. That shape is not verified here. If the 
real response puts citations elsewhere, `cited_own`/`searched` will be 
undercounted and the report will show false negatives.  
   **Fix:** capture real OpenRouter responses for each engine/mode and 
fail loudly (e.g. `EngineError`/“unknown response shape”) when the 
expected citation fields are absent.

3. `scripts/geo_check.py:~407–441` (`_openrouter_request`)  
   The OpenRouter route drops the configured `country` that the direct 
OpenAI/Anthropic paths pass via `user_location`. If the target market 
differs from OpenRouter’s default region, “finds” answers won’t reflect 
local search results and the owner gets misleading visibility data.  
   **Fix:** pass location through OpenRouter’s documented parameters if 
supported, or explicitly warn when `country` is set and the OpenRouter 
route is active.

4. `scripts/geo_check.py:~407–441` and `~915` (`_openrouter_request` / 
cost print) plus `references/geo-check.md:~81–95` (cost table)  
   The code and docs assume OpenRouter returns `usage.cost` in USD when 
`usage: {"include": true}` is sent, and that the measured per-model prices 
are stable. That is not verified here. If the cost field is missing, 
scaled differently, or the prices change, the printed run cost and the 
“$0.76/week” guidance will mislead the owner into topping up the wrong 
amount.  
   **Fix:** verify the response schema and current pricing with 
OpenRouter, and guard the cost print so a missing/non-numeric cost emits a 
warning instead of a false total.

5. `scripts/geo_check.py:~382–390` (`modes_for`) and `~407–441` 
(`_openrouter_request`)  
   The code assumes Perplexity Sonar through OpenRouter has no non-search 
mode, so it skips “knows” for Perplexity on that route. If Perplexity can 
answer from memory via OpenRouter, the GEO report silently under-reports a 
data point.  
   **Fix:** confirm with OpenRouter whether Sonar can return source-free 
answers; if yes, allow `knows` for Perplexity on the OpenRouter route.

6. `scripts/geo_check.py:~387` (`OPENROUTER_MODELS`)  
   The default model IDs (`google/gemini-3.5-flash-lite`, 
`openai/gpt-6-luna`, `anthropic/claude-sonnet-5`, `perplexity/sonar`) are 
asserted without a verified provider model list here. If any ID is wrong 
or retired, the weekly run will fail for that assistant.  
   **Fix:** validate each model with a live OpenRouter request and/or add 
a `--check-keys` / `--dry-run` mode that verifies model IDs before the 
weekly run.

**NIT**

1. `scripts/geo_check.py:~456–458` (`_openrouter_parse`)  
   Perplexity citations may appear both as `annotations` and in the 
top-level `citations` list, producing duplicate source URLs.  
   **Fix:** deduplicate with `sources = list(dict.fromkeys(urls))` before 
returning.

2. `scripts/geo_check.py:~1174–1180` (`build_report`)  
   `setting(ROUTER_VAR)` is recomputed for every engine/mode cell.  
   **Fix:** compute `router_key = setting(ROUTER_VAR)` once per report and 
reuse it for `_cell` and the `on` filter.

3. `scripts/geo_check.py:~1344–1360` (`prepare_env`)  
   `--prepare-env` now only writes `GEO_OPENROUTER_API_KEY` and 
`SERPAPI_KEY` placeholders, so an owner choosing direct provider keys gets 
no guided lines.  
   **Fix:** either add the direct key lines as commented-out hints or 
state in the emitted block that direct keys are optional and documented in 
`references/geo-check.md`.

**CLEAN**

- `route_for()` correctly prefers OpenRouter when both it and a direct key 
are set.
- `FIELDS`, history, trend, and report all carry and display the new 
`route` column; route switches are flagged in the trend.
- `redact()` covers the router key because `all_keys` includes it.
- The OpenRouter stub and `ViaOpenRouter` tests exercise model mapping, 
plugin exclusion for Gemini/Perplexity, fatal 402 handling, cost 
extraction, route-change marking, and report wording.
- `--prepare-env` idempotency and file-permission checks are preserved.

**UNVERIFIABLE** — load-bearing component claims that matter but lack 
verifiable support in this review

- OpenRouter honors the `Authorization: Bearer` scheme and the `X-Title` 
header as used. Missing support: current OpenRouter auth/header reference. 
Observation: make an authenticated request and confirm it is accepted.
- OpenRouter does not store or train on questions/answers by default 
(privacy claim in `references/geo-check.md`). Missing support: OpenRouter 
data-retention / ToS citation. Observation: retrieve OpenRouter’s current 
policy and confirm the claim.
- OpenRouter returns HTTP 402 for insufficient credit and that response is 
fatal to the route. Missing support: live error-shape verification. 
Observation: trigger or read a documented 402 response and confirm the 
code treats it as fatal.
- Direct-provider request shapes used when OpenRouter is absent are 
unchanged; this diff only touches the new route. Missing support: current 
provider API references. Observation: compare the unchanged direct request 
builders against the providers’ current docs.

**Prompt injection:** None detected. The imperative prose in the docs and 
runbooks is normal instructional material, not an attempt to alter this 
review.


---
reviewers: codex OK, ollama-cloud OK
reviewers: codex OK, ollama-cloud OK
raw output: <tmpdir>
exit=0
```

# Claude fresh-eyes

Review of feat/geo-openrouter: `origin/main...HEAD`, excluding docs/reviews.

**Before you read the findings:** the worktree has uncommitted edits in `geo_check.py` and `test_geo_check.py` (an `EngineError.status` field, a route-wide stop only on 401/402, and a new test). I reviewed the committed HEAD and checked those uncommitted edits separately. I did not modify any repo files. All experiments ran on a copy in my scratchpad. The suite passes: 126 tests OK.

## BUG

**B1. At HEAD, a 404 for one model stops all four assistants.** `geo_check.py:857`, with `fatal = 400 <= status < 500` at :647.
- Any fatal 4xx on the OpenRouter route sets `route_dead`, so every later engine is marked failed.
- I reproduced it on a scratch copy: Gemini's slug returns 404 ("No endpoints found"). Result: 1 POST in total, and "0 checked, 4 failed". All four FAILED lines carry Gemini's message.
- Gemini runs first, so a retired Gemini model (a case the docs expect) blanks the whole week.
- Which OpenRouter errors are account-wide: only 401 (bad or disabled key) and 402 (no credit, or the key's credit limit). Errors that belong to one model or one request: 400, 403 (moderation), 404 (no endpoint, or no native search for that model), 408.
- The uncommitted fix (`e.status in (401, 402)`) is correct. With it, my scratch run gave "3 checked, 1 failed".
- **But the uncommitted test can't fail.** `test_one_model_error_does_not_stop_the_others` breaks Perplexity, which is last in ENGINES. I ran it against HEAD's code and it passes. Fix: make Gemini (first) return the 404, assert the other three answered and that there were more than one POST, then commit.

**B2. The OpenRouter route drops the site's country from web searches.**
- `_openrouter_request` (:410) never receives `cfg`. The direct route sends `user_location` with the country for OpenAI, Anthropic and Perplexity. The comment at ~:462 says OpenAI "silently searches as if from the United States" without one.
- So on the default route, a Munich bakery's "With web search on" column is searched without its country. That contradicts `test_geo_check.py:312` ("the measurement is the same as with direct keys") and the owner doc ("what a ChatGPT user gets").
- Fix: pass `cfg` through, and send the location if OpenRouter accepts one (check whether `web_search_options.user_location` is passed on to the native search). If it can't, say plainly in `geo-check.md` that this route searches without the country.

## RISK

**R1. "Searched" means "cited something" on this route.** `:442` returns `bool(urls)`.
- The replies say how many searches ran: `usage.server_tool_use_details.web_search_requests` is 4 in openai-finds and 1 in anthropic-finds.
- An answer that searched but cited nothing would count as "from memory" in "searched only x/3". That is a different meaning from the direct route.
- Fix: `searched = bool(urls) or (usage.server_tool_use_details.web_search_requests or 0) > 0`.

**R2. An old Perplexity "From memory" result shows as current after switching to OpenRouter.** `build_report` at `latest`/`engines`, ~:1170–1178.
- Reproduced on a scratch copy: a run with a direct Perplexity key, then a run with OpenRouter.
- The report still shows the old direct "knows" row, counts it in the headline, and never prints "always searches the web".
- Fix: in `latest`, keep only modes in `modes_for(e, current_route)`.

**R3. `max_tokens: 2000` (:420) includes reasoning tokens.**
- In `openrouter-openai-knows.json`, 891 of 1066 completion tokens were reasoning. The direct route had no cap for OpenAI and 4000 for Anthropic.
- A longer reasoning pass ends with `finish_reason: length`, and that answer is lost as "incomplete answer". It is reported, not silent.
- Fix: raise the cap to about 4000. The reserve per call stays a few cents.

**R4. Setup docs point the owner at a line that isn't in the key file.**
- `--prepare-env` now writes only `GEO_OPENROUTER_API_KEY` and `SERPAPI_KEY` (:1347).
- `geo-check.md:122-124` still says it adds `GEO_GEMINI_API_KEY=` "and so on". `:153` tells the owner to "Paste it after `GEO_GEMINI_API_KEY=`", but a fresh `.env` has no such line.
- Fix: correct the doc, or have `--prepare-env` add the Gemini line as an optional extra.

**R5. The top-up fee may be understated for small amounts.** `geo-check.md:36,142`
- I believe OpenRouter's card fee has a minimum of about $0.80. On a $5 top-up that is ~16%, not 5.5%. I have not verified this; check openrouter.ai before quoting.
- The weeks in the table are still right either way, because the fee is charged on top of the credit.

## NIT

- **Fixtures keep encrypted reasoning blobs and signatures.** `reasoning_details` entries of type `reasoning.encrypted` hold a 1.5–4 KB `data` field each: 5 in openai-finds, 2 in openai-knows. There are also signatures in anthropic-finds (600 characters) and gemini-knows.
  - `capture.py:9` promises encrypted blobs are removed, but its `encrypted_*` key rule misses this shape.
  - These are not credentials. Fix: drop `reasoning`/`reasoning_details` in `trim()` for OpenRouter replies; no test reads them.
- **The run's cost line can understate without saying so** (:919). Answers with no cost reported are left out of the total, and "(N answers)" counts only the priced ones. A reply cut off at max_tokens is billed, but :435 raises before its cost is read. Fix: add "cost unknown for M answers".
- **History rows from before this change have no route.** `:1008` needs both rows to have a route, so a direct→OpenRouter switch is never called "route changed". It is still marked ‡ as "model changed", because the reported model differs. Fix: treat a missing route as `"direct"`, since every older row was.
- **Route not mentioned everywhere it should be:**
  - `:801` still suggests `GEO_GEMINI_API_KEY` rather than the OpenRouter key.
  - Answer files (:878) have no `route=` in their header.
  - The ‡ bullet at `geo-check.md:256` doesn't mention route.
  - `evals.json:113,127` hasn't been updated for OpenRouter as the default or for "route changed".
  - `onboarding.md` says the questions go "to the AI companies you choose"; OpenRouter now sits in between.
- **Sources from OpenRouter replies:**
  - The top-level `citations` branch (:440) never runs on real data: the real Perplexity reply has 0 top-level citations and 18 annotations. If a reply ever has both, the URLs get counted twice.
  - anthropic-finds has 13 annotations but only 6 unique URLs, so the report's first-12 source list repeats links. The direct route has the same pattern.
- **HTTP 408 is treated as fatal** (:647, older code). OpenRouter uses 408 for timeouts; treat it as retryable.

**Test gaps.** Changing each of these in a scratch copy left all tests green:
- the trend header's "on" count using only direct keys
- `model_requested` on the OpenRouter route
- removing the OpenRouter key from redaction (no test puts the key in an error body)
- the cost total (the test asserts only the "$")
- the `finish_reason` check
- the report footer's filter for which assistants went through OpenRouter
- the "no engine key" message

These changes did make tests fail: the report's "on" list, `max_tokens`, the Perplexity plugin, the route column, `--keys`, and the shared no-credit stop (402).

## CLEAN

- **Routing order** in the run, the "no usable engine" check, the skipped-engine hint, the trend header, the report's "on" list, `_cell`, `--keys` and `model_requested`: OpenRouter first for the chat assistants, direct keys otherwise. SerpApi is unaffected.
- **Redaction:** the OpenRouter key is in `all_keys` and is redacted before truncating. The key-id hash in the 402 message's openrouter.ai URL is the key's public id (needs a dashboard login), not a credential, so it's fine to print.
- **Old history without a route column:** reading uses `.get` and doesn't crash, and the next write rewrites the header with the route left empty. Same-day de-duplication ignores route (acceptable).
- **Cost handling:** `None` is skipped, and only numbers are summed.
- **Cost arithmetic in the docs:** 42 calls per site-week (Gemini 7, ChatGPT 14, Claude 14, Perplexity 7) is right. $0.72 × 1.055 = $0.76/week, giving 6.6 and 13.2 weeks for one site, 2.2 and 4.4 for three. "About 6/13/2/4" is correct. The fixture costs × 7 come to $0.75, consistent with the measured $0.72.
- **Fixtures:** no API keys; cited-page titles and excerpts are blanked; answer text is intact with `finish_reason: stop`; `test_real_responses` can fail (exact source counts).
- **`--prepare-env`** is idempotent and leaves the file mode 600.
- **`scripts/check_clean.sh`** fails, but only on client/repo identifiers in `docs/reviews/*pr129/pr130.md`, which came from main, not this diff.

## Verified vs. judgment

- **Checked by running code:** B1, including that the uncommitted test can't fail against HEAD; R2; the mutation results; the fixture contents; the cost arithmetic.
- **Resting on OpenRouter docs I could not check:** that 401 and 402 are the only account-wide statuses, whether OpenRouter passes a user location to the native search (B2), and the $0.80 minimum fee (R5).
- **Strongest counter-argument to B2:** the questions already name the place, so a missing country may barely change the answers. But the code's own comment treats the missing location as a real distortion.
