#!/usr/bin/env bash
# schedule_tracking.sh — opt-in WEEKLY trend tracking via launchd (macOS).
#
# Runs track.sh on a schedule (GSC + Bing → history CSV → trend), logging to
# ~/.config/gsc-insights/logs/<domain>.log, so the trend data accumulates unattended
# and "is my ranking improving?" always has real week-over-week history to answer from.
#
# One LaunchAgent PER SITE — the user chooses which sites to schedule and can remove
# any independently. macOS uses launchd (NOT cron, by project policy). On Linux, run
# the same track.sh from a systemd user timer or cron instead.
#
#   bash schedule_tracking.sh install <domain> "<comma,keywords>" [weekday 0-7] [hour 0-23]
#     weekday: launchd values — 1=Mon … 6=Sat, and BOTH 0 and 7 = Sunday (default 1=Mon).
#   bash schedule_tracking.sh remove  <domain>
#   bash schedule_tracking.sh list
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
LA_DIR="$HOME/Library/LaunchAgents"
LOG_DIR="$HOME/.config/gsc-insights/logs"
PREFIX="com.gsc-insights"

sanitize() { echo "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g'; }
label_for() { echo "$PREFIX.$(sanitize "$1")"; }
plist_for() { echo "$LA_DIR/$(label_for "$1").plist"; }

cmd="${1:-}"; shift || true
case "$cmd" in
  install)
    domain="${1:?domain required (e.g. example.com)}"
    keywords="${2:?keywords required (comma-separated)}"
    weekday="${3:-1}"   # 1 = Monday (launchd: 0 & 7 = Sunday)
    hour="${4:-9}"
    [ -x "$DIR/track.sh" ] || chmod +x "$DIR/track.sh"
    mkdir -p "$LA_DIR" "$LOG_DIR"
    label="$(label_for "$domain")"
    plist="$(plist_for "$domain")"
    log="$LOG_DIR/$(sanitize "$domain").log"
    cat > "$plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>$label</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/bash</string>
    <string>$DIR/track.sh</string>
    <string>$domain</string>
    <string>$keywords</string>
  </array>
  <key>StartCalendarInterval</key>
  <dict>
    <key>Weekday</key><integer>$weekday</integer>
    <key>Hour</key><integer>$hour</integer>
    <key>Minute</key><integer>0</integer>
  </dict>
  <key>StandardOutPath</key><string>$log</string>
  <key>StandardErrorPath</key><string>$log</string>
  <key>RunAtLoad</key><false/>
</dict></plist>
PLIST
    # Reload idempotently. bootout/bootstrap is the modern path; fall back to load/unload.
    launchctl bootout "gui/$(id -u)/$label" 2>/dev/null || launchctl unload "$plist" 2>/dev/null || true
    launchctl bootstrap "gui/$(id -u)" "$plist" 2>/dev/null || launchctl load "$plist"
    echo "✓ Weekly tracking scheduled for $domain — weekday $weekday at ${hour}:00."
    echo "  label : $label"
    echo "  log   : $log"
    echo "  test now:  bash \"$DIR/track.sh\" \"$domain\" \"$keywords\""
    ;;
  remove)
    domain="${1:?domain required}"
    label="$(label_for "$domain")"; plist="$(plist_for "$domain")"
    if [ -f "$plist" ]; then
      launchctl bootout "gui/$(id -u)/$label" 2>/dev/null || launchctl unload "$plist" 2>/dev/null || true
      rm -f "$plist"
      echo "✓ Removed weekly tracking for $domain."
    else
      echo "No schedule found for $domain."
    fi
    ;;
  list)
    found=$(ls "$LA_DIR/$PREFIX."*.plist 2>/dev/null || true)
    if [ -n "$found" ]; then
      echo "Scheduled sites:"
      echo "$found" | sed 's#.*/'"$PREFIX"'\.##; s/\.plist$//; s/^/  - /'
    else
      echo "No sites scheduled yet."
    fi
    ;;
  *)
    echo "usage: schedule_tracking.sh install <domain> \"<keywords>\" [weekday 1-7] [hour 0-23]"
    echo "       schedule_tracking.sh remove <domain>"
    echo "       schedule_tracking.sh list"
    exit 1
    ;;
esac
