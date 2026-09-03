"""Which reported query stands for a target keyword — the choice the report
quotes and the history tracks week over week.

Run:  python3 -m unittest discover -s skills/search-console-insights/scripts/tests
"""

import os
import sys
import unittest

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from _history import NOISE_IMPRESSIONS as FLOOR  # noqa: E402  (10: the trend's `~` floor)
from _lang_normalize import match_keywords  # noqa: E402


def rows(*pairs):
    return [{"query": q, "impressions": n} for q, n in pairs]


def best(kw, *pairs):
    matched = match_keywords(rows(*pairs), [kw], lambda r: r["query"], FLOOR)[0][1]
    return [r["query"] for r in matched]


class BestMatch(unittest.TestCase):
    def test_exact_phrase_beats_long_tail_when_both_are_noise(self):
        # The live bug: volume alone (8 vs 3 impressions, both under the trend's
        # noise floor) tracked a fifteen-word query as "the" position for the
        # keyword, over the phrase the owner actually asked about.
        order = best("AI Events Munich",
                     ("german ai tech industry meetups munich berlin hamburg events", 8),
                     ("ai events munich", 3))
        self.assertEqual(order[0], "ai events munich")

    def test_trusted_volume_beats_a_thin_exact_row(self):
        # Otherwise the tracked query flips every time anonymisation drops the
        # 2-impression exact row for a week, and the trend becomes ≠ markers.
        order = best("AI Events Munich", ("ai events munich", 2), ("ai events in munich", 300))
        self.assertEqual(order[0], "ai events in munich")

    def test_exact_is_word_order_insensitive(self):
        # Both rows above the floor, so exactness decides — regardless of word order.
        order = best("Munich AI Events", ("ai events munich", 12), ("ai events in munich", 40))
        self.assertEqual(order[0], "ai events munich")

    def test_tokens_match_whole_word_prefixes_not_substrings(self):
        # "ai" must not match inside "main"; "event" may match "events".
        self.assertEqual(best("AI Events", ("main events munich", 40)), [])
        self.assertEqual(best("AI Event Munich", ("ai events munich", 6)), ["ai events munich"])

    def test_hyphenated_compound_and_umlaut_spellings_match(self):
        order = best("KI Events München", ("ki-events muenchen", 6))
        self.assertEqual(order, ["ki-events muenchen"])

    def test_solid_german_compound_matches_but_short_words_need_a_whole_word(self):
        # Germans write compounds solid; "ki" must still not catch "kino".
        self.assertEqual(best("Event Kalender", ("eventkalender muenchen", 40)),
                         ["eventkalender muenchen"])
        self.assertEqual(best("KI Events München", ("kino events muenchen", 40)), [])
        self.assertEqual(best("KI", ("kino programm", 40)), [])

    def test_no_match_reports_empty(self):
        self.assertEqual(best("AI Treffen München", ("ai events munich", 50)), [])


if __name__ == "__main__":
    unittest.main()
