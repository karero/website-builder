# REVIEW — DIFF gate, OpenRouter as the default route (feat/geo-openrouter), 2026-09-27

**Reviewed:** `origin/main...fdb949e` (trail and fixture JSON excluded).
Verbatim: `RAW-diff-2026-09-27-r1-geo-openrouter-fdb949e.md`.
**Reviewers:** Codex OK, **ollama-cloud OK** (its weekly limit had reset: the first complete
standard pair of this feature), Claude fresh-eyes OK.
**Gate depth:** one round, as for the previous follow-up (owner direction: "independent
code-review round, then the PR"). The fixes are `locally_verified` (tests, mutation-checked where
marked), **not externally re-verified**.
**Live evidence:** real OpenRouter calls on 2026-09-26/27: all four assistants answered; a full
weekly check for one site (42 answers) cost $0.718; Sonar searched even for "What is 2 + 2?"
without the search option (20 sources); a low balance produced HTTP 402.

C = Codex, K = ollama-cloud, F = fresh-eyes.

| id | sev | src | finding | disposition |
|---|---|---|---|---|
| O1 | BUG | F-B1 | any fatal error stopped all four assistants on the route; the new test broke Perplexity (last) and could not fail | fixed: only 401/402 (account-wide) stop the route; the test now breaks Gemini (first). Mutation-checked |
| O2 | BUG | C2 F-B2 K-R3 | the OpenRouter route drops the site's country from web searches | **documented, not fixable:** OpenRouter documents no location parameter (checked 2026-09-26). geo-check.md says so plainly: a local business's questions name the place; a business selling everywhere can use direct keys or name the market |
| O3 | BUG | C3 F-R2 | an old direct Perplexity "from memory" row stayed current after switching to OpenRouter | fixed: the report keeps only modes the current route can ask. Mutation-checked |
| O4 | BUG | C4 F-N | rows from before the route column never showed "route changed" | fixed: a missing route counts as "direct". Mutation-checked with a genuine old-schema file |
| O5 | BUG | C5 F-N | a cut-off answer's billed cost was left out of the run total; unknown costs were silent | fixed: `EngineError.cost` carries it; the line says "cost unknown for N more". Mutation-checked |
| O6 | BUG | C6 F-R4 K-N3 | the guide pointed at a Gemini key line `--prepare-env` no longer wrote | fixed: `--prepare-env` adds the optional free Gemini line again, with a comment |
| O7 | BUG | K | `--keys` would crash on the Google engines' hints | refuted: `ENV_HINTS` has both Google entries (geo_check.py, ENV_HINTS) |
| O8 | RISK | F-R1 | "searched" meant "cited something" | fixed: the reply's own search counter when present, else citations. Mutation-checked |
| O9 | RISK | F-R3 | a 2,000-token cap includes hidden reasoning | fixed: 4,000 |
| O10 | RISK | F-R5 | the top-up fee has a minimum | fixed: "5.5%, at least $0.80" (it was on OpenRouter's FAQ, read on 2026-09-26, and left out by the author) |
| O11 | RISK | C1 K-R1…R6 | OpenRouter behaviour asserted by our own stub | largely settled by the live evidence above (native search runs, the model slugs answer, `usage.cost` is reported, 402 on no credit, Sonar always searches); real OpenRouter replies are fixtures tested by `test_real_responses.py`. Retention stays OpenRouter's own statement, quoted as such |
| O12 | NIT | F | reasoning blobs and signatures in fixtures | fixed: `trim()` drops them; all fixtures re-trimmed (96 KB total), answer text intact |
| O13 | NIT | F K-N1 | duplicate source URLs in the report | fixed at display (unique, first 12); counts unchanged |
| O14 | NIT | F | 408 treated as fatal | fixed: retried like 429 |
| O15 | NIT | F | route missing from hints, answer headers, the ‡ legend, evals, onboarding | fixed |
| O16 | NIT | F test gaps | `model_requested`, key redaction in an error body, the cost total, the cut-off check, the "no key" message | tests added (`test_request_details_cost_and_redaction`, `test_cut_off_answer_…`, `test_no_key_message_points_to_openrouter`) |

## Final state

132 tests pass. Nothing open. The private-name check fails on this machine only for two review
files that other PRs (#129/#130) added to `main`; not part of this change.
