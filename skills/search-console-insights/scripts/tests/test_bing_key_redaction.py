"""The Bing API key must never survive into an error message.

The key travels as a query parameter, so `requests` puts it in the URL it
quotes back in every transport error. `bing_query` and `insights` both print
those messages to stderr, and the weekly launchd jobs redirect stderr into
`~/.config/gsc-insights/logs/<domain>.log` — so anything reaching a message is
written to disk. Observed live 2026-09-03: one 400 for an unregistered site put
the real key in that log.

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
    """A real 400 Response carrying the URL requests would have built for `key`,
    so the text under test is the genuine message and not an imitation of it."""
    r = requests.Response()
    r.status_code = 400
    r.reason = "Bad Request"
    r.url = (f"{bing_query.API}/GetQueryStats"
             f"?apikey={quote_plus(key)}&siteUrl={quote_plus(SITE)}")
    return r


def error_from(key, get):
    """Call the real code path with `requests.get` stubbed out, and hand back
    the error it raised. No network, no key ever leaving this process."""
    with mock.patch.object(bing_query.requests, "get", get):
        try:
            bing_query.get_query_stats(SITE, key)
        except requests.RequestException as e:
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
        self.assertNotIn(SPACED_KEY, str(err))
        self.assertNotIn(quote_plus(SPACED_KEY), str(err))
        self.assertNotIn("s3cret", str(err))

    def test_an_encoding_we_do_not_predict_is_still_caught(self):
        # Only the structural `apikey=...` pass can catch this one: the key is
        # percent-encoded character by character, so neither the raw key nor its
        # quote_plus form appears. Stands in for a future requests/urllib3 that
        # encodes params differently — the reason that pass exists at all.
        exotic = "".join(f"%{ord(c):02x}" for c in KEY)
        boom = requests.ConnectionError(
            f"Max retries exceeded with url: /GetQueryStats?apikey={exotic}&siteUrl=x")

        def raising_get(*a, **k):
            raise boom

        err = error_from(KEY, raising_get)
        self.assertNotIn(exotic, str(err))

    def test_the_key_is_caught_outside_an_apikey_parameter(self):
        # And only the plain key replace can catch this one: the key is quoted
        # without the `apikey=` prefix the structural pass keys on. Stands in for
        # any message shape that repeats the value somewhere else.
        boom = requests.ConnectionError(f"Tunnel connection failed, sent token {KEY}")

        def raising_get(*a, **k):
            raise boom

        err = error_from(KEY, raising_get)
        self.assertNotIn(KEY, str(err))

    def test_transport_failure_is_redacted_too(self):
        # No response at all, so a different branch: the message comes from
        # urllib3 and still quotes the keyed URL.
        boom = requests.ConnectionError(
            f"HTTPSConnectionPool(host='ssl.bing.com', port=443): Max retries exceeded "
            f"with url: /webmaster/api.svc/json/GetQueryStats?apikey={quote_plus(KEY)}")

        def raising_get(*a, **k):
            raise boom

        err = error_from(KEY, raising_get)
        self.assertNotIn(KEY, str(err))

    def test_nothing_chains_the_unredacted_original(self):
        # _fetch builds the error inside `except` but raises it OUTSIDE, so the
        # original — whose message still holds the key — is never attached.
        # Moving that raise back inside, even as `raise ... from None`, leaves the
        # original on __context__: hidden from the printed traceback, still
        # reachable by anything that walks the chain. Nothing else would fail.
        err = error_from(KEY, lambda *a, **k: keyed_400(KEY))
        self.assertIsNone(err.__cause__)
        self.assertIsNone(err.__context__)

    def test_status_code_still_reaches_the_caller(self):
        # The response itself is dropped (its .url is keyed), so the bare number
        # is copied across on purpose — a caller branching on 4xx vs 5xx has
        # nothing else left to read.
        err = error_from(KEY, lambda *a, **k: keyed_400(KEY))
        self.assertEqual(err.status_code, 400)
        self.assertIsInstance(err, requests.RequestException)


if __name__ == "__main__":
    unittest.main()
