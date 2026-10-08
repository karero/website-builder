# DIFF review — feat/whats-new-missing-files — whats-new marks a frozen template file the site lacks as MISSING
Base `afa7704` · depth: Normal (tooling every site owner runs, plus a new CI job; no user data, no deploy path) · verdict: CLEAN · authority used: WORKTREE-WRITE and BRANCH-COMMIT — atom A (this session created the worktree and the branch); POST AUTHORITY — atom A (this session opens the PR, on the owner's "open the PR when the review is clean"); GATED-THIS-DIFF — atom A (round 1 saw `afa7704...32487dd` in full, round 2 the delta `32487dd..17f7ac4`; codex and melious counted in both)

Consent to send this repo to Codex and to Melious, this session: "Yes, both (Recommended)".

| Round | Head | Artifact | Reviewers | seconds, tokens | BUG/RISK/NIT |
|---|---|---|---|---|---|
| 1 | `32487dd` | full, `afa7704...32487dd` | codex-cli 0.161.0, gpt-6.1-sol, effort high (config), read-only; melious glm-5.3, HTTP, text only; fresh-eyes Claude Sonnet sub-agent, read-only | codex 263 s, 65,978; melious 120 s, 18,108; fresh-eyes 142 s, 106,060 | 0 / 8 / 3 |
| 2 | `17f7ac4` | delta since `32487dd` (`--verify`) | codex-cli 0.161.0, gpt-6.1-sol, effort medium, read-only; melious glm-5.3, HTTP, text only | codex 112 s, 41,344; melious 147 s, 25,210 | 0 / 0 / 0 (one OUTSIDE SCOPE item: F1) |

| id | Sev | Source | Round | Finding | Status | Evidence |
|---|---|---|---|---|---|---|
| R1 | RISK | codex, glm-5.3, fresh-eyes (NIT) | 1 | A template test in a subfolder was flattened to its basename | fixed, locally_verified, externally_reverified r2 | `17f7ac4`; test case `tests/sub/x.spec.ts` |
| R2 | RISK | codex | 1 | `check_template_coverage.sh` searches the whole script for a report arm, so `site_copy_of`'s literal arms could hide a lost one | fixed by a test, guard unchanged; locally_verified, externally_reverified r2 | `17f7ac4`; with the AGENTS.md report arm removed the test reports "expected 22, got 21" |
| R3 | RISK | codex | 1 | The test ignored the report's exit status | fixed, locally_verified, externally_reverified r2 | `17f7ac4`; `report()` asserts exit 0 on all four runs |
| R4 | RISK | glm-5.3 | 1 | The SUITE-VERSION fallback (no TESTS-VERSION) was untested | fixed, locally_verified, externally_reverified r2 | the fallback calls `process_tests_stamp`; new case removes TESTS-VERSION |
| R5 | RISK | glm-5.3, fresh-eyes | 1 | The site-path mapping exists twice with nothing checking they agree | fixed, locally_verified, externally_reverified r2 | agreement check over all 22 TEMPLATE_TRACKED files; with the claude arm of `site_copy_of` removed, 3 checks fail |
| R6 | RISK | glm-5.3 | 1 | The mapping and the fixture share one assumption; nothing pins it to the scaffold | refuted | codex r1 and r2 VERIFIED the mappings against `skills/new-website/SKILL.md` (overlay of `templates/astro/`, AGENTS.md, CONTENT_GUIDE.md, `.claude/`); a run against a real scaffolded site flagged only files absent from it |
| R7 | RISK | glm-5.3 | 1 | `actions/checkout@v7` in the new CI job is unsupported | refuted | all 21 checkout steps in `clean.yml` use `actions/checkout@v7` |
| R8 | RISK | fresh-eyes | 1 | README's `scripts/` listing omits the new test | fixed, locally_verified, externally_reverified r2 | `17f7ac4` |
| N1 | NIT | glm-5.3 | 1 | `hasnt "MISSING"` too broad | fixed, externally_reverified r2 | anchored to the two MISSING messages |
| N2 | NIT | glm-5.3 | 1 | Unquoted word-splitting of the missing list | fixed, externally_reverified r2 | newline-separated, printed with `printf` |
| N3 | NIT | fresh-eyes | 1 | The summary prints site paths, not template paths | refuted | each MISSING line sits under the drift line that names the template file |

Waivers and deferrals: none.
Merge link: `origin/main` (`6f4a7e1`) merged in to bring the branch up to date; `merge_link.sh afa7704 d4515cc 6f4a7e1` is empty (the change's files are untouched by the merge; its one callee suggestion, `index.astro`, is not referenced by the change), and `6f4a7e1...HEAD` equals the reviewed `afa7704...d4515cc` byte for byte. Main moved again (#202, independent-review files only): merged `5d2bf95`; `merge_link.sh 6f4a7e1 d4515cc 5d2bf95` is empty and `5d2bf95...HEAD` again equals the reviewed diff byte for byte.
Follow-ups: F1 (codex r2, OUTSIDE SCOPE, re-raises R7 without new evidence) — whether `actions/checkout@v7` resolves; settled: all 30 checks passed on `f8f3f59`.
Notes: before the first push, both commits were rebuilt to drop a private name from a commit message: `32487dd` → `bcb4bf6`, `17f7ac4` → `d4515cc`, same trees (`98442c7`), so the reviewed diff is byte-identical. ollama seat absent by design (Melious is the second seat; ollama CLI hidden from `PATH`). Fresh-eyes ran round 1 only, as Normal depth sets. No round had a BUG, so no wording pass was owed.
