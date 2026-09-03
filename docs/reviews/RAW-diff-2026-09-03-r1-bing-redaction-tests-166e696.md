# RAW reviewer output — DIFF round 1, kimi-k3:cloud, branch diff origin/main...166e696

Verbatim `ollama_review.sh --diff --model kimi-k3:cloud` output. Triage in the matching REVIEW-*.md.

## Ranked findings

### BUG
None identified from the added test file alone.

### RISK

1. **`skills/search-console-insights/scripts/tests/test_bing_key_redaction.py` — `error_from()`**
   - Patching only `bing_query.requests.get` silently misses a normal refactor to `Session.get`, `requests.request`, or an injected client, potentially allowing a real network call before the test fails.
   - **Fix:** make transport injectable and stub that boundary, or patch every supported transport path and assert the fake transport was invoked before production code can perform I/O.

2. **`…/test_bing_key_redaction.py` — module docstring and test scope**
   - The docstring claims both `bing_query` and `insights` are covered, but no test invokes `insights`, captures stderr, or checks the launched/logging path.
   - **Fix:** add caller-level tests that patch transport, invoke each entry point, and assert captured stderr/log output contains no key.

3. **`…/test_bing_key_redaction.py` — `test_status_code_still_reaches_the_caller()`**
   - The comment says the keyed response is deliberately dropped, but the test only checks `status_code`; attaching the original response with a keyed `.url` would remain green.
   - **Fix:** also assert `err.response is None` and, if applicable, `err.request is None`, or explicitly test the intended absence of URL-bearing attributes.

4. **`…/test_bing_key_redaction.py` — `keyed_400()`**
   - The “genuine” requests URL is manually reconstructed with `quote_plus`; a dependency or production serialization change can make the fixture drift from the real URL while the comment continues to assert authenticity.
   - **Fix:** derive the fixture URL through `requests.Request(..., params=...).prepare()` or the production request-construction helper without performing network I/O.

### NIT

1. **`…/test_bing_key_redaction.py` — `test_status_code_still_reaches_the_caller()`**
   - `assertIsInstance(err, requests.RequestException)` cannot fail after `error_from()` has already returned only an object caught as `requests.RequestException`.
   - **Fix:** remove the redundant assertion or change `error_from()` if wrong-type failures are meant to produce this assertion.

2. **`…/test_bing_key_redaction.py` — `test_a_key_with_a_space_is_caught_in_its_encoded_form()`**
   - `assertNotIn(SPACED_KEY, str(err))` is inherently satisfied for this fixture because only the encoded key is placed in the response URL.
   - **Fix:** keep the encoded-form assertions, or move the raw-key assertion to a fixture that actually embeds the raw key.

3. **`…/test_bing_key_redaction.py` — `test_an_encoding_we_do_not_predict_is_still_caught()`**
   - The comment claims only the structural `apikey=...` pass can catch the exotic encoding, although decoder-based redaction could also catch it.
   - **Fix:** state that this specifically exercises structural parameter redaction rather than claiming it is the only possible mechanism.

## Checked CLEAN

- The test filename and `unittest` entry point are compatible with standard discovery.
- Both HTTP-response and transport-exception paths are exercised.
- Raw-key, `quote_plus`-encoded-key, structurally-embedded encoded-key, and key-outside-`apikey` message shapes are exercised.
- The tests do not require a real Bing credential or intentionally make a network request under the current assumed `requests.get` call path.
- `requests.get` patching is scoped by `mock.patch.object`, so normal sequential execution restores the original function.
- The no-raising path is guarded: a successful production call raises `AssertionError`.
- `__cause__` and `__context__` are both checked for accidental chaining of the unredacted exception.
- HTTP status preservation is checked independently of retaining the keyed response body or URL.
- Test keys are clearly synthetic and sufficiently distinctive for substring assertions.
- Exception message checks consistently inspect the actually returned exception rather than only the mocked response.
