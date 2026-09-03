# RAW reviewer output — DIFF round 3, kimi-k3:cloud, branch diff origin/main...650291a

Verbatim output. NOTE: `ollama_review.sh` exited 1 and routed this to stderr, judging it
"not a review" — its heuristic misfired on the "**None demonstrable from the diff alone.**"
opening. The content is a genuine review and was triaged as one; see the matching REVIEW-*.md.

waiting on kimi-k3:cloud (cloud models can take 15-60s+, especially on a cold first call)...
model output does not look like a review (refusal or error blurb?) — rejected:
## BUGS
**None demonstrable from the diff alone.** Unverifiable contracts with the unseen `bing_query` (module attr `API` used at ~:37, module attr `requests` at ~:58, the literal marker `apikey=<redacted>` at ~:72, and a `status_code` attribute present — as `None` — even on the transport branch at ~:123) would all fail **loudly** if broken, so none are hidden bugs; but their correctness cannot be confirmed from this diff.

## RISKS
1. **`test_bing_key_redaction.py:54-56` (`error_from`'s `stub`) + `:34-44` (`keyed_400`)** — The stub discards the real call args and every test asserts against a URL the *fixture* fabricated (hard-coded `apikey=`/`/GetQueryStats`), so the suite proves redaction works on fixture-shaped URLs, not the URL `get_query_stats` actually builds; a refactor that changes how the key reaches the URL (param rename, pre-encoded/f-string URL) keeps all tests green while the leak path reopens. **Fix:** have `stub` rebuild the response URL from its received `*a/**k` (re-`prepare()` a `requests.Request` from them) instead of calling `keyed_400`, or at minimum assert the key (raw or `quote_plus` form) appears in the stub's actual received URL/params.
2. **`test_nothing_chains_the_unredacted_original` (~:125-133) & `test_the_keyed_response_and_request_are_not_carried` (~:135-141)** — Chain/attachment assertions only run on the HTTP-error fixture; the transport test (~:108-123), which the file itself calls "a different branch," gets no `__context__`/`__cause__`/`.request` checks, so an inside-`except` raise on that branch would chain the keyed urllib3 original and nothing fires. **Fix:** extract a `assertCleanError(err)` helper (message + `__cause__` + `__context__` + `.request`) and call it in both the HTTP and transport tests.

## NITS
3. **Module docstring (~:10-12)** — "guarding the message here covers them all" overstates scope: it holds only while every caller prints nothing but `str(err)`; the file's own response/request/chain tests prove the message isn't the only carrier. **Fix:** soften to "covers every caller that prints only the raised error."
4. **`:23` (`sys.path.insert`)** — inserts an unnormalized, cwd-relative `tests/..` path; the documented `discover` command works, but any other cwd/runner layout silently mis-resolves the import root. **Fix:** `os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")`.
5. **`:58` (`mock.patch.object(bing_query.requests, "get", stub)`)** — mutates the shared global `requests` module for the duration of the patch; fine under sequential unittest, but any concurrent in-process `requests` use during the window silently hits the stub. **Fix:** none needed today; if a threaded runner is ever adopted, patch a narrower seam (injected session / `bing_query` call site).

## CLEAN
- **Fixture encoding realism:** verified `requests.Request(..., params=dict).prepare()` encodes via `urlencode`/`quote_plus`, so `SPACED_KEY` really lands as `s3cret+key+value` — the spaced-key tests (~:74-80, :108-123) exercise the exact `'+'`-vs-`%20` regression described, not a stand-in.
- **Chaining semantics:** verified against CPython behavior — raise outside `except` leaves `__cause__`/`__context__` None; inside-`except` raise sets `__context__`; `raise ... from None` still sets `__context__` (with `__suppress_context__=True`); `raise ... from original` sets `__cause__`. The comment at ~:128-130 is accurate, and the two assertions discriminate all four placements.
- **`error_from` "fails loudly" guard (:47-65):** traced refactor scenarios — real-network success → "expected to fail" AssertionError; real-network failure with stub unreached → "stubbed transport was never called"; non-`RequestException` propagation → unittest error; swallowed failure returning normally → AssertionError. No silent-pass path found; claim holds.
- **Assertion isolation (no vacuous tests):** deleting the raw-key replace fails ~:96-106; deleting the `quote_plus` replace fails ~:74-80 and ~:108-123; deleting the structural `apikey=` pass fails ~:82-94 (exotic string contains neither raw nor `quote_plus` form, and ~:72's `assertIn` marker); re-attaching `response`/`request` kwargs fails ~:135-141; dropping status propagation fails ~:143-147.
- **End-of-string anchoring:** the transport fixture (~:113-115) places the encoded key at end of message with no trailing `&`, so patterns requiring a following delimiter would be caught.
- **Fixture fidelity:** `r.url` + `r.request = prepared` mirrors what requests sets on raised errors, and `raise_for_status` composes its message from `.url`, so the redaction target string is realistic; fresh `requests` exceptions default `.response`/`.request` to `None`, making ~:140-141 well-formed.
- **Test mechanics:** filename/class/method naming matches `unittest discover` defaults; no inter-test state (fresh `Response` per stub call tolerates retries); `KEY` is ASCII-safe for the `%02x` build at ~:86; all imports used.
