#!/usr/bin/env bash
#
# independent_review.sh — external-model half of the `independent-review` gate.
# DEFAULT STANDARD PAIR = Codex CLI + ollama-cloud (glm-5.2:cloud) — both run
# every time (or the first that succeeds with --first-success), and their
# ranked BUG/RISK/NIT reviews print. The skill ALSO runs a host fresh-eyes pass
# (tier 3 — whatever model family the host agent is) and consolidates.
#
# Antigravity (`agy`/Gemini) is OPT-IN ONLY — pass --with-antigravity or set
# WITH_ANTIGRAVITY=1. It does NOT run by default and is never used as a silent
# fallback: the owner's Antigravity free-tier credits are scarce and are spent
# only when explicitly asked for (a genuinely hard case, or the owner directly
# requests "antigravity review"/"agy review"). Default runs never touch it.
#
# PLAN gate always wants 2 reviewers: for --plan (or auto-detected plan type),
# --first-success is overridden back to a full run (both Codex and ollama
# attempted) with a warning — a plan is high-stakes enough that "first thing
# that answered" isn't enough independence.
#
# Exit 0 only means "≥1 reviewer produced output" — the VERDICT (unaddressed
# BUG / unwaived RISK = gate FAIL) is enforced by the skill from the findings,
# never by this exit code. No reviewer at all → exit 4 (FAIL).
#
# SECURITY. The preferred reviewer, `codex exec -s read-only`, runs in a GENUINE
# read-only sandbox — model-generated shell commands cannot write to your repo.
# The ollama tier only sends text. Still: treat any external reviewer as untrusted
# and never pass a write/danger sandbox flag for a review.
#
# Usage:
#   independent_review.sh PLAN.md               # type auto-detected: plan
#   independent_review.sh change.patch --diff   # force diff framing
#   git diff main...HEAD | independent_review.sh -   # stdin -> auto diff
#   independent_review.sh PLAN.md --with-antigravity  # explicitly spend an Antigravity credit too
# Env:
#   (codex model + reasoning effort default from ~/.codex/config.toml — daily driver)
#   CODEX_MODEL    (unset)           ad-hoc codex model override for THIS run only,
#                                    e.g. CODEX_MODEL=gpt-5.6-sol for a hard case or a
#                                    long plan. Does not touch config.toml's daily driver.
#   OLLAMA_MODEL   (glm-5.2:cloud)   ollama model for the standard second reviewer —
#                                    defaults to the owner's pulled ollama-cloud model;
#                                    override to point at a different cloud/local tag.
#   AGY_MODEL      (Gemini 3.1 Pro (High))  Antigravity CLI model, used only when
#                                    --with-antigravity/WITH_ANTIGRAVITY=1 opts it in.
#   WITH_ANTIGRAVITY (0)             set to 1 (or pass --with-antigravity) to include
#                                    the Antigravity/agy tier for this run. Off by default.

set -uo pipefail

# --- args: one file (or -), optional --plan/--diff/--first-success/--local-only/--with-antigravity
FILE="" ; TYPE="" ; FIRST_SUCCESS=0 ; LOCAL_ONLY=0 ; WITH_ANTIGRAVITY="${WITH_ANTIGRAVITY:-0}"
for a in "$@"; do
  case "$a" in
    --plan)  TYPE="plan" ;;
    --diff)  TYPE="diff" ;;
    --first-success) FIRST_SUCCESS=1 ;;   # stop at the first tier that succeeds
    --local-only)    LOCAL_ONLY=1 ;;      # nothing leaves the machine: skip codex/agy/paste,
                                          # local ollama only (explicitly degraded gate)
    --with-antigravity) WITH_ANTIGRAVITY=1 ;;  # explicit opt-in: spend an Antigravity credit this run
    -)       FILE="-" ;;
    -*)      echo "unknown flag: $a" >&2   # a typo'd flag must not silently change gate behavior
             echo "usage: independent_review.sh <file|-> [--plan|--diff] [--first-success] [--local-only] [--with-antigravity]" >&2; exit 2 ;;
    *)       if [ -z "$FILE" ]; then FILE="$a"; else   # a silently dropped 2nd file = unreviewed artifact
               echo "extra argument: $a (one artifact per run)" >&2; exit 2; fi ;;
  esac
done
[ -n "$FILE" ] || { echo "usage: independent_review.sh <file|-> [--plan|--diff] [--first-success] [--local-only] [--with-antigravity]" >&2; exit 2; }
CONTENT="$([ "$FILE" = "-" ] && cat || cat -- "$FILE")" || { echo "cannot read: $FILE" >&2; exit 2; }
if [ -z "$TYPE" ]; then
  case "$FILE" in -|*.diff|*.patch) TYPE="diff" ;; *) TYPE="plan" ;; esac
fi
# The standard second reviewer is the owner's pulled ollama-cloud model — no
# env var needed to get the default duo (Codex + ollama-cloud) working.
# NOT defaulted in --local-only mode: that mode's whole point is nothing
# leaves the machine, and glm-5.2:cloud is a network call by definition —
# local-only still requires the caller to name an explicit LOCAL model tag.
[ "$LOCAL_ONLY" = "1" ] || OLLAMA_MODEL="${OLLAMA_MODEL:-glm-5.2:cloud}"
# PLAN gate always wants 2 independent reviewers attempted — "first thing that
# answered" isn't enough independence for a high-stakes planning doc.
if [ "$TYPE" = "plan" ] && [ "$FIRST_SUCCESS" = "1" ]; then
  echo "note: --first-success is ignored for plan reviews — running the full reviewer set (plans always want ≥2 independent passes)." >&2
  FIRST_SUCCESS=0
fi
# argv ceiling: the whole artifact rides inside ONE -p argument. Linux caps a single
# argv string at 128 KB (MAX_ARG_STRLEN=131072 — hard kernel limit; macOS is laxer,
# ~1 MB total, verified). Stay under the strictest host. Fail LOUD — split, don't truncate.
CONTENT_BYTES="$(printf '%s' "$CONTENT" | wc -c | tr -d ' ')"   # bash ${#} counts CHARS; UTF-8 can be 2-4x more bytes
if [ "$CONTENT_BYTES" -gt 120000 ]; then
  echo "artifact is $(( CONTENT_BYTES / 1024 )) KB — over the 117 KB single-argument limit (Linux E2BIG)." >&2
  echo "Split it (per-directory diffs, or plan sections) and review the pieces." >&2
  exit 2
fi

PROMPT="You are an adversarial, independent reviewer of the ${TYPE} below. The author
cannot see their own blind spots, so be skeptical and specific. Return a RANKED list:
BUG (wrong or self-contradictory now) / RISK (breaks under a normal future change, or a
guard/test that cannot actually fire) / NIT — each with a file:line or section anchor, a
one-line why, and a concrete fix. Then list what you checked that came back CLEAN (silence
is not coverage). Do NOT trust the ${TYPE}'s own line numbers or claims. Review ONLY — do
not modify files or run commands.

--- BEGIN ${TYPE} ---
${CONTENT}
--- END ${TYPE} ---"

# Raw reviewer outputs STREAM to files (never shell-variable-only: a teardown
# mid-review must leave partials on disk — the clerk procedure depends on them).
RAW_DIR="${REVIEW_RAW_DIR:-$(mktemp -d "${TMPDIR:-/tmp}/independent-review.XXXXXX")}"
# A caller-supplied REVIEW_RAW_DIR may not exist yet — without it every tier's
# output redirect fails and the run misreports as "no reviewer available" (exit 4).
# `mkdir -p` alone is not enough: it exits 0 on an EXISTING unwritable dir, which
# would resurrect the same misreport — so prove writability too. Exit 2 = caller/
# environment error, distinct from the exit-4 "no reviewer" gate failure.
mkdir -p -- "$RAW_DIR" || { printf 'cannot create RAW_DIR: %s\n' "$RAW_DIR" >&2; exit 2; }
# Raw outputs hold the reviewed diff + reviewer stderr — keep the dir owner-only,
# matching mktemp's default, so a caller-supplied dir is never world-readable.
# (no `--`: BSD/macOS chmod rejects it after the mode; option parsing already
# stopped at the mode operand, so a dash-leading path is safe regardless)
chmod 700 "$RAW_DIR" || { printf 'cannot make RAW_DIR private: %s\n' "$RAW_DIR" >&2; exit 2; }
# [ -w ] is not proof redirects will work (a writable-but-unsearchable dir still
# fails them) — probe the actual operation: create a file, then remove it.
: >"$RAW_DIR/.write-probe" && rm -f -- "$RAW_DIR/.write-probe" || { printf 'RAW_DIR not writable: %s\n' "$RAW_DIR" >&2; exit 2; }
# A REUSED caller-supplied RAW_DIR must not serve a previous run's partials to the
# clerk. Cleared once, centrally: a tier can be skipped INSIDE its function or at
# the dispatcher (`command -v ollama && …`), and a per-function rm misses the
# latter. Checked: stale files surviving silently would defeat the point.
rm -f -- "$RAW_DIR/codex.out" "$RAW_DIR/codex.err" "$RAW_DIR/agy.out" "$RAW_DIR/agy.err" "$RAW_DIR/ollama.out" "$RAW_DIR/ollama.err" \
  || { printf 'cannot clear stale tier files in RAW_DIR: %s\n' "$RAW_DIR" >&2; exit 2; }

# A reviewer only counts if its output LOOKS like a review — any non-empty stdout
# (auth error, rate-limit notice, refusal) must not satisfy the gate. Anchored to
# list/heading formatting: a refusal SENTENCE that merely mentions "BUG, RISK, or
# NIT" ("I cannot return a ranked list of BUG...") must not match.
looks_like_review() {
  # 1. refusals about the reviewing act FIRST — a refusal formatted like a finding
  #    ("- BUG: I cannot review this file...") must not slip past the positive match.
  #    Verb-anchored so genuine text survives: "a guard that cannot fire" (no act verb)
  #    and "I cannot find any bugs" ("find" deliberately not in the verb list) both pass.
  printf '%s\n' "$1" | grep -qiE "\b(cannot|can't|unable to|not able to|refuse to|refuses to) (access|read|open|review|return|provide|complete|see)\b" && return 1
  # 2. structured findings (list/heading-anchored severity)
  printf '%s\n' "$1" | grep -qiE '^[[:space:]]*([#*-]|[0-9]+\.).*\b(BUG|RISK|NIT)\b' && return 0
  # 3. genuine clean verdicts. Broadened past a strict "\bno findings\b" phrase match
  #    after 3 real Codex responses in one session all misreported as gate-FAIL despite
  #    being genuine clean reviews (verified live 2026-07-13, exit 0, valid stdout each
  #    time): "No BUG / RISK / NIT findings in this diff." (no+findings not adjacent),
  #    "Ranked findings: none." (findings before none, no "no" at all as its own word -
  #    "none" doesn't word-boundary-match \bno\b), and "Ranked findings: none. I found no
  #    BUG, RISK, or NIT..." (findings appears before, not after, the "no"). Order- and
  #    phrasing-tolerant now: matches no+findings in EITHER order, "findings: none",
  #    bare "none" as a sentence, or "no bug/risk/nit" directly.
  printf '%s\n' "$1" | grep -qiE '\bno\b.*\bfindings\b|\bfindings\b.*\bnone\b|\bnone\.?[[:space:]]*$|\bcame back clean\b|\ball clean\b|\bno (bug|risk|nit)s?\b'
}

# --- reviewer tiers: each returns 0 (printed real findings) / 1 (ran, failed/empty/
#     non-review output) / 3 (unavailable). Callers fall through on non-zero. ------
# PREFERRED: OpenAI Codex CLI. Uses ~/.codex/config.toml (model + reasoning effort as
# the daily-driver default) and ~/.codex/auth.json; `exec -s read-only` gives a GENUINE
# read-only sandbox — its shell commands can't touch your repo. The binary may not be
# on PATH (it ships inside the ChatGPT VS Code extension), so resolve it explicitly.
# CODEX_MODEL overrides the model for this run only (e.g. a stronger tier for a hard
# case or a long plan) via `-c model=...`; config.toml's reasoning-effort setting still
# applies on top of it, since that's a separate key the override doesn't touch.
codex_bin() {
  command -v codex 2>/dev/null && return 0
  ls -1 "$HOME"/.vscode/extensions/openai.chatgpt-*/bin/*/codex 2>/dev/null | sort -V | tail -1
}
run_codex() {
  local bin; bin="$(codex_bin)"
  [ -n "$bin" ] && [ -x "$bin" ] && [ -f "$HOME/.codex/auth.json" ] || return 3
  # No array for the optional -c flag: bash 3.2 (macOS's system /usr/bin/bash, which
  # this script's `env bash` shebang can resolve to) throws "unbound variable" on
  # "${arr[@]}" for an EMPTY array under `set -u` — verified on this host, not
  # theoretical — so branch instead of building an argv array conditionally.
  if [ -n "${CODEX_MODEL:-}" ]; then
    "$bin" exec -s read-only -c "model=\"$CODEX_MODEL\"" "$PROMPT" </dev/null >"$RAW_DIR/codex.out" 2>"$RAW_DIR/codex.err"
  else
    "$bin" exec -s read-only "$PROMPT" </dev/null >"$RAW_DIR/codex.out" 2>"$RAW_DIR/codex.err"
  fi
  local rc=$?
  # An explicit CODEX_MODEL request failing must not fail silently — with
  # --first-success the caller just moves on to the next tier with no sign the
  # requested override never actually ran, which defeats the point of asking
  # for a specific (usually stronger) model in the first place.
  if { [ $rc -ne 0 ] || [ ! -s "$RAW_DIR/codex.out" ]; }; then
    if [ -n "${CODEX_MODEL:-}" ]; then
      echo "codex: CODEX_MODEL=\"$CODEX_MODEL\" failed (exit $rc) — full stderr: $RAW_DIR/codex.err" >&2
      tail -20 "$RAW_DIR/codex.err" >&2 2>/dev/null
    fi
    return 1
  fi
  local out; out="$(cat "$RAW_DIR/codex.out")"
  if ! looks_like_review "$out"; then
    [ -n "${CODEX_MODEL:-}" ] && echo "codex: CODEX_MODEL=\"$CODEX_MODEL\" ran but returned non-review output" >&2
    return 1
  fi
  # ^model[[:space:]]*= (not bare ^model): config.toml also has a
  # model_reasoning_effort key, which a bare ^model prefix match also catches —
  # confirmed live in this session's own captured review headers, which were
  # garbled by exactly this ("codex (~/.codex config: gpt-5.6-terra\nmodel_rea…").
  local cfg; cfg="${CODEX_MODEL:-$(grep -E '^model[[:space:]]*=' "$HOME/.codex/config.toml" 2>/dev/null | tr -d ' "' | sed 's/model=//')}"
  printf '## Independent review — codex (%s, read-only)\n\n%s\n' "${cfg:-unknown}" "$out"
}
# OPT-IN ONLY (--with-antigravity / WITH_ANTIGRAVITY=1) — Google Gemini via the
# Antigravity CLI `agy` (brew: antigravity-cli). The owner's Antigravity free-tier
# credits are scarce; this tier is never run automatically, only when explicitly
# requested because it's genuinely worth spending one. FREE tier via the
# Antigravity Google login (shared with the IDE — no separate auth, no API key), and it
# exposes the literal "Gemini 3.1 Pro (High)" model. Verified headless 2026-07-02.
# (The old @google/gemini-cli path is DEPRECATED: Google discontinued its free
# "Login with Google" tier on 2026-06-18 — IneligibleTierError; API-key only. Dropped.)
# --sandbox = terminal restrictions; -p print mode never auto-approves tool calls (we do NOT
# pass --dangerously-skip-permissions). Run from a throwaway dir; treat output as untrusted.
run_agy() {
  command -v agy >/dev/null 2>&1 || return 3
  local sbox out rc model="${AGY_MODEL:-Gemini 3.1 Pro (High)}"
  sbox="$(mktemp -d)"
  # </dev/null: if the CLI ever prompts (tool-approval y/n) inside the captured
  # subshell it would hang invisibly — an empty stdin makes it abort instead.
  ( cd "$sbox" && agy --sandbox --model "$model" -p "$PROMPT" </dev/null ) >"$RAW_DIR/agy.out" 2>"$RAW_DIR/agy.err"; rc=$?
  rm -rf "$sbox"
  { [ $rc -eq 0 ] && [ -s "$RAW_DIR/agy.out" ]; } || return 1
  out="$(cat "$RAW_DIR/agy.out")"
  looks_like_review "$out" || return 1
  printf '## Independent review — antigravity/agy (%s, sandbox)\n\n%s\n' "$model" "$out"
}
run_ollama() {
  [ -n "${OLLAMA_MODEL:-}" ] || return 3          # must be named explicitly
  ollama list >/dev/null 2>&1 || return 3
  local is_local=0
  case "$OLLAMA_MODEL" in
    *cloud*|*:120b|*:405b|*:480b) : ;;            # assume strong/cloud only if named so
    *) is_local=1 ;;
  esac
  local tmp="$RAW_DIR/ollama.out" rc
  ollama run "$OLLAMA_MODEL" "$PROMPT" >"$tmp" </dev/null 2>"$RAW_DIR/ollama.err"; rc=$?
  { [ $rc -eq 0 ] && [ -s "$tmp" ] && looks_like_review "$(cat "$tmp")"; } || return 1
  printf '## Independent review — ollama (%s)\n\n' "$OLLAMA_MODEL"
  # Plain ANSI-stripping is not enough: ollama's own word-wrap redraw ("cursor
  # back N" + "erase to end of line", emitted even when stdout is a file, not
  # a tty) only ERASES on a real terminal — a dumb strip leaves the erased
  # fragment's characters behind as garbled text (e.g. "resc" then "rescue").
  # Emulate the erase: drop the last N chars of the current line for that pair,
  # clamped so it can never reach back past the preceding newline.
  perl -0777 -ne '
    my $s = $_; my $out = "";
    while ($s =~ /\G(?:([^\e]+)|\e\[(\d+)D\e\[K|\e\[[0-9;?]*[A-Za-z])/gc) {
      if (defined $1) { $out .= $1; next; }
      next unless defined $2;
      my $n = $2;
      my $line_len = length($out) - rindex($out, "\n") - 1;
      $n = $line_len if $n > $line_len;
      substr($out, length($out) - $n, $n, "") if $n > 0;
    }
    print $out;
  ' "$tmp"
  # tier 5 (local) = sanity pass, NEVER the sole gate — EXCEPT in --local-only mode,
  # where the owner explicitly traded strength for privacy (mode is marked degraded).
  if [ $is_local -eq 1 ] && [ "$LOCAL_ONLY" != "1" ]; then
    echo "⚠ '$OLLAMA_MODEL' looks LOCAL — sanity pass only, gate NOT satisfied by this tier. Prefer codex or a named cloud model." >&2
    return 1
  fi
}

# --- dispatch. DEFAULT STANDARD PAIR = Codex + ollama-cloud, both run, every
#     section printed (the caller consolidates). Antigravity only runs when
#     --with-antigravity/WITH_ANTIGRAVITY=1 opted it in for this run.
#     --first-success stops at the first tier that returns findings (quick
#     mode; not honored for plan type — see the override above). Exit 0 iff
#     at least one reviewer succeeded — the caller still judges the findings.
# (tier 3 = the HOST agent's fresh-eyes pass — whatever family the host is — run by
#  the orchestrating skill, not this script)
OK=0 ; SUCCESS_COUNT=0
if [ "$LOCAL_ONLY" = "1" ]; then
  # nothing leaves the machine: codex/agy/paste are all external. Local ollama only,
  # and the result is an explicitly DEGRADED gate (owner's privacy trade).
  echo "── LOCAL-ONLY mode: external reviewers skipped; gate is DEGRADED by owner choice ──" >&2
  command -v ollama >/dev/null && run_ollama && OK=1
  [ $OK -eq 1 ] && { echo "raw output: $RAW_DIR" >&2; exit 0; }
  echo "local-only: no local reviewer produced a review (need OLLAMA_MODEL=<local model>)." >&2
  echo "Run the host fresh-eyes pass; do NOT paste externally in local-only mode." >&2
  exit 4
elif [ "$FIRST_SUCCESS" = "1" ]; then
  run_codex && { OK=1; SUCCESS_COUNT=$((SUCCESS_COUNT+1)); }                     # 1. OpenAI Codex CLI
  [ $OK -eq 1 ] || { command -v ollama >/dev/null && run_ollama && { OK=1; SUCCESS_COUNT=$((SUCCESS_COUNT+1)); }; }  # 2. ollama-cloud
  [ $OK -eq 1 ] || { [ "$WITH_ANTIGRAVITY" = "1" ] && run_agy && { OK=1; SUCCESS_COUNT=$((SUCCESS_COUNT+1)); }; }    # 3. agy, opt-in only
else
  run_codex  && { OK=1; SUCCESS_COUNT=$((SUCCESS_COUNT+1)); }                    # 1. OpenAI Codex CLI
  command -v ollama >/dev/null && run_ollama && { OK=1; SUCCESS_COUNT=$((SUCCESS_COUNT+1)); }  # 2. ollama cloud/local
  if [ "$WITH_ANTIGRAVITY" = "1" ]; then
    run_agy && { OK=1; SUCCESS_COUNT=$((SUCCESS_COUNT+1)); }                     # 3. agy, opt-in only
  fi
fi
if [ "$TYPE" = "plan" ] && [ "$SUCCESS_COUNT" -lt 2 ]; then
  echo "⚠ plan gate wants ≥2 independent reviewers; only $SUCCESS_COUNT produced output. Treat as degraded — consider --with-antigravity or a manual paste round." >&2
fi
[ $OK -eq 1 ] && { echo "raw output: $RAW_DIR" >&2; exit 0; }

# No automated reviewer succeeded — DO NOT exit 0. Emit the manual prompt + FAIL (tier 6).
cat >&2 <<'EOF'
## No automated reviewer available/succeeded — the gate is NOT satisfied.
# Standard pair (default, no flags needed if both are set up):
#   codex           # OpenAI Codex CLI (bundled in the ChatGPT VS Code extension) — preferred;
#                   # already reads ~/.codex config (model + reasoning effort) + auth.json
#   ollama          # local daemon + `ollama signin` for the glm-5.2:cloud default tag
# Antigravity is opt-in only (owner's credits are scarce) — add --with-antigravity
# (or WITH_ANTIGRAVITY=1) to spend one this run:
#   brew install antigravity-cli    # `agy` — Gemini 3.1 Pro (High), free Antigravity login
# Or paste the prompt below into any strong model and feed the findings back:
EOF
# skipped tiers (missing CLI/auth) return before writing anything — only ATTEMPTED
# reviewers leave .out/.err files here.
printf 'per-tier stderr for attempted reviewers (auth error vs I/O failure): %s\n' "$RAW_DIR" >&2
printf '%s\n' "$PROMPT"
exit 4
