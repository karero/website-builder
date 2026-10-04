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
| O2 | BUG | C2 F-B2 K-R3 | the OpenRouter route drops the site's country from web searches | **documented, not fixable; accepted by the owner on 2026-09-29 ("Good"):** OpenRouter documents no location parameter (checked 2026-09-26). geo-check.md says so plainly: a local business's questions name the place; a business selling everywhere can use direct keys or name the market |
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

## Round 2 — verifying the fixes, after merging main (2026-09-29)

The session that opened this PR had ended; another session ("Release PR review and
preparation") took it over at the owner's request ("Finalize it pls"). Main was merged in first
(`f2ec19d`): one conflict, the `SKILL.md` table, where both rows were kept (main's new Google
report row, this branch's OpenRouter wording for the AI check). 179 tests and `make check` passed
on the merge.

Seats: ollama-cloud (`kimi-k2.7-code:cloud`, `--verify` against the table above) and a fresh-eyes
Claude verifier that reverted each fix in a scratch copy. Codex was out of quota until 3 October.

| Seat | Verdict on round 1 | New BUG / RISK / NIT |
|---|---|---|
| ollama | all landed; O9 in code but not the docs; O14 partial | 1 / 1 / 1 |
| fresh-eyes Claude | O1, O3, O4 verified by revert; O5, O6 fixed but untested; O9 docs | 0 / 1 / 5 |

- **Fixed, O5's test (fresh-eyes RISK):** the cut-off cost was tested only at the parser, so the
  run could drop it unnoticed. A test through the command line now pins the run's cost line
  with cut-off and empty billed replies.
- **Fixed, billed empty replies (fresh-eyes NIT):** an empty or unreadable reply now carries its
  billed cost too.
- **Fixed, wording (fresh-eyes NIT):** the cost line counts "replies", not "answers".
- **Fixed, O6's test (fresh-eyes NIT):** `--prepare-env` is now tested for the free Gemini line.
- **Fixed, O9 in the docs (ollama BUG, fresh-eyes NIT):** `geo-check.md` says `max_tokens: 4000`;
  it also describes the citations fallback correctly and points "Finds you" at OpenRouter's Costs.
- **Fixed, O14 (ollama NIT):** 408 was made non-fatal but never retried; it is now retried like
  429, and a test counts the attempts (it fails on the round-1 code).
- **Declined (ollama RISK), cost wording:** the Costs heading already says prices were measured on
  2026-09-26 and change, the owner pitch says only "covers the checks for weeks", and every run
  prints its own cost.
- **Declined (fresh-eyes NIT), old Perplexity "knows you" lines in the trend:** the trend is the
  history, and each line carries its dates; the report page already hides them (O3).
- **Follow-up, fixed after release (2026-09-30, owner: "yes"):** a cut-off reply that carries no
  price was left out of the cost line. A reply that came back but cannot be used (cut off, empty,
  unreadable) is now marked as charged (`EngineError.billed`) and counts as "cost unknown" when it
  has no price; an HTTP error is no reply and stays out. A test through the command line pins
  both (it fails on the previous code). Reviewed by ollama-cloud, 1 round, 0 / 2 / 3: the
  variable name and a comment fixed; refuted: the cost summary already skips missing prices, an
  unreadable reply reaches that point only after a successful answer (so "cost unknown" is the
  honest label), and the test does run the command line. Codex was out of quota.
  **Round 2, 2026-10-04 (Codex; ollama hit its quota):** 2 BUG, 1 RISK. Fixed: a malformed reply
  that carries a price kept losing it (now read before the answer is parsed); a 200 reply that
  is not JSON, and `choices` of an unexpected shape (`KeyError`), dropped out of the cost line
  (both now count as "cost unknown", and every shape error is caught in `call_engine`). One
  command-line test covers all three and fails on the round-1 code. RISK, kept as a stated
  limit: that OpenRouter charges for an unusable reply is not proven here, which is why such a
  reply counts as "cost unknown" rather than priced; the comments now say "may have been
  charged".
  **Round 3 (Codex, verify):** the round-2 fixes landed (checked by replay, and the test fails
  on the earlier code). 1 BUG fixed: a reply nested too deep to read raised `RecursionError`
  past `_send`, and that run printed no cost line; it is caught with `ValueError` now, in the
  same test. The RISK repeats round 2's: also stated in the code that an HTTP error counting as
  uncharged is an assumption. "Every shape error" in round 2 meant the ones `call_engine`
  catches; the coverage claim is bounded to the cases the test replays.
  **Round 4 (Codex, verify):** no BUG or NIT; the round-3 fix verified. The billing RISK came up a
  third time and cannot be settled by code review: which failed calls OpenRouter charges for.
  Kept as a stated limit. What is counted: an unusable reply as "cost unknown" (never a made-up
  price), an HTTP error as uncharged, and an HTTP 200 error envelope (`{"error": …}`) as an
  unusable reply. **Settling observation:** after a weekly run with a failure, compare the run's
  cost line with OpenRouter's Activity page. 4 rounds, 11 findings on this follow-up
  (1: 0/2/3 ollama; 2: 2/1/0 Codex; 3: 1/1/0; 4: 0/1/0).

## Final state

All tests pass (181 in the skill suite); `make check` passes. The owner accepted O2 as
documented. Codex did not see round 2 (out of quota).
