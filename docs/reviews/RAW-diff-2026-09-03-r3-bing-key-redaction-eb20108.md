# RAW reviewer output — DIFF round 3, kimi-k3:cloud, code diff main...eb20108 -- skills

Verbatim `ollama_review.sh --diff --model kimi-k3:cloud` output. Triage in REVIEW-diff-2026-09-03-r1-bing-key-redaction-e69bd1b.md.

## BUG

- **None found.** Control-flow and exception-chaining claims in the diff verify as correct (see CLEAN).

## RISK (ranked)

1. **bing_query.py :: `_fetch` / `class BingApiError`** — Raised type silently narrows from `HTTPError`/`ConnectionError` etc. to `BingApiError` with `.response`/`.request` deliberately `None`; any current or near-future caller doing `except requests.HTTPError` or reading `e.response.status_code` (retry/backoff logic, status-aware wrappers) stops catching or AttributeErrors, and a *missed* catch fails loudly, not safely. **Fix:** audit/convert call sites to `except BingApiError` (or broad `except requests.RequestException`), and/or preserve subtype info on the new error, e.g. `err.status_code = getattr(e.response, "status_code", None)`.

2. **bing_query.py :: module scope (verification gap)** — The "redact here, once, before anyone can print it" guarantee only covers endpoints routed through `_fetch`; the diff converts exactly two call sites, and any other keyed `requests.get(...apikey...)` elsewhere in this file (outside the shown hunks) still leaks raw keyed messages into the same stderr log. **Fix:** grep the module for remaining direct `requests.get`/`raise_for_status` keyed calls and route them through `_fetch`; optionally add a lint/CI rule banning bare `requests.get` in this directory.

3. **bing_query.py :: `_fetch`, `except requests.RequestException`** — Redaction scope is limited to `requests.RequestException`; non-RequestException escapes from `requests.get`/`raise_for_status` (e.g. a bare urllib3 `LocationParseError` on a malformed redirect Location, which embeds the full keyed URL, or any future requests regression raising plain `ValueError`) propagate the unredacted keyed message. **Fix:** catch `Exception` (not `BaseException`) and funnel through the same redact-then-`raise err`-outside path, keeping the `type(e).__name__` prefix so the original type isn't masked.

4. **bing_query.py :: `_fetch`, `else: return r.json()...`** — `r.json()` sits outside the protected try; a 200-with-non-JSON body raises an unwrapped, unredacted `JSONDecodeError`/`ValueError` whose str embeds a response-body snippet — if Bing ever returns an error page echoing the request line, the key reaches the log, and the error escape hatch bypasses `BingApiError` entirely. **Fix:** wrap the parse: move `r.json()` into its own `try/except ValueError` that redacts and raises via the same `err` path (catching `ValueError`, not just `requests.RequestException`, since pre-2.27 requests raises plain `ValueError`).

## NIT (ranked)

1. **bing_query.py :: `_fetch`, trailing `raise err`** — Provably safe but `err` is only bound in the except branch, so pylint/pyright will flag possibly-unbound/used-before-assignment. The current structure is *required* to get a genuinely empty `__context__` (raising inside the handler can't achieve that), so don't restructure — **fix** with a targeted `# pylint: disable=possibly-used-before-assignment`-style suppression comment.

2. **bing_query.py :: `class BingApiError` docstring** — "both carry the keyed URL (`.url`)" overgeneralizes: for connection-level failures `.response` is `None`; the actual leak vectors are `.request.url` (always) and `.response.url` (when present). **Fix:** reword to "the request — and the response, when present — carry the keyed URL".

3. **bing_query.py :: `_fetch`, `msg.replace(key, ...)`** — Unconditional literal replace could over-redact unrelated message text if a key were ever short/low-entropy; real Bing keys are long, so impact is cosmetic. **Fix (optional):** gate the literal replaces on `len(key) >= 8` and let the structural regex cover short keys.

## CLEAN (checked, no issue)

- **Chaining claims verified:** constructing `err` inside the handler but raising it after the except block yields `__cause__ is None` and `__context__ is None` (raise-time, not construction-time, is when context binds); the docstring's caveat that `raise ... from None` merely sets `__suppress_context__` while keeping `__context__` populated is accurate.
- **Control flow exhaustive:** try-success → `else` returns rows; RequestException → `err` bound → `raise err`; other exception → propagates. No path reaches `raise err` unbound; no `UnboundLocalError` reachable.
- **Empty/None key guarded:** `if key:` prevents pathological `str.replace("", "<redacted>")` (which would inject between every character); the structural regex still redacts in that case.
- **Encoding fidelity:** requests serializes `params` via `urlencode` (default `quote_via=quote_plus`, `safe=''`), so `quote_plus(key)` reproduces the exact on-the-wire form, including unreserved-char behavior; replacing raw-then-encoded is order-safe and idempotent for plain-alphanumeric keys.
- **Regex safety:** pattern is a literal, never built from the key (no metacharacter injection); `[^&\s]+` correctly terminates at `&`/whitespace/end; `IGNORECASE` covers case drift; over-consumption of a trailing quote is harmless since it only widens redaction.
- **Guard can actually fire:** the `apikey=` regex matches even after the literal replaces ran (rewriting `apikey=<redacted>` to itself) and matches independently of the key's value/encoding — it is not a dead guard against the failure mode it names (changed requests encoding).
- **Argument order:** `_fetch(endpoint, site, key)` matches both call sites (`_fetch("GetQueryStats", site, key)`, `_fetch("GetPageStats", site, key)`) and preserves the original `params` dict.
- **Success-path parity:** `r.json().get("d", []) or []` is behavior-identical to the removed code for both endpoints; aggregation/folding logic is untouched by the hunks.
- **Definition order:** `BingApiError` is defined after the `try: import requests / except ImportError: sys.exit(2)` guard, so the `requests.RequestException` base resolves at class-definition time.
- **Imports:** `re` and `quote_plus` are both used; no unused or shadowed imports introduced.
- **Original exception fully dropped:** `except ... as e` auto-unbinds `e` after the block; no traceback/`.request`/`.response` is copied into `BingApiError`, whose `args` contains only the redacted string — residual `e.args`-style inspection is safe.
- **Catch-compatibility:** `BingApiError` subclasses `requests.RequestException`, so existing *broad* upstream catches still match (only narrow subtype catches are affected — see RISK 1).
- **Leak premise is real, not phantom:** confirmed that `HTTPError` ("... for url: {full_url}") and `ConnectionError` ("Max retries exceeded with url: ...?apikey=...") messages do embed the keyed URL, so the redaction addresses an actual exposure.
