#!/usr/bin/env bash
#
# test_failed_tier_report.sh — drives independent_review.sh end to end, the way a
# caller does (default flags, auto-detected ollama model), with stub `codex` and
# `ollama` CLIs first on PATH and $HOME relocated. No reviewer is contacted and
# nothing leaves the machine; Antigravity is forced off except in case 23, which
# turns it on against a stub `agy`.
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
HERE="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
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
# Like the real CLI (0.157.0, seen 2026-09-26): outside a git repo, refuse to start
# unless --skip-git-repo-check is passed. Records its whole argv, the prompt replaced by
# <prompt> (found by its content, not its position), so a test can pin it exactly: an
# added sandbox override fails the match instead of hiding behind "-s read-only is in
# there somewhere" (round 1, fresh-eyes), and so does one placed after the prompt or
# after a prompt moved to stdin (round 2, fresh-eyes and ollama). Each argument is
# bracketed, so "-s read-only" passed as ONE argument does not match (round 3, fresh-eyes).
skip=0 argv=
for a; do
  [ "$a" = --skip-git-repo-check ] && skip=1
  case "$a" in *'--- BEGIN '*) printf '%s\n' "$a" >"$STUB_MARKS/codex-prompt"; a='<prompt>' ;; esac
  argv="$argv[$a]"
done
printf 'argv=%s cwd=%s git=%s\n' "$argv" "$(pwd -P)" \
  "$(git rev-parse --is-inside-work-tree 2>/dev/null || echo no)" >"$STUB_MARKS/codex-args"
if [ $skip -eq 0 ] && ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  printf '%s\n' 'Reading additional input from stdin...' \
    'Not inside a trusted directory and --skip-git-repo-check was not specified.' >&2
  exit 1
fi
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
  reply) printf '%s\n' "$STUB_REPLY" ;;   # a successful run whose whole reply is $STUB_REPLY
  slow)  sleep 2; printf '%s\n' '- BUG: stub finding one' ;;   # a reviewer that takes a while
  tokens) # a run that reports its token count on stderr, as codex ends a run
        printf '%s\n' 'tokens used' '61,108' >&2; printf '%s\n' '- BUG: stub finding one' ;;
  stubborn) # a CLI that ignores SIGTERM, as one mid-request might; records its pid
        trap '' TERM; echo $$ >"$STUB_MARKS/codex-pid"; sleep 30 ;;
  wrapped) # a launcher whose worker, one level further down, ignores SIGTERM; records its pid
        sh -c 'trap "" TERM; echo $$ >"$STUB_MARKS/codex-worker"; sleep 30' & wait ;;
esac
EOF
cat >"$T/bin/ollama" <<'EOF'
#!/bin/sh
case "$1" in
  list) if [ "${OLLAMA_STUB:-ok}" = listfail ]; then
          echo "Error: could not connect to ollama app, is it running?" >&2; exit 1
        fi
        printf 'NAME                ID      SIZE    MODIFIED\n%s    abc123  -       1 day ago\n' "$STUB_TAG"; exit 0 ;;
  run)  shift
        if [ "$1" = --help ]; then   # STUB_OLDCLI: 1 = too old to know --hidethinking; failhelp =
                                      # help fails; longword = the flag only inside a longer word
          case "${STUB_OLDCLI:-}" in
            1)        echo '      --verbose                 Show timings for response' ;;
            failhelp) echo 'Error: unknown flag: --hidethinking' >&2; exit 1 ;;
            longword) echo '      --hidethinking-format     (a different option)' ;;
            *)        echo '      --hidethinking            Hide thinking output (if provided)' ;;
          esac
          exit 0
        fi
        if [ "$1" = --hidethinking ]; then : >"$STUB_MARKS/ollama-hidethinking"; shift; fi
        : >"$STUB_MARKS/ollama-ran"; printf '%s\n' "$1" >"$STUB_MARKS/ollama-model"
        printf '%s\n' "$2" >"$STUB_MARKS/ollama-prompt" ;;
esac
case "${OLLAMA_STUB:-ok}" in
  ok)     printf '%s\n' '- RISK: stub ollama finding' '- NIT: another' ;;
  think)  # a reasoning model, as the real CLI prints it: the trace only without --hidethinking.
          # Its trace quotes the prompt's "could not read" advice (2026-09-27).
          if [ ! -e "$STUB_MARKS/ollama-hidethinking" ]; then
            printf '%s\n' 'Thinking...' 'The advice says: phrase it about the claim, not "I could not read".' '...done thinking.' ''
          fi
          printf '%s\n' 'RISK — retry.rb:12 — the retry loop never terminates on a stalled connection.' 'No BUG or NIT findings.' ;;
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
  bigquota) # the quota error first, then ~120 KB of other error-shaped lines across stderr
          # and stdout, each line distinct (the quote collapses repeats): past the pipe
          # buffer, so a grep -q that stops at the 429 exits early
          x=$(printf '%8100s' '' | tr ' ' x)
          printf '%s\n' 'Error: 429 Too Many Requests: weekly usage limit reached' >&2
          i=0; while [ $i -lt 7 ]; do printf 'Error: stream %s failed %s\n' "$i" "$x" >&2; i=$((i+1)); done
          i=0; while [ $i -lt 8 ]; do printf 'Error: stream 1%s failed %s\n' "$i" "$x"; i=$((i+1)); done
          exit 1 ;;
  notreview) # a reply the refusal check rejects, carrying a decoy error-shaped 429 line
          printf '%s\n' 'No findings.' 'I could not read the retry code.' \
            'Error: 429 responses are retried, per the comment - UNVERIFIABLE.' ;;
  reply)  printf '%s\n' "$STUB_REPLY" ;;   # as in the codex stub: the whole reply is $STUB_REPLY
  slow)   sleep 2; printf '%s\n' '- RISK: stub ollama finding' ;;
esac
EOF
cat >"$T/bin/agy" <<'EOF'
#!/bin/sh
# Records its argv as the codex stub does, prompt replaced by <prompt>, and keeps the
# prompt itself so a test can check WHICH prompt was sent, not just that one was.
argv=
for a; do
  case "$a" in *'--- BEGIN '*) printf '%s\n' "$a" >"$STUB_MARKS/agy-prompt"; a='<prompt>' ;; esac
  argv="$argv[$a]"
done
printf 'argv=%s\n' "$argv" >"$STUB_MARKS/agy-args"
printf '%s\n' "$(pwd -P)" >"$STUB_MARKS/agy-cwd"
ls -A | wc -l | tr -d ' ' >"$STUB_MARKS/agy-cwd-entries"
case "${AGY_STUB:-ok}" in
  ok)     printf '%s\n' '- BUG: stub agy finding' '- NIT: another' ;;
  denied) # the 2026-09-26 failure: exit 0, nothing on stdout, the reason on stderr
          printf '%s\n' 'jetski: no output produced — a tool required the "command" permission that headless mode cannot prompt for, so it was auto-denied.' >&2 ;;
esac
EOF
# A stub curl for the ollama HTTP API transport: records the URL, the request body and the header
# file it was handed (the file, not argv, must carry any key), and plays back a canned NDJSON stream.
cat >"$T/bin/curl" <<'EOF'
#!/bin/sh
out= body= url=
while [ $# -gt 0 ]; do
  case "$1" in
    -o) out="$2"; shift ;;
    --data-binary) body="${2#@}"; shift ;;
    -H) case "$2" in @*) cp "${2#@}" "$STUB_MARKS/curl-hdr" 2>/dev/null ;; esac; shift ;;
    -w|--max-time) shift ;;
    http*) url="$1" ;;
  esac
  shift
done
printf '%s\n' "$url" >"$STUB_MARKS/curl-url"
cp "$body" "$STUB_MARKS/curl-body"
case "${API_STUB:-ok}" in
  ok)    printf '%s\n' '{"message":{"role":"assistant","content":"- BUG: api "},"done":false}' \
           '{"message":{"role":"assistant","content":"finding one\n- NIT: two"},"done":false}' \
           '{"message":{"role":"assistant","content":""},"done":true,"prompt_eval_count":500,"eval_count":250}' >"$out"
         printf 200 ;;
  429)   printf '%s\n' '{"error":"you have reached your weekly usage limit"}' >"$out"; printf 429 ;;
  trunc) printf '%s\n' '{"message":{"role":"assistant","content":"- BUG: cut off"},"done":false}' >"$out"; printf 200 ;;
  502)   printf 'upstream request failed' >"$out"; printf 502 ;;
  down)  echo "curl: (56) CONNECT tunnel failed, response 403" >&2; exit 56 ;;
esac
EOF
chmod +x "$T/bin/codex" "$T/bin/ollama" "$T/bin/agy" "$T/bin/curl"
# A PATH with no ollama CLI, as in a cloud session: the codex and curl stubs, then the system.
mkdir -p "$T/bin2"; cp "$T/bin/codex" "$T/bin/curl" "$T/bin2/"

# run <name> [VAR=value ...] <command ...> — leaves $T/<name>.out, .err and .rc
run() {
  local name="$1"; shift
  mkdir -p "$T/$name.marks"
  env -u CODEX_MODEL -u CODEX_EFFORT -u REVIEW_LOG -u XDG_STATE_HOME -u OLLAMA_API_KEY -u OLLAMA_TRANSPORT -u OLLAMA_MODEL -u OLLAMA_HOST -u AGY_MODEL -u GIT_DIR -u GIT_WORK_TREE \
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
not_in() { [ -e "$1" ] && ! grep -qF -- "$2" "$1"; }   # not_in <path> <text>: file exists, text absent
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

# 12b. A quota error followed by more error-shaped output than a pipe buffer holds. The
#      classifier piped those lines into grep -q, which exits at the 429; under pipefail the
#      filter it killed mid-write flipped the result to a generic failure. That is a race, lost
#      on roughly a third of runs at this size (the quote caps each file at 64 KiB, so it cannot
#      be made bigger), so each mode runs six times: as started, and with SIGPIPE ignored
#      (EPIPE instead of a signal), as on GitHub Actions runners.
bq_modes="default"
if command -v perl >/dev/null 2>&1; then bq_modes="default ignore"
else echo "SKIP bigquota with SIGPIPE ignored: it needs perl to start bash with SIGPIPE ignored"; fi
for m in $bq_modes; do
  bq_ok=1
  for k in 1 2 3 4 5 6; do
    if [ "$m" = ignore ]; then
      run bigquota CODEX_STUB=ok OLLAMA_STUB=bigquota perl -e '$SIG{PIPE}="IGNORE"; exec @ARGV' bash "$SCRIPT" "$T/change.diff"
    else run bigquota CODEX_STUB=ok OLLAMA_STUB=bigquota bash "$SCRIPT" "$T/change.diff"; fi
    has bigquota.out "reviewers: codex OK, ollama-cloud FAILED (exit 1; quota/rate limit: wait or add credits)" || bq_ok=0
  done
  check "bigquota: classified as quota on all 6 runs$([ "$m" = ignore ] && echo " (SIGPIPE ignored)")" [ "$bq_ok" = 1 ]
done

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

# 19. A clean verdict with a qualifier between "no" and the severity word counts. On 2026-09-20
#     a genuine clean codex review reading "No confirmed BUG or RISK in the supplied diff." was
#     reported FAILED (output is not a review), and the seat was lost. Both seats share the check.
n=0
for reply in "No confirmed BUG or RISK in the supplied diff." "No definite BUG." \
             "I found no confirmed bugs in this change." "No new or confirmed RISK."; do
  n=$((n+1))
  run "verdict$n" CODEX_STUB=reply STUB_REPLY="$reply" bash "$SCRIPT" "$T/change.diff"
  check "verdict$n: codex counted — $reply" has "verdict$n.out" "reviewers: codex OK, ollama-cloud OK"
  check "verdict$n: printed as codex's review, not quoted in a FAILED section" lacks "verdict$n.out" "— FAILED"
done
run verdictollama OLLAMA_STUB=reply STUB_REPLY="No confirmed BUG or RISK in the supplied diff." bash "$SCRIPT" "$T/change.diff"
check "verdictollama: the ollama seat counts the same verdict" has verdictollama.out "reviewers: codex OK, ollama-cloud OK"
check "verdictollama: no FAILED section" lacks verdictollama.out "FAILED"

# 20. ...and what must still be rejected is: a plain refusal (a baseline: rejected before the
#     fix too), a refusal carrying the qualified verdict in a phrase the refusal check knows (it
#     runs first; the phrases it misses are pinned KNOWN WRONG in test_looks_like_review.sh), and
#     "no way to find bugs" (the qualifiers are a literal list, not any word).
n=0
for reply in "I'm sorry, but I am unable to review this diff because the repository is not available to me." \
             "No confirmed BUG or RISK, because I cannot access the diff you supplied." \
             "There is no way to find bugs in this without more context."; do
  n=$((n+1))
  run "refusal$n" CODEX_STUB=reply STUB_REPLY="$reply" bash "$SCRIPT" "$T/change.diff"
  check "refusal$n: exit 0 (ollama-cloud counted)" rc_is "refusal$n" 0
  check "refusal$n: codex rejected — $reply" has "refusal$n.out" "reviewers: codex FAILED (output is not a review), ollama-cloud OK"
done

# 21. Called from outside any git repo (a plan in a scratch dir): codex must still run,
#     in the caller's cwd, with the read-only sandbox still requested and project AGENTS.md
#     and skills kept out — on both command lines, the default and the CODEX_MODEL one.
#     Before the fix the PLAN round came back with codex FAILED and one reviewer
#     (2026-09-26). GIT_CEILING_DIRECTORIES keeps git from finding a repo above $T, wherever
#     TMPDIR lives; run() drops GIT_DIR and GIT_WORK_TREE, which a git hook exports and
#     which would otherwise override it.
mkdir -p "$T/nogit"
NOGIT="$(cd "$T/nogit" && pwd -P)"
CEILING="$(cd "$T" && pwd -P)"
for m in "" stub-override; do
  name="nogit${m:+-model}"
  run "$name" CODEX_MODEL="$m" GIT_CEILING_DIRECTORIES="$CEILING" \
    sh -c 'cd "$1" && shift && exec bash "$@"' _ "$NOGIT" "$SCRIPT" "$T/plan.md"
  check "$name: codex counted, not FAILED" has "$name.out" "reviewers: codex OK, ollama-cloud OK"
  # git=no is what git said from inside the stub itself, so the case cannot pass from
  # inside a repo (round 4, fresh-eyes).
  want="argv=[exec][-s][read-only][--skip-git-repo-check][-c][project_doc_max_bytes=0][-c][skills.include_instructions=false]${m:+[-c][model=\"$m\"]}[<prompt>] cwd=$NOGIT git=no"
  check "$name: exact argv (read-only, nothing looser), caller's cwd, outside git" \
    grep -qxF -- "$want" "$T/$name.marks/codex-args"
done

# 22. KNOWN WRONG (B-TAGCLASS), deferred with the owner's sign-off of 2026-09-26: the size arms of
# is_cloud_ollama_tag() call any "*:120b" tag cloud, even a model pulled and run locally, so it is
# refused under --local-only and counted as a cloud reviewer outside it. These pin today's wrong
# results through the real entry point, so whoever fixes the classifier changes them on purpose.
BIG_TAG="stub-big"; BIG_TAG="${BIG_TAG}:120b"   # built at runtime, like STUB_TAG
run bigtaglocal OLLAMA_MODEL="$BIG_TAG" bash "$SCRIPT" "$T/change.diff" --local-only
check "KNOWN WRONG (B-TAGCLASS): a local *:120b tag is refused under --local-only" has bigtaglocal.err "looks like a cloud tag"
check "KNOWN WRONG (B-TAGCLASS): ...with exit 2, before any reviewer runs" \
  sh -c '[ "$(cat "$1/bigtaglocal.rc")" = 2 ] && [ ! -e "$1/bigtaglocal.marks/ollama-ran" ]' _ "$T"
run bigtag OLLAMA_MODEL="$BIG_TAG" bash "$SCRIPT" "$T/change.diff"
check "KNOWN WRONG (B-TAGCLASS): a local *:120b tag counts as a cloud reviewer" has bigtag.out "reviewers: codex OK, ollama-cloud OK"
check "B-TAGCLASS guard: the tag that ran is the configured one, not the listed cloud model" \
  grep -qxF -- "$BIG_TAG" "$T/bigtag.marks/ollama-model"

# 23. Antigravity headless. With `--sandbox -p` and the MODE-line prompt, agy reached for a
#     tool needing the "command" permission, headless mode auto-denied it, and the tier exited 0
#     with no output — on 1.2.9 and again on 1.2.11 (2026-09-26). The fix asks for plan mode and
#     loosens nothing: no --dangerously-skip-permissions. The exact argv pins that on both command
#     lines, the default and the AGY_MODEL one. The stub cannot show the real CLI now answers; it
#     shows the script asks for what the manual run that did answer used.
#     The prompt: the text-only one said "You have NO tools", which is false for agy, and on
#     2026-09-27 (1.2.12, plan mode) the model tried `echo` to test it; the denial ended the run.
#     So agy gets PROMPT_AGY, which asks for no tool calls without claiming there are none, and
#     must never get the false sentence back.
for m in "" stub-agy-model; do
  name="agy${m:+-model}"
  run "$name" WITH_ANTIGRAVITY=1 AGY_MODEL="$m" bash "$SCRIPT" "$T/change.diff"
  check "$name: agy counted alongside the pair" has "$name.out" "reviewers: codex OK, ollama-cloud OK, antigravity OK"
  check "$name: header names the model" has "$name.out" "## Independent review — antigravity/agy (${m:-CLI default}"
  check "$name: header says plan mode, told not to use tools" has "$name.out" ", sandbox, plan mode, told not to use tools)"
  want="argv=[--sandbox][--mode][plan]${m:+[--model][$m]}[-p][<prompt>]"
  check "$name: exact argv (sandbox + plan mode, nothing looser)" grep -qxF -- "$want" "$T/$name.marks/agy-args"
  check "$name: sent the agy prompt" grep -qF -- "the refusal ends the run" "$T/$name.marks/agy-prompt"
  check "$name: not told the false 'You have NO tools'" not_in "$T/$name.marks/agy-prompt" "You have NO tools"
  check "$name: ollama, which really has no tools, still gets the text-only prompt" \
    grep -qF -- "You have NO tools" "$T/$name.marks/ollama-prompt"
  check "$name: not the MODE-line prompt" not_in "$T/$name.marks/agy-prompt" "MODE: INSPECTED"
  check "$name: the artifact is in the prompt" grep -qF -- "+retry on HTTP 429 after a pause" "$T/$name.marks/agy-prompt"
  # These pin the directory agy is LAUNCHED in, not an access boundary: its tools run elsewhere
  # and can read absolute paths (see the tier table in independent_review.sh).
  check "$name: ran outside the caller's cwd" \
    sh -c '[ -s "$1" ] && [ "$(cat "$1")" != "$(pwd -P)" ]' _ "$T/$name.marks/agy-cwd"
  check "$name: in an empty dir" [ "$(cat "$T/$name.marks/agy-cwd-entries")" = 0 ]
done
# ...and if agy still comes back empty, the tier is FAILED with its stderr quoted, not dropped
# and not counted; the pair still carries the round.
run agydenied WITH_ANTIGRAVITY=1 AGY_STUB=denied bash "$SCRIPT" "$T/change.diff"
check "agydenied: exit 0 (the pair counted)" rc_is agydenied 0
check "agydenied: summary names the empty run" has agydenied.out "reviewers: codex OK, ollama-cloud OK, antigravity FAILED (exit 0 but no output)"
check "agydenied: quotes the auto-deny reason" has agydenied.out "headless mode cannot prompt for"

# 24. The default pair runs at once (2026-09-26): two reviewers that take 2s each finish in
#     well under the 4s they took one after the other, and the sections still print in tier
#     order, codex first. A timings line follows the reviewers line.
start=$SECONDS
run parallel CODEX_STUB=slow OLLAMA_STUB=slow bash "$SCRIPT" "$T/change.diff"
elapsed=$((SECONDS - start))
check "parallel: both counted" has parallel.out "reviewers: codex OK, ollama-cloud OK"
check "parallel: took ${elapsed}s, under the 4s of a sequential run" [ "$elapsed" -lt 4 ]
check "parallel: codex's section prints before ollama's" \
  sh -c 'c=$(grep -n "^## Independent review — codex" "$1" | cut -d: -f1); o=$(grep -n "^## Independent review — ollama" "$1" | cut -d: -f1); [ -n "$c" ] && [ -n "$o" ] && [ "$c" -lt "$o" ]' _ "$T/parallel.out"
check "parallel: a timings line names both tiers" \
  grep -qE '^timings: codex [0-9]+s, ollama-cloud [0-9]+s$' "$T/parallel.out"
check "parallel: a failed tier still gets its FAILED section" has incident.out "## Independent review — ollama-cloud — FAILED"
# --first-success stays one tier at a time: the second never starts once the first counts.
run firstsucc CODEX_STUB=ok bash "$SCRIPT" "$T/change.diff" --first-success
check "first-success: ollama never ran" [ ! -e "$T/firstsucc.marks/ollama-ran" ]
check "first-success: timings name codex alone" grep -qE '^timings: codex [0-9]+s$' "$T/firstsucc.out"
# A skipped tier (not installed) has no time to report.
run notimeskip CODEX_STUB=ok OLLAMA_STUB=listfail bash "$SCRIPT" "$T/change.diff"
check "skipped tier: not in the timings line" grep -qE '^timings: codex [0-9]+s$' "$T/notimeskip.out"

# 24b. Stopping the script stops its reviewers, even one that ignores SIGTERM: none keeps
#      running (and billing) after the script is gone (round 1, fresh-eyes).
mkdir -p "$T/stop.marks"
env -u CODEX_MODEL -u CODEX_EFFORT -u OLLAMA_MODEL -u OLLAMA_HOST -u AGY_MODEL PATH="$T/bin:$PATH" HOME="$T/u" \
  WITH_ANTIGRAVITY=0 REVIEW_RAW_DIR="$T/stop.raw" STUB_MARKS="$T/stop.marks" STUB_TAG="$STUB_TAG" \
  CODEX_STUB=stubborn OLLAMA_STUB=slow bash "$SCRIPT" "$T/change.diff" >"$T/stop.out" 2>"$T/stop.err" &
spid=$!
i=0; while [ ! -s "$T/stop.marks/codex-pid" ] && [ $i -lt 50 ]; do sleep 0.1; i=$((i+1)); done
kill -TERM "$spid"; wait "$spid"; echo $? >"$T/stop.rc"
check "stop: the script exits 130" rc_is stop 130
# Gone or a zombie: once its parent subshell is killed the CLI is reparented, and a container's
# PID 1 may never reap it, so it can linger as <defunct> -- dead, not running.
check "stop: the TERM-ignoring reviewer is gone" \
  sh -c 'p=$(cat "$1"); [ -n "$p" ] && case "$(ps -o stat= -p "$p" 2>/dev/null)" in ""|Z*) true ;; *) false ;; esac' _ "$T/stop.marks/codex-pid"
# ...and a worker the CLI started itself, a grandchild of the tier's subshell (Codex, 2026-09-27).
mkdir -p "$T/stopw.marks"
env -u CODEX_MODEL -u CODEX_EFFORT -u OLLAMA_MODEL -u OLLAMA_HOST -u AGY_MODEL PATH="$T/bin:$PATH" HOME="$T/u" \
  WITH_ANTIGRAVITY=0 REVIEW_RAW_DIR="$T/stopw.raw" STUB_MARKS="$T/stopw.marks" STUB_TAG="$STUB_TAG" \
  CODEX_STUB=wrapped OLLAMA_STUB=slow bash "$SCRIPT" "$T/change.diff" >"$T/stopw.out" 2>"$T/stopw.err" &
spid=$!
i=0; while [ ! -s "$T/stopw.marks/codex-worker" ] && [ $i -lt 50 ]; do sleep 0.1; i=$((i+1)); done
kill -TERM "$spid"; wait "$spid"; echo $? >"$T/stopw.rc"
check "stop: a TERM-ignoring worker under the CLI is gone too" \
  sh -c 'p=$(cat "$1"); [ -n "$p" ] && case "$(ps -o stat= -p "$p" 2>/dev/null)" in ""|Z*) true ;; *) false ;; esac' _ "$T/stopw.marks/codex-worker"

# 25. --verify: a verification round sends the prior findings in their own block, with the
#     round's scope, to every tier; without the flag the prompt carries neither.
printf '%s\n' 'F1 BUG fixed in abc1234: retry loop never ended' 'F2 RISK waived: owner J1' >"$T/prior.md"
run verify bash "$SCRIPT" "$T/change.diff" --verify "$T/prior.md"
check "verify: exit 0" rc_is verify 0
for tier in codex ollama; do
  check "verify: $tier gets the scope paragraph" grep -qF -- "VERIFICATION ROUND." "$T/verify.marks/$tier-prompt"
  check "verify: $tier gets the prior findings, delimited" \
    sh -c 'grep -qxF -- "--- BEGIN PRIOR FINDINGS ---" "$1" && grep -qxF -- "F1 BUG fixed in abc1234: retry loop never ended" "$1" && grep -qxF -- "--- END PRIOR FINDINGS ---" "$1"' _ "$T/verify.marks/$tier-prompt"
  check "verify: $tier's prior findings come before the artifact" \
    sh -c 'p=$(grep -nxF -- "--- END PRIOR FINDINGS ---" "$1" | cut -d: -f1); a=$(grep -nxF -- "--- BEGIN diff ---" "$1" | cut -d: -f1); [ -n "$p" ] && [ -n "$a" ] && [ "$p" -lt "$a" ]' _ "$T/verify.marks/$tier-prompt"
done
run noverify bash "$SCRIPT" "$T/change.diff"
check "no --verify: no scope paragraph" not_in "$T/noverify.marks/codex-prompt" "VERIFICATION ROUND"
check "no --verify: no prior-findings block" not_in "$T/noverify.marks/ollama-prompt" "PRIOR FINDINGS"
check "no --verify: one blank line before the artifact, as before" \
  sh -c 'grep -B2 -xF -- "--- BEGIN diff ---" "$1" | head -1 | grep -qF "Every WRONG must also appear as a BUG."' _ "$T/noverify.marks/codex-prompt"
run verifynoarg bash "$SCRIPT" "$T/change.diff" --verify
check "verify without a file: exit 2" rc_is verifynoarg 2
run verifymissing bash "$SCRIPT" "$T/change.diff" --verify "$T/no-such-file.md"
check "verify with a missing file: exit 2, nothing ran" \
  sh -c '[ "$(cat "$1/verifymissing.rc")" = 2 ] && [ ! -e "$1/verifymissing.marks/codex-ran" ]' _ "$T"
printf '  \n\n' >"$T/blank.md"
run verifyblank bash "$SCRIPT" "$T/change.diff" --verify "$T/blank.md"
check "verify with an empty record: exit 2" has verifyblank.err "the prior-findings file is empty"

# 26. Codex reasoning effort (review depth, 2026-09-26): a --verify round drops to medium unless
#     CODEX_EFFORT says otherwise; "config" keeps config.toml's; an explicit value applies to any
#     round and lands after the model override, before the prompt.
base='[exec][-s][read-only][--skip-git-repo-check][-c][project_doc_max_bytes=0][-c][skills.include_instructions=false]'
argv_of() { sed -e 's/^argv=//' -e 's/ cwd=.*$//' "$T/$1.marks/codex-args"; }
run effverify bash "$SCRIPT" "$T/change.diff" --verify "$T/prior.md"
check "effort: a verify round asks for medium" \
  [ "$(argv_of effverify)" = "$base[-c][model_reasoning_effort=\"medium\"][<prompt>]" ]
check "effort: the codex header names it" has effverify.out "## Independent review — codex (stub-codex, effort medium, read-only)"
run effconfig CODEX_EFFORT=config bash "$SCRIPT" "$T/change.diff" --verify "$T/prior.md"
check "effort: CODEX_EFFORT=config keeps config.toml's, even on a verify round" \
  [ "$(argv_of effconfig)" = "$base[<prompt>]" ]
run efffull bash "$SCRIPT" "$T/change.diff"
check "effort: a full round leaves config.toml's alone" [ "$(argv_of efffull)" = "$base[<prompt>]" ]
check "effort: ...and its header says nothing about effort" has efffull.out "## Independent review — codex (stub-codex, read-only)"
run effboth CODEX_EFFORT=xhigh CODEX_MODEL=stub-strong bash "$SCRIPT" "$T/change.diff"
check "effort: explicit effort after the model override" \
  [ "$(argv_of effboth)" = "$base[-c][model=\"stub-strong\"][-c][model_reasoning_effort=\"xhigh\"][<prompt>]" ]
run effbad CODEX_EFFORT='high"' bash "$SCRIPT" "$T/change.diff"
check "effort: an unknown value exits 2 before any reviewer runs" \
  sh -c '[ "$(cat "$1/effbad.rc")" = 2 ] && [ ! -e "$1/effbad.marks/codex-ran" ]' _ "$T"

# 27. The cost log (review_log.sh, 2026-09-26): one line per attempted seat, with depth and round
#     from the flags, codex's own token count, and nothing when REVIEW_LOG=off. A log that cannot
#     be written never fails the review.
LOGT="$T/costs.tsv"
run costlog REVIEW_LOG="$LOGT" CODEX_STUB=tokens bash "$SCRIPT" "$T/change.diff" --depth normal --round 2
check "costlog: exit 0" rc_is costlog 0
check "costlog: a header and one line per seat" [ "$(wc -l <"$LOGT" | tr -d ' ')" = 3 ]
check "costlog: codex line — gate, depth, round, seat, model, effort, tokens, outcome" \
  awk -F'\t' '$8=="codex" && $5=="diff" && $6=="normal" && $7=="2" && $9=="stub-codex" && $10=="config" && $11 ~ /^[0-9]+$/ && $12=="61108" && $13=="OK" {f=1} END {exit !f}' "$LOGT"
check "costlog: ollama line" awk -F'\t' '$8=="ollama-cloud" && $10=="-" && $12=="-" && $13=="OK" {f=1} END {exit !f}' "$LOGT"
check "costlog: the timings line carries codex's tokens" grep -qE '^timings: codex [0-9]+s \(61108 tokens\), ollama-cloud [0-9]+s$' "$T/costlog.out"
run costfail REVIEW_LOG="$T/costs2.tsv" OLLAMA_STUB=429 bash "$SCRIPT" "$T/change.diff"
check "costlog: a failed seat is logged as FAILED" awk -F'\t' '$8=="ollama-cloud" && $13=="FAILED" {f=1} END {exit !f}' "$T/costs2.tsv"
run costskip REVIEW_LOG="$T/costs3.tsv" OLLAMA_STUB=listfail bash "$SCRIPT" "$T/change.diff"
check "costlog: a skipped seat is not logged" [ "$(wc -l <"$T/costs3.tsv" | tr -d ' ')" = 2 ]
DEFLOG="$T/u/.local/state/independent-review/runs.tsv"   # earlier runs here set no REVIEW_LOG
before="$(cat "$DEFLOG" 2>/dev/null | wc -l | tr -d ' ')"
run costoff REVIEW_LOG=off bash "$SCRIPT" "$T/change.diff"
check "costlog: REVIEW_LOG=off writes nothing" \
  sh -c '[ ! -e "$1/off" ] && [ ! -e "$1/u/off" ] && [ ! -e "$PWD/off" ] && [ "$(cat "$2" 2>/dev/null | wc -l | tr -d " ")" = "$3" ]' _ "$T" "$DEFLOG" "$before"
run costdefault bash "$SCRIPT" "$T/change.diff"
check "costlog: default path under the (relocated) home" [ -s "$T/u/.local/state/independent-review/runs.tsv" ]
: >"$T/notadir"
run costbad REVIEW_LOG="$T/notadir/x/costs.tsv" bash "$SCRIPT" "$T/change.diff"
check "costlog: an unwritable log never fails the review" rc_is costbad 0
check "costlog: ...and says so" has costbad.err "could not write the review cost log"
run costdepth bash "$SCRIPT" "$T/change.diff" --depth extreme
check "costlog: an unknown depth exits 2" rc_is costdepth 2
# The host logs its own seats; the summary groups by depth and seat, and counts rounds per gate.
REVIEW_LOG="$LOGT" bash "$HERE/review_log.sh" add --seat fresh-eyes --model sonnet --seconds 395 \
  --tokens 156477 --gate diff --depth normal --round 1
REVIEW_LOG="$LOGT" bash "$HERE/review_log.sh" summary >"$T/summary.out"
check "summary: a row per depth and seat" grep -qE '^normal +fresh-eyes +1 +1 +395 +395 +156477$' "$T/summary.out"
check "summary: codex row with its mean tokens" grep -qE '^normal +codex +1 +1 +[0-9]+ +[0-9]+ +61108$' "$T/summary.out"
check "summary: rounds per gate" grep -qE '^normal +1 +2\.0 +2$' "$T/summary.out"
check "summary with the log off says so, reads no file named off" \
  sh -c 'REVIEW_LOG=off bash "$1" summary | grep -qF "is off"' _ "$HERE/review_log.sh"
REVIEW_LOG="$LOGT" bash "$HERE/review_log.sh" add --model x >/dev/null 2>&1
check "add without --seat is refused" [ $? = 2 ]

# 27b. Gates (Codex, 2026-09-27): grouping by repo + branch merged two gates on a reused branch
#      into one. --round 1 now starts a gate whose id every later line carries, the host's late
#      seats included; lines from before ids existed keep the old grouping.
G="$T/gaterepo"; mkdir -p "$G"; git -C "$G" init -q
GL="$T/gates.tsv"
inrepo() { run "$1" REVIEW_LOG="$GL" sh -c 'cd "$0" && shift && exec "$@"' "$G" "${@:2}"; }
inrepo gate1a bash "$SCRIPT" "$T/change.diff" --depth normal --round 1
inrepo gate1b bash "$SCRIPT" "$T/change.diff" --depth normal --round 2
inrepo gate2a bash "$SCRIPT" "$T/change.diff" --depth normal --round 1
inrepo gate2b bash "$SCRIPT" "$T/change.diff" --depth normal --round 2
inrepo gate2c bash "$SCRIPT" "$T/change.diff" --depth normal --round 3
inrepo gatefe bash "$HERE/review_log.sh" add --seat fresh-eyes --gate diff --depth normal --round 1
check "gates: --round 1 leaves an id in the repo's git dir" [ -s "$G/.git/independent-review-gate" ]
check "gates: every line carries a gate id" awk -F'\t' 'NR > 1 && ($14 == "" || $14 == "-") {bad=1} END {exit bad}' "$GL"
check "gates: two ids, the late host seat in the second" \
  [ "$(awk -F'\t' 'NR > 1 {print $14}' "$GL" | sort -u | grep -c .)" = 2 ]
REVIEW_LOG="$GL" bash "$HERE/review_log.sh" summary >"$T/gates.out"
check "gates: a reused branch counts as two gates, 2 and 3 rounds" grep -qE '^normal +2 +2\.5 +3$' "$T/gates.out"
OLDL="$T/old.tsv"
printf 'date\trepo\tbranch\thead\tgate\tdepth\tround\tseat\tmodel\teffort\tseconds\ttokens\toutcome\n' >"$OLDL"
for r in 1 2 3; do printf '2026-09-20T10:00:00Z\tr\tb\th\tdiff\thigh\t%s\tcodex\tm\te\t10\t5\tOK\n' "$r" >>"$OLDL"; done
REVIEW_LOG="$OLDL" bash "$HERE/review_log.sh" summary >"$T/old.out"
check "gates: a log from before gate ids still groups by branch" grep -qE '^high +1 +3\.0 +3$' "$T/old.out"
# Many seats writing a new log at once: no line lost. This cannot force the bad interleaving
# (it never showed against the old code either); what closes it is that nothing is written
# with `>`: the header is appended like every line, so a race costs at most a spare header.
RL="$T/race.tsv"; i=0
while [ $i -lt 40 ]; do REVIEW_LOG="$RL" bash "$HERE/review_log.sh" add --seat "s$i" & i=$((i + 1)); done; wait
check "race: forty lines, none lost" [ "$(grep -vc '^date' "$RL")" = 40 ]
check "race: a header first" [ "$(awk 'NR == 1 {print $1}' "$RL")" = date ]
printf 'date\tx\n' >>"$RL"   # a spare header, as a lost race can leave: summary must skip it
REVIEW_LOG="$RL" bash "$HERE/review_log.sh" summary >"$T/race.out"
# The first table has one row per depth+seat: exactly the forty seats, nothing for the header.
check "race: a spare header is not counted as a seat" [ "$(awk 'NR > 1 && NF == 0 {exit} NR > 1' "$T/race.out" | grep -c .)" = 40 ]

# 28. The ollama HTTP API transport (2026-09-26): used when the CLI is absent (or forced). A
#     ':cloud' tag goes to ollama.com without the suffix, streamed; the key, when set, rides in a
#     header FILE that is gone afterwards; the tokens reach the timings line and the cost log.
NOCLI="$T/bin2:/usr/bin:/bin"
run api PATH="$NOCLI" OLLAMA_MODEL="$STUB_TAG" REVIEW_LOG="$T/api.tsv" bash "$SCRIPT" "$T/change.diff"
check "api: counted" has api.out "reviewers: codex OK, ollama-cloud OK"
check "api: header names the transport" has api.out "## Independent review — ollama ($STUB_TAG, HTTP API)"
check "api: the streamed pieces are joined" has api.out "- BUG: api finding one"
check "api: ollama.com, /api/chat" grep -qxF "https://ollama.com/api/chat" "$T/api.marks/curl-url"
check "api: the model without its :cloud suffix, streamed, carrying the artifact" \
  perl -MJSON::PP -e 'local $/; open my $f, "<", $ARGV[0] or exit 1; my $j = decode_json(<$f>); exit !($j->{model} eq "stub-model" && $j->{stream} && $j->{messages}[0]{content} =~ /--- BEGIN diff ---/)' "$T/api.marks/curl-body"
check "api: no key set, no Authorization header sent" not_in "$T/api.marks/curl-hdr" "Authorization"
check "api: tokens in the timings line" grep -qE '^timings: codex [0-9]+s, ollama-cloud [0-9]+s \(750 tokens\)$' "$T/api.out"
check "api: tokens in the cost log" awk -F'\t' '$8=="ollama-cloud" && $12=="750" && $13=="OK" {f=1} END {exit !f}' "$T/api.tsv"
run apikey PATH="$NOCLI" OLLAMA_MODEL="$STUB_TAG" OLLAMA_API_KEY=stub-secret bash "$SCRIPT" "$T/change.diff"
check "apikey: the key rides in the header file" grep -qxF "Authorization: Bearer stub-secret" "$T/apikey.marks/curl-hdr"
check "apikey: and the file is gone afterwards" [ ! -e "$T/apikey.raw/ollama.hdr" ]
check "apikey: never in any output" sh -c '! grep -rqF stub-secret "$1/apikey.out" "$1/apikey.err" "$1/apikey.raw"' _ "$T"
run api429 PATH="$NOCLI" OLLAMA_MODEL="$STUB_TAG" API_STUB=429 bash "$SCRIPT" "$T/change.diff"
check "api429: read as quota" has api429.out "ollama-cloud FAILED (HTTP 429; quota/rate limit: wait or add credits)"
check "api429: the API's message is quoted" has api429.out "weekly usage limit"
run apitrunc PATH="$NOCLI" OLLAMA_MODEL="$STUB_TAG" API_STUB=trunc bash "$SCRIPT" "$T/change.diff"
check "apitrunc: a stream without its done line fails the tier" has apitrunc.out "ollama-cloud FAILED (HTTP 200)"
check "apitrunc: and says it was truncated" has apitrunc.out "a truncated review"
run api502 PATH="$NOCLI" OLLAMA_MODEL="$STUB_TAG" API_STUB=502 bash "$SCRIPT" "$T/change.diff"
check "api502: a non-JSON error body is quoted" has api502.out "response is not JSON: upstream request failed"
run apidown PATH="$NOCLI" OLLAMA_MODEL="$STUB_TAG" API_STUB=down bash "$SCRIPT" "$T/change.diff"
check "apidown: a network failure names curl's exit" has apidown.out "ollama-cloud FAILED (curl exit 56)"
check "apidown: ...with a hint" has apidown.out "is the host allowed by the network policy?"
run apinomodel PATH="$NOCLI" bash "$SCRIPT" "$T/change.diff"
check "apinomodel: no CLI and no model — skipped" has apinomodel.out "ollama SKIPPED (not available)"
check "apinomodel: the note names OLLAMA_MODEL" has apinomodel.err "Set OLLAMA_MODEL=<name>:cloud"
check "apinomodel: nothing was sent" [ ! -e "$T/apinomodel.marks/curl-url" ]
run apiforced OLLAMA_TRANSPORT=api OLLAMA_MODEL="$STUB_TAG" bash "$SCRIPT" "$T/change.diff"
check "apiforced: OLLAMA_TRANSPORT=api wins over an installed CLI" \
  sh -c '[ -e "$1/curl-url" ] && [ ! -e "$1/ollama-ran" ]' _ "$T/apiforced.marks"
run apibadtransport OLLAMA_TRANSPORT=grpc bash "$SCRIPT" "$T/change.diff"
check "an unknown OLLAMA_TRANSPORT exits 2" rc_is apibadtransport 2
run apilocal PATH="$NOCLI" OLLAMA_MODEL=stub-local OLLAMA_HOST=127.0.0.1:11434 bash "$SCRIPT" "$T/change.diff"
check "apilocal: a local tag goes to OLLAMA_HOST" grep -qxF "http://127.0.0.1:11434/api/chat" "$T/apilocal.marks/curl-url"
check "apilocal: with its tag unchanged" grep -qF '"model":"stub-local"' "$T/apilocal.marks/curl-body"
check "apilocal: and stays a sanity pass" has apilocal.out "ollama-local NOT COUNTED (local model: sanity pass only)"

# 29. --seat runs ONE named reviewer (2026-09-26: the wording pass and the final full read).
run seatollama bash "$SCRIPT" "$T/change.diff" --seat ollama
check "seat ollama: a successful single-seat run exits 0" rc_is seatollama 0
check "seat ollama: only ollama ran" sh -c '[ -e "$1/ollama-ran" ] && [ ! -e "$1/codex-ran" ]' _ "$T/seatollama.marks"
check "seat ollama: the summary names it alone" has seatollama.out "reviewers: ollama-cloud OK"
check "seat ollama: the one-reviewer note says it was asked for" has seatollama.out "--seat ollama was requested"
check "seat ollama: ...and when one reviewer is right" has seatollama.out "any other round needs the standard pair"
run seatfirst bash "$SCRIPT" "$T/change.diff" --seat codex --first-success
check "seat: with --first-success exits 2" rc_is seatfirst 2
run seatwithagy WITH_ANTIGRAVITY=1 bash "$SCRIPT" "$T/change.diff" --seat ollama
check "seat: another seat with the Antigravity opt-in exits 2" rc_is seatwithagy 2
run seatagyboth bash "$SCRIPT" "$T/change.diff" --seat agy --with-antigravity
check "seat agy with --with-antigravity is allowed (same reviewer)" has seatagyboth.out "reviewers: antigravity OK"
check "seat agy with --with-antigravity: exactly one Antigravity section, no other seat" \
  sh -c '[ "$(grep -c "^## Independent review — antigravity" "$1/seatagyboth.out")" = 1 ] && [ ! -e "$1/seatagyboth.marks/codex-ran" ] && [ ! -e "$1/seatagyboth.marks/ollama-ran" ]' _ "$T"
run seatcodex bash "$SCRIPT" "$T/change.diff" --seat codex
check "seat codex: only codex ran" sh -c '[ -e "$1/codex-ran" ] && [ ! -e "$1/ollama-ran" ]' _ "$T/seatcodex.marks"
run seatagy bash "$SCRIPT" "$T/change.diff" --seat agy
check "seat agy: names Antigravity, so it runs without WITH_ANTIGRAVITY" has seatagy.out "reviewers: antigravity OK"
run seatbad bash "$SCRIPT" "$T/change.diff" --seat gemini
check "seat: an unknown seat exits 2" rc_is seatbad 2
run seatlocal OLLAMA_MODEL=stub-local bash "$SCRIPT" "$T/change.diff" --local-only --seat codex
check "seat: --local-only refuses an external seat, exit 2, nothing ran" \
  sh -c '[ "$(cat "$1/seatlocal.rc")" = 2 ] && [ ! -e "$1/seatlocal.marks/codex-ran" ]' _ "$T"

# 30. merge_link.sh (2026-09-26): the merge link's artifact, on real merges. Both reviewers of
#     the change that introduced it found a way the one-line command lost a file: a path with a
#     space (round 1) and an own edit the merge threw away (the final full read).
ML="$HERE/merge_link.sh"
if command -v git >/dev/null 2>&1; then
  R="$T/mlrepo"; mkdir -p "$R"
  (
    cd "$R" && git init -q -b main && git config user.email t@t && git config user.name t
    mkdir -p "dir with space" docs/reviews
    echo base >"dir with space/f.txt"; echo base >own.txt; echo base >'[g]*.txt'; echo base >keep.txt
    echo base >callee.txt; echo base >g1.txt; echo base >docs/reviews/trail.md
    git add -A && git commit -qm base && git tag oldbase
    git checkout -qb feat
    echo feature >>"dir with space/f.txt"; echo "my change" >own.txt; echo feature >>'[g]*.txt'
    echo feature >>keep.txt; echo round >>docs/reviews/trail.md
    git commit -qam feat && git tag reviewed
    git checkout -q main
    echo main >"dir with space/f.txt"; echo "main change" >own.txt; echo main >callee.txt; echo main >g1.txt
    git commit -qam main
    git checkout -q feat
    git merge -q main >/dev/null 2>&1 || true
    printf 'resolved\n' >"dir with space/f.txt"        # a merge effect on a spaced path
    git checkout --theirs own.txt                      # the merge throws the own edit away
    git add -A && git commit -qm merge && git tag newhead
    git tag newbase "$(git merge-base main HEAD)"
  ) >/dev/null 2>&1
  ( cd "$R" && bash "$ML" oldbase reviewed newbase ) >"$T/ml.out" 2>"$T/ml.err"; echo $? >"$T/ml.rc"
  check "merge_link: exit 0" rc_is ml 0
  check "merge_link: the spaced path's merge effect is in" has ml.out "+resolved"
  check "merge_link: the own edit the merge threw away is in" has ml.out "-my change"
  check "merge_link: a glob-character name is taken literally, matching no other file" lacks ml.out "b/g1.txt"
  check "merge_link: an unmoved own file is not" lacks ml.out "b/keep.txt"
  check "merge_link: the review trail is left out" lacks ml.out "docs/reviews/trail.md"
  check "merge_link: a base-only file is not in, unless named" lacks ml.out "b/callee.txt"
  ( cd "$R" && bash "$ML" oldbase reviewed newbase -- callee.txt ) >"$T/mlx.out" 2>&1
  check "merge_link: an extra path the change calls is added" has mlx.out "+main"
  ( cd "$R" && bash "$ML" newhead newhead newhead ) >"$T/mlempty.out" 2>&1; echo $? >"$T/mlempty.rc"
  check "merge_link: nothing moved prints nothing (not the whole tree)" \
    sh -c '[ "$(cat "$1/mlempty.rc")" = 0 ] && [ ! -s "$1/mlempty.out" ]' _ "$T"
  ( cd "$R" && bash "$ML" oldbase no-such-rev newbase ) >/dev/null 2>&1; echo $? >"$T/mlbad.rc"
  check "merge_link: an unknown revision exits 2" rc_is mlbad 2
  # A rename is listed by its new name alone, so a merge that brings the old name back lost it
  # (round 4, Codex): with both names kept the merge link printed nothing at all.
  for mode in drop keep; do
    R="$T/mlrename-$mode"; mkdir -p "$R"
    (
      cd "$R" && git init -q -b main && git config user.email t@t && git config user.name t
      printf 'one\ntwo\nthree\nfour\nfive\nsix\n' >old.txt; echo base >other.txt
      git add -A && git commit -qm base && git tag oldbase
      git checkout -qb feat && git mv old.txt new.txt && echo "my edit" >>new.txt
      git commit -qam rename && git tag reviewed
      git checkout -q main && echo main >>other.txt && git commit -qam main
      git checkout -q feat && git merge -q --no-commit --no-ff main
      if [ "$mode" = drop ]; then git rm -qf new.txt; fi
      git checkout main -- old.txt                     # the merge brings the old name back
      git add -A && git commit -qm merge && git tag newbase "$(git merge-base main HEAD)"
    ) >/dev/null 2>&1
    ( cd "$R" && bash "$ML" oldbase reviewed newbase ) >"$T/mlrn-$mode.out" 2>&1
    check "merge_link: a rename the merge undid ($mode the new name) shows the old name" has "mlrn-$mode.out" "old.txt"
  done
fi

# 31. A reasoning model's trace is kept out of the answer (2026-09-27): its trace quoted the
#     prompt's "could not read" advice, and the whole reply was rejected as not a review.
run think OLLAMA_STUB=think bash "$SCRIPT" "$T/change.diff"
check "think: the CLI is asked to hide the trace" test -e "$T/think.marks/ollama-hidethinking"
check "think: ollama-cloud counted, not FAILED" has think.out "reviewers: codex OK, ollama-cloud OK"
check "think: the answer is printed, the trace is not" \
  sh -c 'grep -qF "RISK — retry.rb:12" "$1" && ! grep -qF "Thinking..." "$1"' _ "$T/think.out"
check "think: the model and prompt still reach the CLI" \
  sh -c 'grep -qxF "$2" "$1/ollama-model" && [ -s "$1/ollama-prompt" ]' _ "$T/think.marks" "$STUB_TAG"
run thinkold STUB_OLDCLI=1 OLLAMA_STUB=think bash "$SCRIPT" "$T/change.diff"
check "thinkold: a CLI without the flag is not given it" test ! -e "$T/thinkold.marks/ollama-hidethinking"
check "thinkold: ...and still runs the model, as before this change" test -e "$T/thinkold.marks/ollama-ran"
for how in failhelp longword; do   # round 1, Codex: a failed help, or the flag inside a longer word
  run "think$how" STUB_OLDCLI=$how OLLAMA_STUB=think bash "$SCRIPT" "$T/change.diff"
  check "think$how: the flag is not passed" test ! -e "$T/think$how.marks/ollama-hidethinking"
done

if [ $fails -ne 0 ]; then echo "$fails check(s) FAILED"; exit 1; fi
echo "all checks passed"
