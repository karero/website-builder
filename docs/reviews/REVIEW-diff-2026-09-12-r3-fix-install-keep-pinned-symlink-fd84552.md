# Independent review — DIFF — installers keep a pinned skill (rounds 1–3)

Branch `fix/install-keep-pinned-symlink`, head `fd84552`, base `origin/main` `c2c0333`.

**The change.** Both installers removed any existing symlink and re-pointed it at the checkout.
Someone who had pinned one skill — symlinked it into a sibling worktree of this repo, held at a
vetted commit — lost that pin the next time anyone ran an installer, silently. A pin is now kept
(and `--force` relinks it), a link moved away from anywhere else says so, and the cases where the
guard cannot run announce themselves.

**Verdict.** No open BUG. Round 3's fixes are verified by the test suite (73 checks, macOS bash 3.2
and Linux) and by a mutation run, not by a fourth external round: the gate's three-round cap was
reached, and each round's findings were smaller and narrower than the last (3 BUGs, then 2, then 2
— the last two being a platform gap and stale documentation rather than logic).

## Rounds

| Round | Reviewed | Reviewers — CLI, model, sandbox | Findings |
|---|---|---|---|
| 1 | `86b96c6` | Codex CLI 0.154.0, `gpt-6-astra`, `exec -s read-only`; ollama 0.34.0, `glm-5.3:cloud`, text only | 12 |
| 2 | `ab99df2` | same pair | 12 |
| 3 | `5092505` | same pair | 12 |

All three rounds ran through the merged failed-tier reporting, which is also how this branch's
rounds are known to have had both seats: each closed with `reviewers: codex OK, ollama-cloud OK`.

## Round 1 (on `86b96c6`)

| Sev | Source | Finding | Disposition |
|---|---|---|---|
| BUG | Codex | A shared git common dir does not mean "pinned": a link to another skill, or to the main checkout, was kept | Fixed `ab99df2`: linked worktree of this repo AND the same skill |
| BUG | Codex | The old-git fallback claim was unsupported — `rev-parse` can echo an unknown option and exit 0 | Fixed `ab99df2`: values validated as one absolute path |
| BUG | Codex | The handoff zip omitted the new test, so a packaged `make check` would fail | Fixed `ab99df2` |
| NIT | Codex, ollama | `--force --nope` ignored the trailing argument | Fixed `ab99df2` |
| RISK | ollama | Installing from another checkout of the same repo would no-op instead of refreshing | Fixed `ab99df2`: the main checkout is not a pin |
| RISK | ollama | The old-git stub covered only the failing variant | Fixed `ab99df2`, then properly in `5092505` (the stub itself was broken) |
| NIT | ollama | The "kept" message called any same-repo target a worktree | Fixed `ab99df2` |
| NIT | ollama | Test gaps: relative and dangling links | Fixed `ab99df2` |
| NIT | ollama | The stub interpolated git's path unquoted | Fixed `5092505` (stub rewritten) |
| NIT | ollama | ~35 lines duplicated across the two installers | **Declined**: they are separate shipped entry points and the repo treats one as the other's mirror; the test asserts identical behaviour for both, which is the guard against drift |
| NIT | ollama | `make check` now needs git | Addressed in `fd84552`: the test SKIPs instead of failing |
| RISK | ollama | Pins are best effort where git cannot verify | Documented in `fd84552` |

## Round 2 (on `ab99df2`)

| Sev | Source | Finding | Disposition |
|---|---|---|---|
| BUG | Codex, ollama | The "echoes" old-git fixture shifted the wrong argument, exited 1, and tested the failing variant twice | Fixed `5092505`: positional stub, and the fixture's own exit status and output shape are asserted |
| BUG | Codex | `check_template_coverage.sh` missing from the zip, so a packaged `make check` still failed early | Fixed `5092505`. Pre-existing; no branch or PR existed for it |
| RISK | Codex, ollama | `same_dir` returned true when both paths were missing | Fixed `5092505`, extended in `fd84552` for the unresolvable case |
| RISK | ollama | A pin whose worktree git can no longer read was relinked silently | Fixed `5092505`: every link moved away from elsewhere is reported |
| RISK | ollama | An old git clobbered pins with no output at all | Fixed `5092505`, reworked in `fd84552` |
| RISK | ollama | The expected skill path was compared textually | Fixed `5092505`: physical on both sides |
| NIT | ollama | The old-git case ran against one installer only; no worktree-to-worktree case | Fixed `5092505` |
| NIT | ollama | Makefile help had become a run-on sentence; test file not executable | Fixed `5092505` |
| NIT | ollama | A repeated real-directory backup nests inside the previous `.bak` | **Not fixed**: pre-existing in both installers, outside this change |

## Round 3 (on `5092505`)

| Sev | Source | Finding | Disposition |
|---|---|---|---|
| BUG | Codex, ollama | `one_abs_dir` accepted only `/…`, so on Git for Windows the guard was permanently off | Fixed `fd84552`: drive-letter paths count; both sides are only ever compared with each other |
| BUG | Codex | `docs/CODEX.md` and the README still said re-running "just refreshes the links" | Fixed `fd84552` |
| RISK | Codex, ollama | The test fixture inherited the developer's git config (`commit.gpgsign`, hooks) | Fixed `fd84552`: hermetic |
| RISK | Codex | Several installer runs asserted an outcome but never the exit status | Fixed `fd84552` |
| RISK | ollama | The guard-off note covered one cause of three | Fixed `fd84552`: every cause, and only when links actually moved |
| RISK | ollama | The header overstated pin protection | Fixed `fd84552` |
| NIT | ollama | Duplication across installers | **Declined**, as in round 1 |
| NIT | ollama | `make check` needs git even for zip recipients | Fixed `fd84552`: SKIP, not fail |

## Tests

`scripts/test_install_pin.sh`: 73 checks, both installers, driving them against a throwaway repo
with two linked worktrees. Pin kept (absolute and relative), `--force` relinks, stale link to
another repo refreshed, wrong skill refreshed, dangling link refreshed, unreadable worktree
refreshed and reported, main-checkout link refreshed while another worktree's link is kept, real
directory backed up, unknown and trailing flags refused, both old-git variants and no git at all.
Green on macOS bash 3.2 and on Linux (git 2.39.5, in Docker). 5 checks fail against `5092505`, 23
against the installers before this branch. It runs in `make check` and in the `install-pin` CI job.

## Not verified

Windows itself: no runner was available, so the drive-letter fix is reasoned from `rev-parse`'s
documented output shape and the fact that both sides of every comparison come from the same source.
The pre-2.31 git behaviours are simulated with stubs whose own behaviour the test asserts, not with
old git binaries.
