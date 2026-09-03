# RAW reviewer output — DIFF round 2, kimi-k3:cloud, branch diff main...4dc0794

Verbatim `ollama_review.sh --diff --model kimi-k3:cloud` output. Triage in REVIEW-diff-2026-09-03-r1-bing-key-redaction-e69bd1b.md.

**BUG**
- None found in this diff.

**RISK** (ranked)
1. `bing_query.py::_fetch()` — final `raise err` (post-diff ≈ L91): nothing pins the diff's core invariant (`__context__`/`__cause__` are None). A routine lint-driven cleanup (pylint `possibly-used-before-assignment` on `err`, or someone restructuring into `raise BingApiError(...) from None` inside the handler) silently re-couples `__context__` to the unredacted original and undoes the whole change. Fix: add a unit test forcing one failing call and asserting `err.__context__ is None`, `err.__cause__ is None`, and `key not in str(err)` (plus a key containing a space, asserting the `+` form is also redacted); add a `# deliberate: raised outside except, see docstring` marker at the `raise err` line.
2. `bing_query.py::get_query_stats` / `get_page_stats` (approx. L99, L137): raised type changed from `requests.HTTPError` / `ConnectionError` / `Timeout` to `BingApiError`. Any existing caller or test catching one of those concrete subclasses no longer catches failures (behavioral contract change, silent). Fix: grep callers/tests for `except requests.HTTPError` etc. and confirm they catch `requests.RequestException` or broader; note the new contract in a changelog/test.
3. `bing_query.py::_fetch()` except block (approx. L79–L88): redaction is coupled to requests' current param encoder (`urlencode`/quote_via=`quote_plus`, uppercase hex, `requote_uri` pass-through). A requests/urllib3 upgrade that changes the encoding (e.g., space→`%20`, lowercase hex) makes `quote_plus(key)` stop matching and re-leaks the key into stderr logs with no error. Fix: redact the query param structurally instead, e.g. `re.sub(r'(apikey=)[^&\s]+', r'\1<redacted>', msg, flags=re.I)` in addition to the raw-key replace.

**NIT**
1. `bing_query.py::BingApiError` (≈ L48) / `_fetch()`: the wrap drops `e.response`/`e.request`; a future maintainer "helpfully" passing them through via `RequestException.__init__(response=..., request=...)` re-exposes the keyed URL via `.url` and defeats the redaction. Fix: extend the class docstring: "request/response are intentionally not propagated — both carry the keyed URL."
2. `bing_query.py::_fetch()` docstring: "every `requests` error message … embeds the request URL WITH the key" is overbroad — urllib3 `PoolError`-family messages (ReadTimeout/ConnectTimeout, no `MaxRetryError` wrap) contain host:port only, no query string. Harmless (redaction is safe no-op when the key is absent), but the wrong claim could mislead later edits. Fix: "most errors embed the keyed URL; the remainder embed nothing sensitive."

**CLEAN — checked, no finding**
- Control flow of `_fetch()`: `raise err` is reachable only with `err` bound — except-branch binds it, else-branch returns, non-`RequestException` propagates past the raise. No `UnboundLocalError` path.
- Docstring's chaining claims are accurate: raising outside the except suite leaves `__context__`/`__cause__` None; `raise ... from None` inside the handler sets `__suppress_context__` but still populates `__context__` (display-hidden, introspectable). The inverted try/except/else structure is justified, not cargo cult.
- Encoding match verified end-to-end: requests encodes the params dict via `urlencode` (default quote_via=`quote_plus`), and the same spelling is what appears in both HTTPError messages (`r.url`) and urllib3 `MaxRetryError` messages (path_url) — `requote_uri` preserves quote_plus output including uppercase hex. Raw and `quote_plus` forms are the only two spellings the key can take, and both are replaced.
- Replace ordering: once any encoding occurs, the raw key cannot be a substring of its `quote_plus` output (encoder inserts `+`/`%25` at those positions); when no encoding applies the forms are identical and replace #1 already redacts. No clobber bug; the second replace is a harmless no-op for plain alnum keys and correct otherwise.
- Empty/`None` key: guarded by `if key:`; requests additionally drops `None`-valued params, so `apikey` wouldn't appear at all.
- `r.json()` moved into `else:`: requests' `JSONDecodeError` messages carry line/col only, no URL — no unredacted leak path on the success branch.
- Class placement: `BingApiError` is defined after the `except ImportError: sys.exit(2)` guard, so it can't be evaluated without requests; `requests.RequestException` is a top-level export in supported requests versions, so the subclass resolves at import.
- Redirect edge: HTTPError messages use the final response URL (redirect targets typically drop the original `apikey` param), and `TooManyRedirects` messages carry no URL — covered or nothing to redact.
- Traceback scope: `err.__traceback__`'s frame holds the `key`/`r` locals, but default stderr rendering (`sys.excepthook`/`traceback.print_exc()`) prints no locals — consistent with the docstring's stated stderr-to-logfile threat model.
- Unchanged behavior: query/page aggregation logic, `get("d", []) or []` defaulting, and `timeout=30` are byte-identical to the original; `quote_plus` import has no ordering/collision issue.
