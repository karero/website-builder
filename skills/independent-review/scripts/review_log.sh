#!/usr/bin/env bash
#
# review_log.sh — the cost log of independent-review: one line per reviewer seat per round, so
# the review depths (SKILL.md, "Review depth") and effort levels can be tuned from numbers rather
# than impressions. The log is LOCAL — it never goes in a repo, so it adds no paperwork.
#
#   review_log.sh add --seat <name> [--model M] [--effort E] [--seconds S] [--tokens T]
#                     [--gate plan|diff] [--depth light|normal|high] [--round N] [--outcome O]
#       Append one line. independent_review.sh calls this for codex, ollama and agy; the host
#       calls it for the seats it runs itself (fresh-eyes, code-review, double-knuth, owner).
#       Repo, branch and head come from the current directory's git checkout, if any.
#   review_log.sh new-gate
#       Start a gate: mint an id and keep it in this worktree's git dir. independent_review.sh
#       calls it for --round 1; every later line (its own seats and the host's) carries that id
#       until the next one, so two gates on one reused branch stay two gates.
#   review_log.sh summary [--since YYYY-MM-DD] [--repo NAME]
#       Per depth and seat: runs, OK runs, mean and max seconds, mean tokens where known;
#       then rounds per gate by depth (lines logged before gate ids existed: per repo, branch
#       and gate type).
#
# Log file: $REVIEW_LOG, else ${XDG_STATE_HOME:-$HOME/.local/state}/independent-review/runs.tsv.
# REVIEW_LOG=off turns logging off. A failure to log warns and exits 0: bookkeeping never fails
# a review.
set -u
HEADER=$'date\trepo\tbranch\thead\tgate\tdepth\tround\tseat\tmodel\teffort\tseconds\ttokens\toutcome\tgate_id'
log_path() {   # empty when logging is off
  if [ "${REVIEW_LOG:-}" = off ]; then return 0
  elif [ -n "${REVIEW_LOG:-}" ]; then printf '%s' "$REVIEW_LOG"
  else printf '%s' "${XDG_STATE_HOME:-$HOME/.local/state}/independent-review/runs.tsv"; fi
}
clean() { printf '%s' "${1:--}" | tr '\t\n\r' '   '; }   # one TSV field, never empty
gate_file() { git rev-parse --git-path independent-review-gate 2>/dev/null; }   # empty outside git

new_gate() {
  local id f
  id="$(date -u +%Y%m%dT%H%M%SZ)-$$"
  f="$(gate_file)"
  [ -z "$f" ] || printf '%s\n' "$id" >"$f" 2>/dev/null || true
  printf '%s\n' "$id"
}

add() {
  local seat="" model="" effort="" seconds="" tokens="" gate="" depth="" round="" outcome="OK" gate_id=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --seat|--model|--effort|--seconds|--tokens|--gate|--depth|--round|--outcome|--gate-id)
        [ $# -ge 2 ] || { echo "review_log.sh: $1 needs a value" >&2; return 2; }
        local k="${1#--}"; k="${k//-/_}"; printf -v "$k" '%s' "$2"; shift 2 ;;
      *) echo "review_log.sh: unknown argument: $1" >&2; return 2 ;;
    esac
  done
  [ -n "$seat" ] || { echo "review_log.sh add: --seat is required" >&2; return 2; }
  local f repo="-" branch="-" head="-" top
  f="$(log_path)"
  [ -n "$f" ] || return 0
  if top="$(git rev-parse --show-toplevel 2>/dev/null)"; then
    repo="$(basename -- "$top")"
    branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo -)"
    head="$(git rev-parse --short=7 HEAD 2>/dev/null || echo -)"
  fi
  if [ -z "$gate_id" ]; then
    local gf; gf="$(gate_file)"
    [ -z "$gf" ] || [ ! -r "$gf" ] || IFS= read -r gate_id <"$gf" || true
  fi
  # The header is APPENDED, like every line: two seats finishing together on a new log (codex
  # and ollama run in parallel) may both see it empty, and a `>` could then overwrite a line
  # the other had written. Appending loses nothing; the worst case is a second header line,
  # which summary skips as it skips the first (by its content).
  { mkdir -p -- "$(dirname -- "$f")" &&
    { [ -s "$f" ] || printf '%s\n' "$HEADER" >>"$f"; } &&
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
      "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$(clean "$repo")" "$(clean "$branch")" "$(clean "$head")" \
      "$(clean "$gate")" "$(clean "$depth")" "$(clean "$round")" "$(clean "$seat")" \
      "$(clean "$model")" "$(clean "$effort")" "$(clean "$seconds")" "$(clean "$tokens")" \
      "$(clean "$outcome")" "$(clean "$gate_id")" >>"$f"; } 2>/dev/null \
    || echo "note: could not write the review cost log ($f) — the review itself is unaffected." >&2
  return 0
}

summary() {
  local since="" repo=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --since|--repo) [ $# -ge 2 ] || { echo "review_log.sh: $1 needs a value" >&2; return 2; } ;;
    esac
    case "$1" in
      --since) since="$2"; shift 2 ;;
      --repo)  repo="$2"; shift 2 ;;
      *) echo "review_log.sh: unknown argument: $1" >&2; return 2 ;;
    esac
  done
  local f; f="$(log_path)"
  [ -n "$f" ] || { echo "the review cost log is off (REVIEW_LOG=off)"; return 0; }
  [ -s "$f" ] || { echo "no review cost log yet ($f)"; return 0; }
  awk -F'\t' -v since="$since" -v want="$repo" '
    $1 == "date" { next }
    since != "" && substr($1, 1, 10) < since { next }
    want != "" && $2 != want { next }
    {
      k = $6 "\t" $8
      n[k]++; if ($13 == "OK") ok[k]++
      if ($11 ~ /^[0-9]+$/) { s[k] += $11; sn[k]++; if (!(k in mx) || $11 + 0 > mx[k]) mx[k] = $11 + 0 }
      if ($12 ~ /^[0-9]+$/) { t[k] += $12; tn[k]++ }
      # One gate: its id, or for lines from before ids existed, repo + branch + gate type.
      g = $6 "\t" (($14 != "" && $14 != "-") ? $14 : $2 "\t" $3 "\t" $5)
      if ($7 ~ /^[0-9]+$/ && $7 + 0 > r[g] + 0) r[g] = $7 + 0
    }
    END {
      printf "%-8s %-14s %5s %5s %8s %8s %11s\n", "depth", "seat", "runs", "ok", "mean s", "max s", "mean tokens"
      for (k in n) {
        split(k, p, "\t")
        printf "%-8s %-14s %5d %5d %8s %8s %11s\n", p[1], p[2], n[k], ok[k] + 0, \
          (sn[k] ? sprintf("%.0f", s[k] / sn[k]) : "-"), (sn[k] ? mx[k] : "-"), \
          (tn[k] ? sprintf("%.0f", t[k] / tn[k]) : "-")
      }
      for (g in r) { split(g, p, "\t"); gates[p[1]]++; rs[p[1]] += r[g]; if (r[g] > rmx[p[1]] + 0) rmx[p[1]] = r[g] }
      printf "\n%-8s %6s %12s %11s\n", "depth", "gates", "mean rounds", "max rounds"
      for (d in gates) printf "%-8s %6d %12.1f %11d\n", d, gates[d], rs[d] / gates[d], rmx[d]
    }' "$f"
}

case "${1:-}" in
  add)     shift; add "$@" ;;
  new-gate) new_gate ;;
  summary) shift; summary "$@" ;;
  *) echo "usage: review_log.sh add --seat <name> [...] | review_log.sh new-gate | review_log.sh summary [--since YYYY-MM-DD] [--repo NAME]" >&2; exit 2 ;;
esac
