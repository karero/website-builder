#!/usr/bin/env bash
# track.sh — one-command weekly tracker. Pulls GSC + Bing for the target keywords,
# appends each run to a history CSV, then prints the week-over-week position trend.
# Run it every 1–2 weeks (not daily — daily is noise at low volume).
#
#   bash track.sh [domain] [comma,separated,keywords]
#   bash track.sh genai-wednesday.de "AI Events Munich,AI Meetups Munich,AI Treffen München"
#
# Reads keys from ~/.config/gsc-insights/.env (SERPER not needed here; Bing optional).
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
ENV="$HOME/.config/gsc-insights/.env"
PY="$HOME/.config/gsc-insights/venv/bin/python"
CSV="${GSC_HISTORY_CSV:-$HOME/.config/gsc-insights/history.csv}"
DOMAIN="${1:-genai-wednesday.de}"
KEYWORDS="${2:-AI Events Munich,AI Meetups Munich,AI Treffen München}"

[ -x "$PY" ] || { echo "✗ venv missing at $PY — see SKILL.md setup"; exit 1; }
[ -f "$ENV" ] && { set -a; . "$ENV"; set +a; }

echo "▶ Google Search Console …"
"$PY" "$DIR/gsc_query.py" --site "sc-domain:$DOMAIN" --days 90 \
  --keywords "$KEYWORDS" --csv "$CSV" >/dev/null

echo "▶ Bing Webmaster …"
"$PY" "$DIR/bing_query.py" --site "https://$DOMAIN" \
  --keywords "$KEYWORDS" --csv "$CSV" >/dev/null \
  || echo "  (Bing skipped — set BING_API_KEY in $ENV to include it)"

echo
echo "═══ Position trend — lower is better; ▲ = improved since last run ═══"
"$PY" "$DIR/_history.py" "$CSV"
echo
echo "History CSV: $CSV"
