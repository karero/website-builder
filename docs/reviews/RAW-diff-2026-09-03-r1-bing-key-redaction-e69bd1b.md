# RAW reviewer output — DIFF round 1, kimi-k3:cloud, branch diff main...e69bd1b

Verbatim `ollama_review.sh --diff --model kimi-k3:cloud` output. Triage in the matching REVIEW-*.md.

## BUG

1. **`scripts/bing_query.py` — `_fetch()`, the `msg.replace(quote(key, safe=""), ...)` line (≈L80)** — `requests` encodes `params` via `urlencode` → `quote_plus`, so a key containing a space (classic trailing-whitespace paste, which also guarantees a 401 → error path) appears in the URL as `+`, while the redactor searches for `%20` and the raw form, so **both replaces miss and the key lands in the log file this diff exists to protect**. Fix: also replace `quote_plus(key, safe="")` (or replace raw + quote + quote_plus), and/or `key.strip()` at config load.

## RISK

1. **`bing_query.py` — `_fetch()` tail, `err = RuntimeError(...)` / `raise err` (≈L82–84)** — silent exception-contract change: `get_query_stats`/`get_page_stats` now raise bare `RuntimeError` instead of `requests.HTTPError`, so any caller (outside this diff) doing `except requests.RequestException` stops catching, and the status code/`response` is gone (no way to distinguish 401 vs 429/5xx for retries or tests). Fix: raise a `class RedactedApiError(requests.RequestException)` with the redacted message; if you attach `response`/`request` for status access, scrub `response.request.url` first.

2. **`bing_query.py` — `_fetch()` signature + except block (≈L62–83)** — the docstring's "redact once, before anyone can print it" is defeated by traceback-with-locals tooling: Sentry (captures locals by default), `pytest --showlocals`, `traceback(show_locals=True)` all print `_fetch`'s live `key` local — and even rebinding inside `_fetch` doesn't help because the **caller frames (`get_query_stats`, etc.) also hold `key`**. Fix: hold the key in a tiny credential object whose `__repr__`/`__str__` return `"<redacted>"` and pass that through the stack, or explicitly document that locals-capturing error tooling is unsafe.

3. **Diff-wide — no tests added for `_fetch`** — nothing pins the two invariants this change depends on (key absent from `str(exc)`; `__cause__`/`__context__` both `None`), so a future "cleanup" to `raise ... from None` inside the handler silently re-attaches the unredacted original via `__context__` (hidden from display, still traversable by reporters). Fix: test that mocks `requests.get` to raise a real `HTTPError`/`ConnectionError` whose prepared URL contains the key, then asserts the key substring is absent and `exc.__context__ is None and exc.__cause__ is None`.

## NIT

1. **`bing_query.py` — `_fetch()`, both `msg.replace` lines (≈L79–80)** — whole-message `str.replace` will mangle diagnostics if the key collides with unrelated text (e.g., the key string also appearing inside the echoed `siteUrl` in the same URL). Fix: redact only the `apikey=...` span up to the next `&`, or rebuild the message from `e.request.url` with the query param surgically replaced.

## CHECKED — CLEAN

- **Happy-path equivalence**: same `API` base, endpoint literals (`GetQueryStats`/`GetPageStats`), params dict, `timeout=30`, and `r.json().get("d", []) or []`; both callers' aggregation loops untouched — no wire-behavior drift.
- **Control flow**: no unbound-`err` path — `raise err` is reachable only from the except branch where `err` is always assigned; success returns inside `else`; can't fall through.
- **The `__cause__`/`__context__` claim is true as written**: raising after the except block (PEP 3110 restores exc state on handler exit, and the `as e` name is auto-deleted) leaves both unset — the contorted shape is strictly stronger than `raise ... from None` (which retains the original under `__context__`), so it is justified, not a smell. Flagged only the missing test pin (RISK 3).
- **`if key:` guard**: correctly prevents the empty-string replace pathology (`"<redacted>"` between every character) and `quote(None)` TypeError; falsy-key path still raises a well-formed error with nothing to leak (requests drops `None` params; empty string yields `apikey=` with no secret).
- **Raw-replace coverage of dominant error shapes**: `HTTPError` (`raise_for_status`: `"…for url: <prepared URL>"`, no response body), `ConnectionError`/`MaxRetryError`, and `Timeout` all embed the prepared URL, where alphanumeric keys appear verbatim; `SSLError`/cert failures embed no target URL at all (nothing to leak).
- **Codec audit**: `quote` vs `quote_plus` differ **only** on space (same uppercase `%XX`, same unreserved set) — so BUG 1 is the complete codec gap; `/`, `:`, `%`, `+`, unicode all round-trip identically, and quote's output can never accidentally match the already-inserted `<redacted>` sentinel.
- **Non-`RequestException` escapes**: `requests.get` origination errors (`MissingSchema`, `InvalidURL`, `TooManyRedirects`) all subclass `RequestException`, so nothing key-bearing escapes the handler; `r.json()` failures stay outside it and carry a body excerpt, not the URL — same exposure as pre-diff.
- **No regressions in the two refactored callers**: aggregation order, impression-weighting inputs, and the Query-field-carries-page-URL behavior are unchanged; new names (`_fetch`, `err`, `quote`) shadow nothing visible in the module.
