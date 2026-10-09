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
            "27,000+ agents": 27000, "27.000 Agenten": 27000, "27\u202f000 agents": 27000,
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

    def test_a_plain_space_does_not_group_thousands(self):
        # review finding: "our 5 120 clients" was read as 5120
        self.assertEqual(first_num("5 120 clients")[0], 5)

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

    def test_a_comma_ends_the_search(self):
        # review finding: 60 was tied to clients across the comma
        f = fact(value=120, terms=["client"])
        self.assertEqual(self.statuses("in 60 countries, clients love us", f), [])
        self.assertEqual(self.statuses("Our 5 120 clients", f), [("OK", 120)])

    def test_a_plain_four_digit_count_is_not_taken_for_a_year(self):
        # review finding: "Über 2000 Kunden" was skipped as a year
        f = fact(value=1800, terms=["Kunden"])
        self.assertEqual(self.statuses("Über 2000 Kunden vertrauen uns", f), [("MISMATCH", 2000)])
        self.assertEqual(self.statuses("seit 2010 Kunden", f), [])
        # found on a real site: a date right before the term
        self.assertEqual(self.statuses("launched on 27 March 2026 with these Kunden", f), [])
        self.assertEqual(self.statuses("im Herbst 2025 Kunden", f), [])
        self.assertEqual(self.statuses("\u00a9 2024 Kunden GmbH", f), [])

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


    def locations(self, html, ctype=""):
        p = fc.PageText()
        p.feed(fc.decode(html, ctype) if isinstance(html, bytes) else html)
        return p.locations()

    def test_inline_formatting_does_not_split_numbers_or_words(self):
        # review finding: "<b>27</b>,000" became "27 ,000" and gave MISMATCH 27
        loc = self.locations("<p><b>27</b>,000 clients. Tr<i>u</i>sted.</p>")
        self.assertEqual(loc["page text"], "27,000 clients. Trusted.")
        rows = fc.check_page("u", loc, [fact(value=27000, terms=["client"])],
                             [{"text": "Trusted"}])
        self.assertEqual(sorted(r["status"] for r in rows), ["OK", "RETIRED"])

    def test_numbers_in_structured_data_carry_their_property_name(self):
        # review finding: numeric JSON-LD values were dropped
        loc = self.locations('<script type="application/ld+json">{"@type": "Organization", '
                             '"numberOfEmployees": {"@type": "QuantitativeValue", "value": 30000}}'
                             '</script>')
        self.assertIn("30,000 number of employees", loc["structured data"])
        rows = fc.check_page("u", loc, [fact(value=27000, terms=["employee"])], [])
        self.assertEqual([(r["status"], r["found_value"]) for r in rows], [("MISMATCH", 30000)])

    def test_meta_charset_is_used_when_the_header_names_none(self):
        # review finding: a Latin-1 page was read as UTF-8
        html = '<html><head><meta charset="iso-8859-1"></head><p>27\xa0000 Agenten, Müller GmbH</p>'
        loc = self.locations(html.encode("iso-8859-1"), "text/html")
        self.assertIn("Müller GmbH", loc["page text"])
        rows = fc.check_page("u", loc, [fact(terms=["Agenten"])], [])
        self.assertEqual([r["status"] for r in rows], ["OK"])


class Positioning(unittest.TestCase):
    def surfaces(self, html):
        p = fc.PageText()
        p.feed(html)
        return p.surfaces()

    PAGE = ('<html><head><title>CX outsourcing | Acme</title>'
            '<meta name="description" content="Flexible CX outsourcing for retailers.">'
            '<meta property="og:description" content="Something else"></head><body>'
            '<header><p>Skip to content</p></header><main><h1>Help when <em>you</em> need it</h1>'
            '<p>On-demand <b>CX outsourcing</b> for retail.</p><p>Second paragraph.</p></main>'
            '<footer>Careers at Acme</footer></body></html>')

    def test_surfaces_as_the_starter_test_reads_them(self):
        s = self.surfaces(self.PAGE)
        self.assertEqual(s["title"], "CX outsourcing | Acme")
        self.assertEqual(s["desc"], "Flexible CX outsourcing for retailers.")
        # all h1s, then the intro: the first <p> of <main>, not the header's
        self.assertEqual(s["h1"], "Help when you need it \u00b7 On-demand CX outsourcing for retail.")
        self.assertIn("Careers at Acme", s["body"])

    def test_intro_falls_back_to_article_then_page(self):
        self.assertTrue(self.surfaces("<article><p>A</p></article><p>B</p>")["h1"].endswith("A"))
        self.assertTrue(self.surfaces("<div><p>B<div>x</div></div>")["h1"].endswith("B"))
        # a <main> without a <p> gives no intro, as in the starter test
        self.assertEqual(self.surfaces("<p>B</p><main><h1>H</h1></main>")["h1"], "H \u00b7 ")

    def test_a_paragraph_ends_where_the_browser_ends_it(self):
        # review findings: the intro ran on past a </div> or a new <li> that closes the <p>
        self.assertEqual(self.surfaces("<main><div><p>Short intro</div><a>term</a></main>")["h1"],
                         " \u00b7 Short intro")
        self.assertEqual(self.surfaces("<main><ul><li><p>first<li>term</ul></main>")["h1"], " \u00b7 first")
        self.assertEqual(self.surfaces("<main><p>one<pre>term</pre></main>")["h1"], " \u00b7 one")
        # inline markup inside the paragraph stays part of it
        self.assertEqual(self.surfaces("<main><p>a <a>b</a> <span>c</span></p></main>")["h1"],
                         " \u00b7 a b c")

    def test_only_the_first_main_counts(self):
        # review finding: a later <main> supplied the intro the starter test would not see
        html = "<main><h1>H</h1></main><dialog><main><p>term</p></main></dialog>"
        self.assertEqual(self.surfaces(html)["h1"], "H \u00b7 ")

    def test_title_is_the_first_title_and_keeps_no_break_spaces(self):
        # review finding: every <title> was joined and no-break spaces collapsed
        s = self.surfaces("<head><title>\n  Acme\u00a0Pro  </title></head><body><title>term</title></body>")
        self.assertEqual(s["title"], "Acme\u00a0Pro")
        self.assertEqual(fc.check_positioning(s, {"title": ["Acme Pro"]}),
                         ["<title> needs \u201cAcme Pro\u201d"])

    def test_term_rule_needs_title_description_and_h1_or_intro(self):
        s = self.surfaces(self.PAGE)
        self.assertEqual(fc.check_positioning(s, {"term": "cx outsourcing"}), [])
        missing = fc.check_positioning(s, {"term": "contact center"})
        self.assertEqual([m.split(" needs")[0] for m in missing],
                         ["<title>", "<meta description>", "<h1>/intro"])

    def test_surface_rules_alternatives_and_body(self):
        s = self.surfaces(self.PAGE)
        rule = {"title": [["contact center", "CX outsourcing"]], "body": ["careers"], "desc": ["retail"]}
        self.assertEqual(fc.check_positioning(s, rule), [])
        self.assertEqual(fc.check_positioning(s, {"h1": [["call center", "BPO"]]}),
                         ["<h1>/intro needs one of [call center | BPO]"])

    def test_paths_and_first_matching_rule(self):
        for u, want in (("https://x.com/en/about/", "/en/about"), ("https://x.com/en/about.html", "/en/about"),
                        ("https://x.com/en/about/index.html", "/en/about"), ("https://x.com/", "/"),
                        ("https://x.com/index.html", "/"), ("https://x.com/%C3%BCber", "/\u00fcber")):
            self.assertEqual(fc.norm_path(u), want, u)
        rules = [{"pages": "/en/business/pricing", "term": "a"}, {"pages": "/en/business/*", "term": "b"},
                 {"pages": ["/", "/en"], "term": "c"}]
        self.assertEqual(fc.find_rule("/en/business/pricing", rules)["term"], "a")
        self.assertEqual(fc.find_rule("/en/business/telco/retail", rules)["term"], "b")
        self.assertEqual(fc.find_rule("/en", rules)["term"], "c")
        self.assertIsNone(fc.find_rule("/en/business", rules))  # "/*" needs something after it


class MorePlaces(unittest.TestCase):
    PAGE = ('<html><head><title>Acme</title>'
            '<meta property="og:title" content="Old Name GmbH: 30,000 agents">'
            '<meta property="og:url" content="https://oldname.example/en/">'
            '<link rel="canonical" href="https://oldname.example/en/"></head><body>'
            '<img src="team.jpg" alt="Our 30,000 agents at the Old Name GmbH summit">'
            '<a href="/blog/2024/30000-agents">read more</a>'
            '<template><p>Old Name GmbH</p></template><main><p>Intro text.</p></main></body></html>')

    def rows(self, fact_list, phrases):
        p = fc.PageText()
        p.feed(self.PAGE)
        return p, fc.check_page("u", p.locations(), fact_list, phrases)

    def test_retired_phrases_in_alt_text_share_tags_and_addresses(self):
        # the gap found in the eval run: these places were never searched
        _, rows = self.rows([], [{"text": "Old Name GmbH"}, {"text": "oldname.example"}])
        where = sorted((r["phrase"], r["where"]) for r in rows)
        self.assertEqual(where, [("Old Name GmbH", "image alt text"), ("Old Name GmbH", "share title"),
                                 ("oldname.example", "link addresses")])

    def test_facts_in_alt_text_and_share_title_but_not_in_addresses(self):
        _, rows = self.rows([fact()], [])
        self.assertEqual(sorted(r["where"] for r in rows), ["image alt text", "share title"])

    def test_template_and_noscript_content_is_not_page_structure(self):
        # outside review finding: a <p> inside <template> took the intro's place
        p, _ = self.rows([], [])
        self.assertEqual(p.surfaces()["h1"], " \u00b7 Intro text.")
        q = fc.PageText()
        q.feed("<noscript><p>Enable JS</p><img alt='Old Name GmbH'></noscript><p>Real intro</p>")
        self.assertTrue(q.surfaces()["h1"].endswith("Real intro"))
        self.assertNotIn("image alt text", q.locations())


class FetcherRules(unittest.TestCase):
    class Fake(fc.Fetcher):
        def __init__(self, answers):
            super().__init__(timeout=1, delay=0, respect_robots=True)
            self.answers = answers

        def get(self, url, limit=fc.MAX_BYTES):
            status, ctype, body = self.answers.get(url, (404, "", b""))
            return status, ctype, body[:limit], url

    def test_a_robots_txt_that_cannot_be_read_keeps_the_site_out(self):
        # outside review finding: a 503 on robots.txt meant "everything allowed"
        f = self.Fake({"https://x.com/robots.txt": (503, "", b"")})
        self.assertIn("could not be read (503)", f.blocked("https://x.com/a"))
        self.assertEqual(self.Fake({}).blocked("https://x.com/a"), "")  # a 404 allows all

    def test_a_page_over_5_mb_is_reported_as_cut(self):
        # outside review finding: the cut was silent
        big = b"<html><body><p>" + b"x " * (3 * 1024 * 1024) + b"</p></body></html>"
        f = self.Fake({"https://x.com/big": (200, "text/html", big)})
        result = fc.run({"site": "https://x.com", "pages": ["https://x.com/big"], "facts": [],
                         "retired_phrases": [{"text": "Old Name"}]},
                        10, 0, 1, "", True, f)
        self.assertEqual(len(result["read"]), 1)
        self.assertIn("only the first 5 MB were read", " ".join(result["notes"]))


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

    def test_a_malformed_positioning_block_is_a_message_not_a_crash(self):
        # review finding: a list here raised AttributeError (exit 1, read as "findings")
        for bad in (["x"], "x", {"rules": "x"}):
            with self.subTest(bad=bad):
                with self.assertRaises(fc.FactsError) as cm:
                    fc.load_facts(self.write({"site": "https://x.com", "positioning": bad}))
                self.assertIn('"positioning" must be an object', str(cm.exception))

    def test_positioning_rules_are_validated(self):
        path = self.write({"site": "https://x.com", "positioning": {"rules": [
            {"pages": "en/*", "term": "a"},
            {"pages": "/", "term": "a", "title": ["b"]},
            {"pages": "/x"},
            {"pages": "/y", "h1": [[]]},
        ], "exempt": ["privacy"]}})
        with self.assertRaises(fc.FactsError) as cm:
            fc.load_facts(path)
        msg = str(cm.exception)
        for part in ('starting with "/"', "not both", 'needs a "term"', '"h1" must be', '"exempt"'):
            self.assertIn(part, msg)

    def test_positioning_alone_is_enough(self):
        path = self.write({"site": "https://x.com", "positioning": {"rules": [{"pages": "/", "term": "a"}]}})
        self.assertEqual(fc.load_facts(path)["facts"], [])
        with self.assertRaises(fc.FactsError) as cm:
            fc.load_facts(self.write({"site": "https://x.com"}))
        self.assertIn("nothing to check", str(cm.exception))

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
        '<url><loc>{base}/</loc><image:image xmlns:image="http://www.google.com/schemas/sitemap-image/1.1">'
        "<image:loc>{base}/hero.jpg</image:loc></image:image></url><url><loc>{base}/about</loc></url>"
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
    "/llms.txt": ("text/plain; charset=utf-8", "# Acme\n> Formerly Old Name GmbH. 30,000 agents.\n"),
}


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/old-offer":
            self.send_response(301)
            self.send_header("Location", self.server.base + "/")
            self.end_headers()
            return
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
         "terms": ["agent", "Agenten"], "retired": [25000], "source": "HR system",
         "owner": "Workforce planning", "checked": "[date]"},
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
        history = ""
        if os.path.exists(hist):  # a run that checked nothing writes no history line
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
        # /llms.txt is read too: its old name and its figure count
        llms = [r for r in rows if r["where"] == "llms.txt"]
        self.assertEqual(sorted(r["status"] for r in llms), ["MISMATCH", "RETIRED"])
        self.assertIn("Also read: %s/llms.txt." % self.server.base, md)
        about = find("OUTDATED", 70)
        self.assertEqual(len(about), 1)
        self.assertTrue(about[0]["url"].endswith("/about"))
        self.assertTrue(find("OK", 72))
        self.assertEqual(len(find("RETIRED")), 2)  # the page text and /llms.txt
        # what was not read, and why
        self.assertTrue(any(s["url"].endswith("/private/x") and s["why"] == "robots.txt"
                            for s in result["skipped"]))
        self.assertTrue(any(s["url"].endswith("/brochure.pdf") for s in result["skipped"]))
        self.assertTrue(any(f["url"].endswith("/gone") and f["why"] == "404" for f in result["failed"]))
        # the report names it all
        for part in ("## Mismatches", "## Outdated values", "## Retired phrases still in use",
                     "Source: HR system. Owner: Workforce planning.",
                     "## Facts no page names", "- Languages", "Source: HR system.",
                     "**30,000**", "skipped (robots.txt)", "could not be read (404)"):
            self.assertIn(part, md)
        lines = history.strip().splitlines()
        self.assertEqual(lines[0].split(",")[4], "mismatches")
        self.assertEqual(lines[1].split(",")[2:7], ["2", "3", "2", "2", "2"])

    def test_image_entries_in_the_sitemap_are_not_pages(self):
        # review finding: image:loc was fetched as a page
        _, _, result, _ = self.run_check(self.facts())
        self.assertEqual(result["pages_listed"], 5)
        listed = [p["url"] for p in result["read"] + result["failed"] + result["skipped"]]
        self.assertFalse([u for u in listed if u.endswith(".jpg")])

    def test_a_run_that_reads_no_page_is_never_clean(self):
        # review finding: all pages failing gave a clean headline and a 0/0/0 history line
        facts = self.facts(pages=[self.server.base + "/gone", self.server.base + "/also-gone"])
        tmp = tempfile.mkdtemp()
        path, out, hist = (os.path.join(tmp, n) for n in ("f.json", "r.md", "h.csv"))
        try:
            with open(path, "w") as f:
                json.dump(facts, f)
            with contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()) as err:
                code = fc.main([path, "--out", out, "--history", hist, "--delay", "0"])
            with open(out) as f:
                md = f.read()
            self.assertEqual(code, 2)
            self.assertIn("No page of the site could be read, so nothing was checked", md)
            self.assertFalse(os.path.exists(hist))
            self.assertIn("history was not updated", err.getvalue())
        finally:
            for n in os.listdir(tmp):
                os.remove(os.path.join(tmp, n))
            os.rmdir(tmp)

    def test_only_is_applied_while_the_sitemap_is_read(self):
        # review finding: --only filtered after the list was cut to max_pages * 4
        # The brochure is the sitemap's last entry, past the old cut-off of 4 x 1 entries.
        _, _, result, _ = self.run_check(self.facts(), "--only", "brochure", "--max-pages", "1")
        self.assertEqual(result["pages_listed"], 1)
        self.assertEqual([p["url"] for p in result["skipped"]], [self.server.base + "/brochure.pdf"])

    def test_positioning_on_the_stub_site(self):
        facts = self.facts(facts=[], retired_phrases=[], positioning={
            "rules": [{"pages": "/", "audience": "buyers",  # no h1 here: the intro counts
                       "title": ["agents"], "desc": ["agents"], "h1": [["clients", "customers"]]},
                      {"pages": "/about", "audience": "buyers", "term": "clients"}],
            "exempt": ["/private/*"]})
        code, md, result, history = self.run_check(facts)
        self.assertEqual(code, 1)
        pages = {p["path"]: p["missing"] for p in result["positioning"]["pages"]}
        # "/" meets its per-surface rule; /about has no description and "About" as title
        self.assertEqual(pages["/"], [])
        self.assertEqual([m.split(" needs")[0] for m in pages["/about"]], ["<title>", "<meta description>"])
        self.assertIn("**1 page lost its positioning term**, of 2 with a rule; 0 pages with no rule.", md)
        self.assertNotIn("mismatches", md)  # no facts were checked, so no fact counts
        self.assertIn("| buyers | 2 | 1 | 1 |", md)
        self.assertIn("rule /about: <title> needs", md)
        self.assertEqual(history.strip().splitlines()[1].split(",")[-1], "1")

    def test_exempt_wins_over_a_wildcard_rule_and_redirects_are_listed(self):
        # review findings: an exempt page under "/*" was still checked; an old address
        # that redirects to "/" was checked as the home page and counted twice
        base = self.server.base
        facts = self.facts(facts=[], retired_phrases=[], pages=[base + "/", base + "/about", base + "/old-offer"],
                           positioning={"rules": [{"pages": ["/", "/*"], "term": "agents"}],
                                        "exempt": ["/about"]})
        code, md, result, _ = self.run_check(facts)
        pos = result["positioning"]
        self.assertEqual([p["path"] for p in pos["pages"]], ["/"])
        self.assertEqual(pos["uncovered"], [])
        self.assertEqual([r["url"] for r in pos["redirected"]], [base + "/old-offer"])
        self.assertIn("### Addresses that redirect", md)

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
        code, md, result, history = self.run_check(facts)
        self.assertEqual(code, 2)
        self.assertIn("No pages were found", md)
        self.assertEqual(history, "")


class LargeSitemap(unittest.TestCase):
    def test_a_sitemap_over_5_mb_is_read_in_full(self):
        # review finding: every response was cut at 5 MB, so a large sitemap failed to parse
        import gzip
        urls = "".join("<url><loc>https://example.com/p/%06d-%s</loc></url>" % (i, "x" * 60)
                       for i in range(70000))
        xml = ('<?xml version="1.0"?><urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">'
               + urls + "</urlset>").encode()
        self.assertGreater(len(xml), 5 * 1024 * 1024)

        class Fake:
            def get(self, url, limit=fc.MAX_BYTES):
                body = gzip.compress(xml) if url.endswith(".gz") else xml
                return 200, "application/xml", body[:limit], url

        for name in ("sitemap.xml", "sitemap.xml.gz"):
            with self.subTest(name=name):
                notes = []
                pages = fc.sitemap_urls(Fake(), ["https://example.com/" + name], 100000, notes)
                self.assertEqual((len(pages), notes), (70000, []))


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
