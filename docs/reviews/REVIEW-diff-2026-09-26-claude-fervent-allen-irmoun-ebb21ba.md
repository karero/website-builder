# DIFF review — claude/fervent-allen-irmoun — round budget, wording pass, final full read, merge link

Base `a9d195e` (origin/main) · depth: **Normal** (the review skill's own rules and scripts; no
product code, no secrets) · verdict: **CLEAN** · authority used: WORKTREE-WRITE and BRANCH-COMMIT —
atom A (this session created the branch); no PR/MR open yet, so no marker stamped.
Consent: owner, this session, quoted verbatim: "Yes, ollama-cloud (Recommended)" — ollama-cloud
only; session-scoped, not standing. Codex was unavailable in this environment (no CLI, no
network route), so every round ran with one cross-model seat: degraded, not a pair.
Rounds 4–5 (2026-09-27, a local session on the owner's machine, PR #136 open): Codex, consent quoted
verbatim: "Can you run a CODEX round on" (PR #136); fixes on the owner's instruction "Yes pls fix
it". Authority: WORKTREE-WRITE — atom A (that session created the worktree); BRANCH-COMMIT — atom B
(the owner's instruction above). Gate script from `origin/main` `7c3ab8c`.

| Round | Head | Artifact | Reviewers (model, sandbox) | Seconds, tokens | BUG/RISK/NIT |
|---|---|---|---|---|---|
| 1 | `ebb21ba` | full diff | ollama-cloud `kimi-k2.7-code` (HTTP API, text only); fresh-eyes Claude sub-agent (Sonnet, read-only, repo access) | 396 s, 38,431; fresh-eyes 491 s, 145,673 | 1 / 3 / 3 |
| 2 | `eef9c6d` | delta since `ebb21ba` + prior findings (`--verify`, codex effort n/a) | ollama-cloud `kimi-k2.7-code` | 258 s, 28,438 | 0 / 1 / 3 |
| final full read | `eef9c6d` | full diff | ollama-cloud `glm-5.3` (`--seat ollama`, new to the change) | 332 s, 65,359 | 0 / 2 / 7 (2 substantive) |
| 3 | `0d90439` | delta since `eef9c6d` + prior findings | ollama-cloud `kimi-k2.7-code` | 372 s, 35,848 | 0 / 3 / 0 |
| 4 | `a2583ae` | full diff (new seat for the change) | Codex CLI 0.157.1, `gpt-6-astra`, effort medium, read-only | 110 s, 53,402 | 2 / 0 / 0 (+1 host NIT) |
| 5 | `a62bad0` | delta since `a2583ae` + prior findings (`--verify`) | Codex CLI 0.157.1, `gpt-6-astra`, effort medium, read-only | 84 s, 32,764 | 0 / 0 / 0 |

Total reviewer cost: 2,043 s across seats, 399,915 tokens (ollama 168,076; fresh-eyes 145,673;
Codex 86,166).

| id | Sev | Source | Rd | Finding — one line | Status | Evidence |
|---|---|---|---|---|---|---|
| F1 | BUG | fresh-eyes (+ ollama as RISK) | 1 | merge-link command word-split an unquoted `$(git diff --name-only …)`, silently dropping spaced paths | fixed, externally_reverified (r2) | `eef9c6d`; reproduced on a real merge: old 0 diffs, new the file |
| F2 | RISK | ollama | 1 | `--seat` usable on any round | fixed, externally_reverified (r2) | `eef9c6d`: note names the two legitimate uses |
| F3 | RISK | ollama | 1 | `--seat agy` enables Antigravity without separate opt-in | refuted | flag is as explicit as `--with-antigravity`; SKILL.md says pass either only when the owner asks |
| F4 | NIT | ollama | 1 | `--seat` silently overrode `--first-success`/`--with-antigravity` | fixed | `eef9c6d`, tests |
| F5 | NIT | ollama | 1, 2 | no helper to find base-side files the change calls | follow-up | — |
| F6 | NIT | fresh-eyes | 1 | "6(d)/6(e)" labels read as stop conditions | fixed | `eef9c6d` |
| F7 | NIT | fresh-eyes | 1 | inert `WITH_ANTIGRAVITY=1` for `--seat agy` | fixed | `eef9c6d` |
| R2-1 | RISK | ollama | 2 | `--seat agy` might run Antigravity twice or not at all | refuted | dispatch calls `run_agy` in the `--seat` branch first; test counts exactly one section |
| R2-2 | NIT | ollama | 2 | "silently drops" is inaccurate | refuted | reproduction: empty output, exit 0 |
| R2-3 | NIT | ollama | 2 | `seatagyboth` test too weak | fixed | `0d90439` |
| FR1 | RISK (substantive) | final read | — | merge link lost an own edit the merge threw away (file equals new base) | fixed, externally_reverified (r3) | `0d90439` `scripts/merge_link.sh`; reproduced; tests mutation-checked |
| FR2 | RISK (substantive) | final read | — | a BUG open when rounds end had no disposition | fixed, externally_reverified (r3) | `0d90439`, SKILL.md 6(b) |
| FR3–FR9 | NIT | final read | — | exit-status test, comment vs code, pathspec magic, opt-in wording, `:cloud` for wording pass, fenced command, step 7 count question | fixed, externally_reverified (r3) | `0d90439`; pathspec fix mutation-checked |
| R3-1 | RISK | ollama | 3 | perl filter strips NUL separators | refuted | `perl -0` keeps `\0` in `$_` (od output); tests list two files |
| R3-2 | RISK | ollama | 3 | `git diff` exits 1 on differences under `set -e` | refuted | `git diff` exits 0 without `--exit-code` (checked) |
| R3-3 | RISK | ollama | 3 | template-less `mktemp` not portable | refuted (GNU and BSD both accept it); hardened anyway | explicit `${TMPDIR:-/tmp}/merge_link.XXXXXX`; locally_verified, not externally re-verified |
| C1 | BUG (substantive) | Codex | 4 | merge link lost a rename's old name when the merge brought it back; with both names kept it printed nothing | fixed, locally_verified, externally_reverified (r5) | `a62bad0`: `--no-renames` on both lists; two tests fail on the old script, 218/218 pass |
| C2 | BUG (substantive) | Codex | 4 | wording pass fixed "without another pass" while closeout allows no stamp on an unseen head | fixed, externally_reverified (r5) | `a62bad0`: one confirmation over the fix's delta — a re-gate, not a round or a second wording pass |
| H1 | NIT | host | 4 | `rationale.md` still described the retired 3-to-5-round cap as current | fixed, externally_reverified (r5) | `a62bad0` |

Follow-ups: F5 — a helper listing base-side files the change's code calls, for the merge link.
Notes: the final full read found the round's two substantive issues after two delta rounds had
come back clean of BUGs — the case it exists for. Round 3 closed clean on ollama alone; round 4,
Codex's first look at the change, found two substantive BUGs, which earned round 5 (clean). No
wording changed after round 5, so no wording pass ran. Raw reviewer output goes in the PR comment.
