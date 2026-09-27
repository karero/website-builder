#!/usr/bin/env bash
# Guard: under `set -o pipefail`, no pipe may feed a consumer that exits early.
#
# `producer | grep -q x` looks like a match test, but once the producer's output passes the
# pipe buffer (~64 KiB) the producer can outlive grep's early exit and die writing to a closed
# pipe: SIGPIPE (141), or EPIPE (exit 1 or 2) where SIGPIPE is ignored, as it is on GitHub's
# runners. pipefail reports that failure, so a genuine match reads as a miss. It is silent at
# every size a test normally uses. #130 found it live in three places: package.sh's leak checks
# missed a 20,000-path leak, independent_review.sh's looks_like_review rejected large clean
# reviews (and accepted a refusal whose clean verdict came last), and the quota classifier
# misreported large quota failures. The fix is to capture once and match a herestring
# (`grep -q x <<<"$v"`), or to use a consumer that reads to EOF (`awk 'NR==1'`).
#
# Early-exit consumers flagged after a single `|` or `|&`: head, read, grep -q/-m/-l/-L (and
# their long forms), sed with a q/Q command, and awk with an `exit` before any END block.
#
# Why a LEXER, not a grep. A per-line grep for `| head` / `| grep -q` trips on `|| grep -q
# … file` (OR, not a pipe), on comments that describe the pattern, on a `|` inside a quoted
# regex, and on heredoc bodies, and it misses a pipe at the end of one line feeding a consumer
# on the next. The awk below tracks quotes, $( ), ${ }, backticks, subshells, arithmetic,
# comments, line continuations and heredocs, and splits commands on the real operators.
# Anything it cannot close by end of file is a FAIL, not a guess.
#
# Scope: only scripts that enable pipefail. Without it a pipeline's status is the consumer's,
# so an early exit cannot flip it. Discovery is by shebang, as in check_cdpath_safe.sh.
#
# What it does not do: decide that a site's status is ignored. That judgement goes in EXEMPT,
# one line of reason each, where a reviewer can see it.
set -uo pipefail
CDPATH= cd -- "$(dirname -- "$0")/.." || { echo "FAIL — cannot cd to the repo root from $0."; exit 1; }

# Sites that match but cannot flip a result. Format: 'path|needle' — needle is a fixed string
# that must appear on the flagged line. An entry that matches nothing FAILS as stale, so a fixed
# or moved site forces its entry out. Prefer rewriting a site to adding one here.
EXEMPT=(
  # Both are astro template files copied into every site: a no-op edit shows up as drift in
  # every site's whats-new, and ship.sh's header requires a template-version bump per change.
  'skills/new-website/templates/astro/scripts/ship.sh| | head -1 || true)"'  # `|| true` discards the status
  'skills/new-website/templates/astro/tests/check_ship_push.sh|version_of() { sed -n'  # sed prints 1 tiny line in one write; head never races it
)

# --- discovery (same approach as check_cdpath_safe.sh; see the reasoning there) --------------
# git's file list where there is one (it skips nested checkouts under .claude/worktrees/), else
# find: the handoff zip has no git, and zip recipients run `make check` too.
discover() {
  # Only when the suite root IS the toplevel: a zip unpacked inside some other repository would
  # otherwise get that repository's index, which may track none, some or all of these files.
  if [ "$(git rev-parse --show-toplevel 2>/dev/null)" = "$(pwd -P)" ] && [ -n "$(git ls-files 2>/dev/null)" ]; then
    git ls-files 2>/dev/null
  else
    find . -type f ! -path './.git/*' ! -path './dist/*' ! -path '*/node_modules/*' \
         ! -path './docs/reviews/*' ! -path './.claude/worktrees/*' -print 2>/dev/null |
      sed 's|^\./||'
  fi |
  while IFS= read -r f; do
    [ -f "$f" ] || continue
    case "$(head -n 1 -- "$f" 2>/dev/null | LC_ALL=C tr -d '\0')" in
      '#!'*sh|'#!'*sh' '*) printf '%s\n' "$f" ;;
    esac
  done | sort
}

# A `set` line enabling pipefail: `set -o pipefail`, `set -euo pipefail`, `set -o errexit -o
# pipefail`, … Anchored at the start of the line, so a comment that mentions it does not count.
PIPEFAIL_RE='^[[:space:]]*set[[:space:]]+(.*[[:space:]])?-[a-zA-Z]*o[[:space:]]+pipefail([[:space:];]|$)'

# --- the lexer ---------------------------------------------------------------------------------
# Prints one line per flagged site: <file> TAB <line> TAB <consumer>. A file it cannot parse
# prints <file> TAB 0 TAB PARSE: <reason>. Plain POSIX awk: runs under mawk, nawk and gawk.
# read, not "$(cat <<'AWK' … )": bash 3.2 (macOS /bin/bash) parses a heredoc inside $( ) for
# quotes, and this awk body's unbalanced ' and ` stop the whole script from parsing there.
IFS= read -r -d '' LEXER <<'AWK' || true
function reset() {
  d = 1; ft[1] = "C"; tm[1] = ""; own[1] = 1; sq[1] = 0; an[1] = 0
  buf[1] = ""; op[1] = ""; bl[1] = 0; nh = 0; hh = 0; cont = 0
}
function blank(x) { return x ~ /^[ \t\n]*$/ }
function add(x,   o) {
  o = own[d]
  if (blank(buf[o]) && !blank(x)) bl[o] = FNR
  buf[o] = buf[o] x
}
function push(t, term) {
  d++; ft[d] = t; tm[d] = term; sq[d] = 0; an[d] = 0
  if (t == "C") { own[d] = d; buf[d] = ""; op[d] = ""; bl[d] = FNR } else own[d] = own[d - 1]
}
# Ends the current command in C frame d. A newline after a bare `|`, `&&` or `||` continues the
# pipeline, so a newline on an empty command keeps the pending operator.
function endcmd(newop, isnl) {
  if (!blank(buf[d])) {
    if (op[d] == "|") check(buf[d], bl[d])
    buf[d] = ""; op[d] = newop
  } else if (!isnl) op[d] = newop
}
function popc(term) { endcmd("", 0); d--; add(term) }
function dollar(s, i) {  # at a `$`; returns how many extra chars were consumed
  if (substr(s, i + 1, 2) == "((") { add("$(("); push("A", ""); return 2 }
  if (substr(s, i + 1, 1) == "(") { add("$("); push("C", ")"); return 1 }
  if (substr(s, i + 1, 1) == "{") { add("${"); push("B", "}"); return 1 }
  if (ft[d] == "C" && substr(s, i + 1, 1) == "'") { add("$'"); sq[d] = 2; return 1 }
  add("$"); return 0
}
function check(x, ln,   w, nw, k, kind, rest) {
  sub(/^[ \t\n]+/, "", x)
  for (;;) {
    if (x ~ /^(!|\{|time|command|builtin|env|exec|nohup)([ \t\n]|$)/) { sub(/^[^ \t\n]*[ \t\n]*/, "", x); continue }
    if (x ~ /^[A-Za-z_][A-Za-z0-9_]*=[^ \t\n]*[ \t\n]/) { sub(/^[^ \t\n]*[ \t\n]+/, "", x); continue }
    break
  }
  kind = ""
  if (x ~ /^head([ \t\n;]|$)/) kind = "head"
  else if (x ~ /^read([ \t\n;]|$)/) kind = "read"
  else if (x ~ /^[ef]?grep([ \t\n]|$)/) {
    nw = split(x, w, /[ \t\n]+/)
    for (k = 2; k <= nw; k++) {
      if (w[k] == "--") break
      if (w[k] ~ /^-[a-zA-Z]*[qmlL]/ || w[k] ~ /^--(quiet|silent|max-count|files-with-matches|files-without-match)/) {
        kind = "grep " w[k]; break
      }
    }
  } else if (x ~ /^sed([ \t\n]|$)/) {
    if (substr(x, 4) ~ /(^|[^a-zA-Z_\\])[qQ][0-9]*([ \t\n;}'"]|$)/) kind = "sed with q"
  } else if (x ~ /^[gmn]?awk([ \t\n]|$)/) {
    rest = substr(x, 4)
    if (match(rest, /(^|[^a-zA-Z0-9_])END[ \t\n]*\{/)) rest = substr(rest, 1, RSTART)
    if (rest ~ /(^|[^a-zA-Z0-9_])exit([^a-zA-Z0-9_]|$)/) kind = "awk with exit"
  }
  if (kind != "") print FILENAME "\t" ln "\t" kind
}
function lex(s,   i, n, c, c2, t, j, w, ch, strip) {
  n = length(s)
  for (i = 1; i <= n; i++) {
    c = substr(s, i, 1); t = ft[d]
    if (t == "C") {
      if (sq[d]) {
        if (sq[d] == 2 && c == "\\") { add(substr(s, i, 2)); i++; continue }
        add(c); if (c == "'") sq[d] = 0; continue
      }
      if (c == "\\") { if (i == n) cont = 1; else { add(substr(s, i, 2)); i++ }; continue }
      if (c == "'") { add(c); sq[d] = 1; continue }
      if (c == "\"") { add(c); push("D", ""); continue }
      if (c == "`") { if (tm[d] == "`") popc(c); else { add(c); push("C", "`") }; continue }
      if (c == "$") { i += dollar(s, i); continue }
      if (c == "#" && (i == 1 || substr(s, i - 1, 1) ~ /[ \t;&|()]/)) break
      if (c == "|") {
        if (i > 1 && substr(s, i - 1, 1) == ">") { add(c); continue }  # >| redirection
        c2 = substr(s, i + 1, 1)
        if (c2 == "|") { endcmd("", 0); i++; continue }
        if (c2 == "&") i++
        endcmd("|", 0); continue
      }
      if (c == "&") {
        if ((i > 1 && substr(s, i - 1, 1) ~ /[<>]/) || substr(s, i + 1, 1) == ">") { add(c); continue }  # 2>&1, &>f
        endcmd("", 0); continue
      }
      if (c == ";") { endcmd("", 0); continue }
      if (c == "(") {
        if (substr(s, i + 1, 1) == "(" && blank(buf[d])) { add("(("); push("A", ""); i++; continue }
        add(c); push("C", ")"); continue
      }
      if (c == ")") { if (tm[d] == ")") popc(c); else endcmd("", 0); continue }  # else: a case pattern
      if (c == "<" && substr(s, i + 1, 1) == "<") {
        if (substr(s, i + 2, 1) == "<") { add("<<<"); i += 2; continue }
        j = i + 2; strip = 0
        if (substr(s, j, 1) == "-") { strip = 1; j++ }
        while (substr(s, j, 1) ~ /[ \t]/ && j <= n) j++
        w = ""
        while (j <= n) { ch = substr(s, j, 1); if (ch ~ /[ \t;|&<>()]/) break; w = w ch; j++ }
        gsub(/["'\\]/, "", w)
        if (w == "") { perr = "a heredoc on line " FNR " has no delimiter it can read"; continue }
        nh++; hq[nh] = w; hs[nh] = strip
        add(substr(s, i, j - i)); i = j - 1; continue
      }
      add(c); continue
    }
    if (t == "D" || t == "B") {
      if (c == "\\") { if (i == n) cont = 1; else { add(substr(s, i, 2)); i++ }; continue }
      if ((t == "D" && c == "\"") || (t == "B" && c == "}")) { add(c); d--; continue }
      if (t == "B" && c == "\"") { add(c); push("D", ""); continue }
      if (c == "$") { i += dollar(s, i); continue }
      if (c == "`") { add(c); push("C", "`"); continue }
      add(c); continue
    }
    # t == "A": arithmetic, opaque apart from nesting and substitutions
    if (c == "(") { an[d]++; continue }
    if (c == ")") {
      if (an[d] > 0) { an[d]--; continue }
      if (substr(s, i + 1, 1) == ")") i++
      d--; add("))"); continue
    }
    if (c == "$") { i += dollar(s, i); continue }
  }
  if (cont) { cont = 0; return }
  if (ft[d] == "C") {
    if (sq[d]) add("\n"); else endcmd("", 1)
  } else if (ft[d] == "D") add("\n")
}
function finish(f) {
  if (d == 1 && !sq[1]) endcmd("", 0)
  if (perr != "") print f "\t0\tPARSE: " perr
  else if (hh < nh) print f "\t0\tPARSE: heredoc '" hq[hh + 1] "' never ends"
  else if (d != 1 || sq[1]) print f "\t0\tPARSE: a quote, $( ), ${ } or ( ) is still open at end of file"
  perr = ""
}
FNR == 1 { if (NR > 1) finish(cur); reset(); cur = FILENAME }
{
  if (hh < nh) {
    w = $0; if (hs[hh + 1]) sub(/^\t+/, "", w)
    if (w == hq[hh + 1]) hh++
    next
  }
  lex($0)
}
END { if (NR > 0) finish(cur) }
AWK

# --- self-test, both directions ------------------------------------------------------------------
# A guard that cannot fire is worse than none; one that fires on the fixed form is its mirror.
tmp="$(mktemp -d)" || { echo "FAIL — mktemp failed."; exit 1; }
trap 'rm -rf "$tmp"' EXIT
mkdir "$tmp/bad" "$tmp/good"
case_file=""
while IFS= read -r l; do
  case "$l" in
    '@@ '*) case_file="$tmp/${l#@@ }"; : >"$case_file" ;;
    *) printf '%s\n' "$l" >>"$case_file" ;;
  esac
done <<'CASES'
@@ bad/grep-q
printf '%s\n' "$x" | grep -q foo
@@ bad/head-in-subst
v="$(printf '%s\n' "$y" | head -1)"
@@ bad/grep-m
cmd | grep -m1 foo
@@ bad/grep-cluster-with-env
if echo "$v" | LC_ALL=C grep -Fxq foo; then :; fi
@@ bad/grep-long
cmd | grep --quiet foo
@@ bad/sed-q
cmd | sed -n '/x/{p;q;}'
@@ bad/awk-exit
cmd | awk 'NR == 1 { print; exit }'
@@ bad/pipe-at-eol
cmd |
  grep -qx foo
@@ bad/backslash-continuation
cmd \
  | head -n 1
@@ bad/pipe-stderr
cmd |& head -1
@@ bad/backticks
v=`cmd | head -1`
@@ bad/in-dquoted-subst-in-if
if [ -n "$(cmd 2>&1 | grep -l x)" ]; then :; fi
@@ bad/after-heredoc
cat <<EOF
body | head -1
EOF
cmd | head -1
@@ good/herestring
grep -q foo <<<"$x"
@@ good/or
false || grep -q foo file
@@ good/or-across-lines
[ -f x ] \
  || grep -qE 'a|b' "$1"
@@ good/file-operand
grep -q foo file
@@ good/comment
# printf '%s\n' "$x" | grep -q foo
@@ good/trailing-comment
echo hi  # like `x | head -1`
@@ good/pipe-in-dquotes
echo "a | head -1"
@@ good/pipe-in-squoted-regex
grep -E 'a|head -1' file
@@ good/awk-exit-in-end
cmd | awk '{ n++ } END { exit n == 0 }'
@@ good/grep-count
cmd | grep -c foo
@@ good/grep-reads-to-eof
cmd | grep -v foo | sort
@@ good/sed-q-in-regex
cmd | sed 's/q/x/; /^q$/d'
@@ good/heredoc-body
cat <<-'EOF'
	x | head -1
	EOF
@@ good/redirections
cmd 2>&1 >|out | tr a b
@@ good/param-expansion
echo "${#x} ${x#*|}" | tr a b
@@ good/head-as-producer
head -n 1 file | tr -d '\0'
CASES

TAB=$'\t'
flagged="$(LC_ALL=C awk "$LEXER" "$tmp"/bad/* "$tmp"/good/*)"; lrc=$?
if [ "$lrc" -ne 0 ]; then
  echo "FAIL — self-test: awk exited $lrc; the lexer is broken on this system's awk."
  exit 1
fi
for f in "$tmp"/bad/*; do
  grep -qF "$f$TAB" <<<"$flagged" && ! grep -qF "$f${TAB}0${TAB}PARSE" <<<"$flagged" || {
    echo "FAIL — self-test: the known-bad case '${f##*/}' is not flagged:"
    sed 's/^/    /' "$f"
    exit 1
  }
done
for f in "$tmp"/good/*; do
  if grep -qF "$f$TAB" <<<"$flagged"; then
    echo "FAIL — self-test: the allowed case '${f##*/}' is flagged:"
    sed 's/^/    /' "$f"
    grep -F "$f$TAB" <<<"$flagged" | sed 's/^/    /'
    exit 1
  fi
done
for on in 'set -o pipefail' 'set -euo pipefail' '  set -uo pipefail' 'set -o errexit -o pipefail'; do
  grep -qE "$PIPEFAIL_RE" <<<"$on" || { echo "FAIL — self-test: PIPEFAIL_RE misses '$on'."; exit 1; }
done
for off in '# set -o pipefail' 'set +o pipefail' 'set -eu' 'echo set -o pipefail'; do
  if grep -qE "$PIPEFAIL_RE" <<<"$off"; then echo "FAIL — self-test: PIPEFAIL_RE matches '$off'."; exit 1; fi
done

# --- scan ---------------------------------------------------------------------------------------
all_scripts="$(discover)"
if [ "$(grep -c . <<<"$all_scripts")" -lt 10 ]; then
  echo "FAIL — discovery found fewer than 10 shell scripts; it cannot have run correctly."
  echo "Run this from a checkout or an unpacked handoff zip, with find and head on PATH."
  exit 1
fi
SCOPE=()
while IFS= read -r f; do
  grep -qE "$PIPEFAIL_RE" -- "$f"; grc=$?
  case "$grc" in
    0) SCOPE+=("$f") ;;
    1) ;;
    *) echo "FAIL — grep errored (exit $grc) reading $f; the guard result is unreliable."; exit 1 ;;
  esac
done <<<"$all_scripts"
if [ "${#SCOPE[@]}" -lt 10 ]; then
  echo "FAIL — only ${#SCOPE[@]} script(s) enable pipefail; at least 10 do. Discovery or PIPEFAIL_RE is broken."
  exit 1
fi

found="$(LC_ALL=C awk "$LEXER" "${SCOPE[@]}")"; lrc=$?
if [ "$lrc" -ne 0 ]; then
  echo "FAIL — awk exited $lrc while scanning; the guard result is unreliable."
  exit 1
fi

rc=0
used=()
exempted=0
while IFS=$'\t' read -r f ln kind; do
  [ -n "$f" ] || continue
  if [ "$ln" = 0 ]; then
    echo "FAIL — $f: cannot lex it (${kind#PARSE: }). Fix the script, or teach this guard the construct."
    rc=1; continue
  fi
  src="$(sed -n "${ln}p" <"$f")"
  hit=""
  for i in "${!EXEMPT[@]}"; do
    e="${EXEMPT[$i]}"
    if [ "${e%%|*}" = "$f" ] && [[ "$src" == *"${e#*|}"* ]]; then hit="$i"; break; fi
  done
  if [ -n "$hit" ]; then
    used+=("$hit"); exempted=$((exempted + 1)); continue
  fi
  echo "FAIL — $f:$ln pipes into an early-exit consumer ($kind) under pipefail:"
  echo "    ${src#"${src%%[![:space:]]*}"}"
  rc=1
done <<<"$found"
if [ "$rc" -ne 0 ]; then
  echo "Past ~64 KiB of output the producer dies of SIGPIPE/EPIPE and pipefail reports it. Capture"
  echo "once and match a herestring (grep -q x <<<\"\$v\"), or use a consumer that reads to EOF"
  echo "(awk 'NR==1'). If the status provably cannot matter, add the site to EXEMPT in $0 with a reason."
fi

for i in "${!EXEMPT[@]}"; do
  case " ${used[*]:-} " in *" $i "*) continue ;; esac
  echo "FAIL — stale EXEMPT entry in $0 (it matches no flagged site): ${EXEMPT[$i]}"
  rc=1
done

[ "$rc" = 0 ] && echo "OK — no early-exit pipe under pipefail in ${#SCOPE[@]} scripts (${exempted} exempt, each with a reason in $0)."
exit $rc
