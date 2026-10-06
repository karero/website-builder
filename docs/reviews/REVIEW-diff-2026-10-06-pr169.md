# DIFF review — karero/website-builder#169 — CI: cancel superseded runs; PR branches run once, via pull_request
Base `a7de280` · depth: Normal (CI trigger config: a mistake costs coverage, touches no user data, deploy or secrets) · verdict: CLEAN · authority used: POST AUTHORITY, WORKTREE-WRITE, BRANCH-COMMIT — atom A (this session created the PR, its worktree and its branch); GATED-THIS-DIFF — atom A (codex's verification chain below, base `a7de280`, head `7c5d240`)

Owner's OK to send the diff out (2026-10-06, this session): "Yes, Normal depth (Recommended)" — Codex + ollama-cloud + fresh-eyes Sonnet.

| Round | Head | Artifact | Reviewers | seconds, tokens per seat | BUG/RISK/NIT |
|---|---|---|---|---|---|
| 1 | `f1a411b` | full, `a7de280...f1a411b` | codex-cli 0.160.0 (gpt-6.1-sol, config effort, read-only); ollama kimi-k2.7-code:cloud (text only); fresh-eyes Sonnet sub-agent (read-only) | codex 138s/50197; ollama 148s; fresh-eyes 103s/101858 | 1/4/5 |
| 2 | `8aa7e4c` | delta since `f1a411b` | codex (medium); ollama kimi-k2.7-code:cloud | codex 139s/38966; ollama 395s | 2/2/1 |
| wording pass | `20a8df1` | delta since `8aa7e4c`, prose only | codex (medium) | 73s/44564 | 2/1/0 |
| confirmation 1 | `73b6ebc` | delta since `20a8df1`, prose only | codex (medium) | 36s/21583 | 1/0/0 |
| confirmation 2 | `7c5d240` | delta since `73b6ebc`, prose only | codex (medium) | — | 0/0/0 |

| id | Sev | Source | Round | Finding — one line | Status | Evidence |
|---|---|---|---|---|---|---|
| F1 | RISK | fresh-eyes | 1 | cancel-in-progress also cancels a main run when a second merge lands | fixed, locally_verified, externally_reverified (r2) | `8aa7e4c`: group `github.event_name == 'push' && github.sha \|\| github.ref` |
| F2 | RISK | fresh-eyes | 1 | a PR with merge conflicts gets no pull_request run | fixed (comment names the gap and workflow_dispatch), externally_reverified (r2) | `8aa7e4c` clean.yml comment |
| F3 | NIT | fresh-eyes | 1 | re-running an old run can cancel a newer one | fixed, externally_reverified (r2) | `8aa7e4c` |
| F4 | NIT | fresh-eyes | 1 | README line over-long | fixed, externally_reverified (r2) | `8aa7e4c` |
| F5 | NIT | fresh-eyes | 1 | comment duplicated; no blank line before `jobs:` | fixed, externally_reverified (r2) | `8aa7e4c` |
| F6 | NIT | fresh-eyes | 1 | "#165 runs failed" — they were cancelled while queued | fixed, externally_reverified (r2) | run 37363792585 jobs cancelled with no steps |
| C1 | RISK | codex | 1 | Actions grouping/cancellation claims unsupported; push and PR don't test the same commit | wording fixed; PR path observed live; main-push path open on a missing prerequisite (only seen after merge) | runs 37420420345/37420420357 `cancelled` on `6e5262f` when `f1a411b` landed; 37420461607/37420461611 both `success` (two workflows, same PR, no cross-cancel) |
| C2 | BUG | codex | 1 | README "a personalized build cannot ship" overclaims (pre-existing text in an edited line) | fixed, externally_reverified (confirmation 2) | `8aa7e4c`, `126d830`, `73b6ebc`, `7c5d240` |
| O1 | RISK | ollama | 1 | "in another group" could read as concurrency deduplicating push and PR | fixed, externally_reverified (r2) | `8aa7e4c` |
| O2 | NIT | ollama | 1 | README omits workflow_dispatch | refuted | the sentence states the guard's automatic runs; a manual trigger adds no guarantee (codex r2 agreed) |
| R2-1 | BUG | codex | 2 | README still overclaims: scripts/ ships but is not name-scanned | fixed, externally_reverified (confirmation 2) | check_clean.sh:23 `SCAN_NAMES_ALL` |
| R2-2 | RISK | codex | 2 | = C1, re-raised | open on missing prerequisite (main push after merge) | as C1 |
| R2-3 | BUG | codex | 2 | "same triggers" false: template-tests has path filters | fixed, externally_reverified (wording pass) | `126d830` |
| R2-4 | RISK | ollama | 2 | CI tolerating a missing denylist is unverified | refuted | check_clean.sh:126-128 prints the skip and continues; CI `clean` passed on `f1a411b` with no list |
| R2-5 | NIT | ollama | 2 | "same concurrency group" misleads | fixed with R2-3 | `126d830` |
| WP-1 | BUG | codex | wording | README omits check_clean's exemptions (gitignored files, self-repo reference) | fixed in `7c5d240` after a wrong first fix in `73b6ebc`, externally_reverified (confirmation 2) | check_clean.sh:46-86, 118-125 |
| WP-2 | BUG | codex | wording | README "free of concrete model names" ignores the setup-guide exclusion (re-wrapped line) | fixed, externally_reverified (confirmation 1) | check_model_agnostic.sh:21-24 |

Waivers and deferrals: none.
Follow-ups: verify after merge that the first `main` push run's group is per-commit (C1/R2-2) — two quick merges should both finish.
Notes: Round 2's BUGs were wording only, so no round 3 was owed; the wording pass and two confirmations followed (the second is the last allowed). Fresh-eyes' chain ends at round 1 by design (Normal depth); ollama's at round 2; codex holds the unbroken chain to `7c5d240`. The wording-pass and confirmation deltas were classified prose-only: README body text and YAML comment lines, no code or config hunks.
