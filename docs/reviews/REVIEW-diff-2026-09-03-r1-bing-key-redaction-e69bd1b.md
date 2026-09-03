# Review trail — DIFF, rounds 1–3 (single external reviewer, owner-chosen)

- **Branch**: `claude/agitated-hugle-b41589` — `search-console-insights/scripts/bing_query.py`:
  redact the Bing API key from `requests` error messages before they reach stderr (the
  scheduled launchd jobs redirect stderr into `~/.config/gsc-insights/logs/<domain>.log`,
  so a failing Bing call was writing `apikey=<key>` into a log file).
- **Artifact, round 1**: full branch diff `main...e69bd1b` (45 lines).
- **Artifact, round 2**: full branch diff `main...4dc0794` (round-1 fixes included).
- **Artifact, round 3**: code diff `main...eb20108 -- skills` (round-2 fixes included; the
  docs/reviews trail files excluded from the artifact).
- **Reviewer**: ollama `kimi-k3:cloud`, one shot per round via `ollama_review.sh --diff`,
  named explicitly by the owner. **Not** the standard two-seat independent-review gate:
  one seat, no clerk round. The change is ~40 lines in one script, but it is a secret-handling
  fix, so every round that accepted a behavior-level finding (r1 BUG, r2 RISK) earned a
  re-send rather than closing on local verification alone.
- **Raw verbatim output**: RAW-diff-2026-09-03-r1-bing-key-redaction-e69bd1b.md,
  RAW-diff-2026-09-03-r2-bing-key-redaction-4dc0794.md,
  RAW-diff-2026-09-03-r3-bing-key-redaction-eb20108.md.
- **Verdict, round 1**: 1 BUG, 3 RISK, 1 NIT. **Round 2**: 0 BUG, 3 RISK, 2 NIT.

## Round 1 findings (5)

| id | sev | finding | disposition |
|----|-----|---------|-------------|
| K1 | BUG | `requests` encodes params via `urlencode`/`quote_plus`, so a key containing a space (a trailing-whitespace paste, which also guarantees the error path) appears in the URL as `+`; the redactor searched for the `quote()` form (`%20`) and the raw key, so both replaces missed and the key still landed in the log | **fixed** (4dc0794): replace `quote_plus(key)`, which is exactly what `requests` puts on the wire. Verified with a real 400 using a key with a trailing space: `+`-form absent from the message |
| K2 | RISK | Raising a bare `RuntimeError` silently dropped the `requests.RequestException` contract; a caller doing `except requests.RequestException` stops catching, and status/response are gone | **fixed in part** (4dc0794): now raises `BingApiError(requests.RequestException)` with the redacted message only. **Refuted the "attach response/request" half**: `Response.url` and `PreparedRequest.url` both carry the unredacted key, so attaching them reopens the leak this diff closes; the status code is already in the message text (`400 Client Error`). No caller in the repo relies on either — both consumers (`bing_query.main`, `insights.bing_positions`) use `except Exception` |
| K3 | RISK | Traceback-with-locals tooling (Sentry, `pytest --showlocals`, `show_locals=True`) would still print the `key` local of `_fetch` and its callers | **refuted as out of scope**: none of that tooling exists in this CLI; the leak channel that mattered is `str(e)` → stderr → log file. Any locals-capturing reporter in this process would also capture `os.environ["BING_API_KEY"]` and `args.api_key`, so a credential wrapper object around one parameter would not close it |
| K4 | RISK | No test pins the two invariants (key absent from `str(exc)`; `__cause__`/`__context__` both `None`), so a future `raise ... from None` inside the handler silently re-attaches the original | **owner-waived (by the task brief)**: the skill has no Python test convention (the repo's tests are the Astro Playwright specs), and the brief said to verify by forcing a 400 in that case. Mitigation: the `_fetch` docstring now states the invariant and names the `from None` trap explicitly. Verified live instead: real 400 + ConnectionError, key absent, `__cause__`/`__context__`/`response` all `None` |
| K5 | NIT | Whole-message `str.replace` could mangle diagnostics if the key string also appears in unrelated text (e.g. inside the echoed `siteUrl`) | **refuted**: an extra occurrence of the secret being replaced is over-redaction of a secret, never under-redaction of one, and a site URL containing the API key is not a realistic input. Span-surgical redaction would add parsing for no safety gain |

CLEAN list from the reviewer (happy-path equivalence, no unbound-`err` path, the
`__cause__`/`__context__` claim, the `if key:` guard, codec audit "quote vs quote_plus differ
only on space", non-`RequestException` escapes, caller regressions) checked and agrees with the
in-house pass. The codec audit is what makes K1 a complete fix rather than a patch: with
`quote_plus` matched, no other character encodes differently from the raw form's replace.

## Round 2 findings (5) — on `main...4dc0794`

| id | sev | finding | disposition |
|----|-----|---------|-------------|
| R1 | RISK | Nothing pins the `__context__`/`__cause__` invariant; a lint-driven cleanup (pylint `possibly-used-before-assignment` on `err`) or a restructure to `raise ... from None` inside the handler silently re-couples the unredacted original | **fixed in part** (eb20108): `raise err` now carries a `# deliberate: outside the except block, see docstring` marker. The test-pin half stays **owner-waived** as in K4 (same reason: no Python test convention in the skill; brief said verify by forcing a 400) |
| R2 | RISK | Raised type changed from concrete `requests` subclasses to `BingApiError`; a caller catching `except requests.HTTPError` would stop catching | **refuted** with the grep the reviewer asked for: the only callers are `bing_query.main` and `insights.bing_positions`, both `except Exception`; no tests catch concrete `requests` subclasses. `BingApiError` is still a `RequestException`, so the broad contract holds. Recorded in the eb20108 commit message |
| R3 | RISK | Redaction coupled to requests' current param encoder (`quote_plus`, uppercase hex); an upgrade that changes the encoding re-leaks the key with no error | **fixed** (eb20108): added a structural pass, `re.sub(r"(apikey=)[^&\s]+", r"\1<redacted>", ...)` with a **literal** pattern (never built from the key — the brief's SAST rule). Raw + `quote_plus` replaces stay for any other spot the key could surface. Verified on a `%20`-encoded sample the encoder-based replaces would miss |
| R4 | NIT | The wrap drops `e.response`/`e.request`; a future maintainer passing them through would re-expose the keyed URL via `.url` | **fixed** (eb20108): `BingApiError` docstring states they are deliberately not propagated and why |
| R5 | NIT | Docstring "every `requests` error message embeds the URL with the key" is overbroad; urllib3 pool-timeout messages carry host:port only | **fixed** (eb20108): "most ... embed the request URL WITH the key; the rest embed nothing sensitive, and redaction is a no-op on them" |

CLEAN list from the reviewer (control flow, chaining claims, end-to-end encoding match
"raw and `quote_plus` are the only two spellings the key can take", replace ordering, empty/None
key, `r.json()` moved into `else`, class placement after the import guard, redirect edge,
traceback scope vs the stated threat model, unchanged aggregation) agrees with the in-house pass.

## Round 3 findings (7) — on `main...eb20108 -- skills`

Verdict: 0 BUG, 4 RISK, 3 NIT.

| id | sev | finding | disposition |
|----|-----|---------|-------------|
| T1 | RISK | Raised type drops the original response; a caller doing status-aware retry/backoff (e.g. distinguishing 429 from 400) loses the status code entirely | **fixed** (d6a6097): `BingApiError` now takes a `status_code` kwarg, populated from `e.response.status_code` (a bare int, not sensitive — unlike `.response`/`.request`, which both carry the keyed URL and stay unpropagated). Verified: `status_code == 400` on a real 400, key still absent |
| T2 | RISK | Any keyed `requests.get` elsewhere in the file, outside the two hunks shown, would still leak | **refuted**: `grep -n "requests\.\(get\|post\|request\)" bing_query.py` finds exactly one call site, inside `_fetch` itself — both endpoints (`GetQueryStats`, `GetPageStats`) already route through it. There is no "elsewhere" in this file |
| T3 | RISK | Only `requests.RequestException` is caught; a bare urllib3 exception or a future requests regression raising plain `ValueError` would escape unredacted | **waived**: no non-`RequestException` escape from `requests.get`/`raise_for_status` is observed or documented for the pinned `requests>=2.28`; the two-line try body (`requests.get` + `raise_for_status`) is narrow enough that broadening to bare `except Exception` there would mainly risk masking an unrelated bug rather than close a real gap. The existing docstring already scopes its claim honestly (round 2's NIT5 fix) rather than promising blanket coverage |
| T4 | RISK | `r.json()` sits in the `else:` clause, unprotected by the preceding `except`; a 200 response with a non-JSON body raises an unwrapped `JSONDecodeError` that could carry the key if Bing's body ever echoed the request line | **waived, verified**: confirmed directly — `Response.json()`'s `JSONDecodeError` message is parse-position text only (`"Expecting value: line 1 column 1 (char 0)"`), never the request URL. It is technically a `RequestException` subclass (requests ≥2.27) but carries nothing to redact even though it slips past this `except`, so the leak this diff protects against doesn't apply to it. The reviewer's own scenario requires Bing's response body to echo the keyed request URL back — not a failure mode this API has shown |
| T5 | NIT | Suggests a `# pylint: disable=...` comment on the possibly-unbound-looking `raise err` | **refuted**: no pylint, flake8, or ruff config exists anywhere in this repo (checked); the plain-English `# deliberate: ...` comment added in round 2 is the right form for this codebase's actual reader, a human, not a linter |
| T6 | NIT | `BingApiError` docstring said request AND response "both carry the keyed URL" unconditionally; a connection-level failure has no response at all | **fixed** (d6a6097): reworded to "the response, when there is one" |
| T7 | NIT | Gate the literal key replace on `len(key) >= 8` so a hypothetical short/low-entropy key can't over-redact | **waived**: real Bing Webmaster API keys are long GUIDs; the structural `apikey=` regex already redacts a short key too, so the scenario has no actual gap, only a theoretical one on an unrealistic input |

CLEAN list from the reviewer (chaining claims, exhaustive control flow, empty/None key,
encoding fidelity, regex safety incl. "never built from the key", the guard's ability to
actually fire, argument order, success-path parity, definition order, imports, "original
exception fully dropped", broad-catch compatibility, and confirming the leak premise itself is
real — `HTTPError`/`ConnectionError` messages do embed the keyed URL) agrees with the in-house
pass.

## Round closure

Three rounds. Round 1: 1 BUG + 2 RISK fixed, 2 waived/refuted. Round 2: 3 RISK + 2 NIT fixed
(one RISK's test-pin half stays owner-waived, consistent with round 1). Round 3: 0 BUG; 1 RISK
+ 1 NIT fixed, 3 waived or refuted with direct verification (a grep, a live `JSONDecodeError`
message, and a lint-config check) rather than by assertion. Two consecutive rounds with no
BUG, and round 3's open items are either factually false premises or defended edge cases with
no real key-bearing path — closing here. Final state verified end-to-end: a real 400 against
an unregistered site, a space-containing key, and a `ConnectionError` against an unreachable
host all produce a key-free message with `__cause__`/`__context__`/`.response`/`.request` all
`None` and `status_code` intact, through both the CLI and `insights.bing_positions`.
