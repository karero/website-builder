# DIFF review — branch `fix/prepare-hook-nested-repo` — `prepare` wires the hook only at a repo's root

Base `0d41e96` · depth: Light (a one-line script in the template's `package.json`, test cases, a CI step, doc sentences) · verdict: **the one BUG and every RISK and NIT from both rounds fixed and locally verified; round 2's own fixes were not re-reviewed; no outside seat has run.**

**Gate this got, and why:** one fresh-eyes pass by a read-only sub-agent of the host model, because the diff is small. No outside reviewer (Codex, ollama-cloud) ran and the owner was not asked for data-release consent; that is the owner's call before merge.

| Round | Head | Artifact | Reviewer | seconds, tokens | BUG/RISK/NIT |
|---|---|---|---|---|---|
| 1 | `4bed89c` | full, `0d41e96...4bed89c` | fresh-eyes: host-family model, read-only sub-agent | 599 s, 154 479 | 1 / 3 / 2 |
| 2 | `cbc7e57` | delta since `4bed89c` | the same sub-agent, resumed | 457 s, 185 275 | 0 / 2 / 2 — P1, P2, P4, P5, P6 verified fixed; P3 only partly |

| id | Sev | Finding | Status | Evidence |
|---|---|---|---|---|
| P1 | BUG | A git hook that runs `npm install` in a linked worktree hands it an absolute `GIT_DIR`; git then takes the site's folder for the top of the working tree, so a nested site still rewired the enclosing repo | fixed: the line unsets `GIT_DIR` and `GIT_WORK_TREE` first · locally_verified (the new test case failed on `4bed89c`; sh, dash, bash and zsh: nested left alone, a root site in a linked worktree still wired) | this commit |
| P2 | RISK | `test_pre_push_hook.sh` inherited an exported `GIT_DIR` and aimed its throwaway repos' commands at the caller's repo | fixed: unset beside `ALLOW_MAIN_PUSH` · locally_verified (run with `GIT_DIR` set to a scratch repo: that repo untouched) | this commit |
| P3 | RISK | Existing sites keep the old line (`package.json` is site-owned, no refresh replaces it), and nothing said how to repair a repo already rewired | round 1's fix, a note in `templates/SETUP.md`, did not reach those sites — see Q1 | `cbc7e57`, then the round-2 commit |
| P4 | RISK | `website-team-setup` named only "never ran `npm install`" as the reason the hook is not active | fixed: the bypass list and the "NOT blocked" hint name a site that is not at its repo's root | this commit |
| P5 | NIT | The CI step and the test read `core.hooksPath` from every config scope | fixed: `--local` | this commit |
| P6 | NIT | `README.md`, `clean.yml` and the `Makefile` help described the test without its new scope | fixed | this commit |
| Q1 | RISK | The repair note sat in `SETUP.md`, which is copied once at scaffold and never refreshed, so an older site never sees it | fixed: the header of the hook itself — a file a refresh does replace — quotes the current line and says how to repair; the test pins that it quotes the same line as `package.json` | round-2 commit |
| Q2 | RISK | "Scaffolded before 2026-10" was wrong: the latest release still ships the old line | fixed: the notes name the line itself (one without `--show-prefix`) | round-2 commit |
| Q3 | NIT | `--unset` does not restore a hook folder the bigger repo used before | fixed: "or set it back to that repo's own hooks folder" | round-2 commit |
| Q4 | NIT | A test comment implied every git hook hands down `GIT_DIR`; the primary checkout's hooks get none | fixed | round-2 commit |

Not covered by any run: native Windows `cmd` (the line before this change used the same `2>/dev/null` and `true`), and the CI step on a real runner — the pull request's `template-tests` run settles that one.
