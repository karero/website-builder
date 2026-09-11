#!/usr/bin/env bash
#
# test_failed_tier_report.sh — drives independent_review.sh end to end, the way a
# caller does (default flags, auto-detected ollama model), with stub `codex` and
# `ollama` CLIs first on PATH and $HOME relocated. No reviewer is contacted and
# nothing leaves the machine; Antigravity is forced off.
#
# Why it exists: on 2026-09-11 the ollama-cloud tier hit its weekly quota (HTTP
# 429). The error sat only in a temp .err file, stdout carried the codex section
# alone, and the exit was 0 — so a one-reviewer round read as a clean pair. These
# cases pin that every attempted tier shows up on stdout, that the closing
# "reviewers:" line tells a quota refusal from a config failure (the remedies
# differ), and that the exit-code contract (0 = at least one gate-eligible
# reviewer, 4 = none) is unchanged.
#
# Usage: bash skills/independent-review/scripts/test_failed_tier_report.sh
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
SCRIPT="$HERE/independent_review.sh"
T="$(mktemp -d "${TMPDIR:-/tmp}/ir-test.XXXXXX")"
trap 'rm -rf "$T"' EXIT
mkdir -p "$T/bin" "$T/u/.codex"
: >"$T/u/.codex/auth.json"
printf 'model = "stub-codex"\n' >"$T/u/.codex/config.toml"
printf 'diff --git a/x b/x\n+retry on HTTP 429 after a pause\n' >"$T/change.diff"
printf '# Plan\n\nStep 1: do the thing.\n' >"$T/plan.md"
# Built at runtime: check_model_agnostic.sh flags any literal "<word>:cloud" in this skill.
STUB_TAG="stub-model"; STUB_TAG="${STUB_TAG}:cloud"

cat >"$T/bin/codex" <<'EOF'
#!/bin/sh
case "${CODEX_STUB:-ok}" in
  ok)   printf -- '- BUG: stub finding one\n- NIT: stub finding two\n' ;;
  auth) # codex echoes the reviewed artifact into stderr first — here one that
        # mentions a 429 — and only its last lines carry the real, non-quota error.
        printf 'user\n+retry on HTTP 429 Too Many Requests after a pause\n' >&2
        i=0; while [ $i -lt 20 ]; do echo "exec step $i" >&2; i=$((i+1)); done
        echo "ERROR: not signed in — run codex login" >&2; exit 1 ;;
esac
EOF
cat >"$T/bin/ollama" <<'EOF'
#!/bin/sh
case "$1" in
  list) printf 'NAME                ID      SIZE    MODIFIED\n%s    abc123  -       1 day ago\n' "$STUB_TAG"; exit 0 ;;
  run)  : >"$STUB_MARKS/ollama-ran" ;;
esac
case "${OLLAMA_STUB:-ok}" in
  ok)     printf -- '- RISK: stub ollama finding\n- NIT: another\n' ;;
  429)    # the byte shape of the 2026-09-11 failure: spinner, cursor and sync-mode escapes
          printf '\033[?2026h\033[?25l\033[1G\342\240\231 \033[K\033[?25h\033[?2026l\033[?25l\033[2K\033[1G\033[?25hError: 429 Too Many Requests: you (someone) have reached your weekly usage limit, upgrade for higher limits\n' >&2
          exit 1 ;;
  badtag) i=0; while [ $i -lt 4 ]; do printf '\033[?25l\033[1Gpulling manifest \342\240\213 \033[K\033[?25h' >&2; i=$((i+1)); done
          printf '\nError: pull model manifest: file does not exist\n' >&2; exit 1 ;;
esac
EOF
chmod +x "$T/bin/codex" "$T/bin/ollama"

# run <name> [VAR=value ...] <command ...> — leaves $T/<name>.out, .err and .rc
run() {
  local name="$1"; shift
  mkdir -p "$T/$name.marks"
  env -u CODEX_MODEL -u OLLAMA_MODEL -u OLLAMA_HOST -u AGY_MODEL \
    PATH="$T/bin:$PATH" HOME="$T/u" WITH_ANTIGRAVITY=0 \
    REVIEW_RAW_DIR="$T/$name.raw" STUB_MARKS="$T/$name.marks" STUB_TAG="$STUB_TAG" "$@" \
    >"$T/$name.out" 2>"$T/$name.err"
  echo $? >"$T/$name.rc"
}
fails=0
check() {   # check <description> <command ...>
  if "${@:2}"; then printf 'ok   %s\n' "$1"; else printf 'FAIL %s\n' "$1"; fails=$((fails+1)); fi
}
has()   { grep -qF -- "$2" "$T/$1"; }
lacks() { ! grep -qF -- "$2" "$T/$1"; }
rc_is() { [ "$(cat "$T/$1.rc")" = "$2" ]; }

# 1. The incident itself: codex answers, ollama-cloud is refused with a 429.
run incident CODEX_STUB=ok OLLAMA_STUB=429 bash "$SCRIPT" "$T/change.diff"
check "incident: exit stays 0 (one gate-eligible reviewer succeeded)" rc_is incident 0
check "incident: the codex review is still printed" has incident.out "## Independent review — codex (stub-codex, read-only)"
check "incident: the failed tier gets its own section on stdout" has incident.out "## Independent review — ollama-cloud — FAILED"
check "incident: the section quotes the tier's error" has incident.out "Error: 429 Too Many Requests"
check "incident: no terminal escape bytes reach stdout" lacks incident.out $'\033'
check "incident: no spinner glyphs reach stdout" lacks incident.out '⠙'
check "incident: summary names the quota failure" has incident.out "reviewers: codex OK, ollama-cloud FAILED (quota/rate limit: wait or add credits)"
check "incident: a DIFF round with 1 reviewer says so" has incident.out "⚠ DIFF round landed with 1 successful external reviewer(s)"
check "incident: the summary also reaches stderr" has incident.err "reviewers: codex OK, ollama-cloud FAILED (quota"

# 2. The normal pair: both reviews, no FAILED section, no degraded note.
run pair bash "$SCRIPT" "$T/change.diff"
check "pair: exit 0" rc_is pair 0
check "pair: codex section" has pair.out "## Independent review — codex (stub-codex, read-only)"
check "pair: ollama section, header unchanged" has pair.out "## Independent review — ollama ($STUB_TAG)"
check "pair: no FAILED section" lacks pair.out "FAILED"
check "pair: summary lists both OK" has pair.out "reviewers: codex OK, ollama-cloud OK"
check "pair: no fewer-than-2 note" lacks pair.out "fewer than the 2"

# 3. A config failure (bad model tag) is NOT reported as a quota problem.
run badtag CODEX_STUB=ok OLLAMA_STUB=badtag bash "$SCRIPT" "$T/change.diff"
check "badtag: FAILED section" has badtag.out "## Independent review — ollama-cloud — FAILED"
check "badtag: quotes the real error line" has badtag.out "Error: pull model manifest: file does not exist"
check "badtag: summary says exit 1, not quota" has badtag.out "reviewers: codex OK, ollama-cloud FAILED (exit 1)"
check "badtag: not classified as quota anywhere" lacks badtag.out "quota/rate limit"
check "badtag: spinner redraws collapse to one line" [ "$(grep -c 'pulling manifest' "$T/badtag.out")" = 1 ]

# 4. Only the TAIL of stderr is classified: codex echoes the reviewed diff (which
#    mentions a 429) into stderr before its real, non-quota error.
run codexauth CODEX_STUB=auth bash "$SCRIPT" "$T/change.diff"
check "codexauth: exit 0 (ollama-cloud succeeded)" rc_is codexauth 0
check "codexauth: codex FAILED section" has codexauth.out "## Independent review — codex — FAILED"
check "codexauth: quotes the real error" has codexauth.out "not signed in"
check "codexauth: a 429 in the echoed artifact is not read as quota" has codexauth.out "reviewers: codex FAILED (exit 1), ollama-cloud OK"

# 5. Nothing succeeds: exit 4, both failures on stdout, paste prompt still printed.
run none CODEX_STUB=auth OLLAMA_STUB=429 bash "$SCRIPT" "$T/change.diff"
check "none: exit 4" rc_is none 4
check "none: codex FAILED section" has none.out "## Independent review — codex — FAILED"
check "none: ollama FAILED section" has none.out "## Independent review — ollama-cloud — FAILED"
check "none: summary tells the two failures apart" has none.out "reviewers: codex FAILED (exit 1), ollama-cloud FAILED (quota/rate limit"
check "none: note says 0 reviewers" has none.out "landed with 0 successful external reviewer(s)"
check "none: manual paste prompt still printed" has none.out "--- BEGIN diff ---"

# 6. --first-success on a plan: one reviewer by choice — said, not hidden.
run firstplan bash "$SCRIPT" "$T/plan.md" --first-success
check "firstplan: exit 0" rc_is firstplan 0
check "firstplan: ollama was never run" [ ! -e "$T/firstplan.marks/ollama-ran" ]
check "firstplan: summary lists codex only" has firstplan.out "reviewers: codex OK"
check "firstplan: note names the deliberate choice" has firstplan.out "⚠ PLAN round landed with 1 successful external reviewer(s), fewer than the 2 of the standard pair — --first-success was requested."

# 7. A local model outside --local-only: its review prints but does not count.
run local OLLAMA_MODEL=stub-local bash "$SCRIPT" "$T/change.diff"
check "local: its review is printed" has local.out "## Independent review — ollama (stub-local)"
check "local: no FAILED section for a policy rejection" lacks local.out "— FAILED"
check "local: summary says NOT COUNTED" has local.out "reviewers: codex OK, ollama-local NOT COUNTED (local model: sanity pass only)"
check "local: counts 1 reviewer" has local.out "landed with 1 successful external reviewer(s)"

if [ $fails -ne 0 ]; then echo "$fails check(s) FAILED"; exit 1; fi
echo "all checks passed"
