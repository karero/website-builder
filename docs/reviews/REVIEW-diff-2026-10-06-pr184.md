# DIFF review — karero/website-builder#184 — check_clean: look for private names in scripts/, and say when CI skips that check
Base `698248d` · depth: Normal (a leak guard whose failure is silent; touches no user data, deploy or secrets) · verdict: CLEAN · authority used: POST AUTHORITY, WORKTREE-WRITE, BRANCH-COMMIT — atom A (this session created the PR, its worktree and its branch); GATED-THIS-DIFF — atom A (codex's and ollama's verification chain below, base `698248d`, head `b153870`)

Owner's OK to send the diff out (2026-10-06, this session): "Yes, Normal depth (Recommended)" — Codex + ollama-cloud + fresh-eyes Sonnet. Owner's merge instruction: "merge it once round 3 is clean".

| Round | Head | Artifact | Reviewers | seconds, tokens per seat | BUG/RISK/NIT |
|---|---|---|---|---|---|
| 1 | `e953016` | full, `698248d...e953016` | codex-cli 0.160.1 (gpt-6.1-sol, config effort, read-only); ollama 0.35.1 kimi-k2.7-code:cloud (text only); fresh-eyes Sonnet sub-agent (read-only) | codex 258s/55136; ollama 345s; fresh-eyes 83s/96150 | 1/2/5 |
| 2 | `da1632d` | delta since `e953016` | codex (medium); ollama kimi-k2.7-code:cloud | codex 138s/29634; ollama 213s | 1/1/0 |
| 3 | `b153870` | delta since `da1632d` | codex (medium); ollama kimi-k2.7-code:cloud | codex 102s/29812; ollama 268s | 0/1/1 |

| id | Sev | Source | Round | Finding — one line | Status | Evidence |
|---|---|---|---|---|---|---|
| X1 | RISK | codex, fresh-eyes | 1 | `--exclude=.clean-denylist` skipped that basename everywhere; a copy under docs/ (zipped whole) went unscanned | fixed, locally_verified, externally_reverified (r2) | `da1632d`; test "no git, a copy of the list in docs/: fails"; basename-exclude mutation turns it red |
| X2 | BUG | codex, ollama | 1 | comments-only list: OK line said "no name list here" | fixed, externally_reverified (r2) | `da1632d`; tests assert both exact skip reasons |
| X3 | NIT | fresh-eyes, ollama | 1 | missing-target check hard-coded `scripts` | fixed, externally_reverified (r2) | `missing "$SCAN_DOCS_ALL $SCAN_NAMES_ALL"` |
| X4 | NIT | fresh-eyes | 1 | header comment stale | fixed, externally_reverified (r2) | check_clean.sh:3-4 |
| X5 | NIT | ollama | 1 | README sentence ambiguous about what skips scripts/ | fixed, externally_reverified (r2) | README "Stay generic" paragraph |
| O1 | RISK | ollama | 1 | `g` may not forward `--exclude`; derive basename from `$DENYLIST_FILE` | refuted | `g` runs `command grep "$@"`; flag removed by X1; in-tree list path is fixed (codex r2 agreed) |
| R2-1 | BUG | codex | 2 | own-line filter also dropped lines of a file named `scripts/.clean-denylist:1:notes` | fixed, locally_verified, externally_reverified (r3) | `b153870`: `compgen -G` guard; test "a file named like the list plus a colon: fails"; removing the guard turns it red |
| R2-2 | RISK | ollama | 2 | filter hard-codes the path while `DENYLIST_FILE` is configurable | refuted | `DENYLIST_FILE` fixed to `scripts/.clean-denylist`; fallback is the main checkout's copy, outside the scan (codex r3 verified) |
| R3-1 | RISK | ollama | 3 | any `scripts/.clean-denylist:*` file switches the filter off → the list reports itself | refuted | failure is loud; such a file (e.g. a backup) is not gitignored (`git check-ignore` matches only the exact path) and would carry every private name into a commit, so failing is right; the suggested awk `$1` filter splits at the first colon and reintroduces R2-1 |
| R3-2 | NIT | ollama | 3 | `self='^$'` drops empty lines; comment says nothing is dropped | refuted | a grep hit line is never empty (`path:N:text`) |

Waivers and deferrals: none.
Follow-ups: CI still cannot run the name check (no list there); it now says so on its OK line. A `::warning::` annotation would surface it on the checks page — not done.
Notes: UNVERIFIABLE entries asked: codex 1+2+3, ollama 4+4+4, fresh-eyes 1; confirmed as findings: 0. Settled live: CI run 37464198427 (head `e953016`), job no-pii-secrets printed the skip notice and the SKIPPED OK line; job clean-denylist passed on ubuntu (GNU grep). Round 3 is clean under stop condition (a2): no BUG, its one RISK refuted; no wording pass owed (nothing changed after round 3 but this trail).
