#!/usr/bin/env python3
"""
_history.py — tiny append-only history + trend for the tracker.

gsc_query.py / bing_query.py call `append_rows()` with one row per target keyword
each run; `track.sh` (or `python _history.py <csv>`) prints the week-over-week
position movement. Position is "lower = better", so a DROP in the number is an
improvement (shown ▲). This is what turns the low-volume playbook's "track
position week-over-week" from a manual eyeball into one command.

CSV columns: date, source, keyword, query, position, impressions, clicks
"""
import csv
import collections
import os
import sys

FIELDS = ["date", "source", "keyword", "query", "position", "impressions", "clicks"]


def append_rows(csv_path, items):
    """Append rows (list of dicts keyed by FIELDS) — write the header if new."""
    csv_path = os.path.expanduser(csv_path)
    new = not os.path.exists(csv_path)
    os.makedirs(os.path.dirname(csv_path) or ".", exist_ok=True)
    with open(csv_path, "a", newline="") as f:
        w = csv.DictWriter(f, fieldnames=FIELDS)
        if new:
            w.writeheader()
        for it in items:
            w.writerow({k: it.get(k, "") for k in FIELDS})


def _pos(row):
    v = row.get("position", "")
    try:
        return float(v)
    except (TypeError, ValueError):
        return None


def print_trend(csv_path):
    csv_path = os.path.expanduser(csv_path)
    if not os.path.exists(csv_path):
        print("No history yet — this is the first run. Re-run in 1–2 weeks to see movement.")
        return
    with open(csv_path) as f:
        rows = list(csv.DictReader(f))
    groups = collections.defaultdict(list)
    for r in rows:
        src, kw = r.get("source"), r.get("keyword")
        if not src or not kw:
            continue  # skip a malformed/partial row instead of crashing the whole trend
        groups[(src, kw)].append(r)

    print(f"{'source':5}  {'keyword':30}  {'prev':>5}  {'now':>5}  move")
    print(f"{'-'*5}  {'-'*30}  {'-'*5}  {'-'*5}  {'-'*10}")
    for (src, kw), rs in sorted(groups.items()):
        rs.sort(key=lambda r: r.get("date", ""))
        now, prev = rs[-1], (rs[-2] if len(rs) > 1 else None)
        n, p = _pos(now), (_pos(prev) if prev else None)
        nf = f"{n:.1f}" if n is not None else "—"
        pf = f"{p:.1f}" if p is not None else "—"
        if prev is None:
            move = "(new)"
        elif n is not None and p is not None:
            d = p - n  # positive => position number went down => improved
            move = f"▲ +{d:.1f}" if d > 0.05 else (f"▼ {d:.1f}" if d < -0.05 else "→ 0")
        elif n is not None and p is None:
            move = "▲ now ranking"
        elif n is None and p is not None:
            move = "▼ dropped out"
        else:
            move = "—"
        print(f"{src:5}  {kw[:30]:30}  {pf:>5}  {nf:>5}  {move}")


if __name__ == "__main__":
    print_trend(sys.argv[1] if len(sys.argv) > 1 else "history.csv")
