"""The Bing API key must never survive into an error message.

The key travels as a query parameter, so `requests` puts it in the URL it quotes
back in every transport error. `bing_query` prints those messages to stderr, and
the weekly launchd jobs redirect stderr into
`~/.config/gsc-insights/logs/<domain-with-dots-as-dashes>.log` — so anything reaching a message is
written to disk. Observed live 2026-09-03: one 400 for an unregistered site put
the real key in that log.

Scope: `_fetch`, where the redaction happens, reached through `get_query_stats`.
That covers every caller which prints only the raised error — which is all of them
today. The message is not the sole carrier, so the error's attached response and
request are checked too.

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


def keyed_400(*args, **kwargs):
    """A 400 built from the request production actually made — the stub hands its
    own arguments straight here, so the URL under test is the one
    `get_query_stats` really constructs, encoded by requests itself. Fabricating
    it here instead would only ever prove redaction works on this file's idea of
    the URL, and would stay green through a parameter rename."""
    prepared = requests.Request("GET", args[0] if args else kwargs["url"],
                                params=kwargs.get("params")).prepare()
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
    def assertCarriesNothingKeyed(self, err):
        """The checks that must hold on every branch, not just the one tested:
        nothing chains the unredacted original, and no keyed URL rides along on
        an attached response or request."""
        self.assertIsNone(err.__cause__)
        self.assertIsNone(err.__context__)
        self.assertIsNone(err.response)
        self.assertIsNone(err.request)

    def test_http_error_text_carries_no_key(self):
        err = error_from(KEY, keyed_400)
        self.assertNotIn(KEY, str(err))
        self.assertIn("apikey=<redacted>", str(err))

    def test_a_key_with_a_space_is_caught_in_its_encoded_form(self):
        # requests encodes params with quote_plus, so a space reaches the URL as
        # "+", not "%20". Matching only the raw key or the quote() form missed it
        # and wrote the key to the log — the bug the first review round caught.
        err = error_from(SPACED_KEY, keyed_400)
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
        # Same guarantees as the HTTP branch: one raise serves both today, and if
        # that is ever split, this branch is held to the same standard.
        self.assertCarriesNothingKeyed(err)

    def test_nothing_keyed_rides_along_with_the_error(self):
        # Two ways the key escapes a clean message. _fetch builds the error inside
        # `except` but raises it OUTSIDE, so the original — whose message still
        # holds the key — is never chained; moving that raise back inside, even as
        # `raise ... from None`, leaves it on __context__, hidden from the printed
        # traceback but reachable by anything walking the chain. And the response
        # and request both carry the keyed URL on `.url`, so attaching either
        # hands the key straight to a caller that looks, with the message itself
        # still clean and every other assertion here still green.
        err = error_from(KEY, keyed_400)
        self.assertCarriesNothingKeyed(err)

    def test_status_code_still_reaches_the_caller(self):
        # The response itself is dropped, so the bare number is copied across on
        # purpose — a caller branching on 4xx vs 5xx has nothing else left to read.
        err = error_from(KEY, keyed_400)
        self.assertEqual(err.status_code, 400)


if __name__ == "__main__":
    unittest.main()
