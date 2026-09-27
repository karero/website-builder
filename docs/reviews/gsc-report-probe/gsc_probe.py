#!/usr/bin/env python3
"""Read-only probe of Search Console answers behind SKILL-PLAN-gsc-report.md ("Probe results").

Usage (with the skill's venv and your own sign-in):
    ~/.config/gsc-insights/venv/bin/python gsc_probe.py <domain> "<key search 1>,<key search 2>,..."
Prints facts only (counts, dates, yes/no): no query text at all; key searches appear by number."""
import datetime as dt
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[3] / "skills/search-console-insights/scripts"))
import gsc_query as g  # noqa: E402

CFG = Path.home() / ".config/gsc-insights"
SITE = "sc-domain:" + sys.argv[1]
KEYS = [k.strip() for k in sys.argv[2].split(",") if k.strip()]

creds = g.load_credentials(CFG / "client_secret.json", CFG / "token.json", interactive=False)
svc = g.build_service(creds)
today = dt.date.today()


def raw(body):
    return svc.searchanalytics().query(siteUrl=SITE, body=body).execute()


# 1. How far back, and the latest date, for ["date"] (default dataState = final data)
start = today - dt.timedelta(days=16 * 31 + 10)
r = raw({"startDate": start.isoformat(), "endDate": today.isoformat(), "dimensions": ["date"], "rowLimit": 25000})
rows = r.get("rows", [])
dates = sorted(x["keys"][0] for x in rows)
print(f"[1] date rows={len(rows)} requested_from={start} first={dates[0] if dates else None} last={dates[-1] if dates else None} today={today}")
if dates:
    d0, d1 = dt.date.fromisoformat(dates[0]), dt.date.fromisoformat(dates[-1])
    span = (d1 - d0).days + 1
    print(f"    span_days={span} missing_days_inside={span - len(dates)} months_back~={(today - d0).days / 30.4:.1f} lag_days={(today - d1).days}")
print(f"    response keys: {sorted(r.keys())}")

# 2. Freshness: dataState "all" (includes fresh, not-final data) and any metadata it returns
r2 = raw({"startDate": (today - dt.timedelta(days=10)).isoformat(), "endDate": today.isoformat(),
          "dimensions": ["date"], "dataState": "all"})
d2 = sorted(x["keys"][0] for x in r2.get("rows", []))
print(f"[2] dataState=all last={d2[-1] if d2 else None}; response keys: {sorted(r2.keys())}; metadata={r2.get('metadata')}")

# 3. Are queries reported in lowercase?
q = raw({"startDate": (today - dt.timedelta(days=90)).isoformat(), "endDate": today.isoformat(),
         "dimensions": ["query"], "rowLimit": 5000}).get("rows", [])
upper = sum(1 for x in q if x["keys"][0] != x["keys"][0].lower())
print(f"[3] query rows (90d)={len(q)} with_uppercase={upper}")

# 4. Exact match: does case matter? Compare the returned rows themselves (keys and numbers).
start3 = (today - dt.timedelta(days=92)).isoformat()


def key_rows(text):
    body = {"startDate": start3, "endDate": today.isoformat(), "dimensions": ["date", "query"],
            "dimensionFilterGroups": [{"groupType": "and", "filters": [
                {"dimension": "query", "operator": "equals", "expression": text}]}], "rowLimit": 25000}
    return raw(body).get("rows", [])


nonempty = []
for n, k in enumerate(KEYS, 1):
    lo, ti, up = key_rows(k.lower()), key_rows(k.title()), key_rows(k.upper())
    same = lo == ti == up
    returned = sorted({r["keys"][1] for r in lo})
    lower_keys = all(q == q.lower() for q in returned)
    print(f"[4] key#{n}: rows={len(lo)} lower==Title==UPPER (keys+metrics): {same}; returned query lowercase: {lower_keys}")
    if lo:
        nonempty.append(k.lower())

# 5. Two key searches that EACH return rows, combined in one AND group
if len(nonempty) >= 2:
    a, b = nonempty[:2]
    body = {"startDate": start3, "endDate": today.isoformat(), "dimensions": ["date", "query"],
            "dimensionFilterGroups": [{"groupType": "and", "filters": [
                {"dimension": "query", "operator": "equals", "expression": a},
                {"dimension": "query", "operator": "equals", "expression": b}]}]}
    print(f"[5] two key searches with data on their own ({len(key_rows(a))} and {len(key_rows(b))} rows), "
          f"combined in one AND group: rows={len(raw(body).get('rows', []))}")
else:
    print("[5] fewer than two key searches with data; the AND test needs two")

# 6. Anonymized-query gap: property total vs sum over query rows (same 90 days)
tot = raw({"startDate": (today - dt.timedelta(days=90)).isoformat(), "endDate": today.isoformat()}).get("rows", [])
t_imp = tot[0]["impressions"] if tot else 0
q_imp = sum(x["impressions"] for x in q)
print(f"[6] 90d impressions: property={t_imp:.0f} sum_of_query_rows={q_imp:.0f} share_not_in_query_rows={(1 - q_imp / t_imp) if t_imp else 0:.0%}")
