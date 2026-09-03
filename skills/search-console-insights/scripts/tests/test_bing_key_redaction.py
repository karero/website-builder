"""The Bing API key must never survive into an error message.

The key travels as a query parameter, so `requests` puts it in the URL it quotes
back in every transport error. `bing_query` prints those messages to stderr, and
the weekly launchd jobs redirect stderr into
`~/.config/gsc-insights/logs/<domain>.log` — so anything reaching a message is
written to disk. Observed live 2026-09-03: one 400 for an unregistered site put
the real key in that log.

Scope: `_fetch`, where the redaction happens, reached through `get_query_stats`.
Every caller downstream of it prints whatever it raises, so guarding the message
here covers them all.

Run:  python3 -m unittest discover -s skills/search-console-insights/scripts/tests
"""

import os
import sys
import unittest
from unittest import mock
from urllib.parse import quote_plus

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

import requests  # noqa: E402
import bing_query  # noqa: E402

KEY = "s3cretkeyvalue"
SPACED_KEY = "s3cret key value"  # a pasted key that kept a space, which 400s anyway
SITE = "https://example.com"


def keyed_400(key):
    """A 400 whose URL is built by requests' own encoder, so the fixture tracks
    however requests really spells the key rather than a guess that can drift."""
    prepared = requests.Request("GET", f"{bing_query.API}/GetQueryStats",
                                params={"apikey": key, "siteUrl": SITE}).prepare()
    r = requests.Response()
    r.status_code = 400
    r.reason = "Bad Request"
    r.url = prepared.url
    r.request = prepared  # as requests does; .url on it is keyed too
    return r


def error_from(key, get):
    """Call the real code path with `requests.get` stubbed out, and hand back the
    error it raised. Insists the stub was reached: if the code is ever refactored
    onto another transport, this fails loudly instead of quietly reaching the
    network and passing anyway."""
    reached = []

    def stub(*a, **k):
        reached.append(1)
        return get(*a, **k)

    with mock.patch.object(bing_query.requests, "get", stub):
        try:
            bing_query.get_query_stats(SITE, key)
        except requests.RequestException as e:
            if not reached:
                raise AssertionError("the stubbed transport was never called")
            return e
    raise AssertionError("the call was expected to fail, but returned")


class KeyNeverReachesTheMessage(unittest.TestCase):
    def test_http_error_text_carries_no_key(self):
        err = error_from(KEY, lambda *a, **k: keyed_400(KEY))
        self.assertNotIn(KEY, str(err))
        self.assertIn("apikey=<redacted>", str(err))

    def test_a_key_with_a_space_is_caught_in_its_encoded_form(self):
        # requests encodes params with quote_plus, so a space reaches the URL as
        # "+", not "%20". Matching only the raw key or the quote() form missed it
        # and wrote the key to the log — the bug the first review round caught.
        err = error_from(SPACED_KEY, lambda *a, **k: keyed_400(SPACED_KEY))
        self.assertNotIn(quote_plus(SPACED_KEY), str(err))
        self.assertNotIn("s3cret", str(err))

    def test_an_encoding_we_do_not_predict_is_still_caught(self):
        # Exercises the structural `apikey=...` pass on its own: the key is
        # percent-encoded character by character, so neither the raw key nor its
        # quote_plus form appears for the other replaces to find.
        exotic = "".join(f"%{ord(c):02x}" for c in KEY)
        boom = requests.ConnectionError(
            f"Max retries exceeded with url: /GetQueryStats?apikey={exotic}&siteUrl=x")

        def raising_get(*a, **k):
            raise boom

        err = error_from(KEY, raising_get)
        self.assertNotIn(exotic, str(err))

    def test_the_key_is_caught_outside_an_apikey_parameter(self):
        # Exercises the plain key replace: the key is quoted without the `apikey=`
        # prefix the structural pass keys on. Stands in for any message shape that
        # repeats the value somewhere else.
        boom = requests.ConnectionError(f"Tunnel connection failed, sent token {KEY}")

        def raising_get(*a, **k):
            raise boom

        err = error_from(KEY, raising_get)
        self.assertNotIn(KEY, str(err))

    def test_transport_failure_is_redacted_too(self):
        # No response at all, so a different branch: the message comes from
        # urllib3 and still quotes the keyed URL.
        # Spaced key on purpose: its quote_plus form differs from the raw key, so
        # this also covers the encoded spelling landing at the end of the message.
        boom = requests.ConnectionError(
            f"HTTPSConnectionPool(host='ssl.bing.com', port=443): Max retries exceeded "
            f"with url: /webmaster/api.svc/json/GetQueryStats?apikey={quote_plus(SPACED_KEY)}")

        def raising_get(*a, **k):
            raise boom

        err = error_from(SPACED_KEY, raising_get)
        self.assertNotIn(quote_plus(SPACED_KEY), str(err))
        self.assertNotIn("s3cret", str(err))
        self.assertIsNone(err.status_code)

    def test_nothing_chains_the_unredacted_original(self):
        # _fetch builds the error inside `except` but raises it OUTSIDE, so the
        # original — whose message still holds the key — is never attached.
        # Moving that raise back inside, even as `raise ... from None`, leaves the
        # original on __context__: hidden from the printed traceback, still
        # reachable by anything that walks the chain. Nothing else would fail.
        err = error_from(KEY, lambda *a, **k: keyed_400(KEY))
        self.assertIsNone(err.__cause__)
        self.assertIsNone(err.__context__)

    def test_the_keyed_response_and_request_are_not_carried(self):
        # Both hold the keyed URL on `.url`, so attaching either would hand the
        # key straight back to any caller that looked — with the message itself
        # still clean, and every assertion above still green.
        err = error_from(KEY, lambda *a, **k: keyed_400(KEY))
        self.assertIsNone(err.response)
        self.assertIsNone(err.request)

    def test_status_code_still_reaches_the_caller(self):
        # The response itself is dropped, so the bare number is copied across on
        # purpose — a caller branching on 4xx vs 5xx has nothing else left to read.
        err = error_from(KEY, lambda *a, **k: keyed_400(KEY))
        self.assertEqual(err.status_code, 400)


if __name__ == "__main__":
    unittest.main()
