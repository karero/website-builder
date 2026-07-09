#!/usr/bin/env python3
"""
gsc_query.py — Phase 1 of the search-console-insights skill.

Pulls Google Search Console *Search Analytics* data (queries, pages, CTR,
average position) via the official API and writes a Markdown report that
surfaces the three highest-leverage things:

  1. Where each TARGET keyword currently ranks (or "not yet ranking").
  2. Striking-distance queries (avg position ~8-20) — the fastest Top-10 wins.
  3. High-impression / low-CTR pages — title & meta-description rewrite targets.

Read-only: it uses the `webmasters.readonly` scope and never writes to GSC.

Auth: OAuth "installed app" (desktop) flow. You download an OAuth client
once from Google Cloud Console (Desktop app type) as `client_secret.json`;
the first run opens a browser for consent and caches a refresh token at
~/.config/gsc-insights/token.json so later runs are non-interactive.

Usage:
  python gsc_query.py \
      --site sc-domain:example.com \
      --days 90 \
      --keywords "AI Events Munich,AI Meetups Munich,AI Treffen München" \
      --out report.md

Dependencies: see ../requirements.txt
"""

import argparse

from _lang_normalize import fold
import datetime as dt
import os
import sys
from pathlib import Path

SCOPES = ["https://www.googleapis.com/auth/webmasters.readonly"]
DEFAULT_TOKEN = Path.home() / ".config" / "gsc-insights" / "token.json"
ROW_LIMIT = 25000  # GSC max rows per request; plenty for a small site.

# Striking distance = ranking on roughly page 1-2 but not yet in the Top 10.
STRIKING_MIN, STRIKING_MAX = 8.0, 20.0
# A page in a good position that few people click = title/meta problem.
LOW_CTR_MAX_POSITION = 10.0
LOW_CTR_THRESHOLD = 0.02  # 2%
LOW_CTR_MIN_IMPRESSIONS = 20


def eprint(*a):
    print(*a, file=sys.stderr)


def load_credentials(client_secret: Path, token_path: Path, interactive: bool = True):
    """OAuth installed-app flow with a cached, auto-refreshed token.

    interactive=False NEVER opens a browser: if the token is missing/expired and a
    silent refresh isn't possible, it raises instead of launching a consent flow —
    so non-interactive callers (insights.py's combined view) can't hang on a browser."""
    try:
        from google.oauth2.credentials import Credentials
        from google.auth.transport.requests import Request
        from google_auth_oauthlib.flow import InstalledAppFlow
    except ImportError:
        eprint(
            "Missing dependencies. Install them (locally, one-time):\n"
            "  pip install -r requirements.txt"
        )
        sys.exit(2)

    creds = None
    if token_path.exists():
        creds = Credentials.from_authorized_user_file(str(token_path), SCOPES)

    if creds and creds.valid:
        return creds
    if creds and creds.expired and creds.refresh_token:
        creds.refresh(Request())
    elif not interactive:
        raise RuntimeError(
            "GSC token missing or expired and a silent refresh isn't possible — "
            "re-run the connect/onboarding step to re-consent.")
    else:
        if not client_secret.exists():
            eprint(
                f"OAuth client not found: {client_secret}\n"
                "Create one in Google Cloud Console → APIs & Services → Credentials →\n"
                "  Create credentials → OAuth client ID → Application type: Desktop app,\n"
                "then download it as client_secret.json (see SKILL.md, one-time setup)."
            )
            sys.exit(2)
        flow = InstalledAppFlow.from_client_secrets_file(str(client_secret), SCOPES)
        creds = flow.run_local_server(port=0)

    token_path.parent.mkdir(parents=True, exist_ok=True)
    token_path.write_text(creds.to_json())
    os.chmod(token_path, 0o600)
    return creds


def build_service(creds):
    try:
        from googleapiclient.discovery import build
    except ImportError:
        eprint("Missing google-api-python-client. Run: pip install -r requirements.txt")
        sys.exit(2)
    return build("searchconsole", "v1", credentials=creds, cache_discovery=False)


def query(service, site, start, end, dimensions, row_limit=ROW_LIMIT, country=""):
    body = {
        "startDate": start,
        "endDate": end,
        "dimensions": dimensions,
        "rowLimit": row_limit,
    }
    if country:
        # ISO-3166-1 alpha-3, lowercase (GSC convention), e.g. 'deu' for Germany.
        # Without this, a bilingual/German-market site reads BLENDED global
        # averages — German positions get masked by (or fake) other markets'.
        body["dimensionFilterGroups"] = [{
            "filters": [{"dimension": "country", "expression": country.lower()}],
        }]
    resp = service.searchanalytics().query(siteUrl=site, body=body).execute()
    return resp.get("rows", [])


def pct(x):
    return f"{x * 100:.1f}%"


def fmt_rows(rows, dim_label, limit=20):
    """rows: GSC rows with keys[0] = the dimension value."""
    out = [f"| {dim_label} | Clicks | Impr. | CTR | Avg pos |",
           "|---|---:|---:|---:|---:|"]
    for r in rows[:limit]:
        key = r["keys"][0]
        out.append(
            f"| {key} | {int(r['clicks'])} | {int(r['impressions'])} | "
            f"{pct(r['ctr'])} | {r['position']:.1f} |"
        )
    return "\n".join(out)


def match_keywords(query_rows, keywords):
    """Substring match each target keyword against query rows (folded).

    A keyword like 'AI Events Munich' should also catch 'ai events in munich',
    so we match on all whitespace-split tokens being present in the query.
    Tokens and rows are folded (casefold + German ä/ö/ü/ß) so 'AI Treffen
    München' matches GSC rows spelled 'ai treffen muenchen' and vice versa —
    they are distinct query strings in GSC but the same searcher intent.
    Returns list of (keyword, matched_rows_sorted_by_impressions).
    """
    results = []
    for kw in keywords:
        tokens = [t for t in fold(kw).split() if t]
        matched = [
            r for r in query_rows
            if all(t in fold(r["keys"][0]) for t in tokens)
        ]
        matched.sort(key=lambda r: r["impressions"], reverse=True)
        results.append((kw, matched))
    return results


def build_report(site, start, end, top_queries, top_pages, kw_matches,
                 perm_level, days):
    L = []
    L.append(f"# Search Console insights — {site}")
    L.append(f"\n_Window: {start} → {end} ({days} days). Permission: "
             f"{perm_level or 'unknown'}._\n")

    total_clicks = sum(int(r["clicks"]) for r in top_queries)
    total_impr = sum(int(r["impressions"]) for r in top_queries)

    # --- Honest emptiness check (Rule 12) ---------------------------------
    if not top_queries:
        L.append("> ⚠️ **No Search Analytics rows in this window.**\n>\n"
                 "> This is expected for a property verified recently — GSC only\n"
                 "> collects data *forward from verification*, with a ~2–3 day lag,\n"
                 "> and there is no historical backfill. Re-run this in 1–2 weeks.\n")
        return "\n".join(L)

    L.append(f"**Totals (across returned query rows):** {total_clicks} clicks, "
             f"{total_impr} impressions.\n")

    # --- Target keywords ---------------------------------------------------
    L.append("## Target keywords — where we stand\n")
    for kw, matched in kw_matches:
        if not matched:
            L.append(f"- **{kw}** — _no impressions yet_ (not surfacing in Google "
                     "for this term in this window).")
            continue
        best = matched[0]
        L.append(f"- **{kw}** — best match `{best['keys'][0]}`: "
                 f"avg position **{best['position']:.1f}**, "
                 f"{int(best['impressions'])} impr, {int(best['clicks'])} clicks, "
                 f"CTR {pct(best['ctr'])}"
                 + (f" _(+{len(matched) - 1} related variants)_"
                    if len(matched) > 1 else ""))
    L.append("")

    # --- Striking distance -------------------------------------------------
    striking = sorted(
        [r for r in top_queries
         if STRIKING_MIN <= r["position"] <= STRIKING_MAX and r["impressions"] > 0],
        key=lambda r: r["impressions"], reverse=True,
    )
    L.append("## Striking-distance queries (pos ~8–20 = fastest Top-10 wins)\n")
    if striking:
        L.append(fmt_rows(striking, "Query", limit=20))
    else:
        L.append("_None in range yet._")
    L.append("")

    # --- Low-CTR pages -----------------------------------------------------
    low_ctr = sorted(
        [r for r in top_pages
         if r["position"] <= LOW_CTR_MAX_POSITION
         and r["ctr"] < LOW_CTR_THRESHOLD
         and r["impressions"] >= LOW_CTR_MIN_IMPRESSIONS],
        key=lambda r: r["impressions"], reverse=True,
    )
    L.append("## Good position, low CTR — title/meta rewrite targets\n")
    if low_ctr:
        L.append(fmt_rows(low_ctr, "Page", limit=15))
        L.append("\n→ Hand these to `copywriting` (title) + `website-seo-geo` "
                 "(meta-description limits).")
    else:
        L.append("_None flagged (need pages ranking ≤10 with CTR <2% and ≥20 impr)._")
    L.append("")

    # --- Reference tables --------------------------------------------------
    L.append("## Top queries\n")
    L.append(fmt_rows(top_queries, "Query", limit=25))
    L.append("\n## Top pages\n")
    L.append(fmt_rows(top_pages, "Page", limit=25))
    L.append("")
    return "\n".join(L)


def main():
    ap = argparse.ArgumentParser(description="Pull GSC Search Analytics into a report.")
    ap.add_argument("--site", required=True,
                    help="Property, e.g. sc-domain:example.com or "
                         "https://example.com/")
    ap.add_argument("--days", type=int, default=90)
    ap.add_argument("--keywords", default="",
                    help="Comma-separated target keywords.")
    ap.add_argument("--out", default="", help="Write the Markdown report to this file.")
    ap.add_argument("--client-secret",
                    default=os.environ.get("GSC_CLIENT_SECRET", "client_secret.json"))
    ap.add_argument("--token", default=str(DEFAULT_TOKEN))
    ap.add_argument("--country", default="",
                    help="ISO-3166-1 alpha-3 country filter, e.g. 'deu' — see the "
                         "German-market note in SKILL.md. Default: all countries blended.")
    ap.add_argument("--csv", default="",
                    help="Append target-keyword positions to this history CSV (trend tracking).")
    args = ap.parse_args()

    creds = load_credentials(Path(args.client_secret), Path(args.token))
    service = build_service(creds)

    # Confirm access + capture permission level (proxy for "is this set up?").
    perm_level = None
    try:
        sites = service.sites().list().execute().get("siteEntry", [])
        for s in sites:
            if s.get("siteUrl") == args.site:
                perm_level = s.get("permissionLevel")
        if perm_level is None:
            eprint(f"Note: {args.site} not in your verified properties. "
                   "Check the --site value (sc-domain:… for a Domain property) "
                   "and that verification (search-console-setup) is done.")
    except Exception as e:  # noqa: BLE001 — surface, don't hide (Rule 12)
        eprint(f"Could not list sites (continuing): {e}")

    end = dt.date.today() - dt.timedelta(days=2)   # GSC lags ~2 days
    start = end - dt.timedelta(days=args.days)
    s_start, s_end = start.isoformat(), end.isoformat()

    try:
        top_queries = query(service, args.site, s_start, s_end, ["query"], country=args.country)
        top_pages = query(service, args.site, s_start, s_end, ["page"], country=args.country)
    except Exception as e:  # noqa: BLE001
        eprint(f"Search Analytics query failed: {e}")
        sys.exit(1)

    keywords = [k.strip() for k in args.keywords.split(",") if k.strip()]
    kw_matches = match_keywords(top_queries, keywords) if keywords else []

    if args.csv and kw_matches:
        import _history
        today = dt.date.today().isoformat()
        items = []
        for kw, matched in kw_matches:
            b = matched[0] if matched else None
            items.append({
                "date": today, "source": "gsc", "keyword": kw,
                "query": b["keys"][0] if b else "",
                "position": round(b["position"], 1) if b else "",
                "impressions": int(b["impressions"]) if b else 0,
                "clicks": int(b["clicks"]) if b else 0,
            })
        _history.append_rows(args.csv, items)
        eprint(f"appended {len(items)} keyword rows to {args.csv}")

    report = build_report(args.site, s_start, s_end, top_queries, top_pages,
                          kw_matches, perm_level, args.days)
    print(report)
    if args.out:
        Path(args.out).write_text(report)
        eprint(f"\nWrote {args.out}")


if __name__ == "__main__":
    main()
