#!/usr/bin/env python3
"""
bing_query.py — Bing Webmaster Tools companion to gsc_query.py.

Bing's index feeds Microsoft Copilot and ChatGPT search, so this is a useful
proxy for AI-assistant visibility — and it's FAR simpler to connect than Google:
one API key, no OAuth, no browser. Volume is much smaller than Google for niche
local queries, so treat Bing as a secondary signal, not the headline.

Auth (one-time, ~2 min): Bing Webmaster Tools → Settings → **API Access** →
generate an API key → put it in the env as BING_API_KEY (or pass --api-key).
The same `~/.config/gsc-insights/.env` the Serper key lives in is a fine home.

Endpoint: GetQueryStats returns ONE aggregate row per query over Bing's last
~6 months (Bing accepts no start/end dates — so there is no --days here).

Usage:
  export BING_API_KEY=...
  python bing_query.py --site https://example.com \
     --keywords "AI Events Munich,AI Meetups Munich,AI Treffen München" --out bing.md

Dependencies: requests (see ../requirements.txt)
"""

import argparse
import os
import sys
from pathlib import Path

from _lang_normalize import fold

try:
    import requests
except ImportError:
    print("Missing 'requests'. Run: pip install -r requirements.txt", file=sys.stderr)
    sys.exit(2)

API = "https://ssl.bing.com/webmaster/api.svc/json"
# Striking distance = ranking on roughly page 1-2 but not yet Top 10.
STRIKING_MIN, STRIKING_MAX = 8.0, 20.0


def eprint(*a):
    print(*a, file=sys.stderr)


def pct(x):
    return f"{x * 100:.1f}%"


def get_query_stats(site, key):
    """GetQueryStats → normalized rows. Bing wraps the list under the `d` node."""
    r = requests.get(f"{API}/GetQueryStats",
                     params={"apikey": key, "siteUrl": site}, timeout=30)
    r.raise_for_status()
    rows = r.json().get("d", []) or []
    # Bing can return MORE than one row per query (observed live — e.g. per-date or
    # per-market buckets), so fold to one row per query: sum clicks/impressions and
    # impression-weight the average position (matches how GSC aggregates a period).
    agg = {}
    for it in rows:
        q = it.get("Query", "")
        impr = it.get("Impressions", 0) or 0
        clicks = it.get("Clicks", 0) or 0
        pos = it.get("AvgImpressionPosition", 0) or 0
        a = agg.setdefault(q, {"query": q, "impressions": 0, "clicks": 0, "_pw": 0.0})
        a["impressions"] += impr
        a["clicks"] += clicks
        a["_pw"] += pos * impr
    out = []
    for a in agg.values():
        impr = a["impressions"]
        if impr <= 0:
            continue  # 0 impressions → a 0/0 "position 0.0" would read as better-than-#1
        out.append({
            "query": a["query"],
            "impressions": impr,
            "clicks": a["clicks"],
            "position": a["_pw"] / impr,
            "ctr": a["clicks"] / impr,
        })
    return out


def fmt(rows, limit=20, key="query", label="Query"):
    L = [f"| {label} | Clicks | Impr. | CTR | Avg pos |", "|---|---:|---:|---:|---:|"]
    for r in rows[:limit]:
        L.append(f"| {r[key]} | {int(r['clicks'])} | {int(r['impressions'])} | "
                 f"{pct(r['ctr'])} | {r['position']:.1f} |")
    return "\n".join(L)


def get_page_stats(site, key):
    """GetPageStats — Bing reuses the QueryStats schema, so the PAGE URL lives in the
    `Query` field (Page/Url come back null). Aggregate by URL like get_query_stats."""
    r = requests.get(f"{API}/GetPageStats",
                     params={"apikey": key, "siteUrl": site}, timeout=30)
    r.raise_for_status()
    rows = r.json().get("d", []) or []
    agg = {}
    for it in rows:
        url = it.get("Query", "")  # the URL is in Query for GetPageStats
        impr = it.get("Impressions", 0) or 0
        clicks = it.get("Clicks", 0) or 0
        pos = it.get("AvgImpressionPosition", 0) or 0
        a = agg.setdefault(url, {"page": url, "impressions": 0, "clicks": 0, "_pw": 0.0})
        a["impressions"] += impr
        a["clicks"] += clicks
        a["_pw"] += pos * impr
    out = []
    for a in agg.values():
        impr = a["impressions"]
        if impr <= 0:
            continue  # skip 0-impression pages (phantom position 0.0)
        out.append({"page": a["page"], "impressions": impr, "clicks": a["clicks"],
                    "position": a["_pw"] / impr,
                    "ctr": a["clicks"] / impr})
    return out


def match_keywords(rows, keywords):
    """Substring (token-AND, folded) match — mirrors gsc_query.py, incl. the
    German umlaut/ß folding ('München' matches rows spelled 'muenchen')."""
    res = []
    for kw in keywords:
        toks = [t for t in fold(kw).split() if t]
        m = [r for r in rows if all(t in fold(r["query"]) for t in toks)]
        m.sort(key=lambda r: r["impressions"], reverse=True)
        res.append((kw, m))
    return res


def build_report(site, rows, kw_matches, page_rows=None):
    page_rows = page_rows or []
    L = [f"# Bing Webmaster insights — {site}", "",
         "_Bing aggregates the last ~6 months (no date range). Volume is much smaller "
         "than Google, but Bing's index feeds Copilot/ChatGPT._", ""]
    if not rows:
        L.append("> ⚠️ **No Bing query rows.** Either the site is newly added, has little "
                 "Bing traffic yet, or the API key / siteUrl is wrong. Confirm the property "
                 "is verified in Bing Webmaster Tools and that `--site` is the exact URL "
                 "registered there (https, trailing slash as shown in Bing).")
        return "\n".join(L)

    tot_c = sum(int(r["clicks"]) for r in rows)
    tot_i = sum(int(r["impressions"]) for r in rows)
    L.append(f"**Totals:** {tot_c} clicks, {tot_i} impressions across {len(rows)} queries.\n")

    L.append("## Target keywords — where we stand on Bing\n")
    for kw, m in kw_matches:
        if not m:
            L.append(f"- **{kw}** — _no Bing impressions_.")
            continue
        b = m[0]
        L.append(f"- **{kw}** — `{b['query']}`: avg position **{b['position']:.1f}**, "
                 f"{int(b['impressions'])} impr, {int(b['clicks'])} clicks, CTR {pct(b['ctr'])}"
                 + (f" _(+{len(m) - 1} related)_" if len(m) > 1 else ""))
    L.append("")

    striking = sorted(
        [r for r in rows if STRIKING_MIN <= r["position"] <= STRIKING_MAX and r["impressions"] > 0],
        key=lambda r: r["impressions"], reverse=True,
    )
    L.append("## Striking-distance queries on Bing (pos ~8–20)\n")
    L.append(fmt(striking, 20) if striking else "_None in range._")

    # Good-position-but-no-clicks pages (Bing's volume is tiny, so the bar is low).
    seen_unclicked = sorted(
        [r for r in page_rows if r["position"] <= 10 and r["clicks"] == 0 and r["impressions"] >= 2],
        key=lambda r: r["impressions"], reverse=True,
    )
    L.append("\n## Pages seen on Bing but not clicked (title/snippet targets)\n")
    L.append(fmt(seen_unclicked, 15, key="page", label="Page") if seen_unclicked
             else "_None (need a page ranking ≤10 with 0 clicks and ≥2 impressions)._")

    L.append("\n## Top Bing queries\n")
    L.append(fmt(sorted(rows, key=lambda r: r["impressions"], reverse=True), 25))
    if page_rows:
        L.append("\n## Top Bing pages\n")
        L.append(fmt(sorted(page_rows, key=lambda r: r["impressions"], reverse=True), 15,
                     key="page", label="Page"))
    L.append("")
    return "\n".join(L)


def main():
    ap = argparse.ArgumentParser(description="Pull Bing Webmaster query stats into a report.")
    ap.add_argument("--site", required=True,
                    help="Verified Bing site URL, e.g. https://example.com")
    ap.add_argument("--keywords", default="", help="Comma-separated target keywords.")
    ap.add_argument("--out", default="", help="Write the Markdown report to this file.")
    ap.add_argument("--api-key", default=os.environ.get("BING_API_KEY", ""))
    ap.add_argument("--csv", default="",
                    help="Append target-keyword positions to this history CSV (trend tracking).")
    args = ap.parse_args()

    if not args.api_key:
        eprint("No BING_API_KEY set — skipping Bing (the GSC Phase 1 data is unaffected).\n"
               "Get a key: Bing Webmaster Tools → Settings → API Access → generate, then:\n"
               "  export BING_API_KEY=...   (or add it to ~/.config/gsc-insights/.env)")
        sys.exit(3)

    try:
        rows = get_query_stats(args.site, args.api_key)
    except Exception as e:  # noqa: BLE001 — surface, don't hide (Rule 12)
        eprint(f"Bing API call failed: {e}")
        sys.exit(1)
    try:
        page_rows = get_page_stats(args.site, args.api_key)
    except Exception as e:  # noqa: BLE001 — pages are a bonus; degrade, don't abort
        eprint(f"Bing GetPageStats failed (continuing without page stats): {e}")
        page_rows = []

    keywords = [k.strip() for k in args.keywords.split(",") if k.strip()]
    kw_matches = match_keywords(rows, keywords) if keywords else []

    if args.csv and kw_matches:
        import datetime as _dt
        import _history
        today = _dt.date.today().isoformat()
        items = []
        for kw, matched in kw_matches:
            b = matched[0] if matched else None
            items.append({
                "date": today, "source": "bing", "keyword": kw,
                "query": b["query"] if b else "",
                "position": round(b["position"], 1) if b else "",
                "impressions": int(b["impressions"]) if b else 0,
                "clicks": int(b["clicks"]) if b else 0,
            })
        _history.append_rows(args.csv, items)
        eprint(f"appended {len(items)} keyword rows to {args.csv}")

    report = build_report(args.site, rows, kw_matches, page_rows)
    print(report)
    if args.out:
        Path(args.out).write_text(report)
        eprint(f"\nWrote {args.out}")


if __name__ == "__main__":
    main()
