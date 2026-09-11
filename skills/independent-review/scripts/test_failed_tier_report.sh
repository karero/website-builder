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

# Stubs are plain sh with printf '%s\n' so they behave the same under dash (CI) and bash.
cat >"$T/bin/codex" <<'EOF'
#!/bin/sh
: >"$STUB_MARKS/codex-ran"
case "${CODEX_STUB:-ok}" in
  ok)   printf '%s\n' '- BUG: stub finding one' '- NIT: stub finding two' ;;
  auth) # codex echoes the reviewed artifact into stderr — here one that mentions
        # a 429 — long before its real, non-quota error.
        printf '%s\n' 'user' '+retry on HTTP 429 Too Many Requests after a pause' >&2
        i=0; while [ $i -lt 20 ]; do echo "exec step $i" >&2; i=$((i+1)); done
        echo "ERROR: not signed in - run codex login" >&2; exit 1 ;;
  authshort) # the same, with the artifact line right next to the error
        printf '%s\n' 'user' '+retry on HTTP 429 Too Many Requests after a pause' >&2
        echo "ERROR: not signed in - run codex login" >&2; exit 1 ;;
  authctx) # a diff CONTEXT line (leading space) shaped like an error, then the real one
        printf '%s\n' 'user' ' ERROR: 429 Too Many Requests in the old handler' >&2
        echo "ERROR: not signed in - run codex login" >&2; exit 1 ;;
  tracing429) # a tracing-style error line followed by trailer lines. The shape is
        # assumed, not captured from a real codex quota refusal.
        printf '%s\n' '2026-09-11T19:24:25.123Z ERROR codex_core::client: unexpected status 429 Too Many Requests' \
          'tokens used' '0' 'session end' 'bye' >&2; exit 1 ;;
  diskquota) # a local setup failure that merely contains the word "quota"
        echo "ERROR: disk quota exceeded while writing the session log" >&2; exit 1 ;;
esac
EOF
cat >"$T/bin/ollama" <<'EOF'
#!/bin/sh
case "$1" in
  list) if [ "${OLLAMA_STUB:-ok}" = listfail ]; then
          echo "Error: could not connect to ollama app, is it running?" >&2; exit 1
        fi
        printf 'NAME                ID      SIZE    MODIFIED\n%s    abc123  -       1 day ago\n' "$STUB_TAG"; exit 0 ;;
  run)  : >"$STUB_MARKS/ollama-ran" ;;
esac
case "${OLLAMA_STUB:-ok}" in
  ok)     printf '%s\n' '- RISK: stub ollama finding' '- NIT: another' ;;
  429)    # the byte shape of the 2026-09-11 failure: spinner, cursor and sync-mode escapes
          printf '\033[?2026h\033[?25l\033[1G\342\240\231 \033[K\033[?25h\033[?2026l\033[?25l\033[2K\033[1G\033[?25hError: 429 Too Many Requests: you (someone) have reached your weekly usage limit, upgrade for higher limits\n' >&2
          exit 1 ;;
  out429) printf '%s\n' 'Error: 429 Too Many Requests: weekly usage limit reached'; exit 1 ;;
  badtag) i=0; while [ $i -lt 4 ]; do printf '\033[?25l\033[1Gpulling manifest \342\240\213 \033[K\033[?25h' >&2; i=$((i+1)); done
          printf '\nError: pull model manifest: file does not exist\n' >&2; exit 1 ;;
  oddesc) # escapes outside the ESC[...letter shape: ESC[0~ (final byte ~), a charset
          # designation ESC(B, and a BEL
          printf '\033[0~\033[2;5H\033(BError: bad model\007\n' >&2; exit 1 ;;
  oddbody) # a review body with an escape the redraw filter does not emulate
          printf 'Introduction\n\033[0~1. BUG: important finding\n- NIT: second finding\n' ;;
  strayesc) # a review body ending in a lone ESC the filter cannot parse
          printf '%s\n' '- BUG: one' '- NIT: two'; printf '\033' ;;
  utf8cut) # stderr starting mid-glyph, as `tail -c` produces: two continuation bytes
          printf '\240\231 spinner\nError: 429 Too Many Requests: weekly usage limit reached\n' >&2; exit 1 ;;
  notreview) # a reply the refusal check rejects, carrying a decoy error-shaped 429 line
          printf '%s\n' 'No findings.' 'I could not read the retry code.' \
            'Error: 429 responses are retried, per the comment - UNVERIFIABLE.' ;;
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
check "incident: summary names the quota failure" has incident.out "reviewers: codex OK, ollama-cloud FAILED (exit 1; quota/rate limit: wait or add credits)"
check "incident: a DIFF round with 1 reviewer says so" has incident.out "⚠ DIFF round landed with 1 reviewer(s) counted toward the gate"
check "incident: the summary also reaches stderr" has incident.err "reviewers: codex OK, ollama-cloud FAILED (exit 1; quota"

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

# 4. Only error-record lines decide quota: codex echoes the reviewed diff (which
#    mentions a 429) into stderr before its real, non-quota error — far from it (4)
#    and right next to it (4b; round-1 review, Codex).
run codexauth CODEX_STUB=auth bash "$SCRIPT" "$T/change.diff"
check "codexauth: exit 0 (ollama-cloud succeeded)" rc_is codexauth 0
check "codexauth: codex FAILED section" has codexauth.out "## Independent review — codex — FAILED"
check "codexauth: quotes the real error" has codexauth.out "not signed in"
check "codexauth: a 429 in the echoed artifact is not read as quota" has codexauth.out "reviewers: codex FAILED (exit 1), ollama-cloud OK"
run codexshort CODEX_STUB=authshort bash "$SCRIPT" "$T/change.diff"
check "codexshort: the 429 line sits inside the quoted tail" has codexshort.out "+retry on HTTP 429 Too Many Requests"
check "codexshort: and still is not read as quota" has codexshort.out "reviewers: codex FAILED (exit 1), ollama-cloud OK"

# 5. Nothing succeeds: exit 4, both failures on stdout, paste prompt still printed.
run none CODEX_STUB=auth OLLAMA_STUB=429 bash "$SCRIPT" "$T/change.diff"
check "none: exit 4" rc_is none 4
check "none: codex FAILED section" has none.out "## Independent review — codex — FAILED"
check "none: ollama FAILED section" has none.out "## Independent review — ollama-cloud — FAILED"
check "none: summary tells the two failures apart" has none.out "reviewers: codex FAILED (exit 1), ollama-cloud FAILED (exit 1; quota/rate limit"
check "none: note says 0 reviewers" has none.out "landed with 0 reviewer(s) counted toward the gate"
check "none: manual paste prompt still printed" has none.out "--- BEGIN diff ---"

# 6. --first-success on a plan: one reviewer by choice — said, not hidden.
run firstplan bash "$SCRIPT" "$T/plan.md" --first-success
check "firstplan: exit 0" rc_is firstplan 0
check "firstplan: ollama was never run" [ ! -e "$T/firstplan.marks/ollama-ran" ]
check "firstplan: summary lists codex only" has firstplan.out "reviewers: codex OK"
check "firstplan: note names the deliberate choice" has firstplan.out "⚠ PLAN round landed with 1 reviewer(s) counted toward the gate, fewer than the 2 of the standard pair — --first-success was requested."

# 7. A local model outside --local-only: its review prints but does not count.
run local OLLAMA_MODEL=stub-local bash "$SCRIPT" "$T/change.diff"
check "local: its review is printed" has local.out "## Independent review — ollama (stub-local)"
check "local: no FAILED section for a policy rejection" lacks local.out "— FAILED"
check "local: summary says NOT COUNTED" has local.out "reviewers: codex OK, ollama-local NOT COUNTED (local model: sanity pass only)"
check "local: counts 1 reviewer" has local.out "landed with 1 reviewer(s) counted toward the gate"

# 8. --local-only: the one local reviewer counts (degraded), and is not called external.
run localonly OLLAMA_MODEL=stub-local bash "$SCRIPT" "$T/change.diff" --local-only
check "localonly: exit 0" rc_is localonly 0
check "localonly: codex never ran" [ ! -e "$T/localonly.marks/codex-ran" ]
check "localonly: summary" has localonly.out "reviewers: ollama-local OK"
check "localonly: note names the mode" has localonly.out "landed with 1 reviewer(s) counted toward the gate, fewer than the 2 of the standard pair — --local-only, degraded by owner choice."
check "localonly: not described as external" lacks localonly.out "external reviewer"

# 9. An error printed on STDOUT before a non-zero exit is quoted and classified.
run out429 CODEX_STUB=ok OLLAMA_STUB=out429 bash "$SCRIPT" "$T/change.diff"
check "out429: stdout is quoted" has out429.out "    Error: 429 Too Many Requests: weekly usage limit reached"
check "out429: classified as quota" has out429.out "reviewers: codex OK, ollama-cloud FAILED (exit 1; quota/rate limit: wait or add credits)"

# 10. A named model whose `ollama list` fails (daemon down) is a FAILED tier with its
#     error, not a silent SKIPPED; with no model named, it is skipped and stderr says why.
run listfail CODEX_STUB=ok OLLAMA_STUB=listfail OLLAMA_MODEL="$STUB_TAG" bash "$SCRIPT" "$T/change.diff"
check "listfail: FAILED section" has listfail.out "## Independent review — ollama-cloud — FAILED"
check "listfail: quotes the daemon error" has listfail.out "could not connect to ollama app"
check "listfail: summary names the preflight" has listfail.out "ollama-cloud FAILED ('ollama list' failed (is the ollama daemon running?))"
run listfailauto CODEX_STUB=ok OLLAMA_STUB=listfail bash "$SCRIPT" "$T/change.diff"
check "listfailauto: skipped, with the startup note on stderr" has listfailauto.err "'ollama list' failed — cannot auto-detect"
check "listfailauto: summary says SKIPPED" has listfailauto.out "reviewers: codex OK, ollama SKIPPED (not available)"
check "listfailauto: the note fits a skip, not a failure (round 2, kimi)" has listfailauto.out "the standard pair did not both run"
check "listfailauto: no pointer to a FAILED section that is not there" lacks listfailauto.out "each FAILED section above"

# 11. Escapes outside the simple ESC[..letter shape are stripped too.
run oddesc CODEX_STUB=ok OLLAMA_STUB=oddesc bash "$SCRIPT" "$T/change.diff"
check "oddesc: the error text survives" has oddesc.out "    Error: bad model"
check "oddesc: no escape bytes reach stdout" lacks oddesc.out $'\033'
check "oddesc: no BEL reaches stdout" lacks oddesc.out $'\007'

# 12. stderr cut mid-glyph (tail -c cuts on bytes) must not kill the quote (round 2, Fable).
run utf8cut CODEX_STUB=ok OLLAMA_STUB=utf8cut bash "$SCRIPT" "$T/change.diff"
check "utf8cut: the error is still quoted" has utf8cut.out "    Error: 429 Too Many Requests: weekly usage limit reached"
check "utf8cut: and classified as quota" has utf8cut.out "reviewers: codex OK, ollama-cloud FAILED (exit 1; quota/rate limit: wait or add credits)"

# 13. A reply rejected as not a review: its own outcome, never quota or setup advice,
#     even with an error-shaped 429 line in it (round 2, Fable; the other branch's reviewers).
run notreview CODEX_STUB=ok OLLAMA_STUB=notreview bash "$SCRIPT" "$T/change.diff"
check "notreview: exit 0 (codex counted)" rc_is notreview 0
check "notreview: FAILED section" has notreview.out "## Independent review — ollama-cloud — FAILED"
check "notreview: summary names the rejection" has notreview.out "reviewers: codex OK, ollama-cloud FAILED (output is not a review)"
check "notreview: the reply is quoted" has notreview.out "    I could not read the retry code."
check "notreview: not a quota or setup problem" has notreview.out "Not a quota or setup problem"
check "notreview: the decoy 429 is not read as quota" lacks notreview.out "quota/rate limit"
check "notreview: no sign-in advice" lacks notreview.out "sign-in"

# 14. A tracing-style codex error with trailer lines after it is still classified.
run tracing CODEX_STUB=tracing429 bash "$SCRIPT" "$T/change.diff"
check "tracing: codex classified as quota" has tracing.out "reviewers: codex FAILED (exit 1; quota/rate limit: wait or add credits), ollama-cloud OK"

# 15. A diff context line (leading space) shaped like an error is not read as quota
#     (round 2, Codex).
run codexctx CODEX_STUB=authctx bash "$SCRIPT" "$T/change.diff"
check "codexctx: an indented artifact line is not read as quota" has codexctx.out "reviewers: codex FAILED (exit 1), ollama-cloud OK"

# 16. The review-body filter consumes an escape it does not emulate (ESC[0~) instead of
#     silently ending the review there (round 2, Codex; pre-existing on main)...
run oddbody CODEX_STUB=ok OLLAMA_STUB=oddbody bash "$SCRIPT" "$T/change.diff"
check "oddbody: the finding after the escape survives" has oddbody.out "1. BUG: important finding"
check "oddbody: counted" has oddbody.out "reviewers: codex OK, ollama-cloud OK"
check "oddbody: no escape bytes" lacks oddbody.out $'\033'

# 17. ...and fails the tier on one it cannot parse, rather than counting a truncated review.
run strayesc CODEX_STUB=ok OLLAMA_STUB=strayesc bash "$SCRIPT" "$T/change.diff"
check "strayesc: FAILED, not a truncated review" has strayesc.out "reviewers: codex OK, ollama-cloud FAILED (output filter failed (exit 4))"

# 18. "disk quota exceeded" is a setup failure, not a provider refusal (round 2, kimi).
run diskquota CODEX_STUB=diskquota bash "$SCRIPT" "$T/change.diff"
check "diskquota: not read as a provider quota" has diskquota.out "reviewers: codex FAILED (exit 1), ollama-cloud OK"

if [ $fails -ne 0 ]; then echo "$fails check(s) FAILED"; exit 1; fi
echo "all checks passed"
