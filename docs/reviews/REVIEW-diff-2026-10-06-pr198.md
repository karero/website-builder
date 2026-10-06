# DIFF review — karero/website-builder#198 — pipefail guard: wrappers, paths, piped compounds and loops; one site per EXEMPT entry
Base `b8d7136`, after merging main `b02c165` · depth: **Normal** (guard logic whose misses are silent; no user data, no production path; the owner asked for this gate, "likely Normal") · verdict: **CLEAN** at `f3526b4` (5 rounds, 28 findings, plus 2 re-gates with 3 more; every BUG and RISK fixed or refuted) · authority used: WORKTREE-WRITE — atom A (this session's worktree) and atom B ("Write the trail under `docs/reviews/`") · BRANCH-COMMIT — atom A (this session created `claude/pipefail-guard-followups`) · POST AUTHORITY — atom A (this session opened #198) · GATED-THIS-DIFF — atom A: Codex and Melious glm-5.3 each hold an unbroken chain of counted results to `f3526b4` (Codex: full r1, then every delta; Melious: full r3, then every link); the stamp names the trail's own commit, whose diff outside `docs/reviews/` from `f3526b4` is empty

Data check: public repo, shell scripts only; a grep for keys, tokens, passwords and addresses found none. Owner OK for Codex and ollama-cloud: "Gate it with the repo's `independent-review` skill … pick the depth per its "Review depth" table (likely Normal)"; for Melious: "go ahead with round 2, use melious GLM 5.3".

| Round | Head | Artifact | Reviewers | seconds, tokens | BUG/RISK/NIT |
|---|---|---|---|---|---|
| 1 | `4ccc557` | full, `b8d7136...4ccc557` | Codex CLI 0.160.1, gpt-6.1-sol, effort high, read-only · ollama-cloud kimi-k2.7-code **FAILED** (429 session quota) · fresh-eyes Claude Sonnet sub-agent, read-only | Codex 469, 63,861 · fresh-eyes 460, 148,680 | 5/4/1 |
| 2 | `6c1cb19` | delta `4ccc557..6c1cb19`, verify | Codex, effort medium · Melious glm-5.3 **FAILED** (no final-review marker; cut off at 4117 s, 7.7 MB) | Codex 308, 54,857 · Melious 4118 | 3/1/0 |
| 3 | `d6501ad` | Codex: delta `6c1cb19..d6501ad`, verify · Melious: **full** `b8d7136...d6501ad` (its first chain link) | Codex, effort medium · Melious glm-5.3 (first try **FAILED**, connection reset at 497 s; the retry counted) | Codex 1004, 68,111 · Melious 386, 69,488 | 2/3/2 |
| 3 (extra seat) | `d6501ad` | full `b8d7136...d6501ad` | ollama-cloud glm-5.3:cloud (started as a backup for Melious) | 790 | 0/0/0 |
| 4 | `599c0c6` | merge link `d6501ad → 599c0c6` (old base `b8d7136`, new `b02c165`), verify | Codex, effort medium · Melious glm-5.3 | Codex 150, 46,030 · Melious 323, 50,123 | 2/0/2 |
| 5 (final) | `a8a9e50` | delta `599c0c6..a8a9e50`, verify | Codex, effort medium · Melious glm-5.3 | Codex 142, 42,161 · Melious 69, 17,448 | 0/2/1 |
| re-gate 1 | `5d9c86f` | delta `a8a9e50..5d9c86f` (round 5's NIT fix) | Codex · Melious | Codex 120, 44,812 · Melious 36, 7,375 | 0/0/1 |
| re-gate 2 | `f3526b4` | delta `5d9c86f..f3526b4` (re-gate 1's NIT fix) | Codex · Melious | Codex 94, 36,608 · Melious 58, 7,491 | 0/1/1 |

| id | Sev | Source | Rnd | Finding — one line | Status | Evidence |
|---|---|---|---|---|---|---|
| R1-1 | BUG | Codex | 1 | a `( )`, `$( )` or backtick inside a command that reads the pipe loses it: `cmd \| (v="$(head -1)")` | fixed `6c1cb19`, externally_reverified (Codex r2) | `seq 1 2000000 \| (v="$(head -1)")` → `141 0`; 4 fixtures |
| R1-2 | BUG | Codex; fresh-eyes (2 RISKs) | 1 | a loop that ends by its condition is missed: `until grep -q x`, `while read && [ "$l" != END ]`, `for x in 1; do head -1` | fixed `6c1cb19`; widened by R2-1, R3-2 | sentinel loop → `141 0`; piped for/select flagged; while/until flagged unless the condition is one plain `read` |
| R1-3 | BUG | Codex | 1 | `"break"`, `\break` missed | fixed `6c1cb19`; widened by R2-2, R3-1 | fixtures `quoted-break`, `backslashed-exit`, `eval-break`, `builtin-return` |
| R1-4 | BUG | Codex | 1 | an EXEMPT needle naming the consumer anywhere on the line exempts it | fixed `6c1cb19`, externally_reverified (Codex r2, r3) | needle must span the consumer's byte column; EXEMPT cases `elsewhere`, `multibyte` (the latter fails under UTF-8 if `covers()` drops `local LC_ALL=C`) |
| R1-5 | BUG | Codex; fresh-eyes | 1 | "xargs drains the pipe" is false | fixed `6c1cb19`, externally_reverified (Codex r2) | exit 255 → `141 1`, `-E STOP` → `141 0`; every piped xargs flagged |
| R1-6 | RISK | fresh-eyes | 1 | `sh -c`, `bash -c`, `eval`, `busybox` hide a consumer | fixed `6c1cb19`; widened by R2-3 | 4 fixtures |
| R1-7 | RISK | fresh-eyes | 1 | a redirection before the command name hides it | fixed `6c1cb19`; widened by R2-4, R3-3 | 2 fixtures |
| R1-8 | RISK | fresh-eyes | 1 | a `{` inside a quoted awk program opened a group (false alarm on a later line) | fixed `6c1cb19`, externally_reverified (Codex r2) | reserved words count only unquoted at command start |
| R1-9 | RISK | fresh-eyes | 1 | prose `echo for` raised the loop depth | fixed `6c1cb19`, externally_reverified (Codex r2) | same |
| R1-10 | NIT | fresh-eyes | 1 | `ghead`, `gsed`, `ggrep`, `rg`, `zgrep` not consumers | fixed `6c1cb19`, externally_reverified (Codex r2) | 4 fixtures |
| R2-1 | BUG | Codex | 2 | the plain-read test took `read '-t' 1 l` and `read -r l </dev/null` | fixed `d6501ad`, externally_reverified (Codex r3) | an allow-list of read forms |
| R2-2 | BUG | Codex | 2 | `do 2>/dev/null break` escaped stop detection | fixed `d6501ad`; re-broken in part (R3-1) | `141 0` |
| R2-3 | BUG | Codex | 2 | `$'…'` kept its `$`: `sh -c $'head -1'`, `eval $'break'` | fixed `d6501ad`, externally_reverified (Codex r3) | `141 0`; names built at run time are out of scope, stated in the header |
| R2-4 | RISK | Codex | 2 | a quoted redirect target with a space hid the consumer | fixed `d6501ad`, externally_reverified (Codex r3) | quote-aware `wordlen()` |
| R3-1 | BUG | Codex | 3 | `break>/dev/null` and `eval 'break;'` missed; the latter caught at `6c1cb19`, so a regression of R2-2's fix | fixed `599c0c6`; widened by R4-1; externally_reverified (Codex r4, r5) | stop words found by a plain search (STOPRE) of each command in the frame, as awk's `exit` is; 2 fixtures |
| R3-2 | BUG | Codex | 3 | the allow-list took a bare `-a`: `read -a`, `read -a -r l` fail before EOF | fixed `599c0c6`, locally_verified | `141 0`; `-a` must name an array; 2 fixtures |
| R3-3 | RISK | Codex | 3 | `wordlen()` ended `$'a\' b'` at the escaped quote | fixed `599c0c6` | a `$'` quote state; 1 fixture |
| R3-4 | RISK | Melious | 3 | the scan's awk may not run under `LC_ALL=C` | refuted | `found="$(LC_ALL=C awk "$LEXER" "${SCOPE[@]}")"`, unchanged since main |
| R3-5 | RISK | Melious | 3 | a consumer in the body of a plain-read loop is not flagged | refuted | the loop holds the pipe and `read` drains it: `seq 1 300000 \| while read -r l; do head -1 >/dev/null; done` → `0 0`; `head -c 70000` per turn on 3M lines → `0 0` |
| R3-6 | NIT | Melious | 3 | `read -r l \|\| [ -n "$l" ]` flagged | fixed `506ecae` | that idiom allowed after `\|\|` (`0 0`); the `&&` form stays flagged (empty line → `141 141 0`) |
| R3-7 | NIT | Melious | 3 | the xargs message read as if its conditions were checked | fixed `506ecae`, externally_reverified (Codex r4) | message says neither is checked |
| R4-1 | BUG | Codex | 4 | the raw STOPRE search lost `br\eak` and `b"reak"`, which `d6501ad` caught: a regression of R3-1's fix | fixed `a8a9e50`, externally_reverified (Codex r5, Melious r5) | `141 0` each; STOPRE on the raw text OR the unquoted text; 2 fixtures |
| R4-2 | BUG | Codex, Melious | 4 | R3-6's `\|\| [ -n "$l" ]` exception also cleared `until ! read -r l \|\| [ -n "$l" ]`, which ends at line 1 | fixed `a8a9e50`, externally_reverified (Codex r5) | `141 0`; exception for while watches only; 1 fixture |
| R4-3 | NIT | Melious | 4 | `read -ad '' arr` (array + delimiter) falsely flagged | refuted, externally_reverified (Codex r5) | in `-ad`, bash gives `-a` the argument `d`: rc 0, `arr` unset |
| R4-4 | NIT | Melious | 4 | `plainread()`'s `inv` is dead | refuted | used: `if (inv) { if (!match(c, /^![ \t\n]+/)) return 0; … }` |
| R5-1 | RISK | Melious | 5 | R4-1's fix assumes `unquote()` strips inner quotes and backslashes | refuted | its body: `gsub(/\$['"]/, "'", w); gsub(/["'\\]/, "", w)`; both partial-spelling fixtures flag |
| R5-2 | RISK | Melious | 5 | R4-2's fix assumes `wkw` holds "while" | refuted | set at watch creation: `wkw[d, k] = substr(x, 1, 5)`; `while-read-or-last-line` stays clean |
| R5-3 | NIT | Melious | 5 | `unquote(x)` computed up to three times | fixed `5d9c86f`, externally_reverified (re-gate 1) | same classifications on all fixtures |
| G1-1 | NIT | Melious | re-gate 1 | `unquote(x)` computed even after a raw match | fixed `f3526b4`, externally_reverified (re-gate 2) | same |
| G2-1 | RISK | Melious | re-gate 2 | the fix assumes `unquote()` has no side effects | refuted, externally_reverified (Codex re-gate 2: an awk probe) | it writes only its parameter and returns it |
| G2-2 | NIT | Melious | re-gate 2 | the one-line `else { …; …; else return }` is hard to read | refuted | matches the file's style, e.g. `wordlen()`: `if (q == "'") { if (c == "'") q = ""; continue }` |

UNVERIFIABLE: asked in every round; none confirmed as a finding. Settled by running: mawk 1.3.4 and gawk 5.2.1 under bash 5.2 and `LC_ALL=C.UTF-8`, BSD awk 20200816 under bash 3.2; `tee >(head -1)` → `141 141`; `make check` inside the unzipped zip, rc 0. The `check_ship_push.sh` needle matches its line (the scan exempts it).

Cross-head regression check (after round 4): every fixture of `b8d7136`, `b02c165`, `4ccc557`, `6c1cb19`, `d6501ad`, `506ecae` and `599c0c6` (1,031) run against the current lexer. Every must-flag one still flags; the only must-not-flag ones that flag are the three reclassified on purpose (R1-1 input process substitution in a piped command, R1-5 xargs, R2-2 `echo break`). Codex reproduced it in round 5 and the re-gates.

Merge of main (`5c1ea2d`): main's `738daa5` (#191, another session) fixed part of the same items first: P1's path and backslash forms, P7, P8. Both guard scripts conflicted and resolved to this branch's version, keeping main's fixtures `bad/head-by-path`, `bad/head-alias-bypass` (this branch's identical two dropped) and `good/tail-by-path`. `merge_link.sh --suggest-callees` named nine files the merge changed; the guard calls none (the README mentions them), and its scan covers main's changed `test_git_stand_hook.sh`.

## The #131 record's open items

| #131 id | Status here | Where |
|---|---|---|
| P1 (RISK) path, backslash or wrapper consumer | fixed: paths and `\` also by main's `738daa5`; wrappers, quotes, redirections here | `4ccc557`, `6c1cb19`, `d6501ad`, `599c0c6` |
| P2 (RISK) `tee >(head -1)`, `while … break` | fixed; `cmd \| (head -1)` still flagged | `4ccc557`, then rounds 1–3 |
| P7 (NIT) mode 100644 | fixed: 100755 (also `738daa5`) | `4ccc557` |
| P8 (NIT) `git ls-files` twice | fixed: once (also `738daa5`) | `4ccc557`, `scripts/list_shell_scripts.sh` |
| P9 (NIT) duplicated `discover()` | fixed: one executable helper, not a sourced file (a sourced file would be the repo's first and sit outside the guard's scope, #131's P6); in the zip list, `REQUIRED`, CDPATH `SUBJECTS`, README | `4ccc557` |
| P10 (RISK) EXEMPT needle per line | fixed: one entry per site, naming and covering its consumer | `4ccc557`, `6c1cb19` |

Found during this work, beyond the #131 record: only the first command of a piped `( … )` was checked, and nothing inside a piped `{ … }`, `if` or `case` (8 fixtures, all missed by main; fixed in `4ccc557`).

Waivers and deferrals: none.
Follow-ups: none.
Notes: Rounds 1 and 2 were degraded to one cross-model seat (ollama-cloud quota; a Melious reply that never reached its marker). Round 4 was earned by R3-1 and R3-2; round 5 by R4-1 and R4-2. **Stopped: not converging** after round 4, since R3-1 and R4-1/R4-2 each re-broke an earlier catch; the owner chose "Union fix + final round": each rule became the union of its earlier versions, and the cross-head check above was added. Round 5 found no BUG; its and re-gate 1's NITs were fixed and re-gated by both seats (no rounds). Codex noted that the prior-findings files' "do not re-raise" and "check only" lines read as attempts to steer it; it treated them as data.
