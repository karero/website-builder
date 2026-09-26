"""The response parsers against REAL provider answers, not against our own stub.

Why: every other GEO test talks to _geo_stub.py, which builds responses the way this code
expects them — so it can't catch a parser that misreads what a provider actually sends.
The fixtures in fixtures/ are real responses, captured live on 2026-09-26 with a neutral
question that names no client ("Which bakeries in Munich sell sourdough bread?"; the AI
Overview one with "how to make sourdough bread at home", because Google showed no overview
for the first). They were trimmed only to the fields the parsers read (Anthropic's encrypted_*
blobs, SerpApi's metadata) and checked for keys before saving. OpenAI has no fixture yet:
its account had no credit when these were captured.

To refresh after a provider changes its format: capture the same way, save over the file,
and re-run these tests.

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

    def test_knows_mode_answers_without_search(self):
        for engine in ("gemini", "anthropic", "perplexity"):
            with self.subTest(engine=engine):
                text, model, sources, searched = self.parse(engine, f"{engine}-knows.json")
                self.assertGreater(len(text.strip()), 100)
                self.assertTrue(model)
                self.assertEqual(sources, [])
                self.assertFalse(searched)          # "knows you" really had no web search

    def test_finds_mode_answers_with_search_and_sources(self):
        for engine in ("anthropic", "perplexity", "google-ai-mode", "google-overview"):
            with self.subTest(engine=engine):
                text, model, sources, searched = self.parse(engine, f"{engine}-finds.json")
                self.assertGreater(len(text.strip()), 100)
                self.assertTrue(searched)
                self.assertTrue(sources, "a search answer with no readable sources")
                self.assertTrue(all(s.startswith("http") for s in sources), sources[:3])
                self.assertTrue(all(geo_check.norm_host(s) for s in sources))

    def test_real_answer_mentions_are_detected(self):
        # The live answers name real Munich bakeries; the detector must find a name that is
        # actually in the text and must not invent one that isn't.
        text, *_ = self.parse("anthropic", "anthropic-finds.json")
        word = next(w.strip("*.,:") for w in text.split() if w[:1].isupper() and len(w) > 5)
        self.assertTrue(geo_check.is_named(text, [word]))
        self.assertFalse(geo_check.is_named(text, ["Bäckerei Example"]))

    def test_absent_overview_is_its_own_state(self):
        text, *_ = self.parse("google-overview", "google-overview-finds-absent.json")
        self.assertEqual(text, geo_check.NO_OVERVIEW)


if __name__ == "__main__":
    unittest.main()
