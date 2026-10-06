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
# their long forms; also ggrep, zgrep and rg), sed with a q/Q command, awk with an `exit` before
# any END block, and xargs. Also found by a path (/usr/bin/head), quoted or backslashed
# (\head), behind a wrapper (timeout 5 head, sh -c 'head -1') or a redirection, and as any
# command of a piped `( … )`, `{ … }`, `if` or `case`, of a `>( … )`, or of a $( ) inside any of
# these. A piped for or select loop is flagged; a piped while or until loop too, unless its
# condition is one plain `read` and nothing in it can break, exit or return.
#
# Why a LEXER, not a grep. A per-line grep for `| head` / `| grep -q` trips on `|| grep -q
# … file` (OR, not a pipe), on comments that describe the pattern, on a `|` inside a quoted
# regex, and on heredoc bodies, and it misses a pipe at the end of one line feeding a consumer
# on the next. The awk below tracks quotes, $( ), ${ }, backticks, subshells, arithmetic,
# comments, line continuations and heredocs, and splits commands on the real operators.
# Anything it cannot close by end of file is a FAIL, not a guess.
#
# Scope: only scripts that enable pipefail. Without it a pipeline's status is the consumer's,
# so an early exit cannot flip it. Discovery is list_shell_scripts.sh's, shared with
# check_cdpath_safe.sh.
#
# It reads commands as they are written. A command name built at run time ($cmd, $'\x68ead',
# eval "$prog") is not followed, any more than a script it calls.
#
# What it does not do: decide that a site's status is ignored. That judgement goes in EXEMPT,
# one line of reason each, where a reviewer can see it.
set -uo pipefail
CDPATH= cd -- "$(dirname -- "$0")/.." || { echo "FAIL — cannot cd to the repo root from $0."; exit 1; }

# Sites that match but cannot flip a result. Format: 'path|needle' — needle is a fixed string
# that must appear on the flagged line, name its consumer and cover where that consumer stands
# (`| head -1`, not text elsewhere on the line). An entry covers ONE site; a line with two needs two. An entry that matches nothing
# FAILS as stale, so a fixed or moved site forces its entry out. Prefer rewriting a site to
# adding one here.
EXEMPT=(
  # Both are astro template files copied into every site: a no-op edit shows up as drift in
  # every site's whats-new, and ship.sh's header requires a template-version bump per change.
  'skills/new-website/templates/astro/scripts/ship.sh| | head -1 || true)"'  # `|| true` discards the status
  'skills/new-website/templates/astro/tests/check_ship_push.sh|"$1" | head -1; }'  # sed prints 1 tiny line in one write; head never races it
)

# A `set` line enabling pipefail: `set -o pipefail`, `set -euo pipefail`, `set -o errexit -o
# pipefail`, … Anchored at the start of the line, so a comment that mentions it does not count.
PIPEFAIL_RE='^[[:space:]]*set[[:space:]]+(.*[[:space:]])?-[a-zA-Z]*o[[:space:]]+pipefail([[:space:];]|$)'

# --- the lexer ---------------------------------------------------------------------------------
# Prints one line per flagged site: <file> TAB <line> TAB <column> TAB <consumer>. A file it
# cannot parse prints <file> TAB 0 TAB 0 TAB PARSE: <reason>. Plain POSIX awk: runs under mawk,
# nawk and gawk.
# read, not "$(cat <<'AWK' … )": bash 3.2 (macOS /bin/bash) parses a heredoc inside $( ) for
# quotes, and this awk body's unbalanced ' and ` stop the whole script from parsing there.
IFS= read -r -d '' LEXER <<'AWK' || true
BEGIN {
  EXITRE = "(^|[^a-zA-Z0-9_])exit([^a-zA-Z0-9_]|$)"
  STOPRE = "(^|[^a-zA-Z0-9_])(break|exit|return)([^a-zA-Z0-9_]|$)"
  CONSUMERS = "^(g?head|read|[efgz]?grep|rg|g?sed|[gmn]?awk|xargs)$"
  WRAPPERS = "^(time|command|builtin|exec|eval|env|nohup|nice|ionice|chrt|taskset|timeout|gtimeout|stdbuf|gstdbuf|setsid|sudo|doas|chroot|flock|unbuffer|busybox|sh|bash|dash|ksh|zsh)$"
}
function reset() {
  d = 1; ft[1] = "C"; tm[1] = ""; own[1] = 1; sq[1] = 0; an[1] = 0; ld[1] = 0; nwat[1] = 0; pc[1] = 0; cd[1] = 0; cwat[1] = 0
  buf[1] = ""; op[1] = ""; bl[1] = 0; bc[1] = 0; nh = 0; hh = 0; cont = 0
}
function blank(x) { return x ~ /^[ \t\n]*$/ }
function add(x,   o) {
  o = own[d]
  if (blank(buf[o]) && !blank(x)) { bl[o] = FNR; bc[o] = col }
  buf[o] = buf[o] x
}
# A new C frame inherits the pipe from the command it opens in: a ( … ), $( … ) or ` … ` inside
# a command that reads the pipe reads it too (`cmd | ( v=$(head -1) )`).
function push(t, term,   o, r) {
  o = own[d]; r = (op[o] == "|" || pc[o] || cwat[o])
  d++; ft[d] = t; tm[d] = term; sq[d] = 0; an[d] = 0
  if (t == "C") { own[d] = d; buf[d] = ""; op[d] = ""; bl[d] = FNR; bc[d] = 0; ld[d] = 0; nwat[d] = 0; pc[d] = r; cd[d] = 0; cwat[d] = 0 } else own[d] = own[d - 1]
}
# Ends the current command in C frame d. A newline after a bare `|`, `&&` or `||` continues the
# pipeline, so a newline on an empty command keeps the pending operator. A command reads the
# pipe if a `|` feeds it, if its frame reads the pipe (pc: see push(), and any `>( … )`), or if it sits in
# a piped `{ … }`, `if` or `case` that has not closed yet (cwat, the depth that one opened at):
# any command in there can be the last to read, and the pipe closes when the last one exits.
function endcmd(newop, isnl,   piped, base) {
  if (!blank(buf[d])) {
    piped = (op[d] == "|" || pc[d] || cwat[d]); base = cd[d]
    structure(buf[d])
    if (piped && !cwat[d] && cd[d] > base) cwat[d] = base + 1
    if (piped) check(buf[d], bl[d], bc[d])
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
# Whether an awk command can exit before reading all its input. Fail-safe by design: every
# shell word after `awk` is decoded ('…' literal; "…" with \" \\ \$ \` unescaped) and
# checked as if it were program text, so a program is found wherever it sits (after options,
# redirections, gawk's -e, several -e) without an option table having to be complete. Skipped,
# only so they cannot raise a false alarm: a redirection (judged by its unquoted start, so a
# quoted program like '1>0 {…}' is still read) with its target, and the value of -F, -v,
# --assign or --field-separator; after `--` no word is taken for an option. A word skipped by
# mistake would be a miss, so these lists stay narrow; a word checked by mistake (an input
# file named exit.log, another option's value) is at worst a false alarm, fixed in EXEMPT.
# A program read from a file (-f, -E, --file, --exec) is not visible here, so that consumer is
# flagged too (returns 2): read the file once and EXEMPT the site if it never exits early.
function awkexits(s,   n, i, c, q, w, have, words, lead, pre, nw, k, dd, val) {
  n = length(s); q = ""; w = ""; have = 0; nw = 0; pre = ""
  for (i = 1; i <= n + 1; i++) {
    c = (i <= n) ? substr(s, i, 1) : " "
    if (q == "'") { if (c == "'") q = ""; else w = w c; continue }
    if (q == "\"") {
      if (c == "\\" && substr(s, i + 1, 1) ~ /["\\$`]/) { w = w substr(s, i + 1, 1); i++; continue }
      if (c == "\"") q = ""; else w = w c
      continue
    }
    if (c == "'" || c == "\"" || c == "\\") {
      if (!have) pre = w   # the word's unquoted start
      have = 1
      if (c == "\\") { w = w substr(s, i + 1, 1); i++ } else q = c
      continue
    }
    if (c ~ /[ \t\n]/) {
      if (have || w != "") { words[++nw] = w; lead[nw] = have ? pre : w }
      w = ""; have = 0; pre = ""; continue
    }
    w = w c
  }
  dd = 0; val = 0
  for (k = 1; k <= nw; k++) {
    w = words[k]
    if (lead[k] == w && w ~ /^[0-9]*(<|<<|<<-|<<<|>|>>|>[|]|>&|<&|&>|&>>|<>)$/) { k++; continue }   # 2> file
    if (lead[k] ~ /^[0-9]*[<>&]/) continue                        # 2>/dev/null, 2>'exit.log'
    if (val) { val = 0; continue }       # the value -v/-F was waiting for, even "--" (awk -F --)
    if (!dd && w == "--") { dd = 1; continue }
    if (!dd && (w ~ /^-[fE]/ || w ~ /^--(file|exec)(=|$)/)) return 2
    if (!dd && (w ~ /^-[Fv]$/ || w ~ /^--(assign|field-separator)$/)) { val = 1; continue }
    if (!dd && (w ~ /^-[Fv]./ || w ~ /^--(assign|field-separator)=/)) continue
    if (early_exit(w)) return 1
  }
  return 0
}
# Whether awk program text can exit early. Fail-safe, in two steps. First a plain search of
# the whole decoded program for the word `exit`, with nothing removed: no word, no finding,
# and a plain search cannot be fooled. Only then may the finding be cleared: unlit() blanks
# strings, regex literals and comments, strip_end() drops END blocks from that blanked text
# (an exit there runs after all input is read), and if no exit is left the finding goes —
# but only if unlit() met nothing it could have misread (`unsure`). Every misreading therefore
# costs a false alarm, never a miss.
function early_exit(prog,   u) {
  if (prog !~ EXITRE) return 0
  u = unlit(prog)
  if (unsure) return 1
  return strip_end(u) ~ EXITRE
}
# Blanked text without its END blocks: an END counts only where a rule can start (the start,
# a newline, } or ;) and only if its braces close; otherwise the text stays.
function strip_end(rest,   out, j, nb, ch, m, pre) {
  out = ""
  while (match(rest, /(^|[\n};])[ \t\n]*END[ \t\n]*\{/)) {
    j = RSTART + RLENGTH; nb = 1
    while (j <= length(rest) && nb > 0) { ch = substr(rest, j, 1); if (ch == "{") nb++; else if (ch == "}") nb--; j++ }
    if (nb > 0) break
    m = substr(rest, RSTART, 1); pre = (m ~ /[\n};]/) ? m : ""
    out = out substr(rest, 1, RSTART - 1) pre
    rest = substr(rest, j)
  }
  return out rest
}
# The program with its strings, regex literals and comments blanked, in one pass. A / opens a
# regex only where nothing else can stand: at the start or right after one of \n ( , { } ; !
# ~ & | = * % ^ < > ? :. It divides after a digit (a number, or a name ending in one, which
# no keyword does), ], ., or a closed string or regex (awk reads "a" /x/ as a division).
# Anything else sets `unsure`, and early_exit() then keeps its finding: a / after a name
# (`n / 2` or `print /re/`: telling a variable from a keyword is one more thing to get wrong),
# after $, + or - (x++ / 2), after ) (`if (c) /re/` vs `(a) / 2`), a string or regex still
# open at the end of its line, and any backslash-newline.
function unlit(s,   n, i, c, out, last) {
  n = length(s); out = ""; last = ""; unsure = 0
  for (i = 1; i <= n; i++) {
    c = substr(s, i, 1)
    if (c == "\\") {
      if (substr(s, i + 1, 1) == "\n") unsure = 1
      out = out substr(s, i, 2); i++; last = "a"; continue
    }
    if (c == "\"" || (c == "/" && (last == "" || index("\n(,{};!~&|=*%^<>?:", last)))) {
      for (i++; i <= n && substr(s, i, 1) != c && substr(s, i, 1) != "\n"; i++)
        if (substr(s, i, 1) == "\\") { if (substr(s, i + 1, 1) == "\n") unsure = 1; i++ }
      if (i > n || substr(s, i, 1) == "\n") unsure = 1
      out = out c c; last = "0"; continue
    }
    if (c == "#") { while (i < n && substr(s, i + 1, 1) != "\n") i++; continue }
    if (c == "/" && last !~ /[0-9\].]/) unsure = 1
    out = out c
    if (c !~ /[ \t]/) last = c
  }
  return out
}
# A word as the shell runs it: quotes, $'…' and $"…" markers and backslashes go (`"break"`,
# `\head` and $'head' still run).
function unquote(w) { gsub(/\$['"]/, "'", w); gsub(/["'\\]/, "", w); return w }
# The length of the shell word x starts with: up to unquoted whitespace.
function wordlen(x,   i, n, c, q) {
  n = length(x); q = ""
  for (i = 1; i <= n; i++) {
    c = substr(x, i, 1)
    if (q == "'") { if (c == "'") q = ""; continue }
    if (q == "$'" || q == "\"") { if (c == "\\") i++; else if (c == substr(q, length(q))) q = ""; continue }
    if (c == "\\") { i++; continue }
    if (c == "$" && substr(x, i + 1, 1) == "'") { q = "$'"; i++; continue }
    if (c == "'" || c == "\"") { q = c; continue }
    if (c ~ /[ \t\n]/) return i - 1
  }
  return n
}
# A command name as the shell runs it: unquoted, and a path cut to its last part, so
# /usr/bin/head, \head and 'head' are all head.
function cmdname(w) { w = unquote(w); sub(/.*\//, "", w); return w }
# One line per flagged site: file, line, the column its consumer starts at, and what it is.
function flag(ln, cl, kind) { print FILENAME "\t" ln "\t" cl "\t" kind }
function flagloop(k, why) {
  if (wfl[d, k]) return
  wfl[d, k] = 1; flag(wln[d, k], wcl[d, k], wkw[d, k] " loop that can stop reading early (" why ")")
}
# The piped command x (starting at line ln, column cl), behind any `!`, `{`, `if`, `then`,
# `else`, `elif`, `do` and any redirection before the command name (`2>/dev/null head`).
# A loop is judged by its kind and condition; see structure() for the rest of its watch. A
# known consumer is judged where it stands. Behind an assignment or a wrapper, every later word
# that names a consumer is judged, not only the one the wrapper would run: `timeout -s KILL 5
# head`, `sh -c 'head -1'` and `env -u awk grep -q` need no option table, and a wrong pick
# costs a false alarm, not a miss. A wrapper missing from WRAPPERS hides its consumer; add it.
function check(x, ln, cl,   w, kind, n0, k, rl) {
  sub(/^[ \t\n]+/, "", x); n0 = length(x)
  for (;;) {
    if (match(x, /^(!|\{|if|then|else|elif|do)[ \t\n]+/)) { x = substr(x, RLENGTH + 1); continue }
    if (match(x, /^[0-9]*(<<<|<>|<&|<|>>|>[|]|>&|>|&>>|&>)[ \t\n]*/)) {
      x = substr(x, RLENGTH + 1); x = substr(x, wordlen(x) + 1); sub(/^[ \t\n]+/, "", x); continue
    }
    break
  }
  if (x ~ /^(while|until)([^A-Za-z0-9_=]|$)/) {
    k = ++nwat[d]; wdep[d, k] = ld[d]; wln[d, k] = ln; wcl[d, k] = cl + n0 - length(x)
    wkw[d, k] = substr(x, 1, 5); wfl[d, k] = 0; wcond[d, k] = 1
    if (!plainread(substr(x, 6), wkw[d, k] == "until")) flagloop(k, "its condition is not one plain read")
    return
  }
  if (x ~ /^(for|select)([^A-Za-z0-9_=]|$)/) {
    w = (x ~ /^for/) ? "for" : "select"
    flag(ln, cl + n0 - length(x), w " loop that can stop reading early (it ends with its word list, not with its input)")
    return
  }
  match(x, /^[^ \t\n;]*/); w = cmdname(substr(x, 1, RLENGTH))
  if (w ~ CONSUMERS) kind = kindof(w substr(x, RLENGTH + 1))
  else if (w ~ WRAPPERS || x ~ /^[A-Za-z_][A-Za-z0-9_]*=/) {
    while (match(x, /[^ \t\n;]+/)) {
      rl = RLENGTH; w = cmdname(substr(x, RSTART, rl)); x = substr(x, RSTART)
      if (w ~ CONSUMERS && (kind = kindof(w substr(x, rl + 1))) != "") break
      x = substr(x, rl + 1)
    }
  }
  if (kind != "") flag(ln, cl + n0 - length(x), kind)
}
# Whether a loop condition c is one plain `read` (after `!` for until): the one condition that
# ends only at end of input. An allow-list, so anything it does not know is flagged: simple
# assignments (IFS= …), then `read` with only -r, -s, -e, -a <name>, -d <word> and variable names. Not
# -t (a timeout ends it), -u or a redirection (it reads elsewhere), nor a quoted option.
function plainread(c, inv) {
  sub(/^[ \t\n]+/, "", c); sub(/[ \t\n]+$/, "", c)
  if (inv) { if (!match(c, /^![ \t\n]+/)) return 0; c = substr(c, RLENGTH + 1) }
  while (match(c, /^[A-Za-z_][A-Za-z0-9_]*=("[^"]*"|'[^']*'|\$'[^']*'|[^ \t\n"'<>|&;]*)[ \t\n]+/)) c = substr(c, RLENGTH + 1)
  if (c !~ /^read([ \t\n]|$)/) return 0
  c = substr(c, 5)
  while (match(c, /^[ \t\n]+(-[rse]*d[ \t\n]*('[^']*'|"[^"]*"|\$'[^']*'|[^ \t\n"'<>|&;]+)|-[rse]*a[ \t\n]+[A-Za-z_][A-Za-z0-9_]*|-[rse]+|[A-Za-z_][A-Za-z0-9_]*)/)) c = substr(c, RLENGTH + 1)
  return c == ""
}
# Loops and compound commands, tracked for each command of a C frame. A frame is its own scope:
# an exit inside $( ) or ( ) ends that subshell, not the loop around it.
# Reserved words count only unquoted and where a command starts, behind `!`, `do`, `then`,
# `else`, `elif` and `time`, which is the only place the shell sees them: openers `{`, `if` and
# `case` (cd) and `while`, `until`, `for` and `select` (ld), plus the `{` of a function
# definition; closers `}`, `fi`, `esac` and `done`. Missing an opener is the miscount that could
# miss, as its closer would end the watch around it early.
# Loops: a piped while/until loop is watched (check()). A command before its `do` is one more
# condition command (`read -r l && [ "$l" != END ]`), which can end the loop early, except the
# last-line idiom `while read … || [ -n "$l" ]`, which ends only at end of input too (in an
# until loop the same text ends at the first line). Then a plain search, as for awk's exit: the
# word break, exit or return in a command of the frame flags every open watch, found in its
# text as written OR with quotes and backslashes removed (STOPRE on both), so neither reading
# can lose what the other finds. `2>/dev/null break`, `break>/dev/null`, `eval 'break;'`,
# `b"reak"`, `br\eak` and `command exit` need no parsing; `echo "press return"` costs a false
# alarm. Text inside $( ) is not searched: it is another frame, and an exit there ends that
# subshell. Even a break that only leaves an inner loop counts, since `break 2` leaves more. A
# `done` closes the watches it ends.
function structure(x,   w, k) {
  sub(/^[ \t\n]+/, "", x)
  if (x ~ /^do([ \t\n]|$)/) { for (k = 1; k <= nwat[d]; k++) wcond[d, k] = 0 }
  else {
    w = (op[d] == "||" && x ~ /^\[[ \t]+-n[ \t]+"\$\{?[A-Za-z_][A-Za-z0-9_]*\}?"[ \t]+\]$/)
    for (k = 1; k <= nwat[d]; k++)
      if (wcond[d, k] && !(w && wkw[d, k] == "while")) flagloop(k, "its condition has more than one command")
  }
  for (;;) {
    if (match(x, /^(!|do|then|else|elif|time)[ \t\n]+/)) { x = substr(x, RLENGTH + 1); continue }
    if (match(x, /^(\{|if|case)([ \t\n]+|$)/)) { cd[d]++; x = substr(x, RLENGTH + 1); continue }
    if (x ~ /^(while|until|for|select)([^A-Za-z0-9_=-]|$)/) { ld[d]++; sub(/^[a-z]+[ \t\n]*/, "", x); continue }
    break
  }
  if (x ~ /^(function[ \t]+[^ \t\n(]+([ \t]*\(\))?|[A-Za-z_][A-Za-z0-9_:.-]*[ \t]*\(\))[ \t\n]*\{([ \t\n]|$)/) cd[d]++
  while (match(x, /^(\}|fi|esac|done)([ \t\n;&|<>)]+|$)/)) {
    if (substr(x, 1, 4) == "done") {
      while (nwat[d] > 0 && wdep[d, nwat[d]] >= ld[d]) nwat[d]--
      if (ld[d] > 0) ld[d]--
    } else {
      if (cd[d] > 0) cd[d]--
      if (cwat[d] > cd[d]) cwat[d] = 0
    }
    x = substr(x, RLENGTH + 1)
  }
  if (nwat[d] == 0 || !(match(x, STOPRE) || match(unquote(x), STOPRE))) return
  w = (match(x, STOPRE) ? substr(x, RSTART, RLENGTH) : "")
  if (w == "" && match(unquote(x), STOPRE)) w = substr(unquote(x), RSTART, RLENGTH)
  gsub(/[^a-z]/, "", w)
  for (k = 1; k <= nwat[d]; k++) flagloop(k, w " on line " FNR)
}
# The kind of early-exit consumer x is, or "" for none; x starts at its command name.
function kindof(x,   w, nw, k, kind) {
  kind = ""
  if (x ~ /^g?head([ \t\n;]|$)/) kind = "head"
  else if (x ~ /^read([ \t\n;]|$)/) kind = "read"
  else if (x ~ /^xargs([ \t\n;]|$)/) kind = "xargs (it stops reading if a command it runs exits 255, or at an -E end-of-file string; neither is checked here)"
  else if (x ~ /^([efgz]?grep|rg)([ \t\n]|$)/) {
    nw = split(x, w, /[ \t\n]+/)
    for (k = 2; k <= nw; k++) {
      gsub(/["']/, "", w[k])   # grep '-q' and grep "-q" are grep -q to the shell
      if (w[k] == "--") break
      if (w[k] ~ /^-[a-zA-Z]*[qmlL]/ || w[k] ~ /^--(quiet|silent|max-count|files-with-matches|files-without-match)/) {
        kind = w[1] " " w[k]; break
      }
    }
  } else if (x ~ /^g?sed([ \t\n]|$)/) {
    sub(/^g?sed/, "", x)
    if (x ~ /(^|[^a-zA-Z_\\])[qQ][0-9]*([ \t\n;}'"]|$)/) kind = "sed with q"
  } else if (x ~ /^[gmn]?awk([ \t\n]|$)/) {
    sub(/^[gmn]?awk/, "", x)
    k = awkexits(x)
    if (k == 1) kind = "awk with exit"
    else if (k == 2) kind = "awk -f: its program file is not checked; read it, and EXEMPT the site if it never exits early"
  }
  return kind
}
function lex(s,   i, n, c, c2, t, j, w, ch, strip, piped) {
  n = length(s)
  for (i = 1; i <= n; i++) {
    c = substr(s, i, 1); t = ft[d]; col = i
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
        if (c2 == "|") { endcmd("||", 0); i++; continue }  # kept for structure(): read … || [ -n "$l" ]
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
        # A `( … )` reads the pipe where its command does (push()); a `>( … )` always does, as
        # whatever writes to it feeds it.
        add(c); push("C", ")"); if (i > 1 && substr(s, i - 1, 1) == ">") pc[d] = 1; continue
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
  if (perr != "") print f "\t0\t0\tPARSE: " perr
  else if (hh < nh) print f "\t0\t0\tPARSE: heredoc '" hq[hh + 1] "' never ends"
  else if (d != 1 || sq[1]) print f "\t0\t0\tPARSE: a quote, $( ), ${ } or ( ) is still open at end of file"
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

# covers <line> <needle> <column>: whether some occurrence of the needle spans that column. Bytes,
# as awk counted them under LC_ALL=C.
covers() {
  local LC_ALL=C rest="$1" pre off=0 p
  while [[ "$rest" == *"$2"* ]]; do
    pre="${rest%%"$2"*}"; p=$((off + ${#pre} + 1))
    [ "$p" -le "$3" ] && [ $((p + ${#2})) -gt "$3" ] && return 0
    off=$p; rest="${rest:${#pre}+1}"
  done
  return 1
}

# --- exemptions ---------------------------------------------------------------------------------
# resolve <entry>...: reads the lexer's records on stdin; prints a FAIL for each site no entry
# exempts, then for each entry that exempted nothing (stale), and returns 1 if it printed any.
# Sets `exempted` to the count. An entry exempts ONE site: in its file, where its needle both
# names the site's consumer (head, grep, sed, awk, read, xargs, while, until, for, select) and
# covers the column that consumer starts at, so other text on the line cannot stand in for it.
# Once used, an entry is spent: a second consumer added to an exempted line fails like any other.
resolve() {
  local f ln col kind src word e i hit taken r=0 used=" "
  exempted=0
  while IFS=$'\t' read -r f ln col kind; do
    [ -n "$f" ] || continue
    if [ "$ln" = 0 ]; then
      echo "FAIL — $f: cannot lex it (${kind#PARSE: }). Fix the script, or teach this guard the construct."
      r=1; continue
    fi
    src="$(sed -n "${ln}p" <"$f")"
    word="${kind%% *}"
    hit=""; taken=""; i=0
    for e in "$@"; do
      i=$((i + 1))
      [ "${e%%|*}" = "$f" ] && [[ "${e#*|}" == *"$word"* ]] && covers "$src" "${e#*|}" "$col" || continue
      case "$used" in *" $i "*) taken="$e"; continue ;; esac
      hit="$i"; break
    done
    if [ -n "$hit" ]; then
      used="$used$hit "; exempted=$((exempted + 1)); continue
    fi
    echo "FAIL — $f:$ln pipes into an early-exit consumer ($kind) under pipefail:"
    echo "    ${src#"${src%%[![:space:]]*}"}"
    [ -z "$taken" ] || echo "    (EXEMPT entry '$taken' already covers another site; an entry covers one)"
    r=1
  done
  if [ "$r" -ne 0 ]; then
    echo "Past ~64 KiB of output the producer dies of SIGPIPE/EPIPE and pipefail reports it. Capture"
    echo "once and match a herestring (grep -q x <<<\"\$v\"), or use a consumer that reads to EOF"
    echo "(awk 'NR==1'). If the status provably cannot matter, add the site to EXEMPT in $0 with a reason."
  fi
  i=0
  for e in "$@"; do
    i=$((i + 1))
    case "$used" in *" $i "*) continue ;; esac
    echo "FAIL — stale EXEMPT entry in $0 (it exempts no flagged site; its needle must name the consumer): $e"
    r=1
  done
  return "$r"
}

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
@@ bad/subshell-consumer
cmd | ( grep -q x )
@@ bad/group-consumer
cmd | { grep -q x; }
@@ bad/grep-q-single-quoted
cmd | grep '-q' x
@@ bad/grep-q-double-quoted
cmd | grep "-q" x
@@ bad/awk-exit-after-end-block
cmd | awk 'END { print n } NR == 1 { exit }'
@@ bad/awk-exit-in-begin
cmd | awk 'BEGIN { exit }'
@@ bad/awk-exit-beside-string
cmd | awk '{ print "x" } NR == 1 { exit }'
@@ bad/awk-program-in-double-quotes
cmd | awk "NR == 1 { exit }"
@@ bad/awk-with-options
cmd | awk -F'\t' -v n=1 'NR == n { print; exit }'
@@ bad/gawk-exit
cmd | gawk 'NR == 1 { exit }'
@@ bad/awk-redirect-before-program
cmd | awk 2>/dev/null 'NR == 1 { exit }'
@@ bad/awk-separated-redirect-before-program
cmd | awk 2> /dev/null 'NR == 1 { exit }'
@@ bad/awk-long-assign
cmd | gawk --assign n=1 'NR == n { exit }'
@@ bad/awk-long-field-separator
cmd | gawk --field-separator '\t' 'NR == 1 { exit }'
@@ bad/awk-W-option
cmd | mawk -W interactive 'NR == 1 { exit }'
@@ bad/gawk-source
cmd | gawk -e 'NR == 1 { exit }'
@@ bad/awk-program-looks-like-redirect
cmd | awk '1>0 { print; exit }'
@@ bad/awk-redirect-between-option-and-value
cmd | awk -v 2>/dev/null n=1 'NR == n { exit }'
@@ bad/awk-redirect-after-double-dash
cmd | awk -- 2>/dev/null 'NR == 1 { exit }'
@@ bad/awk-clobber-redirect
cmd | awk 2>| /dev/null 'NR == 1 { exit }'
@@ bad/gawk-exit-in-second-source
cmd | gawk -e '{ print }' -e 'NR == 1 { exit }'
@@ bad/awk-unknown-option-before-program
cmd | gawk --profile prof.out 'NR == 1 { exit }'
@@ bad/awk-dash-program-after-double-dash
cmd | awk -v value=1 -- '-value { print; exit }'
@@ bad/awk-escaped-quote-in-double-quoted-program
cmd | awk "NR == 1 { print \"x\"; exit }"
@@ bad/awk-quotes-in-comments-around-exit
cmd | awk '# a "quote
{ print; exit }
# and another "'
@@ bad/awk-hash-in-string-before-exit
cmd | awk '{ print "#" } NR == 1 { exit }'
@@ bad/awk-regex-with-quote-after-print
cmd | awk '{ print /"/; exit }'
@@ bad/awk-end-inside-a-string
cmd | awk '{ print "END {"; if (NR == 1) exit; print "}" }'
@@ bad/awk-brace-in-end-string
cmd | awk 'END { print "{" } NR == 1 { exit }'
@@ bad/awk-backslash-newline
cmd | awk '{ x = 1 \
/ 2; exit }'
@@ bad/awk-end-marker-inside-a-string
cmd | awk '{ print ";END {"; exit; print "}" }'
@@ bad/awk-braces-split-across-strings
cmd | awk 'END { print "{" } NR == 1 { exit } { print "}" }'
@@ bad/awk-division-after-postfix-increment
cmd | awk '{ x = 2; y = x++ / 2; exit; # /
}'
@@ bad/awk-regex-after-if-paren
cmd | awk '{ if (1) /#/; exit }'
@@ bad/awk-regex-after-else-print
cmd | awk '{ if (0) print 1; else print /#/; exit }'
@@ bad/awk-slash-after-a-name-keeps-the-finding
cmd | awk '{ n = NR / 2; print n; exit } # a comment with a /'
@@ bad/awk-program-from-a-file
cmd | awk -f prog.awk
@@ bad/gawk-program-from-a-file-long-option
cmd | gawk -v n=1 --file=prog.awk
@@ bad/awk-field-separator-dashdash-then-file
cmd | awk -F -- -f prog.awk
@@ bad/gawk-program-via-exec
cmd | gawk -E prog.awk
@@ bad/gawk-program-via-exec-long-option
cmd | gawk --exec prog.awk
@@ bad/awk-escaped-newline-in-string
cmd | awk '{ s = "a\
"; exit }'
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
@@ bad/head-by-path
cmd | /usr/bin/head -1
@@ bad/head-alias-bypass
cmd | \head -1
@@ bad/consumer-name-quoted
cmd | 'grep' -q x
@@ bad/timeout-wrapper
cmd | timeout 5 head -1
@@ bad/timeout-wrapper-with-signal
cmd | timeout -s KILL 5 grep -q x
@@ bad/env-wrapper-with-options
cmd | env -i PATH=/bin grep -q x
@@ bad/env-wrapper-by-path
cmd | /usr/bin/env head -1
@@ bad/command-wrapper-with-option
cmd | command -p head -1
@@ bad/nice-wrapper
cmd | nice -n 5 sed 1q
@@ bad/stdbuf-wrapper
cmd | stdbuf -oL awk 'NR == 1 { exit }'
@@ bad/time-wrapper-with-option
cmd | time -p head -1
@@ bad/nested-wrappers
cmd | nice timeout 5 env LC_ALL=C grep -q x
@@ bad/wrapper-then-path
cmd | timeout 5 /usr/bin/head -1
@@ bad/wrapper-argument-named-like-a-consumer
cmd | env -u awk grep -q x
@@ bad/if-consumer
cmd | if grep -q x; then :; fi
@@ bad/tee-into-process-substitution
cmd | tee >(head -1) >/dev/null
@@ bad/redirect-into-process-substitution
cmd > >(grep -q x)
@@ bad/while-read-break
cmd | while IFS= read -r l; do
  [ "$l" = x ] && break
done
@@ bad/while-read-break-one-line
cmd | while read -r l; do break; done
@@ bad/while-read-exit-in-case
cmd | while read -r l; do
  case $l in x) exit 1 ;; esac
done
@@ bad/until-loop-return
f() {
  cmd | until ! read -r l; do return; done
}
@@ bad/while-in-group-consumer
cmd | { while read -r l; do break; done; }
@@ bad/while-in-subshell-consumer
cmd | ( while read -r l; do exit; done )
@@ bad/while-on-the-next-line
cmd |
  while read -r l; do break; done
@@ bad/while-break-after-inner-loop
cmd | while read -r l; do
  for x in a b; do :; done
  break
done
@@ bad/while-break-2-from-inner-loop
cmd | while read -r l; do for x in a; do break 2; done; done
@@ bad/while-break-after-then
cmd | while read -r l; do if [ -z "$l" ]; then break; fi; done
@@ bad/consumer-later-in-a-piped-subshell
cmd | ( echo start; head -1 )
@@ bad/consumer-later-in-a-piped-group
cmd | { echo start; grep -q x; }
@@ bad/consumer-in-a-piped-if
cmd | if true; then head -1; fi
@@ bad/consumer-in-a-piped-else
cmd | if false; then :; else sed 1q; fi
@@ bad/consumer-in-a-piped-case
cmd | case $1 in
  a) head -1 ;;
esac
@@ bad/consumer-later-in-a-process-substitution
cmd | tee >(echo start; head -1) >/dev/null
@@ bad/loop-later-in-a-piped-group
cmd | { echo start; while read -r l; do break; done; }
@@ bad/consumer-after-a-nested-if-in-a-piped-group
cmd | {
  if true; then :; fi
  head -1
}
@@ bad/xargs-stops-at-an-eof-string
cmd | xargs -E STOP echo
@@ bad/xargs-stops-when-a-command-exits-255
cmd | xargs -n 1 sh -c 'exit 255'
@@ bad/consumer-in-a-substitution-in-a-piped-subshell
cmd | (v="$(head -1)")
@@ bad/consumer-in-a-substitution-of-the-piped-command
cmd | echo "$(head -1)"
@@ bad/subshell-after-then-in-a-piped-if
cmd | if true; then (head -1); fi
@@ bad/consumer-in-a-backtick-in-a-piped-group
cmd | { v=`head -1`; }
@@ bad/until-condition-is-a-consumer
cmd | until grep -q x; do :; done
@@ bad/while-condition-with-a-sentinel
cmd | while IFS= read -r l && [ "$l" != END ]; do :; done
@@ bad/while-condition-on-two-lines
cmd | while read -r l
  [ "$l" != END ]
do :; done
@@ bad/while-condition-is-not-read
cmd | while true; do head -1; done
@@ bad/while-read-with-a-timeout
cmd | while read -t 1 -r l; do :; done
@@ bad/for-loop-consumer
cmd | for x in 1; do head -1; done
@@ bad/quoted-break
cmd | while read -r l; do "break"; done
@@ bad/backslashed-exit
cmd | while read -r l; do \exit 1; done
@@ bad/eval-break
cmd | while read -r l; do eval break; done
@@ bad/builtin-return
f() { cmd | while read -r l; do builtin return; done; }
@@ bad/sh-c-wrapper
cmd | sh -c 'head -1'
@@ bad/bash-c-wrapper
cmd | bash -c "grep -q x"
@@ bad/eval-wrapper
cmd | eval head -1
@@ bad/busybox-wrapper
cmd | busybox awk 'NR == 1 { exit }'
@@ bad/redirect-before-the-consumer
cmd | 2>/dev/null head -1
@@ bad/separated-redirect-before-the-consumer
cmd | 2> /dev/null grep -q x
@@ bad/homebrew-ghead
cmd | ghead -1
@@ bad/homebrew-gsed-q
cmd | gsed 1q
@@ bad/homebrew-ggrep-q
cmd | ggrep -q x
@@ bad/ripgrep-q
cmd | rg -q x
@@ bad/consumer-after-a-function-in-a-piped-group
cmd | {
  f() { :; }
  head -1
}
@@ bad/read-with-a-quoted-timeout-option
cmd | while read '-t' 1 l; do :; done
@@ bad/read-from-another-file-in-the-condition
cmd | while read -r l </dev/null; do :; done
@@ bad/redirected-break
cmd | while read -r l; do 2>/dev/null break; done
@@ bad/ansi-c-quoted-break-in-eval
cmd | while read -r l; do eval $'break'; done
@@ bad/ansi-c-quoted-shell-program
cmd | sh -c $'head -1'
@@ bad/redirect-target-with-a-space
cmd | 2>"a b" head -1
@@ bad/break-as-an-argument-keeps-the-finding
cmd | while read -r l; do echo break; done
@@ bad/while-read-and-a-test
cmd | while read -r l && [ -n "$l" ]; do :; done
@@ bad/while-read-or-another-command
cmd | while read -r l || true; do :; done
@@ bad/break-glued-to-a-redirection
cmd | while read -r l; do break>/dev/null; done
@@ bad/eval-of-a-quoted-break
cmd | while read -r l; do eval 'break;'; done
@@ bad/read-a-without-a-name
cmd | while read -a; do :; done
@@ bad/read-a-then-an-option
cmd | while read -a -r l; do :; done
@@ bad/redirect-target-in-ansi-c-quotes-with-an-escaped-quote
cmd | 2>$'a\' b' head -1
@@ bad/partly-backslashed-break
cmd | while read -r l; do br\eak; done
@@ bad/partly-quoted-break
cmd | while read -r l; do b"reak"; done
@@ bad/until-read-or-last-line
cmd | until ! read -r l || [ -n "$l" ]; do :; done
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
@@ good/awk-exit-in-string
cmd | awk '{ print "exit" }'
@@ good/awk-exit-in-regex
cmd | awk '/exit/ { n++ } END { print n + 0 }'
@@ good/awk-exit-regex-after-brace
cmd | awk '{ n++ } /exit/ { print n }'
@@ good/awk-exit-regex-assigned
cmd | awk '{ x = /exit/; print x }'
@@ good/awk-exit-in-double-quoted-string
cmd | awk "{ print \"exit\" }"
@@ good/awk-field-separator-is-not-a-file
cmd | awk -F, '{ print $1 }'
@@ good/awk-var-named-exit
cmd | awk -v exit_code=0 '{ print }'
@@ good/awk-assign-value-named-exit
cmd | gawk --assign mode=exit '{ print mode }'
@@ good/awk-redirect-named-exit
cmd | awk '{ print }' 2>exit.log
@@ good/awk-redirect-quoted-target-named-exit
cmd | awk '{ print }' 2>'exit.log'
@@ good/awk-redirect-separated-quoted-target
cmd | awk '{ print }' 2> "exit.log"
@@ good/awk-redirect-between-option-and-value
cmd | awk -v 2>/dev/null mode=exit '{ print mode }'
@@ good/awk-clobber-redirect-named-exit
cmd | awk '{ print }' 2>| exit.log
@@ good/awk-exit-in-comment
cmd | awk '{ n++ } # exit early? no
END { print n }'
@@ good/awk-herestring-named-exit
cmd | awk '{ print }' <<< exit
@@ good/awk-division-then-exit-in-end
cmd | awk '{ s += $1 / 2 } END { if (s > NR) exit 1 }'
@@ good/subshell-drains
cmd | ( cat >/dev/null )
@@ good/subshell-not-piped
( grep -q x file )
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
@@ good/tail-by-path
cmd | /usr/bin/tail -1
@@ good/head-as-producer
head -n 1 file | tr -d '\0'
@@ good/wrapper-around-draining-consumer
cmd | timeout 5 grep -c x
@@ good/path-to-draining-consumer
cmd | /usr/bin/grep -v x | sort
@@ good/wrapped-head-as-producer
timeout 5 head -n 1 file | tr -d '\0'
@@ good/while-read-drains
cmd | while IFS= read -r l; do printf '%s\n' "$l"; done
@@ good/while-read-continue
cmd | while read -r l; do [ -n "$l" ] || continue; echo "$l"; done
@@ good/exit-after-the-piped-loop
cmd | while read -r l; do
  for x in a; do echo "$x"; done
done
exit 0
@@ good/break-in-a-loop-not-piped
while read -r l; do break; done <file
@@ good/exit-in-a-substitution-in-the-loop
cmd | while read -r l; do v="$(exit 1)"; done
@@ good/input-process-substitution
diff <(head -n 1 file) other
@@ good/tee-into-draining-process-substitution
cmd | tee >(sort >out) >/dev/null
@@ good/consumer-after-a-piped-group-ends
cmd | { cat; }
head -n 1 file
@@ good/consumer-after-a-piped-if-ends
cmd | if true; then cat; fi
head -n 1 file
@@ good/consumer-in-a-group-not-piped
{ echo start; head -n 1 file; }
@@ good/brace-inside-a-quoted-awk-program
cmd | awk '/x/ { print }'
head -n 1 file
@@ good/loop-word-in-prose-then-exit
echo for while
cmd | while read -r l; do :; done
exit 0
@@ good/while-read-with-ifs-and-options
cmd | while IFS= read -r -d '' f; do printf '%s\n' "$f"; done
@@ good/until-not-read
cmd | until ! read -r l; do :; done
@@ good/while-read-with-combined-options
cmd | while IFS= read -rd '' f; do :; done
@@ good/while-read-or-last-line
cmd | while IFS= read -r l || [ -n "$l" ]; do printf '%s\n' "$l"; done
@@ good/read-into-an-array
cmd | while read -ra parts; do :; done
@@ good/exit-word-inside-a-substitution-in-a-piped-loop
cmd | while read -r l; do v="$(echo exit)"; done
CASES

TAB=$'\t'
flagged="$(LC_ALL=C awk "$LEXER" "$tmp"/bad/* "$tmp"/good/*)"; lrc=$?
if [ "$lrc" -ne 0 ]; then
  echo "FAIL — self-test: awk exited $lrc; the lexer is broken on this system's awk."
  exit 1
fi
for f in "$tmp"/bad/*; do
  grep -qF "$f$TAB" <<<"$flagged" && ! grep -qF "$f${TAB}0${TAB}0${TAB}PARSE" <<<"$flagged" || {
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
# EXEMPT, through the lexer and the same resolve() the scan uses. Each case gives how many FAIL
# lines it must print: an entry covers one site, and its needle must name and cover its consumer.
ex="$tmp/exempt"; mkdir "$ex"
printf '%s\n' 'a="$(cmd | head -1 || true)"' >"$ex/one"
printf '%s\n' 'a="$(cmd | head -1 || true)"; b="$(cmd | head -1 || true)"' >"$ex/two"
printf '%s\n' 'a="$(cmd | head -1 || true)"; b="$(cmd | sed 1q || true)"' >"$ex/pair"
printf '%s\n' 'v() { sed -n 1p "$1" | head -1; }' >"$ex/unnamed"
printf '%s\n' 'cmd | head -1  # header row' >"$ex/elsewhere"
printf '%s\n' 'echo "— — é" | head -1' >"$ex/multibyte"
exempt_case() {  # <FAIL lines wanted> <what a mismatch means> <file> <entry>...
  local want="$1" what="$2" f="$3" out got; shift 3
  out="$(resolve "$@" <<<"$(LC_ALL=C awk "$LEXER" "$f")")"
  got="$(grep -c '^FAIL' <<<"$out")"
  [ "$got" = "$want" ] || { echo "FAIL — self-test: EXEMPT $what ($got FAIL line(s), not $want):"; sed 's/^/    /' <<<"$out"; exit 1; }
}
exempt_case 0 'misses its one site' "$ex/one" "$ex/one"'| | head -1 || true)"'
exempt_case 1 'covers a second site on its line' "$ex/two" "$ex/two"'| | head -1 || true)"'
exempt_case 0 'entries cannot cover two sites on one line' "$ex/pair" "$ex/pair|a=\"\$(cmd | head -1" "$ex/pair|b=\"\$(cmd | sed 1q"
exempt_case 2 'covers a site its needle does not name' "$ex/unnamed" "$ex/unnamed|v() { sed -n"
exempt_case 2 'covers a site from text elsewhere on its line' "$ex/elsewhere" "$ex/elsewhere|# header row"
exempt_case 0 'misses a site after multi-byte text (columns are bytes)' "$ex/multibyte" "$ex/multibyte"'|" | head'

# --- scan ---------------------------------------------------------------------------------------
all_scripts="$(bash scripts/list_shell_scripts.sh)" || { printf '%s\n' "$all_scripts"; exit 1; }
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

resolve ${EXEMPT[@]+"${EXEMPT[@]}"} <<<"$found"; rc=$?

[ "$rc" = 0 ] && echo "OK — no early-exit pipe under pipefail in ${#SCOPE[@]} scripts (${exempted} exempt, each with a reason in $0)."
exit $rc
