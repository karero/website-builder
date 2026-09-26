"""geo_check.py — the weekly "does AI name you?" check.

Why these tests matter: the owner reads the trend as "is AI naming my business more
often?". A detector that misses 'Baeckerei' for 'Bäckerei', a failed rerun that wipes
a good week, a ‡ that never fires when the question changed, or a key that leaks into
the launchd log would each make that answer quietly wrong. Scenario ids (S1…S9) refer
to docs/reviews/SKILL-PLAN-geo-check.md.

Most tests enter through geo_check.main() — the same call the CLI and track.sh make —
against a local stub server (_geo_stub.py), with HOME pointed at a temp dir.

Run:  python3 -m unittest discover -s skills/search-console-insights/scripts/tests
"""
import contextlib
import csv
import io
import os
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))
sys.path.insert(0, os.path.dirname(__file__))

import geo_check  # noqa: E402
import _geo_stub as stub  # noqa: E402

DOMAIN = "example-bakery.de"
# Placeholders that no real-key pattern matches (check_clean.sh scans the repo).
GKEY, OKEY = "test-gemini-placeholder", "test-openai-placeholder"
BROAD = "Where can I buy sourdough bread in Munich-Schwabing?"


class GeoTestCase(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.srv, cls.base = stub.start()

    @classmethod
    def tearDownClass(cls):
        cls.srv.shutdown()
        cls.srv.server_close()

    def setUp(self):
        stub.reset()
        self.tmp = tempfile.TemporaryDirectory()
        self.home = Path(self.tmp.name)
        env = {k: v for k, v in os.environ.items()
               if not k.startswith("GEO_") and k not in ("OPENAI_API_KEY",)}
        env.update(stub.env_for(self.base))
        env["HOME"] = str(self.home)
        self.env = mock.patch.dict(os.environ, env, clear=True)
        self.env.start()

    def tearDown(self):
        self.env.stop()
        self.tmp.cleanup()

    def cli(self, *args, stdin=None):
        out = io.StringIO()
        with contextlib.redirect_stdout(out), contextlib.redirect_stderr(out):
            if stdin is not None:
                with mock.patch("sys.stdin", io.StringIO(stdin)):
                    rc = geo_check.main([DOMAIN, *args])
            else:
                rc = geo_check.main([DOMAIN, *args])
        return rc, out.getvalue()

    def setup_site(self, questions=(("broad", BROAD),), confirm=True):
        rc, out = self.cli("--init", "--name", "Bäckerei Example", "--domain", "www.example-bakery.de",
                           "--lang", "de", "--country", "DE")
        self.assertEqual(rc, 0, out)
        for slot, text in questions:
            rc, out = self.cli("--set-question", "--slot", slot, "--text-file", "-", stdin=text)
            self.assertEqual(rc, 0, out)
        if confirm:
            rc, out = self.cli("--confirm")
            self.assertEqual(rc, 0, out)

    def history(self):
        p = self.home / ".config/gsc-insights/geo/geo_history.csv"
        with open(p, newline="") as f:
            return list(csv.DictReader(f))


class Detection(unittest.TestCase):
    """S3 — the name counts however the engine spells it, and only as a whole name."""

    def test_spellings_that_must_count(self):
        cases = [
            ("Bäckerei Example", "Try Baeckerei Example on Hohenzollernstraße."),
            ("Bäckerei Example", "BÄCKEREI EXAMPLE is the best known."),
            ("Bäckerei Example", "Bäckerei-Example bakes daily."),
            ("Café Müller", "Cafe Mueller is nearby."),
            ("Café Müller", "Cafe Muller is nearby."),
            ("Café Müller", "CAFE MUELLER is nearby."),
            ("Bäckerei Café", "Baeckerei Cafe opens at 7."),
            ("Luigi's Pizza", "Luigi’s Pizza has a stone oven."),
            ("C&A", "Shops like C&A sell basics."),
            ("Bäckerei Example", "Bäckerei Example (decomposed)".replace("ä", "ä")),
        ]
        for name, answer in cases:
            with self.subTest(name=name, answer=answer):
                self.assertTrue(geo_check.is_named(answer, [name]))

    def test_near_misses_that_must_not_count(self):
        cases = [
            ("Example", "There are many examples of good bakeries."),
            ("Bäckerei Example", "Bäckerei Examples list is long."),  # genitive-s: documented limitation
            ("Muster", "Mustermann Bakery"),
        ]
        for name, answer in cases:
            with self.subTest(name=name, answer=answer):
                self.assertFalse(geo_check.is_named(answer, [name]))


class HostMatching(unittest.TestCase):
    """S2 — 'cited your site' means the host really is yours."""

    def test_own_hosts(self):
        for h in ["example-bakery.de", "www.example-bakery.de", "https://www.example-bakery.de/brot",
                  "shop.example-bakery.de", "EXAMPLE-BAKERY.DE.", "example-bakery.de:443"]:
            with self.subTest(h=h):
                self.assertTrue(geo_check.host_matches(h, ["www.example-bakery.de"]))

    def test_lookalikes(self):
        for h in ["example-bakery.de.evil.test", "notexample-bakery.de",
                  "other.test/?url=example-bakery.de"]:
            with self.subTest(h=h):
                self.assertFalse(geo_check.host_matches(h, ["example-bakery.de"]))

    def test_idna(self):
        self.assertTrue(geo_check.host_matches("xn--bckerei-example-0kb.de", ["bäckerei-example.de"]))


class WeeklyRun(GeoTestCase):
    def test_s1_gemini_only(self):
        self.setup_site()
        os.environ["GEO_GEMINI_API_KEY"] = GKEY
        stub.engine_reply("gemini", "Bäckerei Example is great.", sources=["https://www.example-bakery.de/"])
        rc, out = self.cli()
        self.assertEqual(rc, 0, out)
        self.assertIn("skipped — no GEO_OPENAI_API_KEY", out)
        self.assertIn("engines: 1 checked, 0 failed, 3 not set up", out)
        rows = self.history()
        # Gemini answers only without search: its terms forbid analysing grounded answers.
        self.assertEqual({(r["engine"], r["mode"]) for r in rows}, {("gemini", "knows")})
        posts = [h for h in stub.STATE["hits"] if h[0] == "POST"]
        self.assertEqual(len(posts), 3)  # 3 samples of the broad question
        self.assertTrue(all("tools" not in h[3] for h in posts))
        # The key travels as a header, never in the URL, and the bare question is all that's sent.
        self.assertTrue(all(h[2].get("x-goog-api-key") == GKEY and GKEY not in h[1] for h in posts))
        self.assertEqual(posts[0][3]["contents"][0]["parts"][0]["text"], BROAD)
        self.assertNotIn("systemInstruction", posts[0][3])

    def test_s2_counts(self):
        self.setup_site()
        os.environ["GEO_OPENAI_API_KEY"] = OKEY
        stub.engine_reply("openai", "Go to Bäckerei Example.", sources=["https://www.example-bakery.de/"])
        self.cli()
        finds = next(r for r in self.history() if r["mode"] == "finds")
        self.assertEqual((finds["ok"], finds["named"], finds["cited_own"], finds["searched"]),
                         ("3", "3", "3", "3"))
        tool = next(h[3] for h in stub.STATE["hits"] if h[0] == "POST" and h[3].get("tools"))
        self.assertEqual(tool["tools"][0]["user_location"], {"type": "approximate", "country": "DE"})
        self.assertEqual((tool["tool_choice"], tool["store"]), ("required", False))
        self.assertIn("example-bakery.de", finds["cited_domains"])
        knows = next(r for r in self.history() if r["mode"] == "knows")
        self.assertEqual(knows["cited_own"], "")  # no web tools, nothing to cite

    def test_branded_is_never_scored(self):
        self.setup_site(questions=(("broad", BROAD), ("branded", "What is Bäckerei Example?")))
        os.environ["GEO_GEMINI_API_KEY"] = GKEY
        stub.engine_reply("gemini", "I have no information about Bäckerei Example.")
        self.cli()
        branded = [r for r in self.history() if r["slot"] == "branded"]
        self.assertTrue(branded and all(r["named"] == "" for r in branded))

    def test_s7_not_set_up(self):
        rc, out = self.cli()
        self.assertEqual(rc, 3)
        self.assertIn("not set up", out)

    def test_s7b_config_without_keys_is_a_problem(self):
        self.setup_site()
        rc, out = self.cli()
        self.assertEqual(rc, 1)
        self.assertIn("has no engine key", out)

    def test_generic_openai_key_is_never_used(self):
        self.setup_site()
        os.environ["OPENAI_API_KEY"] = "someone-elses-key"
        rc, out = self.cli()
        self.assertEqual(rc, 1)
        self.assertFalse([h for h in stub.STATE["hits"] if h[0] == "POST"])

    def test_keys_are_read_from_the_env_file(self):
        self.setup_site()
        env = self.home / ".config/gsc-insights/.env"
        env.write_text(f'GEO_GEMINI_API_KEY="{GKEY}"\nOPENAI_API_KEY=ignored\n')
        stub.engine_reply("gemini", "Bäckerei Example.")
        rc, out = self.cli()
        self.assertEqual(rc, 0, out)
        self.assertIn("engines: 1 checked", out)

    def test_s8_failed_engine_is_a_problem_and_redacted(self):
        self.setup_site()
        os.environ["GEO_GEMINI_API_KEY"] = GKEY
        os.environ["GEO_OPENAI_API_KEY"] = OKEY
        stub.engine_reply("gemini", "", status=403, body=f'{{"error": "API key {GKEY} not valid"}}')
        stub.engine_reply("openai", "Bäckerei Example.", sources=["https://example-bakery.de"])
        rc, out = self.cli()
        self.assertEqual(rc, 1)
        self.assertIn("gemini FAILED", out)
        self.assertNotIn(GKEY, out)
        self.assertIn("engines: 1 checked, 1 failed, 2 not set up", out)
        g = [r for r in self.history() if r["engine"] == "gemini"]
        self.assertTrue(g and all(r["ok"] == "0" and r["named"] == "0" for r in g))
        self.assertTrue(all(r["ok"] == "3" for r in self.history() if r["engine"] == "openai"))

    def test_failed_rerun_does_not_erase_a_good_row(self):
        self.setup_site()
        os.environ["GEO_GEMINI_API_KEY"] = GKEY
        stub.engine_reply("gemini", "Bäckerei Example.")
        self.cli()
        stub.engine_reply("gemini", "", status=429)
        self.cli()
        self.assertTrue(all(r["ok"] == "3" for r in self.history()))
        self.assertEqual(len(self.history()), 1)

    def test_same_day_rerun_replaces(self):
        self.setup_site()
        os.environ["GEO_GEMINI_API_KEY"] = GKEY
        stub.engine_reply("gemini", "nothing relevant")
        self.cli()
        stub.engine_reply("gemini", "Bäckerei Example.")
        self.cli()
        rows = self.history()
        self.assertEqual(len(rows), 1)
        self.assertTrue(all(r["named"] == "3" for r in rows))

    def test_answers_saved_verbatim(self):
        self.setup_site()
        os.environ["GEO_GEMINI_API_KEY"] = GKEY
        stub.engine_reply("gemini", "Line one.\nBäckerei Example, line two.")
        self.cli()
        files = list((self.home / ".config/gsc-insights/geo/answers/example-bakery.de").rglob("*.txt"))
        self.assertEqual(len(files), 3)
        self.assertIn("Line one.\nBäckerei Example, line two.", files[0].read_text())

    def test_perplexity_knows_mode_sends_no_search_tool(self):
        self.setup_site()
        os.environ["GEO_PERPLEXITY_API_KEY"] = "test-pplx-placeholder"
        stub.engine_reply("perplexity", "Bäckerei Example.", sources=["https://example-bakery.de"])
        rc, out = self.cli()
        self.assertEqual(rc, 0, out)
        self.assertEqual({r["mode"] for r in self.history()}, {"knows", "finds"})
        bodies = [h[3] for h in stub.STATE["hits"] if h[0] == "POST"]
        self.assertTrue(all("preset" not in b for b in bodies))  # a preset keeps search on
        self.assertEqual(sum(1 for b in bodies if "tools" not in b), 3)

    def test_finds_answer_without_a_search_is_visible(self):
        self.setup_site()
        os.environ["GEO_ANTHROPIC_API_KEY"] = "test-anthropic-placeholder"
        stub.engine_reply("anthropic", "Bäckerei Example.", searched=False)
        self.cli()
        finds = next(r for r in self.history() if r["mode"] == "finds")
        self.assertEqual(finds["searched"], "0")
        rc, out = self.cli("--trend")
        self.assertIn("searched only 0/3", out)


class Homepage(GeoTestCase):
    def test_s4_changed_warns_but_never_fails(self):
        self.setup_site()
        os.environ["GEO_GEMINI_API_KEY"] = GKEY
        stub.engine_reply("gemini", "Bäckerei Example.")
        stub.STATE["homepage"] = stub.STATE["homepage"].replace("Sourdough", "Cakes and coffee")
        rc, out = self.cli()
        self.assertEqual(rc, 0, out)
        self.assertIn("homepage changed", out)
        self.assertIn("Cakes and coffee", out)

    def test_s4b_unreadable_warns_and_confirm_refuses(self):
        self.setup_site()
        os.environ["GEO_GEMINI_API_KEY"] = GKEY
        stub.engine_reply("gemini", "Bäckerei Example.")
        stub.STATE["homepage"] = "<html><title>Just a moment...</title><h1>Checking your browser</h1></html>"
        rc, out = self.cli()
        self.assertEqual(rc, 0, out)
        self.assertIn("Couldn't read your homepage", out)
        before = geo_check.load_config(DOMAIN)["fingerprint"]
        rc, out = self.cli("--confirm")
        self.assertEqual(rc, 1)
        self.assertEqual(geo_check.load_config(DOMAIN)["fingerprint"], before)
        stub.STATE["homepage_status"] = 503
        rc, out = self.cli()
        self.assertIn("HTTP 503", out)

    def test_s5_check_drift_then_keep_or_change(self):
        self.setup_site()
        stub.STATE["homepage"] = stub.STATE["homepage"].replace("Sourdough", "Cakes")
        rc, out = self.cli("--check-drift")
        self.assertIn("State: changed", out)
        self.assertIn(BROAD, out)
        # "keep my question": re-fingerprint only, the rev stays
        self.cli("--confirm")
        cfg = geo_check.load_config(DOMAIN)
        self.assertEqual(cfg["queries"][0]["rev"], 1)
        rc, out = self.cli("--check-drift")
        self.assertIn("State: same", out)
        # "use the new one": rev bumps
        self.cli("--set-question", "--slot", "broad", "--text-file", "-", stdin="Where can I buy cake in Schwabing?")
        self.assertEqual(geo_check.load_config(DOMAIN)["queries"][0]["rev"], 2)


class Trend(GeoTestCase):
    def run_week(self, text, model="m-1"):
        stub.engine_reply("gemini", text, model=model)
        rc, out = self.cli()
        self.assertIn(rc, (0, 1), out)

    def age_history(self):
        """Pretend the rows so far were written a week ago (dates and run ids)."""
        p = self.home / ".config/gsc-insights/geo/geo_history.csv"
        rows = self.history()
        for r in rows:
            r["date"], r["run_id"] = "2026-01-01", "20260101T000000Z-" + r["run_id"][17:]
        with open(p, "w", newline="") as f:
            w = csv.DictWriter(f, fieldnames=geo_check.FIELDS)
            w.writeheader()
            w.writerows(rows)

    def trend(self):
        rc, out = self.cli("--trend")
        self.assertEqual(rc, 0)
        return out

    def test_improvement_shows_up(self):
        self.setup_site()
        os.environ["GEO_GEMINI_API_KEY"] = GKEY
        self.run_week("nothing relevant")
        self.age_history()
        self.run_week("Bäckerei Example.")
        out = self.trend()
        self.assertRegex(out, r"gemini\s+knows you\s+broad\s+named 0/3 .*→ 3/3.* ▲")
        self.assertNotIn("‡", out)

    def test_s6_model_change_is_marked(self):
        self.setup_site()
        os.environ["GEO_GEMINI_API_KEY"] = GKEY
        self.run_week("Bäckerei Example.", model="m-1")
        self.age_history()
        self.run_week("Bäckerei Example.", model="m-2")
        self.assertIn("‡ model changed", self.trend())

    def test_s5_question_change_is_marked_per_slot(self):
        self.setup_site(questions=(("broad", BROAD), ("narrow", "Sourdough bakery Schwabing open Sunday?")))
        os.environ["GEO_GEMINI_API_KEY"] = GKEY
        self.run_week("Bäckerei Example.")
        self.age_history()
        self.cli("--set-question", "--slot", "broad", "--text-file", "-", stdin="Best bakery in Schwabing?")
        self.run_week("Bäckerei Example.")
        lines = self.trend().splitlines()
        broad = [l for l in lines if " broad " in l]
        narrow = [l for l in lines if " narrow " in l]
        self.assertTrue(broad and all("question changed" in l for l in broad))
        self.assertTrue(narrow and not any("‡" in l for l in narrow))

    def test_settings_change_is_marked(self):
        self.setup_site()
        os.environ["GEO_GEMINI_API_KEY"] = GKEY
        self.run_week("Bäckerei Example.")
        self.age_history()
        self.cli("--set-names", "--alias", "Example Bakery", "--name", "Bäckerei Example")
        self.run_week("Bäckerei Example.")
        self.assertIn("settings changed", self.trend())

    def test_failed_latest_is_shown_not_hidden(self):
        self.setup_site()
        os.environ["GEO_GEMINI_API_KEY"] = GKEY
        self.run_week("Bäckerei Example.")
        self.age_history()
        stub.engine_reply("gemini", "", status=500)
        self.cli()
        out = self.trend()
        self.assertIn("latest attempt", out)
        self.assertIn("named 3/3", out)


class Safety(GeoTestCase):
    def test_override_needs_test_mode_and_loopback(self):
        os.environ["GEO_TEST_MODE"] = "0"
        self.assertEqual(geo_check.override("GEO_OPENAI_BASE_URL", "https://api.openai.com"),
                         "https://api.openai.com")
        os.environ["GEO_TEST_MODE"] = "1"
        os.environ["GEO_OPENAI_BASE_URL"] = "https://evil.test"
        self.assertEqual(geo_check.override("GEO_OPENAI_BASE_URL", "https://api.openai.com"),
                         "https://api.openai.com")

    def test_redaction_covers_every_key_and_encoding(self):
        keys = ["abc def", "plainkey123"]
        msg = geo_check.redact("url?k=abc+def&x=plainkey123 and abc def", keys)
        self.assertNotIn("plainkey123", msg)
        self.assertNotIn("abc def", msg)
        self.assertNotIn("abc+def", msg)

    def test_country_must_be_alpha2(self):
        with self.assertRaises(SystemExit):
            self.cli("--init", "--name", "X", "--lang", "de", "--country", "deu")


if __name__ == "__main__":
    unittest.main()
