#!/usr/bin/env bash
#
# independent_review.sh — external-model half of the `independent-review` gate.
# Runs a plan MD or a diff through ALL available INDEPENDENT models (default) —
# or the first that succeeds with --first-success — and prints their ranked
# BUG/RISK/NIT reviews. The skill ALSO runs a fresh-eyes Claude pass and
# consolidates. Exit 0 only means "≥1 reviewer produced output" — the VERDICT
# (unaddressed BUG / unwaived RISK = gate FAIL) is enforced by the skill from
# the findings, never by this exit code. No reviewer at all → exit 4 (FAIL).
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
# Env:
#   (codex model + reasoning effort come from ~/.codex/config.toml, e.g. gpt-5.5 xhigh)
#   AGY_MODEL      (Gemini 3.1 Pro (High))  Antigravity CLI model for tier 2.
#   OLLAMA_MODEL   (unset)           explicit ollama model — REQUIRED to use the
#                                    ollama tier. Cloud vs local is NOT detectable
#                                    from `ollama list`, so you must name it.

set -uo pipefail

# --- args: one file (or -), optional --plan/--diff/--first-success -----------
FILE="" ; TYPE="" ; FIRST_SUCCESS=0
for a in "$@"; do
  case "$a" in
    --plan)  TYPE="plan" ;;
    --diff)  TYPE="diff" ;;
    --first-success) FIRST_SUCCESS=1 ;;   # stop at the first tier that succeeds
    -)       FILE="-" ;;
    -*)      : ;;                         # ignore unknown flags
    *)       [ -z "$FILE" ] && FILE="$a" ;;
  esac
done
[ -n "$FILE" ] || { echo "usage: independent_review.sh <file|-> [--plan|--diff] [--first-success]" >&2; exit 2; }
CONTENT="$([ "$FILE" = "-" ] && cat || cat -- "$FILE")" || { echo "cannot read: $FILE" >&2; exit 2; }
if [ -z "$TYPE" ]; then
  case "$FILE" in -|*.diff|*.patch) TYPE="diff" ;; *) TYPE="plan" ;; esac
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

# --- reviewer tiers: each returns 0 (printed real findings) / 1 (ran, failed/empty)
#     / 3 (unavailable). Callers fall through on non-zero. ------------------------
# PREFERRED: OpenAI Codex CLI. Uses ~/.codex/config.toml (model + reasoning effort — e.g.
# gpt-5.5 / xhigh) and ~/.codex/auth.json; `exec -s read-only` gives a GENUINE read-only
# sandbox — its shell commands can't touch your repo. The binary may not be on PATH (it ships inside the
# ChatGPT VS Code extension), so resolve it explicitly.
codex_bin() {
  command -v codex 2>/dev/null && return 0
  ls -1 "$HOME"/.vscode/extensions/openai.chatgpt-*/bin/*/codex 2>/dev/null | sort -V | tail -1
}
run_codex() {
  local bin; bin="$(codex_bin)"
  [ -n "$bin" ] && [ -x "$bin" ] && [ -f "$HOME/.codex/auth.json" ] || return 3
  local out
  out="$("$bin" exec -s read-only "$PROMPT" 2>/dev/null)"; local rc=$?
  { [ $rc -eq 0 ] && [ -n "$out" ]; } || return 1
  printf '## Independent review — codex (~/.codex config: %s, read-only)\n\n%s\n' \
    "$(grep -E '^model' "$HOME/.codex/config.toml" 2>/dev/null | tr -d ' "' | sed 's/model=//')" "$out"
}
# 2. Google Gemini — via the Antigravity CLI `agy` (brew: antigravity-cli). FREE tier via the
#    Antigravity Google login (shared with the IDE — no separate auth, no API key), and it
#    exposes the literal "Gemini 3.1 Pro (High)" model. Verified headless 2026-07-02.
#    (The old @google/gemini-cli path is DEPRECATED: Google discontinued its free
#    "Login with Google" tier on 2026-06-18 — IneligibleTierError; API-key only. Dropped.)
#    --sandbox = terminal restrictions; -p print mode never auto-approves tool calls (we do NOT
#    pass --dangerously-skip-permissions). Run from a throwaway dir; treat output as untrusted.
run_agy() {
  command -v agy >/dev/null 2>&1 || return 3
  local sbox out rc model="${AGY_MODEL:-Gemini 3.1 Pro (High)}"
  sbox="$(mktemp -d)"
  out="$(cd "$sbox" && agy --sandbox --model "$model" -p "$PROMPT" 2>/dev/null)"; rc=$?
  rm -rf "$sbox"
  { [ $rc -eq 0 ] && [ -n "$out" ]; } || return 1
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
  local tmp rc
  tmp="$(mktemp)"
  ollama run "$OLLAMA_MODEL" "$PROMPT" >"$tmp" 2>/dev/null; rc=$?
  { [ $rc -eq 0 ] && [ -s "$tmp" ]; } || { rm -f "$tmp"; return 1; }
  printf '## Independent review — ollama (%s)\n\n' "$OLLAMA_MODEL"
  perl -pe 's/\e\[[0-9;?]*[A-Za-z]//g' "$tmp"; rm -f "$tmp"
  # tier 5 (local) = sanity pass, NEVER the sole gate: print the findings but return
  # non-zero so the caller still hits the manual/FAIL path (gate stays unsatisfied).
  if [ $is_local -eq 1 ]; then
    echo "⚠ '$OLLAMA_MODEL' looks LOCAL — sanity pass only, gate NOT satisfied by this tier. Prefer codex or a named cloud model." >&2
    return 1
  fi
}

# --- dispatch. DEFAULT = run ALL available reviewers and print every section
#     (maximum blind-spot diversity; the caller consolidates). --first-success
#     stops at the first tier that returns findings (quick mode). Exit 0 iff
#     at least one reviewer succeeded — the caller still judges the findings.
# (tier 3 = Claude fresh-eyes pass, run by the orchestrating skill, not this script)
OK=0
if [ "$FIRST_SUCCESS" = "1" ]; then
  run_codex && OK=1                                            # 1. OpenAI Codex CLI
  [ $OK -eq 1 ] || { run_agy && OK=1; }                        # 2. Gemini 3.1 Pro via agy
  [ $OK -eq 1 ] || { command -v ollama >/dev/null && run_ollama && OK=1; }  # 4/5. ollama
else
  run_codex  && OK=1                                           # 1. OpenAI Codex CLI
  run_agy    && OK=1                                           # 2. Gemini 3.1 Pro via agy
  command -v ollama >/dev/null && run_ollama && OK=1           # 4/5. ollama cloud/local
fi
[ $OK -eq 1 ] && exit 0

# No automated reviewer succeeded — DO NOT exit 0. Emit the manual prompt + FAIL (tier 6).
cat >&2 <<'EOF'
## No automated reviewer available/succeeded — the gate is NOT satisfied.
# Set one up:
#   codex           # OpenAI Codex CLI (bundled in the ChatGPT VS Code extension) — preferred;
#                   # already reads ~/.codex config (gpt-5.5 xhigh) + auth.json
#   brew install antigravity-cli    # `agy` — Gemini 3.1 Pro (High), free Antigravity login
#   OLLAMA_MODEL=glm-5.2:cloud …    # a named ollama cloud model (strong, private-ish)
# Or paste the prompt below into any strong model and feed the findings back:
EOF
printf '%s\n' "$PROMPT"
exit 4
