# Code review — DIFF — round 1 — 2026-09-26 — PR #129

Artifact: branch `claude/clever-edison-ookn0s`, reviewed at `6340685` against `origin/main`
(`be86234`), i.e. `git diff origin/main...6340685`. Follow-up to #123: two SIGPIPE/NUL-noise
cleanups in `scripts/check_cdpath_safe.sh` and `skills/independent-review/scripts/check_prompt_sync.sh`.

## Gate used, and why not independent-review

The owner chose `/code-review` in place of the `independent-review` DIFF gate ("Can you use
/code-review instead of independet review?"). The session was a cloud container with neither
Codex nor ollama installed: `independent_review.sh` exited 4 (`codex SKIPPED (not available),
ollama SKIPPED (not available)`), so nothing left the machine and no cross-model seat ran. A
fresh-eyes host sub-agent was started and then stopped when the gate changed; it produced no
findings. **This round is same-family only** — not a cross-model review.

| Seat | Tool | Outcome |
|---|---|---|
| host | `/code-review`, effort high, on `origin/main...HEAD` | 8 findings |

## Findings and dispositions

| # | Sev | Location | Finding | Status |
|---|---|---|---|---|
| F8 | RISK | `scripts/check_cdpath_safe.sh` FAIL report | `diff \| head -20` prints "diff: standard output: Broken pipe" into a real FAIL report when SIGPIPE is ignored | **fixed** (`f05947f`), `locally_verified`: 200k-line diff, 20/20 noisy runs before, 0/20 after, same 20 lines shown |
| F5 | RISK | `check_prompt_sync.sh` tier check | `grep -E … >/dev/null` relies on a GNU grep detail (it treats `/dev/null` output like `-q`) | **refuted**, `locally_verified`: GNU grep 3.11 with `>/dev/null` consumed a 5 MB input in 20/20 runs (`-q`: 0/20). BSD grep has no such shortcut. **Moot after merge**: #128 replaced these lines with a direct grep on the file |
| F6 | NIT | `check_prompt_sync.sh` | `uncommented` re-reads the file ~180 times per run | **refuted** (not material): whole script 0.77 s. Moot after merge, as for F5 |
| F7 | NIT | `check_cdpath_safe.sh` `discover()` | `tr` adds a fork per file; bash's builtin `read` would drop NULs with no subprocess | **refuted** (not material): +0.06 s. `read`'s NUL handling on bash 3.2 (macOS default) was not testable here, so the tested `tr` form stays |
| F4 | RISK | other SUBJECTS (`check_model_agnostic.sh`, `whats-new.sh`) | `printf \| grep -q` under pipefail could flip the exit status the guard compares | **refuted for current inputs**, `locally_verified`: every input is ≤ 15 KB, below the pipe buffer, so the write completes before the reader exits; guard 0/60 failures with SIGPIPE ignored. Latent; carried in the follow-up below |
| F1 | BUG (pre-existing) | `scripts/package.sh` leak checks | `grep \| head -5 \| grep .` under `set -euo pipefail` skips FAIL on a large leak | **out of scope — follow-up**. Reproduced: 20,000 node_modules paths give status `141 0 0`, MISSED; a 50-path leak is caught. Not introduced or widened by this change (file untouched) |
| F2 | RISK (pre-existing) | `independent_review.sh` `looks_like_review` | `printf \| grep -q` under pipefail; a >64 KiB reviewer reply could flip the verdict | **out of scope — follow-up**. Not reproduced here |
| F3 | RISK (pre-existing) | `independent_review.sh` quota classifier | same pattern; a quota failure with large output could get the wrong remedy | **out of scope — follow-up**. Not reproduced here |

Tally: 1 fixed, 4 refuted or moot, 3 out of scope. None open in this PR.

## After the review

- `origin/main` moved to `c2d8f21` (#128), which removed `check_prompt_sync.sh`'s early-exit
  pipelines by grepping the file directly. The merge took main's version of that file, so this
  PR no longer changes it. The `check_cdpath_safe.sh` comment conflict was resolved by hand, to
  name the real racer (the tier check's `grep -v | grep -q`, not the `| head -1`).
- **Not re-reviewed:** the merge resolution (`ddcb1dd`) and the F8 fix. Both were re-tested
  on the merged tree: guard 0/60 failures with SIGPIPE ignored, mutation still exits 1,
  `discover()` list identical (23 scripts) with null-byte warnings 1 → 0, `check_prompt_sync.sh`
  0/100 broken-pipe runs, `make check` green.
- Skill-creator validator (`quick_validate.py`): `independent-review` valid; its `SKILL.md`
  is untouched. `website-seo-geo` fails it on `main` too (angle brackets in its description);
  untouched here.

## Follow-up

F1–F4: a separate task, "Fix pipefail early-exit pipelines that misreport", covering
`package.sh`, `independent_review.sh` and the latent SUBJECTS cases, with a >64 KiB
regression test for the leak check.

**Done:** karero/website-builder#130 (merged `03e32a0`) fixed F1–F4; its record is
`REVIEW-diff-2026-09-26-r1-pr130.md`. The lint that keeps the pattern out is karero/website-builder#131.
