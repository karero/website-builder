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
  stubborn) # a CLI that ignores SIGTERM, as one mid-request might; records its pid
        trap '' TERM; echo $$ >"$STUB_MARKS/codex-pid"; sleep 30 ;;
esac
EOF
cat >"$T/bin/ollama" <<'EOF'
#!/bin/sh
case "$1" in
  list) if [ "${OLLAMA_STUB:-ok}" = listfail ]; then
          echo "Error: could not connect to ollama app, is it running?" >&2; exit 1
        fi
        printf 'NAME                ID      SIZE    MODIFIED\n%s    abc123  -       1 day ago\n' "$STUB_TAG"; exit 0 ;;
  run)  : >"$STUB_MARKS/ollama-ran"; printf '%s\n' "$2" >"$STUB_MARKS/ollama-model"
        printf '%s\n' "$3" >"$STUB_MARKS/ollama-prompt" ;;
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
chmod +x "$T/bin/codex" "$T/bin/ollama" "$T/bin/agy"

# run <name> [VAR=value ...] <command ...> — leaves $T/<name>.out, .err and .rc
run() {
  local name="$1"; shift
  mkdir -p "$T/$name.marks"
  env -u CODEX_MODEL -u CODEX_EFFORT -u OLLAMA_MODEL -u OLLAMA_HOST -u AGY_MODEL -u GIT_DIR -u GIT_WORK_TREE \
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
#     with no output — on 1.2.9 and again on 1.2.11 (2026-09-26). The fix asks for plan mode and sends the text-only
#     prompt, and loosens nothing: no --dangerously-skip-permissions. The exact argv pins that
#     on both command lines, the default and the AGY_MODEL one. The stub cannot show the real
#     CLI now answers; it shows the script asks for what the manual run that did answer used.
for m in "" stub-agy-model; do
  name="agy${m:+-model}"
  run "$name" WITH_ANTIGRAVITY=1 AGY_MODEL="$m" bash "$SCRIPT" "$T/change.diff"
  check "$name: agy counted alongside the pair" has "$name.out" "reviewers: codex OK, ollama-cloud OK, antigravity OK"
  check "$name: header names the model" has "$name.out" "## Independent review — antigravity/agy (${m:-CLI default}"
  check "$name: header says plan mode, text-only prompt" has "$name.out" ", sandbox, plan mode, text-only prompt)"
  want="argv=[--sandbox][--mode][plan]${m:+[--model][$m]}[-p][<prompt>]"
  check "$name: exact argv (sandbox + plan mode, nothing looser)" grep -qxF -- "$want" "$T/$name.marks/agy-args"
  check "$name: sent the text-only prompt" grep -qF -- "You have NO tools" "$T/$name.marks/agy-prompt"
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

if [ $fails -ne 0 ]; then echo "$fails check(s) FAILED"; exit 1; fi
echo "all checks passed"
