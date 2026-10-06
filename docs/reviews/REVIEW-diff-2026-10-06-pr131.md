# DIFF review — karero/website-builder#131 — the pipefail early-exit pipe guard (post-merge)
Base `48bc564` · depth: **Light gate** (a lint over the suite's own scripts plus four status-irrelevant rewrites; no user data, no production path; owner: "Write the #131 review record from here") · verdict: **OPEN** · authority used: WORKTREE-WRITE, BRANCH-COMMIT — atom A (this session created branch `claude/compassionate-gates-02gt12` and its checkout) and atom B (the owner's instruction above); POST AUTHORITY not held (this session did not open #131), so the findings went to the owner in session, not to a PR comment; GATED-THIS-DIFF not held, no stamp.

#131 merged at 21:37 on 2026-09-26 with no review round: no GitHub reviews or comments, and its session's summary reads "no reviews". This is a post-merge round on the merged pair. Nothing left the machine.

| Round | Head | Artifact | Reviewer | seconds, tokens | BUG/RISK/NIT |
|---|---|---|---|---|---|
| 1 | `addd95b` | full, `48bc564...addd95b` | `/code-review` at medium (Claude host) | not captured | 0/7/3 |

| id | Sev | Rnd | Finding — one line | Status | Evidence |
|---|---|---|---|---|---|
| P1 | RISK | 1 | a consumer behind a path, a `\` or a wrapper is missed: `\| /usr/bin/head`, `\| \head`, `\| timeout 5 head` | open on `main`, locally_verified | case scripts in a throwaway repo, run through both `addd95b`'s and `4e69534`'s guard: not flagged by either |
| P2 | RISK | 1 | early exit inside a subshell, a process substitution or a `while read … break` is missed | subshell fixed on `main` (v0.27 pre-release F7, redesign); `tee >(head -1)` and `while … break` open on `main`, locally_verified | same harness: `\| (head -1)` missed at `addd95b`, flagged at `4e69534`; the other two missed by both |
| P3 | RISK | 1 | `[[ $x =~ ^(a\|head) ]]` reads as a pipe into `head`: false FAIL | accepted by design on `main` | flagged by both versions; v0.27 redesign rule: a false alarm, settled with an `EXEMPT` entry, rather than a miss |
| P4 | RISK | 1 | grep's flags are split without regard to quotes: `grep -E "foo -m bar"` false FAIL, `grep "-q"` missed | miss fixed on `main` (v0.27 F7, `grep '-q'`); false alarm accepted by design | harness: `"-q"` missed at `addd95b`, flagged at `4e69534`; `"foo -m bar"` flagged by both |
| P5 | RISK | 1 | a `case` pattern's `)` inside `$( … )` pops the frame, so later pipes are mis-attributed | not reproduced | `v=$(case $x in a) echo 1;; esac); cmd \| head -1`: the trailing pipe is flagged by both versions |
| P6 | RISK | 1 | pipefail inherited by a sourced file, or turned on outside the file, is out of scope | not reproduced: no live exposure | `git grep -E '^[[:space:]]*(source\|\.)[[:space:]]+[^=[:space:]]'` over tracked files on `main` (docs and non-shell types excluded): no hits |
| P7 | NIT | 1 | `check_pipefail_pipes.sh` is mode 100644; the other 15 `scripts/*.sh` are 100755 | open on `main` | `git ls-tree`; its three callers (Makefile, `clean.yml`, `check_cdpath_safe.sh`) run it through `bash`, so nothing fails today |
| P8 | NIT | 1 | both guards list the repo twice: `[ -n "$(git ls-files)" ]`, then `git ls-files` again | open on `main` | `check_cdpath_safe.sh:86-87`, `check_pipefail_pipes.sh:49-50` |
| P9 | NIT | 1 | `discover()` is a near copy of `check_cdpath_safe.sh`'s | open on `main` | `check_pipefail_pipes.sh:45` |
| P10 | RISK | 1 | an `EXEMPT` needle is a substring of the line, so a second early-exit consumer added to an exempted line is exempted too | open on `main` | `check_pipefail_pipes.sh:598-601`: `[[ "$src" == *"${e#*\|}"* ]]` matches per line, not per site |

Waivers and deferrals: none.
Follow-ups: P1 and P2's two open shapes (wrapper or path consumers; process substitution, `while … break`); P10 (match an exemption to one site, not a line); P7 (`chmod +x`); P8 and P9 (one listing, one shared `discover()`).
Notes: Misses are RISK here per the strict prompt ("a guard that cannot fire"); the v0.27 pre-release review graded its pipefail-guard misses BUG, so the owner may escalate P1/P2 to a Normal gate. This round missed a real BUG in this version: bash 3.2 could not parse the script (v0.27 pre-release F0, fixed `4164018`); that review's Codex round also found the subshell and `grep '-q'` misses. The harness lived in this session's scratchpad; its cases are the shapes quoted above.
