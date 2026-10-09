#!/usr/bin/env python3
"""
facts_check.py — compare every figure on a live site with one list of approved facts.

Read-only. It reads the site's sitemap (or a page list), fetches each page once, finds
every number that names a fact ("27,000+ agents", "NPS of 72", "35 languages") in the
visible text, the title, the meta and social descriptions and the structured data
(JSON-LD), and reports each one that differs from the approved value. It also reports
phrases the owner has retired ("old name", "old figure") wherever they still appear.
It changes nothing on the site.

Standard library only (Python 3.9+), so it runs on a stock python3 with no installs.

Usage:
  python3 facts_check.py --init facts.json          # write a starter facts file
  python3 facts_check.py facts.json                 # check, print the report
  python3 facts_check.py facts.json --out report.md --json report.json \
      --history history.csv                         # the weekly run

Exit codes: 0 every mention matches, 1 at least one finding (mismatch, outdated value or
retired phrase), 2 the run could not start (bad facts file, no pages to read).

How a number is tied to a fact (the rules SKILL.md explains to the owner):
  - after:  one of the fact's `terms` follows the number within `window` words
            (default 4), with no other number or sentence end in between:
            "27,000+ vetted agents" -> term "agent".
            A term matches any word that starts with it ("agent" matches "agents").
  - before: one of the fact's `before` phrases ends right before the number:
            "an NPS of 72" -> before phrase "NPS of".
  - unit:   "%" ties only percentages to the fact; "" (default) only plain numbers.
  - A year-like number (1900 to 2100, written plainly) and a zero are ignored for a fact
    whose own value is not in that range, so "Founded in 2016. Clients ..." and a
    count-up that starts at 0 do not count as client numbers.
Each tied number is OK (the approved value or one in `also_accept`), OUTDATED (in
`retired`) or MISMATCH (anything else).
"""

from __future__ import annotations

import argparse
import csv
import datetime as _dt
import gzip
import json
import os
import re
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
import urllib.robotparser
import xml.etree.ElementTree as ET
from html.parser import HTMLParser
from typing import Dict, List, Optional, Tuple

USER_AGENT = "facts-check/1.0 (read-only site consistency check)"
MAX_BYTES = 5 * 1024 * 1024
DEFAULT_WINDOW = 4

# ---------------------------------------------------------------------------
# Numbers
# ---------------------------------------------------------------------------

# Grouped thousands (27,000 / 27.000 / 27 000 with a normal, no-break or thin space)
# or a plain run of digits; then an optional decimal part; then an optional
# multiplier, plus sign and percent. The lookbehind keeps a match from starting
# inside a word or inside another number.
NUM_RE = (
    r"(?<![\w.,])"
    r"(?P<int>\d{1,3}(?:[,.\u00a0\u202f\u2009 ]\d{3})+(?!\d)|\d+)"
    r"(?P<dec>[.,]\d+(?!\d))?"
    r"(?:[\u00a0 ]?(?P<mult>k|K|Tsd\.|M|Mio\.?|Mrd\.?|[Mm]illions?|Millionen|"
    r"[Bb]illions?|Milliarden?|bn)(?!\w))?"
    r"(?P<plus>[\u00a0 ]?\+)?"
    r"(?P<pct>[\u00a0 ]?%)?"
)
WORD_RE = r"[^\W\d_]+(?:['\u2019\-][^\W\d_]+)*"
STOP_RE = r"[.!?;](?=\s|$)|[|\u2022\u00b7]"
TOKEN_RE = re.compile(
    "(?P<num>%s)|(?P<word>%s)|(?P<stop>%s)" % (NUM_RE, WORD_RE, STOP_RE)
)

MULTIPLIERS = {
    "k": 1e3, "K": 1e3, "Tsd.": 1e3,
    "M": 1e6, "Mio": 1e6, "Mio.": 1e6, "million": 1e6, "millions": 1e6,
    "Million": 1e6, "Millions": 1e6, "Millionen": 1e6,
    "Mrd": 1e9, "Mrd.": 1e9, "billion": 1e9, "billions": 1e9, "Billion": 1e9,
    "Billions": 1e9, "Milliarde": 1e9, "Milliarden": 1e9, "bn": 1e9,
}


def parse_number(m: "re.Match") -> Tuple[float, bool]:
    """Value of a NUM match, and whether it was written plainly (no grouping,
    decimals, multiplier, plus or percent): only a plain number can be a year."""
    raw_int = m.group("int")
    digits = re.sub(r"[,.\u00a0\u202f\u2009 ]", "", raw_int)
    value = float(digits)
    dec = m.group("dec")
    if dec:
        value += float("0." + dec[1:])
    mult = m.group("mult")
    if mult:
        value *= MULTIPLIERS[mult]
    plain = (digits == raw_int and not dec and not mult
             and not m.group("plus") and not m.group("pct"))
    return value, plain


def same(a: float, b: float) -> bool:
    return abs(a - b) <= 1e-9 * max(1.0, abs(a), abs(b))


# ---------------------------------------------------------------------------
# Facts file
# ---------------------------------------------------------------------------

STARTER = {
    "site": "https://example.com",
    "sitemap": "",
    "pages": [],
    "extra_urls": [],
    "facts": [
        {
            "id": "clients",
            "label": "Number of clients",
            "value": 120,
            "unit": "",
            "terms": ["client", "customer"],
            "before": [],
            "also_accept": [100],
            "retired": [70],
            "source": "[where the approved value comes from]",
            "owner": "[who confirms it]",
            "checked": "[date it was last confirmed]",
        },
        {
            "id": "customer-nps",
            "label": "Customer NPS",
            "value": 72,
            "unit": "",
            "terms": [],
            "before": ["NPS of", "NPS score of", "NPS"],
            "also_accept": [],
            "retired": [],
            "source": "[where the approved value comes from]",
            "owner": "[who confirms it]",
            "checked": "[date it was last confirmed]",
        },
    ],
    "retired_phrases": [
        {"text": "[an old product name or claim]", "note": "[why it is retired]"}
    ],
}


class FactsError(Exception):
    pass


def _num(x) -> bool:
    return isinstance(x, (int, float)) and not isinstance(x, bool)


def load_facts(path: str) -> dict:
    try:
        with open(path, encoding="utf-8") as f:
            data = json.load(f)
    except FileNotFoundError:
        raise FactsError("no facts file at %s (create one with --init)" % path)
    except json.JSONDecodeError as e:
        raise FactsError("%s is not valid JSON: %s" % (path, e))
    problems: List[str] = []
    if not isinstance(data, dict):
        raise FactsError("%s must hold one JSON object" % path)
    site = data.get("site", "")
    if not isinstance(site, str) or not re.match(r"https?://[^/\s]+", site):
        problems.append('"site" must be the site\'s address, e.g. "https://example.com"')
    facts = data.get("facts")
    if not isinstance(facts, list) or not facts:
        problems.append('"facts" must be a list with at least one fact')
        facts = []
    seen = set()
    for i, fact in enumerate(facts):
        where = "fact %d" % (i + 1)
        if not isinstance(fact, dict):
            problems.append("%s is not an object" % where)
            continue
        fid = fact.get("id")
        if not isinstance(fid, str) or not fid.strip():
            problems.append('%s needs an "id"' % where)
        else:
            where = 'fact "%s"' % fid
            if fid in seen:
                problems.append("%s appears twice" % where)
            seen.add(fid)
        if not _num(fact.get("value")):
            problems.append('%s needs a numeric "value" (write 27000, not "27,000+")' % where)
        if fact.get("unit", "") not in ("", "%"):
            problems.append('%s: "unit" is "" or "%%"' % where)
        terms = fact.get("terms", [])
        before = fact.get("before", [])
        for key, val in (("terms", terms), ("before", before)):
            if not isinstance(val, list) or not all(isinstance(t, str) and t.strip() for t in val):
                problems.append('%s: "%s" must be a list of words or phrases' % (where, key))
        if isinstance(terms, list) and isinstance(before, list) and not terms and not before:
            problems.append('%s needs "terms" or "before", or no number can be tied to it' % where)
        for key in ("also_accept", "retired"):
            val = fact.get(key, [])
            if not isinstance(val, list) or not all(_num(v) for v in val):
                problems.append('%s: "%s" must be a list of numbers' % (where, key))
        if _num(fact.get("value")) and any(
                _num(v) and same(v, fact["value"]) for v in fact.get("retired", []) or []):
            problems.append("%s: the approved value is also listed as retired" % where)
        w = fact.get("window", DEFAULT_WINDOW)
        if not isinstance(w, int) or isinstance(w, bool) or not 1 <= w <= 12:
            problems.append('%s: "window" must be a whole number from 1 to 12' % where)
    for i, rp in enumerate(data.get("retired_phrases", []) or []):
        if not isinstance(rp, dict) or not isinstance(rp.get("text"), str) or not rp["text"].strip():
            problems.append('retired phrase %d needs a "text"' % (i + 1))
    for key in ("pages", "extra_urls"):
        val = data.get(key, []) or []
        if not isinstance(val, list) or not all(isinstance(u, str) and u.startswith(("http://", "https://")) for u in val):
            problems.append('"%s" must be a list of full addresses (https://...)' % key)
    if problems:
        raise FactsError("%s has problems:\n  - %s" % (path, "\n  - ".join(problems)))
    return data


# ---------------------------------------------------------------------------
# Finding mentions in text
# ---------------------------------------------------------------------------

def _phrase_words(phrase: str) -> List[str]:
    return [w.lower() for w in re.findall(WORD_RE, phrase)]


def _word_matches(word: str, term: str) -> bool:
    return word.startswith(term)


def tokenize(text: str):
    return [(m.lastgroup, m) for m in TOKEN_RE.finditer(text)]


def find_mentions(text: str, fact: dict) -> List[dict]:
    """Every number in `text` that the fact's rules tie to it."""
    value = float(fact["value"])
    unit = fact.get("unit", "")
    window = fact.get("window", DEFAULT_WINDOW)
    terms = [_phrase_words(t) for t in fact.get("terms", [])]
    terms = [t for t in terms if t]
    befores = [_phrase_words(p) for p in fact.get("before", [])]
    befores = [b for b in befores if b]
    fact_is_year = 1900 <= value <= 2100
    tokens = tokenize(text)
    out = []
    for i, (kind, m) in enumerate(tokens):
        if kind != "num":
            continue
        is_pct = bool(m.group("pct"))
        if (unit == "%") != is_pct:
            continue
        num, plain = parse_number(m)
        if plain and 1900 <= num <= 2100 and not fact_is_year:
            continue
        if num == 0 and value != 0:
            continue
        tied = False
        # after: a term within `window` words, before another number or a stop
        after_words: List[str] = []
        j = i + 1
        while j < len(tokens) and tokens[j][0] == "word" and len(after_words) < window:
            after_words.append(tokens[j][1].group(0).lower())
            j += 1
        for t in terms:
            for s in range(0, len(after_words) - len(t) + 1):
                if all(_word_matches(after_words[s + k], t[k]) for k in range(len(t))):
                    tied = True
                    break
            if tied:
                break
        # before: a phrase that ends right before the number
        if not tied and befores:
            before_words: List[str] = []
            j = i - 1
            while j >= 0 and tokens[j][0] == "word" and len(before_words) < 8:
                before_words.insert(0, tokens[j][1].group(0).lower())
                j -= 1
            for b in befores:
                if len(before_words) >= len(b) and before_words[-len(b):] == b:
                    tied = True
                    break
        if not tied:
            continue
        if same(num, value) or any(same(num, float(v)) for v in fact.get("also_accept", [])):
            status = "OK"
        elif any(same(num, float(v)) for v in fact.get("retired", [])):
            status = "OUTDATED"
        else:
            status = "MISMATCH"
        out.append({
            "status": status,
            "found": m.group(0).strip(),
            "found_value": num,
            "snippet": snippet(text, m.start(), m.end()),
        })
    return out


def snippet(text: str, start: int, end: int, pad: int = 60) -> str:
    a = max(0, start - pad)
    b = min(len(text), end + pad)
    if a > 0:  # start and end on a word boundary
        sp = text.find(" ", a, start)
        a = sp + 1 if sp != -1 else a
    if b < len(text):
        sp = text.rfind(" ", end, b)
        b = sp if sp != -1 else b
    left = ("\u2026" if a > 0 else "") + text[a:start]
    right = text[end:b] + ("\u2026" if b < len(text) else "")
    s = left + "**" + text[start:end].strip() + "**" + right
    return re.sub(r"\s+", " ", s).strip()


def find_phrases(text: str, phrase: str) -> List[str]:
    norm = re.sub(r"\s+", " ", text)
    p = re.sub(r"\s+", " ", phrase.strip())
    out = []
    for m in re.finditer(re.escape(p), norm, re.IGNORECASE):
        out.append(snippet(norm, m.start(), m.end()))
    return out


# ---------------------------------------------------------------------------
# Reading pages
# ---------------------------------------------------------------------------

BLOCK_TAGS = {
    "p", "div", "li", "ul", "ol", "dt", "dd", "h1", "h2", "h3", "h4", "h5", "h6",
    "td", "th", "tr", "br", "section", "article", "header", "footer", "main",
    "nav", "aside", "figure", "figcaption", "blockquote", "span", "a", "button",
    "label", "summary", "details", "strong", "em", "b", "i",
}
SKIP_TAGS = {"script", "style", "noscript", "template", "svg", "iframe", "canvas"}


class PageText(HTMLParser):
    """Visible text, title, descriptions and JSON-LD strings of one HTML page."""

    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.parts: Dict[str, List[str]] = {
            "page text": [], "title": [], "meta description": [],
            "social description": [], "structured data": [],
        }
        self._skip = 0
        self._in_title = False
        self._in_ldjson = False
        self._ld_buf: List[str] = []

    def handle_starttag(self, tag, attrs):
        a = {k.lower(): (v or "") for k, v in attrs}
        if tag == "script" and a.get("type", "").lower() == "application/ld+json":
            self._in_ldjson = True
            self._ld_buf = []
            return
        if tag in SKIP_TAGS:
            self._skip += 1
            return
        if tag == "title":
            self._in_title = True
        elif tag == "meta":
            name = (a.get("name") or a.get("property") or "").lower()
            content = a.get("content", "")
            if name == "description":
                self.parts["meta description"].append(content)
            elif name in ("og:description", "twitter:description"):
                self.parts["social description"].append(content)
        if tag in BLOCK_TAGS:
            self.parts["page text"].append(" ")

    def handle_startendtag(self, tag, attrs):
        self.handle_starttag(tag, attrs)
        if tag in SKIP_TAGS and tag != "script":
            self._skip = max(0, self._skip - 1)

    def handle_endtag(self, tag):
        if tag == "script" and self._in_ldjson:
            self._in_ldjson = False
            self._add_ldjson("".join(self._ld_buf))
            return
        if tag in SKIP_TAGS:
            self._skip = max(0, self._skip - 1)
            return
        if tag == "title":
            self._in_title = False
        if tag in BLOCK_TAGS:
            self.parts["page text"].append(" ")

    def handle_data(self, data):
        if self._in_ldjson:
            self._ld_buf.append(data)
        elif self._skip:
            return
        elif self._in_title:
            self.parts["title"].append(data)
        else:
            self.parts["page text"].append(data)

    def _add_ldjson(self, raw: str):
        try:
            obj = json.loads(raw)
        except ValueError:
            return

        def walk(o):
            if isinstance(o, dict):
                for v in o.values():
                    walk(v)
            elif isinstance(o, list):
                for v in o:
                    walk(v)
            elif isinstance(o, str) and not o.startswith(("http://", "https://")):
                self.parts["structured data"].append(o)

        walk(obj)

    def locations(self) -> Dict[str, str]:
        out = {}
        for k, v in self.parts.items():
            sep = " " if k == "page text" else " | "
            if k != "page text":  # og: and twitter: descriptions often repeat one text
                v = list(dict.fromkeys(s.strip() for s in v))
            text = re.sub(r"[ \t\r\n\u00a0]+", " ", sep.join(s for s in v if s.strip())).strip()
            if text:
                out[k] = text
        return out


class Fetcher:
    def __init__(self, timeout: float, delay: float, respect_robots: bool):
        self.timeout = timeout
        self.delay = delay
        self.respect_robots = respect_robots
        self._opener = urllib.request.build_opener()
        self._robots: Dict[str, Optional[urllib.robotparser.RobotFileParser]] = {}
        self._last = 0.0

    def _wait(self):
        gap = time.monotonic() - self._last
        if gap < self.delay:
            time.sleep(self.delay - gap)
        self._last = time.monotonic()

    def get(self, url: str) -> Tuple[int, str, bytes, str]:
        """(status, content type, body, final url). Status 0 = no answer."""
        self._wait()
        req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT,
                                                   "Accept": "text/html,application/xml;q=0.9,*/*;q=0.5"})
        try:
            with self._opener.open(req, timeout=self.timeout) as r:
                body = r.read(MAX_BYTES + 1)[:MAX_BYTES]
                return r.status, r.headers.get("Content-Type", ""), body, r.geturl()
        except urllib.error.HTTPError as e:
            return e.code, "", b"", url
        except (urllib.error.URLError, OSError, ValueError) as e:
            return 0, str(getattr(e, "reason", e)), b"", url

    def allowed(self, url: str) -> bool:
        if not self.respect_robots:
            return True
        p = urllib.parse.urlsplit(url)
        root = "%s://%s" % (p.scheme, p.netloc)
        if root not in self._robots:
            rp = urllib.robotparser.RobotFileParser()
            status, _, body, _ = self.get(root + "/robots.txt")
            if status == 200:
                rp.parse(body.decode("utf-8", "replace").splitlines())
            elif status in (401, 403):
                rp.disallow_all = True
            else:
                rp.allow_all = True
            self._robots[root] = rp
        return self._robots[root].can_fetch(USER_AGENT, url)


def decode(body: bytes, ctype: str) -> str:
    m = re.search(r"charset=([\w-]+)", ctype or "", re.I)
    enc = m.group(1) if m else "utf-8"
    try:
        return body.decode(enc, "replace")
    except LookupError:
        return body.decode("utf-8", "replace")


def sitemap_urls(fetcher: Fetcher, start: List[str], limit: int, notes: List[str]) -> List[str]:
    pages: List[str] = []
    queue = list(start)
    seen = set()
    while queue and len(pages) < limit and len(seen) < 200:
        sm = queue.pop(0)
        if sm in seen:
            continue
        seen.add(sm)
        status, ctype, body, _ = fetcher.get(sm)
        if status != 200 or not body:
            notes.append("sitemap %s: %s" % (sm, status or ctype or "no answer"))
            continue
        if sm.endswith(".gz") or body[:2] == b"\x1f\x8b":
            try:
                body = gzip.decompress(body)
            except OSError:
                notes.append("sitemap %s: not a readable .gz file" % sm)
                continue
        try:
            root = ET.fromstring(body)
        except ET.ParseError:
            notes.append("sitemap %s: not valid XML" % sm)
            continue
        locs = [el.text.strip() for el in root.iter() if el.tag.endswith("loc") and el.text]
        if root.tag.endswith("sitemapindex"):
            queue.extend(locs)
        else:
            for u in locs:
                if u not in pages:
                    pages.append(u)
    return pages[:limit]


def default_sitemaps(fetcher: Fetcher, site: str) -> List[str]:
    root = site.rstrip("/")
    status, _, body, _ = fetcher.get(root + "/robots.txt")
    listed = []
    if status == 200:
        for line in body.decode("utf-8", "replace").splitlines():
            if line.lower().startswith("sitemap:"):
                listed.append(line.split(":", 1)[1].strip())
    return listed or [root + "/sitemap.xml", root + "/sitemap-index.xml", root + "/sitemap_index.xml"]


# ---------------------------------------------------------------------------
# The run
# ---------------------------------------------------------------------------

def check_page(url: str, locations: Dict[str, str], facts: List[dict],
               retired_phrases: List[dict]) -> List[dict]:
    rows = []
    seen = set()
    for fact in facts:
        for where, text in locations.items():
            for hit in find_mentions(text, fact):
                key = (fact["id"], where, hit["snippet"])
                if key in seen:
                    continue
                seen.add(key)
                hit.update({"kind": "fact", "fact": fact["id"], "url": url, "where": where})
                rows.append(hit)
    for rp in retired_phrases:
        for where, text in locations.items():
            for snip in find_phrases(text, rp["text"]):
                rows.append({"kind": "phrase", "status": "RETIRED", "phrase": rp["text"],
                             "note": rp.get("note", ""), "url": url, "where": where,
                             "snippet": snip})
    return rows


def run(data: dict, max_pages: int, delay: float, timeout: float, only: str,
        respect_robots: bool, fetcher: Optional[Fetcher] = None) -> dict:
    fetcher = fetcher or Fetcher(timeout, delay, respect_robots)
    notes: List[str] = []
    site = data["site"].rstrip("/")
    if data.get("pages"):
        pages = list(dict.fromkeys(data["pages"]))
        source = "the facts file's page list"
    else:
        start = [data["sitemap"]] if data.get("sitemap") else default_sitemaps(fetcher, site)
        pages = sitemap_urls(fetcher, start, max_pages * 4 if only else max_pages, notes)
        source = "the sitemap"
    if only:
        pages = [u for u in pages if only in u]
    pages = pages[:max_pages]
    own = [(u, "own") for u in pages]
    extra = [(u, "elsewhere") for u in dict.fromkeys(data.get("extra_urls", []) or [])]
    facts = data["facts"]
    retired_phrases = data.get("retired_phrases", []) or []
    rows: List[dict] = []
    read, failed, skipped = [], [], []
    for url, origin in own + extra:
        if not fetcher.allowed(url):
            skipped.append({"url": url, "origin": origin, "why": "robots.txt"})
            continue
        status, ctype, body, final = fetcher.get(url)
        if status != 200:
            failed.append({"url": url, "origin": origin, "why": str(status or ctype or "no answer")})
            continue
        if "html" not in ctype.lower() and not body.lstrip()[:15].lower().startswith((b"<!doctype", b"<html")):
            skipped.append({"url": url, "origin": origin, "why": "not an HTML page: %s" % (ctype.split(";")[0] or "unknown type")})
            continue
        parser = PageText()
        try:
            parser.feed(decode(body, ctype))
            parser.close()
        except Exception as e:  # a broken page must not stop the run
            failed.append({"url": url, "origin": origin, "why": "could not parse: %s" % e})
            continue
        for row in check_page(url, parser.locations(), facts, retired_phrases):
            row["origin"] = origin
            if final != url:
                row["final_url"] = final
            rows.append(row)
        read.append({"url": url, "origin": origin})
    return {
        "site": site,
        "date": _dt.date.today().isoformat(),
        "source": source,
        "pages_listed": len(pages),
        "read": read, "failed": failed, "skipped": skipped,
        "notes": notes, "rows": rows,
        "facts": facts, "retired_phrases": retired_phrases,
    }


def counts(result: dict) -> Dict[str, int]:
    c = {"OK": 0, "MISMATCH": 0, "OUTDATED": 0, "RETIRED": 0}
    for r in result["rows"]:
        c[r["status"]] += 1
    return c


def fmt_value(v: float) -> str:
    return "{:,}".format(int(v)) if float(v).is_integer() else ("%g" % v)


def report_md(result: dict) -> str:
    c = counts(result)
    rows = result["rows"]
    L: List[str] = []
    L.append("# Facts check: %s" % result["site"])
    L.append("")
    L.append("Run %s. Pages from %s: %d listed, %d read, %d could not be read, %d skipped."
             % (result["date"], result["source"], result["pages_listed"],
                sum(1 for p in result["read"] if p["origin"] == "own"),
                sum(1 for p in result["failed"] if p["origin"] == "own"),
                sum(1 for p in result["skipped"] if p["origin"] == "own")))
    if result["pages_listed"] == 0:
        L.append("")
        L.append("**No pages were found, so nothing was checked.** See the notes at the end.")
    L.append("")
    L.append("**%d mismatch%s, %d outdated value%s, %d retired phrase%s**, %d mention%s that match."
             % (c["MISMATCH"], "" if c["MISMATCH"] == 1 else "es",
                c["OUTDATED"], "" if c["OUTDATED"] == 1 else "s",
                c["RETIRED"], "" if c["RETIRED"] == 1 else "s",
                c["OK"], "" if c["OK"] == 1 else "s"))
    L.append("")
    L.append("| Fact | Approved | Match | Mismatch | Outdated | Pages naming it |")
    L.append("|---|---|---|---|---|---|")
    for f in result["facts"]:
        fr = [r for r in rows if r["kind"] == "fact" and r["fact"] == f["id"]]
        unit = f.get("unit", "")
        L.append("| %s | %s%s | %d | %d | %d | %d |" % (
            f.get("label") or f["id"], fmt_value(f["value"]), unit,
            sum(r["status"] == "OK" for r in fr), sum(r["status"] == "MISMATCH" for r in fr),
            sum(r["status"] == "OUTDATED" for r in fr), len({r["url"] for r in fr})))
    for title, status in (("Mismatches", "MISMATCH"), ("Outdated values", "OUTDATED")):
        hits = [r for r in rows if r["status"] == status]
        if not hits:
            continue
        L.append("")
        L.append("## %s" % title)
        for f in result["facts"]:
            fh = [r for r in hits if r["fact"] == f["id"]]
            if not fh:
                continue
            L.append("")
            L.append("### %s: approved %s%s" % (f.get("label") or f["id"], fmt_value(f["value"]), f.get("unit", "")))
            src = f.get("source", "")
            if src and not src.startswith("["):
                L.append("Source: %s." % src)
            for r in sorted(fh, key=lambda r: (r["origin"] != "own", r["url"], r["where"])):
                tag = "" if r["origin"] == "own" else " (not your site)"
                L.append("- %s%s, %s: found **%s**. \u201c%s\u201d"
                         % (r["url"], tag, r["where"], r["found"], r["snippet"]))
    ph = [r for r in rows if r["status"] == "RETIRED"]
    if ph:
        L.append("")
        L.append("## Retired phrases still in use")
        for r in sorted(ph, key=lambda r: (r["phrase"], r["origin"] != "own", r["url"])):
            tag = "" if r["origin"] == "own" else " (not your site)"
            note = (" (%s)" % r["note"]) if r.get("note") and not r["note"].startswith("[") else ""
            L.append("- \u201c%s\u201d%s on %s%s, %s: \u201c%s\u201d"
                     % (r["phrase"], note, r["url"], tag, r["where"], r["snippet"]))
    never = [f for f in result["facts"]
             if not any(r["kind"] == "fact" and r["fact"] == f["id"] for r in rows)]
    if never:
        L.append("")
        L.append("## Facts no page names")
        L.append("Either no page states them, or their terms do not match how the pages say it.")
        for f in never:
            L.append("- %s" % (f.get("label") or f["id"]))
    if result["failed"] or result["skipped"] or result["notes"]:
        L.append("")
        L.append("## Not checked")
        for p in result["failed"]:
            L.append("- %s: could not be read (%s)" % (p["url"], p["why"]))
        for p in result["skipped"]:
            L.append("- %s: skipped (%s)" % (p["url"], p["why"]))
        for n in result["notes"]:
            L.append("- %s" % n)
    L.append("")
    L.append("Read-only: this check changed nothing. Text that appears only after JavaScript runs is not seen.")
    return "\n".join(L) + "\n"


def append_history(path: str, result: dict) -> None:
    c = counts(result)
    new = not os.path.exists(path) or os.path.getsize(path) == 0
    with open(path, "a", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        if new:
            w.writerow(["date", "site", "pages_read", "pages_not_read", "mismatches",
                        "outdated", "retired_phrases", "matches"])
        w.writerow([result["date"], result["site"],
                    sum(1 for p in result["read"] if p["origin"] == "own"),
                    sum(1 for p in result["failed"] + result["skipped"] if p["origin"] == "own"),
                    c["MISMATCH"], c["OUTDATED"], c["RETIRED"], c["OK"]])


def main(argv: Optional[List[str]] = None, fetcher: Optional[Fetcher] = None) -> int:
    ap = argparse.ArgumentParser(description="Compare every figure on a live site with one list of approved facts. Read-only.")
    ap.add_argument("facts", help="the facts file (JSON)")
    ap.add_argument("--init", action="store_true", help="write a starter facts file at that path and stop")
    ap.add_argument("--out", default="", help="write the Markdown report here (default: print it)")
    ap.add_argument("--json", default="", help="also write the full result as JSON here")
    ap.add_argument("--history", default="", help="append one line of counts to this CSV (the weekly trend)")
    ap.add_argument("--max-pages", type=int, default=1000, help="read at most this many of the site's pages (default 1000)")
    ap.add_argument("--only", default="", help="only pages whose address contains this text, e.g. /en/")
    ap.add_argument("--delay", type=float, default=0.5, help="seconds between requests (default 0.5)")
    ap.add_argument("--timeout", type=float, default=20.0, help="seconds to wait for one page (default 20)")
    ap.add_argument("--ignore-robots", action="store_true",
                    help="read pages robots.txt disallows (only on a site you own)")
    a = ap.parse_args(argv)

    if a.init:
        if os.path.exists(a.facts):
            print("%s exists; not overwritten." % a.facts, file=sys.stderr)
            return 2
        with open(a.facts, "w", encoding="utf-8") as f:
            json.dump(STARTER, f, indent=2, ensure_ascii=False)
            f.write("\n")
        print("Wrote %s. Fill in the site, the facts and their sources, then run the check." % a.facts)
        return 0

    try:
        data = load_facts(a.facts)
    except FactsError as e:
        print(str(e), file=sys.stderr)
        return 2
    if a.max_pages < 1:
        print("--max-pages must be at least 1", file=sys.stderr)
        return 2

    result = run(data, a.max_pages, a.delay, a.timeout, a.only, not a.ignore_robots, fetcher)
    md = report_md(result)
    if a.out:
        with open(a.out, "w", encoding="utf-8") as f:
            f.write(md)
        print("Report written to %s" % a.out)
    else:
        sys.stdout.write(md)
    if a.json:
        with open(a.json, "w", encoding="utf-8") as f:
            json.dump(result, f, indent=2, ensure_ascii=False)
    if a.history:
        append_history(a.history, result)
    if result["pages_listed"] == 0 or not any(p["origin"] == "own" for p in result["read"]):
        print("No page of the site could be read; nothing was checked.", file=sys.stderr)
        return 2
    c = counts(result)
    return 1 if (c["MISMATCH"] or c["OUTDATED"] or c["RETIRED"]) else 0


if __name__ == "__main__":
    sys.exit(main())
