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
import html
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
        # An allowlist, so no key or setting exported in the developer's shell (SERPAPI_KEY,
        # GEO_*_MODEL, OPENAI_API_KEY…) can reach the code under test.
        env = {k: os.environ[k] for k in ("PATH", "LANG", "TMPDIR") if k in os.environ}
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
        self.assertIn("engines: 1 checked, 0 failed, 5 not set up", out)
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
        self.assertIn("engines: 1 checked, 1 failed, 4 not set up", out)
        g = [r for r in self.history() if r["engine"] == "gemini"]
        self.assertTrue(g and all(r["ok"] == "0" and r["named"] == "0" for r in g))
        self.assertTrue(all(r["ok"] == "3" for r in self.history() if r["engine"] == "openai"))

    def test_no_credit_stops_asking_that_engine(self):
        # The live smoke test: OpenAI answered every call with this 429, the run retried each
        # one with pauses and took 9 minutes. Waiting doesn't add credit.
        self.setup_site()
        os.environ["GEO_OPENAI_API_KEY"] = OKEY
        os.environ["GEO_ANTHROPIC_API_KEY"] = "test-anthropic-placeholder"
        stub.engine_reply("openai", "", status=429, body=(
            '{"error": {"message": "You have no credits remaining. Add credits to continue.",'
            ' "type": "insufficient_quota", "code": "credit_balance_exhausted"}}'))
        stub.engine_reply("anthropic", "Bäckerei Example.")
        rc, out = self.cli()
        self.assertEqual(rc, 1)
        openai_calls = [h for h in stub.STATE["hits"] if h[1] == "/v1/responses"]
        self.assertEqual(len(openai_calls), 1)
        self.assertIn("openai FAILED: HTTP 429: You have no credits remaining. Add credits to continue."
                      " (not retried)", out)
        self.assertTrue(any(h[1] == "/v1/messages" for h in stub.STATE["hits"]))  # others still asked

    def test_plain_rate_limit_is_retried(self):
        self.setup_site()
        os.environ["GEO_GEMINI_API_KEY"] = GKEY
        stub.engine_reply("gemini", "", status=429, body='{"error": {"message": "Resource exhausted, slow down"}}')
        self.cli()
        self.assertEqual(len([h for h in stub.STATE["hits"] if h[0] == "POST"]), 9)  # 3 samples x 3 tries

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


class GoogleViaSerpApi(GeoTestCase):
    """Google's own AI answers (AI Mode, AI Overview) through the owner's SerpApi key."""

    def setUp(self):
        super().setUp()
        self.setup_site()
        os.environ["SERPAPI_KEY"] = "test-serpapi-placeholder"
        rc, out = self.cli("--google", "on")
        self.assertEqual(rc, 0, out)

    def rows(self, engine):
        return [r for r in self.history() if r["engine"] == engine]

    def test_ai_mode_named_and_cited(self):
        stub.STATE["serp"]["google_ai_mode"] = (200, {
            "reconstructed_markdown": "Try **Bäckerei Example** in Schwabing.",
            "references": [{"link": "https://www.example-bakery.de/brot", "title": "t"}]})
        rc, out = self.cli()
        self.assertEqual(rc, 1, out)  # google-overview has no stub → it fails, AI Mode still counts
        r = next(r for r in self.rows("google-ai-mode") if r["slot"] == "broad")
        self.assertEqual((r["mode"], r["ok"], r["named"], r["cited_own"]), ("finds", "1", "1", "1"))
        call = next(h[3] for h in stub.STATE["hits"] if h[1] == "/search")
        self.assertEqual((call["engine"], call["gl"], call["hl"], call["no_cache"]),
                         ("google_ai_mode", "de", "de", "true"))
        self.assertEqual(call["q"], BROAD)

    def test_overview_inline_and_via_follow_up(self):
        stub.STATE["serp"]["google_ai_mode"] = (200, {"text_blocks": [{"type": "paragraph", "snippet": "x"}]})
        stub.STATE["serp"]["google"] = (200, {"ai_overview": {"page_token": "tok123"}})
        stub.STATE["serp"]["google_ai_overview"] = (200, {"text_blocks": [
            {"type": "list", "list": [{"title": "Bäckerei Example", "snippet": "sourdough"}]}],
            "references": [{"link": "https://example-bakery.de"}]})
        rc, out = self.cli()
        self.assertEqual(rc, 0, out)
        r = next(r for r in self.rows("google-overview") if r["slot"] == "broad")
        self.assertEqual((r["named"], r["cited_own"]), ("1", "1"))
        follow = [h[3] for h in stub.STATE["hits"] if h[1] == "/search" and h[3]["engine"] == "google_ai_overview"]
        self.assertTrue(follow and follow[0]["page_token"] == "tok123")

    def test_no_overview_is_its_own_state(self):
        stub.STATE["serp"]["google_ai_mode"] = (200, {"text_blocks": []})
        stub.STATE["serp"]["google"] = (200, {"organic_results": []})
        self.cli()
        r = next(r for r in self.rows("google-overview") if r["slot"] == "broad")
        self.assertEqual((r["ok"], r["named"], r["status"]), ("1", "0", "no AI Overview shown"))
        rc, out = self.cli("--trend")
        self.assertIn("Google showed no AI Overview", out)

    def test_engines_option_asks_only_those(self):
        os.environ["GEO_GEMINI_API_KEY"] = GKEY
        stub.engine_reply("gemini", "Bäckerei Example.")
        stub.STATE["serp"]["google_ai_mode"] = (200, {"reconstructed_markdown": "Bäckerei Example"})
        rc, out = self.cli("--engines", "google-ai-mode")
        self.assertEqual(rc, 0, out)
        self.assertEqual({r["engine"] for r in self.history()}, {"google-ai-mode"})
        self.assertFalse([h for h in stub.STATE["hits"] if h[0] == "POST"])
        with self.assertRaises(SystemExit):
            self.cli("--engines", "bing-chat")

    def test_invalid_key_stops_and_never_prints_the_key(self):
        stub.STATE["serp"]["google_ai_mode"] = (401, {"error": "Invalid API key. Your API key should be here: https://serpapi.com/manage-api-key"})
        stub.STATE["serp"]["google"] = (200, {"error": "Invalid API key for test-serpapi-placeholder"})
        rc, out = self.cli()
        self.assertEqual(rc, 1)
        self.assertIn("google-ai-mode FAILED", out)
        self.assertIn("google-overview FAILED: SerpApi: Invalid API key", out)
        self.assertNotIn("test-serpapi-placeholder", out)
        ai_mode_calls = [h for h in stub.STATE["hits"] if h[1] == "/search" and h[3]["engine"] == "google_ai_mode"]
        self.assertEqual(len(ai_mode_calls), 1)


class ReviewFindings(GeoTestCase):
    """Regression tests for the DIFF-gate round-1 findings (docs/reviews trail)."""

    def test_serpapi_key_alone_does_not_switch_google_on(self):
        # An owner with SERPAPI_KEY for the Top-10 check must not start paying for Google AI
        # checks without saying yes: off until --google on, and no key counts until then.
        self.setup_site()
        os.environ["SERPAPI_KEY"] = "test-serpapi-placeholder"
        rc, out = self.cli()
        self.assertEqual(rc, 1)
        self.assertIn("has no engine key", out)
        self.assertIn("off for this site", out)
        self.assertFalse([h for h in stub.STATE["hits"] if h[1] == "/search"])

    def test_gemini_per_minute_limit_is_retried_not_treated_as_no_credit(self):
        self.setup_site()
        os.environ["GEO_GEMINI_API_KEY"] = GKEY
        # Gemini's real per-minute 429 also mentions "plan and billing details".
        stub.engine_reply("gemini", "", status=429, body=(
            '{"error": {"code": 429, "status": "RESOURCE_EXHAUSTED", "message": "You exceeded your current '
            'quota, please check your plan and billing details.", "details": [{"@type": '
            '"type.googleapis.com/google.rpc.QuotaFailure", "violations": [{"quotaId": '
            '"GenerateRequestsPerMinutePerProjectPerModel-FreeTier"}]}]}}'))
        self.cli()
        self.assertEqual(len([h for h in stub.STATE["hits"] if h[0] == "POST"]), 9)  # 3 samples x 3 tries

    def test_gemini_daily_quota_stops_that_engine(self):
        self.setup_site()
        os.environ["GEO_GEMINI_API_KEY"] = GKEY
        stub.engine_reply("gemini", "", status=429, body=(
            '{"error": {"code": 429, "status": "RESOURCE_EXHAUSTED", "message": "Quota exceeded", '
            '"details": [{"violations": [{"quotaId": "GenerateRequestsPerDayPerProjectPerModel-FreeTier"}]}]}}'))
        rc, out = self.cli()
        self.assertEqual(len([h for h in stub.STATE["hits"] if h[0] == "POST"]), 1)
        self.assertIn("(not retried)", out)

    def test_key_is_redacted_even_where_the_message_is_cut(self):
        self.setup_site()
        os.environ["GEO_GEMINI_API_KEY"] = GKEY
        stub.engine_reply("gemini", "", status=400,
                          body='{"error": {"message": "' + "x" * 230 + GKEY + '"}}')
        rc, out = self.cli()
        self.assertNotIn(GKEY[:8], out)

    def test_empty_or_cut_off_answers_are_failures_not_misses(self):
        self.setup_site()
        os.environ["GEO_GEMINI_API_KEY"] = GKEY
        stub.engine_reply("gemini", "   ")
        rc, out = self.cli()
        self.assertEqual(rc, 1)
        self.assertIn("empty answer", out)
        self.assertTrue(all(r["ok"] == "0" for r in self.history()))

    def test_anthropic_answer_cut_at_max_tokens_is_a_failure(self):
        self.assertRaises(geo_check.EngineError, geo_check.parse_response, "anthropic",
                          {"stop_reason": "max_tokens", "content": [{"type": "text", "text": "Bäckerei"}]})
        self.assertRaises(geo_check.EngineError, geo_check.parse_response, "openai",
                          {"status": "incomplete", "incomplete_details": {"reason": "max_output_tokens"}})
        self.assertRaises(geo_check.EngineError, geo_check.parse_response, "gemini",
                          {"candidates": [{"finishReason": "SAFETY", "content": {"parts": []}}]})

    def test_model_override_from_env_file_with_inline_comment(self):
        env = self.home / ".config/gsc-insights/.env"
        env.parent.mkdir(parents=True, exist_ok=True)
        env.write_text("GEO_OPENAI_MODEL=replacement-model   # set 2026-10\n"
                       "GEO_OPENAI_API_KEY=\"quoted-key # not a comment\"\n")
        self.assertEqual(geo_check.model_for("openai"), "replacement-model")
        self.assertEqual(geo_check.load_keys()["openai"], "quoted-key # not a comment")

    def test_detector_version_bump_marks_the_trend(self):
        self.setup_site()
        os.environ["GEO_GEMINI_API_KEY"] = GKEY
        stub.engine_reply("gemini", "Bäckerei Example.")
        self.cli()
        with mock.patch.object(geo_check, "DETECTOR_VERSION", "99"):
            before = self.history()[0]["config_rev"]
            self.assertNotEqual(geo_check.config_rev(geo_check.load_config(DOMAIN)), before)

    def test_set_names_alias_adds_and_name_replaces(self):
        self.setup_site()
        self.cli("--set-names", "--alias", "Example Bakery")
        self.assertEqual(geo_check.load_config(DOMAIN)["names"], ["Bäckerei Example", "Example Bakery"])
        self.cli("--set-names", "--name", "Neue Bäckerei")
        self.assertEqual(geo_check.load_config(DOMAIN)["names"], ["Neue Bäckerei"])

    def test_bot_wall_that_mentions_the_domain_is_unreadable(self):
        self.setup_site()
        before = geo_check.load_config(DOMAIN)["fingerprint"]
        stub.STATE["homepage"] = ("<html><head><title>Just a moment...</title>"
                                  "<link rel=canonical href='https://example-bakery.de/'></head>"
                                  "<body><h1>Checking your browser</h1>example-bakery.de</body></html>")
        rc, out = self.cli("--confirm")
        self.assertEqual(rc, 1)
        self.assertEqual(geo_check.load_config(DOMAIN)["fingerprint"], before)

    def test_domain_only_in_markup_is_not_enough(self):
        self.setup_site()
        stub.STATE["homepage"] = ("<html><head><title>Cookie settings</title>"
                                  "<link rel=canonical href='https://example-bakery.de/'></head>"
                                  "<body><h1>We value your privacy</h1></body></html>")
        rc, out = self.cli("--check-drift")
        self.assertIn("Couldn't read the homepage", out)

    def test_new_question_without_confirm_is_flagged(self):
        self.setup_site()
        self.cli("--set-question", "--slot", "narrow", "--text-file", "-", stdin="Sourdough on Sunday?")
        rc, out = self.cli("--check-drift")
        self.assertIn("State: unconfirmed", out)

    def test_set_question_reads_a_file_path(self):
        self.setup_site()
        qf = self.home / "q.txt"
        qf.write_text("Where is the best sourdough in Schwabing?\n")
        rc, out = self.cli("--set-question", "--slot", "narrow", "--text-file", str(qf))
        self.assertEqual(rc, 0, out)
        self.assertEqual(geo_check.load_config(DOMAIN)["queries"][1]["text"],
                         "Where is the best sourdough in Schwabing?")

    def test_report_labels_answers_to_an_earlier_question(self):
        self.setup_site()
        os.environ["GEO_GEMINI_API_KEY"] = GKEY
        stub.engine_reply("gemini", "Bäckerei Example.")
        self.cli()
        self.cli("--set-question", "--slot", "broad", "--text-file", "-", stdin="Best cake in Schwabing?")
        rc, out = self.cli("--report")
        page = Path(out.split("Report: ")[1].strip()).read_text()
        self.assertIn("an earlier version of the question", page)
        self.assertIn(html.escape(BROAD), page)

    def test_follow_up_overview_error_is_a_failure(self):
        self.setup_site()
        os.environ["SERPAPI_KEY"] = "test-serpapi-placeholder"
        self.cli("--google", "on")
        stub.STATE["serp"]["google_ai_mode"] = (200, {"reconstructed_markdown": "x"})
        stub.STATE["serp"]["google"] = (200, {"ai_overview": {"page_token": "tok"}})
        stub.STATE["serp"]["google_ai_overview"] = (200, {"error": "Invalid API key."})
        rc, out = self.cli()
        self.assertIn("google-overview FAILED: SerpApi: Invalid API key", out)
        r = next(r for r in self.history() if r["engine"] == "google-overview" and r["slot"] == "broad")
        self.assertNotEqual(r["status"], "no AI Overview shown")


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


class KeySetup(GeoTestCase):
    """The owner walkthrough: prepare the key file, then check what's set — never show a key."""

    def env_file(self):
        return self.home / ".config/gsc-insights/.env"

    def cli_bare(self, *args):
        out = io.StringIO()
        with contextlib.redirect_stdout(out), contextlib.redirect_stderr(out):
            rc = geo_check.main(list(args))
        return rc, out.getvalue()

    def test_prepare_env_appends_once_and_keeps_existing_lines(self):
        self.env_file().parent.mkdir(parents=True)
        self.env_file().write_text("BING_API_KEY=keepme")  # no trailing newline
        rc, out = self.cli_bare("--prepare-env")
        self.assertEqual(rc, 0, out)
        text = self.env_file().read_text()
        self.assertTrue(text.startswith("BING_API_KEY=keepme\n"))
        self.assertIn("GEO_GEMINI_API_KEY=\n", text)
        self.cli_bare("--prepare-env")
        self.assertEqual(self.env_file().read_text(), text)  # a second run adds nothing
        self.assertEqual(self.env_file().stat().st_mode & 0o777, 0o600)

    def test_keys_never_prints_a_value(self):
        self.env_file().parent.mkdir(parents=True)
        self.env_file().write_text(f"GEO_GEMINI_API_KEY={GKEY}\nGEO_OPENAI_API_KEY=\n")
        rc, out = self.cli_bare("--keys")
        self.assertNotIn(GKEY, out)
        self.assertRegex(out, r"GEO_GEMINI_API_KEY\s+set")
        self.assertRegex(out, r"GEO_OPENAI_API_KEY\s+empty")


class Report(GeoTestCase):
    """The owner-facing page. Answers are untrusted text from outside: they must never run
    as code in the owner's browser, and highlighting the name must not break links."""

    def test_markdown_is_rendered_safely(self):
        html_out = geo_check._mark_names(geo_check._light_markdown(
            "### Top\nTry **Bäckerei Example** at [site](https://example-bakery.de/x)"
            " <script>alert(1)</script> [bad](javascript:alert(1))"), ["Bäckerei Example", "example"])
        self.assertIn("<strong>Top</strong>", html_out)
        self.assertIn("<strong><mark>Bäckerei Example</mark></strong>", html_out)
        self.assertIn('href="https://example-bakery.de/x"', html_out)  # no <mark> inside the href
        self.assertIn("&lt;script&gt;", html_out)
        self.assertNotIn("<script>", html_out)
        self.assertNotIn('href="javascript', html_out)

    def test_report_shows_latest_answers_of_every_engine(self):
        self.setup_site()
        os.environ["GEO_GEMINI_API_KEY"] = GKEY
        stub.engine_reply("gemini", "Nothing about bakeries.")
        self.cli()
        os.environ["SERPAPI_KEY"] = "test-serpapi-placeholder"
        self.cli("--google", "on")
        stub.STATE["serp"]["google_ai_mode"] = (200, {"reconstructed_markdown": "Go to **Bäckerei Example**.",
                                                       "references": [{"link": "https://example-bakery.de"}]})
        stub.STATE["serp"]["google"] = (200, {})
        self.cli("--engines", "google-ai-mode,google-overview")  # a later run with only Google
        rc, out = self.cli("--report")
        self.assertEqual(rc, 0, out)
        page = Path(out.split("Report: ")[1].strip()).read_text()
        self.assertIn("Gemini", page)                      # the earlier run is not hidden
        self.assertIn("Google AI Mode", page)
        self.assertIn("named in 1 of 1", page)
        self.assertIn("named in 0 of 3", page)
        self.assertIn("Google showed no AI Overview", page)
        self.assertIn(html.escape(BROAD), page)

    def test_weekly_run_writes_the_report(self):
        self.setup_site()
        os.environ["GEO_GEMINI_API_KEY"] = GKEY
        stub.engine_reply("gemini", "Bäckerei Example.")
        rc, out = self.cli()
        self.assertIn("report:", out)


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
