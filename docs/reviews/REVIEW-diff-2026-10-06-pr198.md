# DIFF review — karero/website-builder#198 — pipefail guard: wrappers, paths, piped compounds and loops; one site per EXEMPT entry
Base `b8d7136`, after merging main `b02c165` · depth: **Normal** (guard logic whose misses are silent; no user data, no production path; the owner asked for this gate, "likely Normal") · verdict: **OPEN** (round 4 running on `599c0c6`) · authority used: WORKTREE-WRITE — atom A (this session's worktree) and atom B ("Write the trail under `docs/reviews/`") · BRANCH-COMMIT — atom A (this session created `claude/pipefail-guard-followups`) · POST AUTHORITY — atom A (this session opened #198) · GATED-THIS-DIFF — not yet held for `599c0c6`, no stamp

Data check: public repo, shell scripts only; a grep for keys, tokens, passwords and addresses found none. Owner OK for Codex and ollama-cloud: "Gate it with the repo's `independent-review` skill … pick the depth per its "Review depth" table (likely Normal)"; for Melious: "go ahead with round 2, use melious GLM 5.3".

| Round | Head | Artifact | Reviewers | seconds, tokens | BUG/RISK/NIT |
|---|---|---|---|---|---|
| 1 | `4ccc557` | full, `b8d7136...4ccc557` | Codex CLI 0.160.1, gpt-6.1-sol, effort high, read-only · ollama-cloud kimi-k2.7-code **FAILED** (429 session quota) · fresh-eyes Claude Sonnet sub-agent, read-only | Codex 469, 63,861 · fresh-eyes 460, 148,680 | 5/4/1 |
| 2 | `6c1cb19` | delta `4ccc557..6c1cb19`, verify | Codex, effort medium · Melious glm-5.3 **FAILED** (no final-review marker; cut off at 4117 s, 7.7 MB) | Codex 308, 54,857 · Melious 4118 | 3/1/0 |
| 3 | `d6501ad` | Codex: delta `6c1cb19..d6501ad`, verify · Melious: **full** `b8d7136...d6501ad` (its first chain link) | Codex, effort medium · Melious glm-5.3 (first try **FAILED**, connection reset at 497 s; the retry counted) | Codex 1004, 68,111 · Melious 386, 69,488 | 2/3/2 |
| 4 | `599c0c6` | merge link `d6501ad → 599c0c6` (old base `b8d7136`, new `b02c165`), verify | Codex, effort medium · Melious glm-5.3 | running | — |

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
| R3-1 | BUG | Codex | 3 | `break>/dev/null` and `eval 'break;'` missed; the latter caught at `6c1cb19`, so a regression of R2-2's fix | fixed `599c0c6`, locally_verified | stop words found by a plain search (STOPRE) of each command in the frame, as awk's `exit` is; 2 fixtures |
| R3-2 | BUG | Codex | 3 | the allow-list took a bare `-a`: `read -a`, `read -a -r l` fail before EOF | fixed `599c0c6`, locally_verified | `141 0`; `-a` must name an array; 2 fixtures |
| R3-3 | RISK | Codex | 3 | `wordlen()` ended `$'a\' b'` at the escaped quote | fixed `599c0c6` | a `$'` quote state; 1 fixture |
| R3-4 | RISK | Melious | 3 | the scan's awk may not run under `LC_ALL=C` | refuted | `found="$(LC_ALL=C awk "$LEXER" "${SCOPE[@]}")"`, unchanged since main |
| R3-5 | RISK | Melious | 3 | a consumer in the body of a plain-read loop is not flagged | refuted | the loop holds the pipe and `read` drains it: `seq 1 300000 \| while read -r l; do head -1 >/dev/null; done` → `0 0`; `head -c 70000` per turn on 3M lines → `0 0` |
| R3-6 | NIT | Melious | 3 | `read -r l \|\| [ -n "$l" ]` flagged | fixed `506ecae` | that idiom allowed after `\|\|` (`0 0`); the `&&` form stays flagged (empty line → `141 141 0`) |
| R3-7 | NIT | Melious | 3 | the xargs message read as if its conditions were checked | fixed `506ecae` | message says neither is checked |

UNVERIFIABLE: 4 asked in round 1, 3 in round 2, 3 in round 3 (Codex) and 4 (Melious); 0 confirmed. Settled by running: mawk 1.3.4 and gawk 5.2.1 under bash 5.2 and `LC_ALL=C.UTF-8`, BSD awk 20200816 under bash 3.2; `tee >(head -1)` → `141 141`; `make check` inside the unzipped zip, rc 0. The `check_ship_push.sh` needle matches its line (the scan exempts it).

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
Notes: Round 1 is degraded (one cross-model seat; ollama-cloud quota), round 2 too (Melious failed). Round 4 is earned by round 3's substantive BUGs (R3-1, R3-2). R3-1 re-broke part of R2-2's fix: stop detection was then redesigned to a plain search, the shape the v0.27 awk-check redesign settled on, rather than patched again. A `glm-5.3:cloud` attempt on ollama-cloud for round 3 was started as a backup and had not reported when round 3 closed.
