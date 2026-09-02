#!/usr/bin/env bash
# track.sh — one-command weekly tracker. Pulls GSC + Bing for the target keywords,
# appends each run to a history CSV, then prints the week-over-week position trend.
# Run it every 1–2 weeks (not daily — daily is noise at low volume).
#
#   bash track.sh <domain> "<comma,separated,keywords>"
#   bash track.sh example.com "AI Events Munich,AI Meetups Munich,AI Treffen München"
#
# Reads keys from ~/.config/gsc-insights/.env (SERPER not needed here; Bing optional).
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
ENV="$HOME/.config/gsc-insights/.env"
PY="$HOME/.config/gsc-insights/venv/bin/python"
DOMAIN="${1:?domain required (e.g. example.com)}"
KEYWORDS="${2:?keywords required (comma-separated)}"

[ -x "$PY" ] || { echo "✗ venv missing at $PY — see SKILL.md setup"; exit 1; }
[ -f "$ENV" ] && { set -a; . "$ENV"; set +a; }
# Resolved AFTER sourcing .env, so a GSC_HISTORY_CSV set there (the natural
# place for it, alongside every other env var this tool uses) actually takes
# effect for scheduled runs -- not just ad-hoc python invocations.
CSV="${GSC_HISTORY_CSV:-$HOME/.config/gsc-insights/history.csv}"

# Exit 4 from either script means "the report/pull itself succeeded but the
# history CSV write failed" (gsc_query.py/bing_query.py catch write errors so
# they never crash an ad-hoc report — see _history.py). track.sh's whole job
# IS building history, so unlike an ad-hoc caller, it must not treat that as
# silent success: warn loudly rather than let the run look clean when nothing
# was actually recorded. Any OTHER nonzero code is a real failure and still
# aborts this script (set -e) — only 4 gets the `|| rc=$?` catch-and-continue.
history_gap=0

echo "▶ Google Search Console …"
# GSC_COUNTRY (ISO alpha-3, e.g. deu): optional country filter so the tracked
# history matches ad-hoc --country reports (env-var pattern like GSC_HISTORY_CSV).
# 28-day window (GSC_TRACK_DAYS overrides): weekly points from a 90-day window
# are ~92% the same data — real moves show up damped and weeks late. 28 matches
# the SKILL.md cadence. NOTE: changing the window shifts the level of the
# recorded positions once, so the first post-change trend line is not comparable.
rc=0
"$PY" "$DIR/gsc_query.py" --site "sc-domain:$DOMAIN" --days "${GSC_TRACK_DAYS:-28}" \
  --keywords "$KEYWORDS" --csv "$CSV" ${GSC_COUNTRY:+--country "$GSC_COUNTRY"} >/dev/null || rc=$?
if [ "$rc" = 4 ]; then
  echo "  ⚠ GSC pulled fine but the history write failed — this run added nothing to the trend."
  history_gap=1
elif [ "$rc" != 0 ]; then
  exit "$rc"
fi

echo "▶ Bing Webmaster …"
rc=0
"$PY" "$DIR/bing_query.py" --site "https://$DOMAIN" \
  --keywords "$KEYWORDS" --csv "$CSV" >/dev/null || rc=$?
if [ "$rc" = 3 ]; then
  echo "  (Bing skipped — set BING_API_KEY in $ENV to include it)"
elif [ "$rc" = 4 ]; then
  echo "  ⚠ Bing pulled fine but the history write failed — this run added nothing to the trend."
  history_gap=1
elif [ "$rc" != 0 ]; then
  echo "  ✗ Bing API error (exit $rc) — run bing_query.py directly to see why"
fi

echo
echo "═══ Position trend — lower is better; ▲ = improved since last run ═══"
"$PY" "$DIR/_history.py" "$CSV"
echo
echo "History CSV: $CSV"
# Nonzero even though the trend above printed fine -- a scheduled run's exit
# code is the only unattended signal that anything went wrong; a launchd log
# nobody tails wouldn't otherwise surface a silently-skipped write.
[ "$history_gap" = 0 ] || exit 4
