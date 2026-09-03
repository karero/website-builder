# RAW reviewer output — DIFF round 2, kimi-k3:cloud, branch diff origin/main...b12bcb8

Verbatim `ollama_review.sh --diff --model kimi-k3:cloud` output. Triage in the matching REVIEW-*.md.

## BUG
None found. The file is internally self-consistent; the remaining items are RISK/NIT below.

## RISK

1. **`test_bing_key_redaction.py:38-42` (`keyed_400`) — the `.request` half of `test_the_keyed_response_and_request_are_not_carried` cannot fire.**
   Real responses from `requests.get` carry the keyed `PreparedRequest` on `.request` (requests' `build_response` sets `response.request = req`), but the fixture leaves `r.request = None`, so a regression that forwards `r.request` onto the raised error copies `None` and stays green — exactly the leak the test comment describes, in the only form production produces it.
   **Fix:** in `keyed_400`, add `r.request = prepared` (the prepared request is already in hand two lines above).

2. **`test_bing_key_redaction.py:45-63` (`error_from`) — the "fails loudly instead of quietly reaching the network" guarantee does not survive a normal refactor, and the patch mutates the shared module.**
   `mock.patch.object(bing_query.requests, "get", stub)` patches the global `requests` module attribute, which only intercepts attribute-style `requests.get(...)` calls; a future `from requests import get` inside `bing_query` bypasses the stub, and if the real call returns a redacted error (e.g., a 401 whose message contains `apikey=<redacted>`), test 1 can pass after hitting the network — the `reached` guard only fires when a `RequestException` surfaces with the stub untouched.
   **Fix:** pin the seam explicitly — e.g. assert at module setup that `bing_query.requests is requests` and `not hasattr(bing_query, "get")` — or add a socket-level guard (patch `socket.socket.connect` to raise inside `error_from`) so any quiet network reach fails regardless of import style.

## NIT

3. **`test_bing_key_redaction.py:113-115` (`test_transport_failure_is_redacted_too`) — `quote_plus(KEY)` is a no-op for this key.**
   `KEY` is alphanumeric, so its quote_plus form equals the raw key; the end-of-string `apikey=` case is fully backstopped by the raw-key replace and the test cannot distinguish "structural pass handles end-of-string" from "raw pass covered it."
   **Fix:** use `SPACED_KEY` here so the urllib3-style message exercises the encoded form at end-of-string.

4. **`test_bing_key_redaction.py:82-85` (comment on `test_an_encoding_we_do_not_predict_is_still_caught`) — comment overclaims.**
   The hand-built exotic encoding does not "stand in for a future requests that encodes params differently" (any realistic future encoding flows through the `keyed_400` fixture, which already tracks requests' real encoder); what it tests is the structural `apikey=` pass, full stop.
   **Fix:** trim the comment to state it exercises the structural pass with an encoding no other replace could find.

## CHECKED — CLEAN

- **Encoding assumptions verified against real requests behavior:** requests encodes `params` via `urlencode`/`quote_plus`, so a space becomes `+`; building the fixture URL through `requests.Request(...).prepare()` correctly tracks the library rather than a guess, and `quote_plus(SPACED_KEY)` = `s3cret+key+value` matches what `prepared.url` will contain.
- **Exception-chaining semantics verified:** `raise ... from None` still sets `__context__` (it only sets `__suppress_context__`), and an implicit `raise` inside `except` sets `__context__` with `__cause__` None — so the paired `assertIsNone(err.__cause__)` / `assertIsNone(err.__context__)` in `test_nothing_chains_the_unredacted_original` does catch every re-chaining variant, as the comment claims.
- **`error_from` control flow verified:** returns the exception on the happy path; loud `AssertionError` both when the call succeeds and when a `RequestException` arrives without the stub being reached; the final `raise` sits correctly outside the `with` so the patch is already torn down; a non-`RequestException` propagates and fails loudly.
- **Fixture never touches the patched symbol:** `keyed_400`/the raising stubs use only `Request`, `Response`, and `ConnectionError` constructors, never `requests.get`, so fixture construction inside the patched region is undisturbed.
- **requests defaults verified:** `RequestException.__init__` defaults `.response`/`.request` to `None` and `raise_for_status` attaches only `.response` — so the `.response` half of test 7 *can* fire, and tests 5/7/8's expectations (`status_code` present, `None` on transport failure, `400` on HTTP error) are mutually consistent with the presumed custom-attribute design; no internal contradiction.
- **No assertion self-masking:** the `<redacted>` placeholder contains none of the asserted-absent substrings (`s3cret`, the exotic percent-form), so `assertNotIn` cannot pass trivially via the placeholder; `SITE` appears only in percent-encoded form and collides with no assertion.
- **Test 2 redundancy is sound:** `assertNotIn("s3cret", ...)` also covers the raw-with-literal-space variant, so the belt-and-suspenders intent holds.
- **Isolation/statelessness:** constants are module-level and immutable; the patch is fully reverted by the context manager; no test depends on execution order or leaks global state (beyond the intentional, permanent `sys.path.insert`).
- **Run instructions consistent:** the documented `unittest discover -s …/tests` works with the self-contained `sys.path.insert` shim; top-level test files in the start directory need no `__init__.py`.
- **Scope claim consistency:** the module docstring scopes coverage to `_fetch` via `get_query_stats`, and every test in fact goes through `error_from`/`get_query_stats` — no test silently asserts behavior outside the stated scope. (The factual claims about launchd logs and the 2026-09-03 incident, and `bing_query`'s actual redaction format/`status_code` attribute, are outside this diff and were treated as unverifiable premises, not checkable here.)
