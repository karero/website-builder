#!/usr/bin/env python3
"""Mock-up of the Google & Bing report page — INVENTED numbers for a fictional bakery.
Self-contained HTML, inline SVG, no JavaScript (plan D5). Writes mockup.html next to itself."""
import datetime as dt
import html
import math
import random
from pathlib import Path

random.seed(7)
H = html.escape
SITE = "sunrise-bakery.example"
TODAY = dt.date(2026, 10, 12)

# ---- invented data ---------------------------------------------------------------------------
weeks70 = [TODAY - dt.timedelta(weeks=69 - i) for i in range(70)]
visitors, shown = [], []
for i, w in enumerate(weeks70):
    trend = 38 + i * 0.9
    season = 12 * math.sin((w.timetuple().tm_yday / 365) * 2 * math.pi - 1.2)
    visitors.append(max(5, round(trend + season + random.uniform(-7, 7))))
    shown.append(max(200, round((trend + season) * 31 + random.uniform(-250, 250))))
visitors[-4:] = [98, 101, 104, 109]      # last 4 weeks = 412
visitors[-8:-4] = [84, 86, 88, 91]       # previous 4 weeks = 349 -> +18%

weeks13 = weeks70[-13:]
KEY = [
    # name, positions (13 weeks), low-data weeks (index), config change at index or None
    ("bakery near the station", [14.2, 13.8, 13.1, 12.6, 12.9, 11.8, 11.1, 10.4, 9.9, 9.2, 8.8, 8.3, 8.1], set(), None),
    ("sourdough bread old town", [6.4, 6.1, 6.3, 5.8, 5.5, 5.6, 5.1, 4.9, 4.6, 4.5, 4.2, 4.1, 4.0], set(), None),
    ("breakfast café old town", [12.3, 12.0, 11.7, 11.9, 11.2, 10.8, 10.9, 9.1, 8.4, 7.9, 7.6, 7.2, 6.9], set(), 7),
    ("gluten-free bread", [9.1, 9.0, 9.3, 9.6, 9.4, 9.8, 10.1, 10.3, 10.0, 10.6, 10.9, 11.0, 11.2], set(), None),
    ("birthday cake order", [19.4, 21.0, 18.8, 19.9, 20.4, 19.1, 18.7, 19.6, 20.2, 19.0, 18.9, 19.5, 19.3], {1, 4, 8}, None),
]
ALMOST = [("fresh croissants old town", 11.2, 340, "/menu/"),
          ("bakery open on sunday", 13.4, 510, "/opening-hours/")]
WORTH_A_LOOK = [("/cakes/", 900, 3), ("/about/", 620, 5)]

# ---- chart helpers ---------------------------------------------------------------------------
PT, PB = 14, 26
# Two drawings per chart: wide for screens >= 560px, narrow for phones, swapped by a media
# query. An SVG scales its text with its width, so one drawing is either tiny on a phone or
# huge on a desktop; no script is needed to pick one.
SIZES = {"wide": (640, 44, 104, 2), "narrow": (340, 34, 58, 4)}


def month_ticks(weeks):
    out, seen = [], set()
    for i, w in enumerate(weeks):
        key = (w.year, w.month)
        if key not in seen and w.day <= 7:
            seen.add(key)
            out.append((i, w.strftime("%b") if w.month != 1 else w.strftime("%b %Y")))
    return out


def nice_max(v):
    """Smallest 1/2/2.5/5 x 10^k at or above v, so the line fills the chart."""
    mag = 10 ** math.floor(math.log10(v))
    for m in (1, 1.2, 1.5, 2, 2.5, 3, 4, 5, 6, 8, 10):
        if m * mag >= v:
            return int(m * mag)


def line_chart(values, weeks, label_fmt, title, h=190):
    return "".join(_line_chart(values, weeks, label_fmt, title, h, k) for k in SIZES)


def _line_chart(values, weeks, label_fmt, title, h, size):
    W, PL, PR, every = SIZES[size]
    top = nice_max(max(values))
    iw, ih = W - PL - PR, h - PT - PB
    x = lambda i: PL + iw * i / (len(values) - 1)
    y = lambda v: PT + ih * (1 - v / top)
    g = []
    for t in (0, top // 2, top):
        g.append(f'<line class="grid" x1="{PL}" x2="{W - PR}" y1="{y(t):.1f}" y2="{y(t):.1f}"/>'
                 f'<text class="tick" x="{PL - 6}" y="{y(t) + 4:.1f}" text-anchor="end">{t:,}</text>')
    for i, lab in month_ticks(weeks)[::every]:
        g.append(f'<text class="tick" x="{x(i):.1f}" y="{h - 6}" text-anchor="middle">{lab}</text>')
    pts = " ".join(f"{x(i):.1f},{y(v):.1f}" for i, v in enumerate(values))
    g.append(f'<polyline class="line" points="{pts}"/>')
    for i, (w, v) in enumerate(zip(weeks, values)):   # native tooltips, no script
        g.append(f'<circle class="hit" cx="{x(i):.1f}" cy="{y(v):.1f}" r="7"><title>week of {w:%d %b %Y}: {label_fmt(v)}</title></circle>')
    lx, ly = x(len(values) - 1), y(values[-1])
    g.append(f'<circle class="dot" cx="{lx:.1f}" cy="{ly:.1f}" r="4"/>'
             f'<text class="endlabel" x="{lx + 10:.1f}" y="{ly + 4:.1f}">{label_fmt(values[-1])}</text>')
    return (f'<svg class="{size}" viewBox="0 0 {W} {h}" role="img" aria-label="{H(title)}">'
            f'<title>{H(title)}</title>{"".join(g)}</svg>')


# One scale for every key-search chart (small multiples): the same slope means the same move.
POS_HI = max(10, int(math.ceil(max(max(p) for _, p, _, _ in KEY) / 5.0) * 5))


def position_chart(name, pos, low, change, h=150):
    return "".join(_position_chart(name, pos, low, change, h, k) for k in SIZES)


def _position_chart(name, pos, low, change, h, size):
    W, PL, PR, every = SIZES[size]
    lo, hi = 1, POS_HI
    iw, ih = W - PL - PR, h - PT - PB
    x = lambda i: PL + iw * i / (len(pos) - 1)
    y = lambda p: PT + ih * (p - lo) / (hi - lo)            # position 1 at the TOP
    g = []
    ticks = {1, 10} | ({20} if hi >= 20 else set())
    if hi - max(ticks) >= 10:
        ticks.add(hi)
    for t in sorted(ticks):
        cls = "grid strong" if t == 10 else "grid"
        g.append(f'<line class="{cls}" x1="{PL}" x2="{W - PR}" y1="{y(t):.1f}" y2="{y(t):.1f}"/>'
                 f'<text class="tick" x="{PL - 6}" y="{y(t) + 4:.1f}" text-anchor="end">{t}</text>')
    for i, lab in month_ticks(weeks13)[::max(1, every // 2)]:
        g.append(f'<text class="tick" x="{x(i):.1f}" y="{h - 6}" text-anchor="middle">{lab}</text>')
    segs = [range(0, change), range(change, len(pos))] if change else [range(len(pos))]
    for seg in segs:
        pts = " ".join(f"{x(i):.1f},{y(pos[i]):.1f}" for i in seg)
        g.append(f'<polyline class="line" points="{pts}"/>')
    if change:
        cx = (x(change - 1) + x(change)) / 2
        g.append(f'<line class="mark" x1="{cx:.1f}" x2="{cx:.1f}" y1="{PT}" y2="{h - PB}"/>'
                 f'<text class="tick" x="{cx + 4:.1f}" y="{PT + 10}">‡ {"measured differently from here" if size == "wide" else "changed"}</text>')
    for i, p in enumerate(pos):
        tip = f"week of {weeks13[i]:%d %b}: position {p:.1f}" + (" — too few searches to tell" if i in low else "")
        cls = "hollow" if i in low else "hit"
        r = 4 if i in low else 7
        g.append(f'<circle class="{cls}" cx="{x(i):.1f}" cy="{y(p):.1f}" r="{r}"><title>{tip}</title></circle>')
    lx, ly = x(len(pos) - 1), y(pos[-1])
    g.append(f'<circle class="dot" cx="{lx:.1f}" cy="{ly:.1f}" r="4"/>'
             f'<text class="endlabel" x="{lx + 10:.1f}" y="{ly + 4:.1f}">{pos[-1]:.0f}</text>')
    return (f'<svg class="{size}" viewBox="0 0 {W} {h}" role="img" aria-label="Position over 3 months for {H(name)}">'
            f'<title>Position over 3 months: {H(name)}</title>{"".join(g)}</svg>')


def numbers_table(headers, rows):
    head = "".join(f"<th>{H(h)}</th>" for h in headers)
    body = "".join("<tr>" + "".join(f"<td>{H(str(c))}</td>" for c in r) + "</tr>" for r in rows)
    return f'<details><summary>See the numbers</summary><table><tr>{head}</tr>{body}</table></details>'


def movement(pos, change):
    first = pos[change] if change else pos[0]
    d = round(first) - round(pos[-1])
    if d >= 1:
        return f"{first:.0f} → {pos[-1]:.0f}, up {d} place{'s' if d > 1 else ''}", "up"
    if d <= -1:
        return f"{first:.0f} → {pos[-1]:.0f}, down {-d} place{'s' if d < -1 else ''}", "down"
    return f"about {pos[-1]:.0f}, no clear change", "flat"


# ---- page ------------------------------------------------------------------------------------
last4, prev4 = sum(visitors[-4:]), sum(visitors[-8:-4])
moved_up = sum(1 for _, p, _, c in KEY if movement(p, c)[1] == "up")
headline = (f"{last4} people came from Google in the last 4 weeks, "
            f"{round((last4 - prev4) / prev4 * 100)}% more than the 4 weeks before. "
            f"{moved_up} of your {len(KEY)} key searches moved up.")

cards = []
for name, pos, low, change in KEY:
    text, _ = movement(pos, change)
    rows = [(f"{w:%d %b}", f"{p:.1f}" + (" (too few searches)" if i in low else ""))
            for i, (w, p) in enumerate(zip(weeks13, pos))]
    note = ""
    if low:
        note = '<p class="note"><svg class="key" viewBox="0 0 12 12"><circle class="hollow" cx="6" cy="6" r="4"/></svg> hollow point: too few searches that week to tell a move</p>'
    if change:
        note += '<p class="note">‡ You changed which country is counted here, so the line is broken: the two parts are not compared.</p>'
    cards.append(f'<section class="card"><h3>“{H(name)}”</h3><p class="move">{H(text)}</p>'
                 f'{position_chart(name, pos, low, change)}{note}'
                 f'{numbers_table(["Week", "Position"], rows)}</section>')

vis_rows = [(f"{w:%d %b %Y}", v) for w, v in zip(weeks70, visitors)]
shown_rows = [(f"{w:%d %b %Y}", f"{v:,}") for w, v in zip(weeks70, shown)]

page = f"""<!doctype html>
<html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Google report — {SITE}</title>
<style>
:root {{ color-scheme: light; --bg:#fcfcfb; --card:#ffffff; --ink:#0b0b0b; --ink2:#52514e; --muted:#898781;
  --grid:#e1e0d9; --line:#2a78d6; --border:#e1e0d9; }}
@media (prefers-color-scheme: dark) {{ :root:not([data-theme="light"]) {{ color-scheme: dark; --bg:#1a1a19;
  --card:#222220; --ink:#ffffff; --ink2:#c3c2b7; --muted:#898781; --grid:#2c2c2a; --line:#3987e5; --border:#33332f; }} }}
:root[data-theme="dark"] {{ color-scheme: dark; --bg:#1a1a19; --card:#222220; --ink:#ffffff; --ink2:#c3c2b7;
  --muted:#898781; --grid:#2c2c2a; --line:#3987e5; --border:#33332f; }}
* {{ box-sizing: border-box; }}
body {{ margin:0; background:var(--bg); color:var(--ink); font:16px/1.5 -apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif; }}
main {{ max-width:760px; margin:0 auto; padding:24px 16px 48px; }}
h1 {{ font-size:1.5rem; margin:0 0 4px; }} h2 {{ font-size:1.2rem; margin:32px 0 8px; }} h3 {{ font-size:1rem; margin:0; }}
.sub {{ color:var(--ink2); margin:0 0 20px; }}
.answer {{ font-size:1.3rem; line-height:1.4; font-weight:600; background:var(--card); border:1px solid var(--border);
  border-radius:12px; padding:16px 18px; margin:0 0 12px; }}
.mock {{ border:1px dashed var(--muted); color:var(--ink2); border-radius:8px; padding:8px 12px; font-size:.9rem; }}
.card {{ background:var(--card); border:1px solid var(--border); border-radius:12px; padding:14px 16px; margin:12px 0; }}
.move {{ color:var(--ink2); margin:2px 0 6px; }}
.note {{ color:var(--ink2); font-size:.9rem; margin:6px 0 0; }}
svg {{ width:100%; height:auto; display:block; overflow:visible; }}
svg.narrow {{ display:none; }}
@media (max-width: 559px) {{ svg.wide {{ display:none; }} svg.narrow {{ display:block; }} }}
.grid {{ stroke:var(--grid); stroke-width:1; }} .grid.strong {{ stroke:var(--muted); stroke-opacity:.5; }}
.tick {{ fill:var(--muted); font-size:11px; }} .tick.faint {{ font-size:10px; }}
.line {{ fill:none; stroke:var(--line); stroke-width:2; stroke-linejoin:round; stroke-linecap:round; }}
.dot {{ fill:var(--line); stroke:var(--card); stroke-width:2; }}
.hit {{ fill:transparent; }} .hollow {{ fill:var(--card); stroke:var(--line); stroke-width:2; }}
.mark {{ stroke:var(--muted); stroke-width:1; }}
.endlabel {{ fill:var(--ink); font-size:12px; font-weight:600; }}
svg.key {{ width:12px; height:12px; display:inline-block; vertical-align:-1px; }}
details {{ margin-top:8px; font-size:.9rem; }} summary {{ cursor:pointer; color:var(--ink2); }}
table {{ border-collapse:collapse; width:100%; margin-top:8px; font-variant-numeric:tabular-nums; }}
th, td {{ text-align:left; padding:6px 8px; border-bottom:1px solid var(--border); }} th {{ color:var(--ink2); font-weight:600; }}
.plain th, .plain td {{ font-size:.95rem; }}
</style></head><body><main>
<p class="mock">Mock-up with invented numbers for a fictional bakery — not real data.</p>
<h1>How people find you on Google</h1>
<p class="sub">{SITE} · updated {TODAY:%d %B %Y}</p>
<p class="answer">{H(headline)}</p>
<details><summary>How to read this</summary>
<p><b>Came from Google</b> counts people who clicked through to your site from a Google search. <b>Shown</b> counts how
often your site appeared in someone's results, whether or not they clicked. <b>Position</b> is where you appeared:
1 is the very top, and positions 1–10 are the first page. Google reports with a delay of 2–3 days.</p></details>

<h2>People who came from Google, per week</h2>
<section class="card">{line_chart(visitors, weeks70, lambda v: f"{v:,} people", "People who came from Google per week, last 16 months")}
{numbers_table(["Week of", "People"], vis_rows)}</section>

<h2>How often you were shown, per week</h2>
<section class="card">{line_chart(shown, weeks70, lambda v: f"{v:,}", "Times shown in Google per week, last 16 months", h=150)}
{numbers_table(["Week of", "Times shown"], shown_rows)}</section>

<h2>Your key searches, last 3 months</h2>
<p class="sub">Higher is better: the top of each chart is position 1, and the darker line at 10 is the end of Google's first page.</p>
{"".join(cards)}

<h2>Almost on page 1</h2>
<p class="sub">Searches where you are just below the first page. A small improvement to the page listed could bring you onto page 1.</p>
<table class="plain"><tr><th>Search</th><th>Position</th><th>Shown (4 weeks)</th><th>Your page</th></tr>
{"".join(f"<tr><td>{H(q)}</td><td>{p:.0f}</td><td>{s:,}</td><td>{H(u)}</td></tr>" for q, p, s, u in ALMOST)}</table>

<h2>Shown often, rarely clicked</h2>
<p class="sub">Worth a look: first check how the page appears in Google today, before changing anything.</p>
<table class="plain"><tr><th>Your page</th><th>Shown (4 weeks)</th><th>Clicked</th></tr>
{"".join(f"<tr><td>{H(u)}</td><td>{s:,}</td><td>{c}</td></tr>" for u, s, c in WORTH_A_LOOK)}</table>

<h2>Bing</h2>
<p>Bing is not connected yet. Ask me <i>“connect Bing”</i> and I'll walk you through it.</p>

<p class="sub" style="margin-top:32px">Also see: <a href="#">Does AI name you?</a> — your AI report.</p>
</main></body></html>"""

out = Path(__file__).with_name("mockup.html")
out.write_text(page, encoding="utf-8")
print(out)
