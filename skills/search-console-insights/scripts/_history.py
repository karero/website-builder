#!/usr/bin/env python3
"""
_history.py — tiny append-only history + trend for the tracker.

gsc_query.py / bing_query.py call `append_rows()` with one row per target keyword
each run; `track.sh` (or `python _history.py <csv>`) prints the week-over-week
position movement. Position is "lower = better", so a DROP in the number is an
improvement (shown ▲). This is what turns the low-volume playbook's "track
position week-over-week" from a manual eyeball into one command.

CSV columns: date, source, keyword, query, position, impressions, clicks,
window, country. The last two record the pull's configuration so the trend
can flag a move that compares two different configs; they were appended to
the schema (2026-08-29). append_rows() migrates an older-header CSV in
place before appending — without that, the extra columns land past the old
header and DictReader silently drops them, killing the flag for exactly
the histories the window change affects.
"""
import csv
import collections
import os
import sys

FIELDS = ["date", "source", "keyword", "query", "position", "impressions", "clicks",
          "window", "country"]


def append_rows(csv_path, items):
    """Append rows (list of dicts keyed by FIELDS) — write the header if new.

    An existing file carrying the ONE legacy 7-column header this tool ever
    wrote is migrated first (full header rewritten, legacy rows padded with
    empty values, via a temp file + atomic replace) — read with utf-8-sig so
    a BOM from a spreadsheet re-save can't break the header match. A legacy
    row's blank config then genuinely differs from a new row's recorded
    config, so the trend's ‡ flag fires on the first post-migration
    comparison instead of being silently dead. Any OTHER unrecognized header
    is left untouched (never rewritten — it isn't ours to reshape) with a
    stderr note; a zero-byte file counts as new."""
    csv_path = os.path.expanduser(csv_path)
    new = not os.path.exists(csv_path) or os.path.getsize(csv_path) == 0
    os.makedirs(os.path.dirname(csv_path) or ".", exist_ok=True)
    if not new:
        with open(csv_path, newline="", encoding="utf-8-sig") as f:
            header = next(csv.reader(f), None)
        if header == FIELDS[:7]:
            with open(csv_path, newline="", encoding="utf-8-sig") as f:
                old_rows = list(csv.DictReader(f))
            tmp = csv_path + ".tmp"
            with open(tmp, "w", newline="") as f:
                w = csv.DictWriter(f, fieldnames=FIELDS, extrasaction="ignore")
                w.writeheader()
                for old in old_rows:
                    w.writerow({k: (old.get(k) or "") for k in FIELDS})
            os.replace(tmp, csv_path)
        elif header != FIELDS:
            print(f"note: unrecognized history header in {csv_path} — file left "
                  f"as-is; the appended config columns may not be readable there",
                  file=sys.stderr)
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


def _impr(row):
    """Parsed impressions, or None when the cell is blank/absent/garbled —
    None must stay distinct from a genuine 0 so legacy rows without a value
    never earn the thin-noise marker by coercion."""
    v = row.get("impressions", "")
    try:
        return int(str(v).strip())
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

    legend = {}
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
        # A "movement" that compares two DIFFERENT matched queries, or leans on
        # a handful of impressions on EITHER side, is not a rank change — mark
        # it so the arrow can't be over-read (the "AI Resources dropped -3.1"
        # class of misread: the matcher had switched queries, on 2-5
        # impressions). min() over the position-bearing sides, not max(): a
        # fat-prev/thin-now move is exactly the case the marker exists for.
        q_now, q_prev = (now.get("query") or ""), ((prev or {}).get("query") or "")
        if prev is not None and q_now and q_prev and q_now != q_prev:
            move += " ≠"
            legend["≠"] = ("≠ best-matching query changed between runs — "
                           "not the same query's movement")
        imprs = [i for i in (_impr(r) for r in (now, prev)
                             if r is not None and _pos(r) is not None)
                 if i is not None]
        if prev is not None and imprs and min(imprs) < 10:
            move += " ~"
            legend["~"] = ("~ a compared side has under 10 impressions — "
                           "movement is noise at this volume")
        cfg_now = (now.get("window") or "", now.get("country") or "")
        cfg_prev = (((prev or {}).get("window")) or "", ((prev or {}).get("country")) or "")
        # Unequal tuples imply at least one non-empty side, so inequality
        # alone is the whole test — an unknown (legacy-blank) config vs a
        # recorded one deliberately counts as a change.
        if prev is not None and cfg_now != cfg_prev:
            move += " ‡"
            legend["‡"] = ("‡ the tracked window/country changed — or the earlier "
                           "row predates the config columns (previously "
                           "unrecorded); positions not comparable across it")
        if src == "bing" and prev is not None:
            legend["bing"] = ("bing rows: positions are ~6-month aggregates — "
                              "week-over-week moves are damped and lag")
        print(f"{src:5}  {kw[:30]:30}  {pf:>5}  {nf:>5}  {move}")
    for note in legend.values():
        print(f"  {note}")


if __name__ == "__main__":
    print_trend(sys.argv[1] if len(sys.argv) > 1 else "history.csv")
