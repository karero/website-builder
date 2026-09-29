"""The response parsers against REAL provider answers, not against our own stub.

Why: every other GEO test talks to _geo_stub.py, which builds responses the way this code
expects them — so it can't catch a parser that misreads what a provider actually sends.
The fixtures in fixtures/ are real responses, captured live on 2026-09-26 with a neutral
question that names no client ("Which bakeries in Munich sell sourdough bread?"; the AI
Overview one with "how to make sourdough bread at home", because Google showed no overview
for the first). Trimmed in code by fixtures/capture.py's trim(): encrypted_* blobs, SerpApi metadata, and
the titles, snippets and thumbnails of cited pages (third-party page text) inside reference /
citation / result lists; answer text untouched. (A hand trim on 2026-09-26 briefly blanked the
AI Mode answer blocks too; they were restored from the capture and re-trimmed by trim().) Checked for API keys before saving. The OpenAI pair was captured
later the same day, once the account had credit. google-overview-finds-absent.json is `{}`:
synthetic, what a response without an ai_overview block trims down to.

How they were captured, exactly: fixtures/capture.py (re-run it to refresh them after a
provider changes its format, then re-run these tests).

Run:  python3 -m unittest discover -s skills/search-console-insights/scripts/tests
"""
import json
import os
import sys
import unittest
from pathlib import Path

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))
import geo_check  # noqa: E402

FIX = Path(__file__).parent / "fixtures"


def load(name):
    return json.loads((FIX / name).read_text(encoding="utf-8"))


class RealResponses(unittest.TestCase):
    def parse(self, engine, name):
        return geo_check.parse_response(engine, load(name))

    # Each answer's LAST words, and exact source counts: a parser that keeps only the first text
    # block (Anthropic sends ~23), the first part, or skips nested lists fails here.
    KNOWS = {"gemini": "German sourdough loaf.", "anthropic": "other ways to research this?",
             "perplexity": "neighborhoods and opening hours**.", "openai": "after a particular loaf."}
    FINDS = {"anthropic": ("Riedmair", 11), "perplexity": ("Rischart", 15), "openai": ("Zöttl", 7),
             "google-ai-mode": ("Backstube Haidhausen", 6),
             "google-overview": ("Dutch oven or heavy cast-iron pot", 8)}

    def test_knows_mode_answers_whole_and_without_search(self):
        for engine, tail in self.KNOWS.items():
            with self.subTest(engine=engine):
                text, model, sources, searched = self.parse(engine, f"{engine}-knows.json")
                self.assertIn(tail, text)
                self.assertTrue(model)
                self.assertEqual(sources, [])
                self.assertFalse(searched)          # "knows you" really had no web search

    def test_finds_mode_answers_whole_with_search_and_sources(self):
        for engine, (late_phrase, n_sources) in self.FINDS.items():
            with self.subTest(engine=engine):
                text, model, sources, searched = self.parse(engine, f"{engine}-finds.json")
                self.assertIn(late_phrase, text)
                self.assertTrue(searched)
                self.assertEqual(len(sources), n_sources)
                self.assertTrue(all(s.startswith("http") and geo_check.norm_host(s) for s in sources))

    def test_real_answer_mentions_are_detected(self):
        # Names actually in the real answers — not taken from the parser's own output.
        text, *_ = self.parse("anthropic", "anthropic-finds.json")
        self.assertTrue(geo_check.is_named(text, ["Hofpfisterei"]))
        self.assertTrue(geo_check.is_named(text, ["Neulinger"]))
        self.assertFalse(geo_check.is_named(text, ["Bäckerei Example"]))

    def test_openrouter_answers_whole_with_the_right_search_state(self):
        # Real OpenRouter replies (captured 2026-09-26, same bakery question): "from memory" has no
        # sources and no search; "with web search on" has the provider's own citations.
        cases = {"openrouter-gemini-knows.json": (False, 0), "openrouter-openai-knows.json": (False, 0),
                 "openrouter-anthropic-knows.json": (False, 0), "openrouter-openai-finds.json": (True, 5),
                 "openrouter-anthropic-finds.json": (True, 13), "openrouter-perplexity-finds.json": (True, 18)}
        for name, (searched, n_sources) in cases.items():
            with self.subTest(fixture=name):
                text, model, sources, did_search, cost = geo_check._openrouter_parse(load(name))
                self.assertGreater(len(text.strip()), 300)
                self.assertTrue(model.split("/")[0] in ("google", "openai", "anthropic", "perplexity"))
                self.assertEqual((did_search, len(sources)), (searched, n_sources))
                self.assertTrue(all(s.startswith("http") for s in sources))
                self.assertIsInstance(cost, float)

    def test_absent_overview_is_its_own_state(self):
        # {} is what remains of a response without an ai_overview block once trimmed (synthetic).
        text, *_ = self.parse("google-overview", "google-overview-finds-absent.json")
        self.assertEqual(text, geo_check.NO_OVERVIEW)


if __name__ == "__main__":
    unittest.main()
