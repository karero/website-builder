"""facts_check.py: number parsing, tying numbers to facts, and a full run against a
stub site served on 127.0.0.1 (no real network calls).

Run:  python3 -m unittest discover -s skills/facts-check/scripts/tests
"""

import contextlib
import io
import json
import os
import sys
import tempfile
import threading
import unittest
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

import facts_check as fc  # noqa: E402


def first_num(text):
    for kind, m in fc.tokenize(text):
        if kind == "num":
            return fc.parse_number(m)
    return None


def fact(**kw):
    base = {"id": "f", "value": 27000, "terms": ["agent"], "before": []}
    base.update(kw)
    return base


class ParseNumber(unittest.TestCase):
    def test_formats(self):
        cases = {
            "27,000+ agents": 27000, "27.000 Agenten": 27000, "27 000 agents": 27000,
            "27 000 agents": 27000, "27k agents": 27000, "2,5 Mio. Nutzer": 2.5e6,
            "1.5 million users": 1.5e6, "100M revenue": 1e8, "1,234.5 units": 1234.5,
            "1.234,5 Einheiten": 1234.5, "3.14 ratio": 3.14, "72% NPS": 72,
        }
        for text, want in cases.items():
            with self.subTest(text=text):
                got, _ = first_num(text)
                self.assertTrue(fc.same(got, want), "%s -> %s" % (text, got))

    def test_unit_letters_are_not_multipliers(self):
        got, _ = first_num("5 km away")
        self.assertEqual(got, 5)
        got, _ = first_num("100 Mitarbeiter")
        self.assertEqual(got, 100)

    def test_only_a_plain_number_can_be_a_year(self):
        self.assertTrue(first_num("since 2016")[1])
        self.assertFalse(first_num("2,016 agents")[1])
        self.assertFalse(first_num("2016+ agents")[1])

    def test_no_match_inside_words_or_codes(self):
        self.assertIsNone(first_num("model X7 and ISO9001"))


class FindMentions(unittest.TestCase):
    def statuses(self, text, f):
        return [(h["status"], h["found_value"]) for h in fc.find_mentions(text, f)]

    def test_term_after_the_number(self):
        f = fact(also_accept=[25000.0], retired=[8500])
        self.assertEqual(self.statuses("27,000+ vetted freelance agents", f), [("OK", 27000)])
        self.assertEqual(self.statuses("over 25.000 Agenten", f), [("OK", 25000)])
        self.assertEqual(self.statuses("8,500 agents", f), [("OUTDATED", 8500)])
        self.assertEqual(self.statuses("30,000 agents", f), [("MISMATCH", 30000)])

    def test_other_numbers_near_the_term_are_not_tied(self):
        # 60 sits after "agents", not before a term: it is a country count.
        f = fact()
        self.assertEqual(self.statuses("27,000 agents in 60 countries", f), [("OK", 27000)])

    def test_window_and_sentence_end_limit_the_search(self):
        f = fact()
        self.assertEqual(self.statuses("27,000 of the very best trained agents", f), [])
        self.assertEqual(self.statuses("We grew 30,000. Our agents are great", f), [])
        self.assertEqual(self.statuses("27,000 of the very best trained agents", fact(window=6)),
                         [("OK", 27000)])

    def test_years_and_zero_are_ignored_unless_the_fact_is_one(self):
        f = fact(value=120, terms=["client"])
        self.assertEqual(self.statuses("Founded in 2016 clients first", f), [])
        self.assertEqual(self.statuses("0 clients", f), [])
        founded = fact(value=2016, terms=[], before=["founded in"])
        self.assertEqual(self.statuses("Founded in 2016 in Munich", founded), [("OK", 2016)])
        self.assertEqual(self.statuses("founded in 2015", founded), [("MISMATCH", 2015)])

    def test_before_phrase_and_percent_unit(self):
        nps = fact(value=72, terms=[], before=["NPS of"])
        self.assertEqual(self.statuses("an NPS of 72 last year", nps), [("OK", 72)])
        self.assertEqual(self.statuses("an NPS of 68 last year", nps), [("MISMATCH", 68)])
        self.assertEqual(self.statuses("NPS of 72%", nps), [])  # unit "" ignores percentages
        pct = fact(value=30, unit="%", terms=["faster"], before=[])
        self.assertEqual(self.statuses("30% faster replies and 40 faster", pct), [("OK", 30)])

    def test_multiword_term(self):
        f = fact(value=35, terms=["languages spoken"])
        self.assertEqual(self.statuses("35 languages spoken", f), [("OK", 35)])
        self.assertEqual(self.statuses("35 languages", f), [])

    def test_snippet_marks_the_number(self):
        hit = fc.find_mentions("We work with 30,000 agents worldwide.", fact())[0]
        self.assertIn("**30,000**", hit["snippet"])


class CheckPage(unittest.TestCase):
    def test_a_repeated_description_is_one_finding(self):
        html = ('<html><head><meta property="og:description" content="We have 30,000 agents.">'
                '<meta name="twitter:description" content="We have 30,000 agents."></head></html>')
        p = fc.PageText()
        p.feed(html)
        rows = fc.check_page("u", p.locations(), [fact()], [])
        self.assertEqual([r["status"] for r in rows], ["MISMATCH"])


class LoadFacts(unittest.TestCase):
    def write(self, obj):
        fd, path = tempfile.mkstemp(suffix=".json")
        with os.fdopen(fd, "w") as f:
            f.write(obj if isinstance(obj, str) else json.dumps(obj))
        self.addCleanup(os.remove, path)
        return path

    def test_problems_are_listed_together(self):
        path = self.write({"site": "example.com", "facts": [
            {"id": "a", "value": "27,000+", "terms": []},
            {"id": "a", "value": 5, "terms": ["x"], "retired": [5], "unit": "pct"},
        ]})
        with self.assertRaises(fc.FactsError) as cm:
            fc.load_facts(path)
        msg = str(cm.exception)
        for part in ('"site"', "numeric", 'needs "terms" or "before"', "appears twice",
                     "also listed as retired", '"unit"'):
            self.assertIn(part, msg)

    def test_starter_file_is_valid(self):
        path = self.write(fc.STARTER)
        self.assertEqual(fc.load_facts(path)["site"], "https://example.com")

    def test_bad_json(self):
        with self.assertRaises(fc.FactsError):
            fc.load_facts(self.write("{not json"))


# ---------------------------------------------------------------------------
# A stub site
# ---------------------------------------------------------------------------

PAGES = {
    "/robots.txt": ("text/plain", "User-agent: *\nDisallow: /private/\nSitemap: {base}/sitemap-index.xml\n"),
    "/sitemap-index.xml": ("application/xml",
        '<?xml version="1.0"?><sitemapindex xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">'
        "<sitemap><loc>{base}/sitemap-0.xml</loc></sitemap></sitemapindex>"),
    "/sitemap-0.xml": ("application/xml",
        '<?xml version="1.0"?><urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">'
        "<url><loc>{base}/</loc></url><url><loc>{base}/about</loc></url>"
        "<url><loc>{base}/private/x</loc></url><url><loc>{base}/gone</loc></url>"
        "<url><loc>{base}/brochure.pdf</loc></url></urlset>"),
    "/": ("text/html; charset=utf-8",
        "<html><head><title>Acme: 27,000+ agents</title>"
        '<meta name="description" content="Over 25,000 agents in 60 countries.">'
        '<script type="application/ld+json">{"@type":"Organization","description":"30,000 agents"}</script>'
        "<style>.x{width:2000px}</style><script>var agents = 99999;</script></head>"
        '<body><div class="stat"><span>27.000+</span><span>Agenten</span></div>'
        "<p>Trusted by 120 clients. Founded in 2016.</p>"
        "<p>We were the Old Name GmbH.</p></body></html>"),
    "/about": ("text/html",
        "<html><head><title>About</title></head><body>"
        "<h2>70+</h2><p>clients from startups to large firms</p>"
        "<p>An NPS of 72.</p></body></html>"),
    "/brochure.pdf": ("application/pdf", "%PDF-1.4"),
}


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        page = PAGES.get(self.path)
        if page is None:
            self.send_response(404)
            self.end_headers()
            return
        ctype, body = page
        data = body.replace("{base}", self.server.base).encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def log_message(self, *a):
        pass


FACTS = {
    "facts": [
        {"id": "agents", "label": "Agents in the network", "value": 27000,
         "terms": ["agent", "Agenten"], "retired": [25000], "source": "HR system"},
        {"id": "clients", "label": "Clients", "value": 120, "terms": ["client"],
         "retired": [70]},
        {"id": "nps", "label": "Customer NPS", "value": 72, "terms": [], "before": ["NPS of"]},
        {"id": "languages", "label": "Languages", "value": 35, "terms": ["language"]},
    ],
    "retired_phrases": [{"text": "Old Name GmbH", "note": "renamed in 2024"}],
}


class FullRun(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        os.environ["no_proxy"] = os.environ["NO_PROXY"] = "127.0.0.1,localhost"
        cls.server = ThreadingHTTPServer(("127.0.0.1", 0), Handler)
        cls.server.base = "http://127.0.0.1:%d" % cls.server.server_address[1]
        cls.thread = threading.Thread(target=cls.server.serve_forever, daemon=True)
        cls.thread.start()

    @classmethod
    def tearDownClass(cls):
        cls.server.shutdown()
        cls.server.server_close()

    def run_check(self, facts, *extra):
        tmp = tempfile.mkdtemp()
        self.addCleanup(lambda: [os.remove(os.path.join(tmp, f)) for f in os.listdir(tmp)] and os.rmdir(tmp))
        path = os.path.join(tmp, "facts.json")
        with open(path, "w") as f:
            json.dump(facts, f)
        out, js, hist = (os.path.join(tmp, n) for n in ("r.md", "r.json", "h.csv"))
        argv = [path, "--out", out, "--json", js, "--history", hist, "--delay", "0", "--timeout", "5"]
        with contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
            code = fc.main(argv + list(extra))
        with open(out) as f:
            md = f.read()
        with open(js) as f:
            result = json.load(f)
        with open(hist) as f:
            history = f.read()
        return code, md, result, history

    def facts(self, **kw):
        d = dict(FACTS, site=self.server.base)
        d.update(kw)
        return d

    def test_finds_every_kind_of_finding(self):
        code, md, result, history = self.run_check(self.facts())
        self.assertEqual(code, 1)
        rows = result["rows"]

        def find(status, value=None, where=None):
            return [r for r in rows if r["status"] == status
                    and (value is None or r.get("found_value") == value)
                    and (where is None or r["where"] == where)]

        # agents: title OK, page text OK (German grouping, number and label in two spans),
        # meta description outdated, structured data mismatch; the inline script is not read
        self.assertTrue(find("OK", 27000, "title"))
        self.assertTrue(find("OK", 27000, "page text"))
        self.assertTrue(find("OUTDATED", 25000, "meta description"))
        self.assertTrue(find("MISMATCH", 30000, "structured data"))
        self.assertFalse([r for r in rows if r.get("found_value") == 99999])
        # 60 countries is not an agent count; 2016 is not a client count
        self.assertFalse([r for r in rows if r.get("found_value") in (60, 2016)])
        # clients: 120 OK on the home page, 70+ outdated on /about across a heading and a paragraph
        self.assertTrue(find("OK", 120))
        about = find("OUTDATED", 70)
        self.assertEqual(len(about), 1)
        self.assertTrue(about[0]["url"].endswith("/about"))
        self.assertTrue(find("OK", 72))
        self.assertEqual(len(find("RETIRED")), 1)
        # what was not read, and why
        self.assertTrue(any(s["url"].endswith("/private/x") and s["why"] == "robots.txt"
                            for s in result["skipped"]))
        self.assertTrue(any(s["url"].endswith("/brochure.pdf") for s in result["skipped"]))
        self.assertTrue(any(f["url"].endswith("/gone") and f["why"] == "404" for f in result["failed"]))
        # the report names it all
        for part in ("## Mismatches", "## Outdated values", "## Retired phrases still in use",
                     "## Facts no page names", "- Languages", "Source: HR system.",
                     "**30,000**", "skipped (robots.txt)", "could not be read (404)"):
            self.assertIn(part, md)
        lines = history.strip().splitlines()
        self.assertEqual(lines[0].split(",")[4], "mismatches")
        self.assertEqual(lines[1].split(",")[2:7], ["2", "3", "1", "2", "1"])

    def test_clean_site_exits_zero(self):
        facts = self.facts(pages=[self.server.base + "/"], retired_phrases=[],
                           facts=[{"id": "clients", "value": 120, "terms": ["client"]}])
        code, md, result, _ = self.run_check(facts)
        self.assertEqual(code, 0)
        self.assertIn("**0 mismatches, 0 outdated values, 0 retired phrases**", md)

    def test_ignore_robots_reads_disallowed_pages(self):
        code, _, result, _ = self.run_check(self.facts(), "--ignore-robots")
        self.assertTrue(any(f["url"].endswith("/private/x") and f["why"] == "404"
                            for f in result["failed"]))

    def test_only_and_extra_urls(self):
        facts = self.facts(extra_urls=[self.server.base + "/about"])
        code, md, result, _ = self.run_check(facts, "--only", "/about")
        own = [p["url"] for p in result["read"] if p["origin"] == "own"]
        self.assertEqual(len(own), 1)
        self.assertTrue(own[0].endswith("/about"))
        self.assertIn("(not your site)", md)

    def test_no_pages_is_an_error_not_a_pass(self):
        facts = self.facts(sitemap=self.server.base + "/nothing.xml")
        code, md, result, _ = self.run_check(facts)
        self.assertEqual(code, 2)
        self.assertIn("No pages were found", md)


class Cli(unittest.TestCase):
    def test_init_writes_once(self):
        tmp = tempfile.mkdtemp()
        path = os.path.join(tmp, "facts.json")
        try:
            with contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
                self.assertEqual(fc.main([path, "--init"]), 0)
                self.assertEqual(fc.main([path, "--init"]), 2)
            self.assertEqual(fc.load_facts(path)["facts"][0]["id"], "clients")
        finally:
            os.remove(path)
            os.rmdir(tmp)

    def test_bad_facts_file_exits_two(self):
        with contextlib.redirect_stderr(io.StringIO()) as err:
            self.assertEqual(fc.main(["/nonexistent/facts.json"]), 2)
        self.assertIn("--init", err.getvalue())


if __name__ == "__main__":
    unittest.main()
