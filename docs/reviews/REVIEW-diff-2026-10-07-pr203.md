# DIFF review — karero/website-builder#203 — template-tests: run on every change, skip the test jobs, require one check

Base `origin/main` (`63e2353`) · depth: **Normal** (CI gating that decides which merges are blocked) · verdict: **CLEAN — no BUG open**; every RISK and NIT fixed, refuted or settled with a run or the docs.

| Round | Head | Artifact | Reviewers | BUG/RISK/NIT |
|---|---|---|---|---|
| 1 | `9b9d722` | `origin/main...9b9d722`, `docs/reviews/` excluded | Codex `gpt-6.1-sol`, read-only; melious `glm-5.3`, HTTP API | 2 / 4 / 3 |
| 2 | `a76fd25` | `origin/main...a76fd25`, with round 1's dispositions | same pair | 0 / 2 / 2 |
| 3 | `8bafb34` | `origin/main...8bafb34`, with round 2's dispositions | same pair | 0 / 3 / 2 |

| id | Sev | Source | Round | Finding — one line | Status | Evidence |
|---|---|---|---|---|---|---|
| R1-1 | BUG | codex | 1 | `git diff --name-only` lists a moved file only at its new path, so moving a tested file out read as "nothing tested changed" | fixed `a76fd25` | `--no-renames`; scratch repo: `git mv` out of `templates/astro` gives 2 paths, `run=true` |
| R1-2 | BUG | codex | 1 | `scripts/whats-new.sh` missing from the paths; verify-windows runs the command it prints | fixed `a76fd25` | added; a `whats-new.sh`-only change gives `run=true` |
| R1-3 | RISK | codex | 1 | the gate read any `run` other than `true` as "skip" | fixed `a76fd25` | only `true`/`false` accepted; `''` and `typo` fail |
| R1-4 | RISK | codex | 1 | required-check integration unevidenced | settled | probe #204 (base = this branch, docs-only): `changes` passed, five test jobs skipped, `template-tests-ok` passed ([run 37586485007](https://github.com/karero/website-builder/actions/runs/37586485007)); skipped, `prepare-any-shell` reported as one check, not its three matrix names |
| R1-5 | RISK | glm | 1 | a failing `git diff` would be swallowed as an empty list | refuted | under the runner's shell the step exits 128, no output; `changes` fails, so the gate fails |
| R1-6 | RISK | glm | 1 | `if: always()` with all needs skipped, and the result strings, unverified | settled | #204's run above; GitHub docs: a job skipped by `if:` reports Success |
| R1-7 | NIT | glm | 1 | the `ALL` sentinel in the file list | fixed `a76fd25` | a flag; a root file named `ALL` gives `run=false` |
| R1-8 | NIT | glm | 1 | the log count misleads when there is nothing to compare | fixed `a76fd25` | says "nothing to compare with" |
| R1-9 | NIT | glm | 1 | forms-skill on checkout/setup-node v4, the rest v7 | fixed `a76fd25` | v7 |
| R2-1 | RISK | codex | 2 | git quotes accented names, so they missed the patterns and the tests skipped (the old `paths:` filter did not) | fixed `8bafb34` | `core.quotePath=false`; a name git still quotes runs the tests. With the runner's default git config: `forms/…/Größe.ts` runs, `docs/Größe.md` skips, `docs/a"b.md` runs |
| R2-2 | RISK | codex | 2 | R1-4 again: no artifact | settled | as R1-4, plus this PR's own run (R3-1) |
| R2-3 | NIT | glm | 2 | a force push to main leaves `before` unreachable | refuted | the ruleset's `non_fast_forward` rule (read live) refuses it; were it to happen, the step fails loudly |
| R2-4 | NIT | glm | 2 | the gate's comment claims it fails on "a cancel" | refuted | it does fail on a `cancelled` result (tested); whether GitHub runs it after a run-level cancel does not change that |
| R3-1 | RISK | codex, glm | 3 | the ruleset and both paths need recorded runs | settled | skip path: R1-4. Run path: on `8bafb34` all five test jobs ran and `template-tests-ok` passed ([run 37588692804](https://github.com/karero/website-builder/actions/runs/37588692804)). Ruleset 24584953 read 2026-10-07: 20 required checks, all from `clean.yml`, none from this workflow; the owner adds `template-tests-ok` after merge |
| R3-2 | RISK | glm | 3 | the guard against a failing diff relies on the default shell having `-e` | refuted | GitHub's workflow syntax: an unspecified shell on Linux runs `bash -e {0}` |
| R3-3 | NIT | glm | 3 | a force-pushed base branch other than main makes the diff fail | refuted | loud, not silent; PRs here target main, where force pushes are refused |
| R3-4 | NIT | glm | 3 | the heredoc's `EOF` depends on YAML indentation; use a pipe | refuted | a piped `while` runs in a subshell and would lose `run=true`; a mis-indented `EOF` fails loudly |

Waivers: none. Deferrals: none.

Notes: data release to melious consented by the owner on 2026-10-06, this session. The run path and the skip path were both observed on GitHub; the accented-name and failing-diff cases were measured locally under `bash -eo pipefail` with the runner's default git config.
