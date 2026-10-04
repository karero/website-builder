# DIFF review — branch `fix/prepare-hook-nested-repo` — `prepare` wires the hook only at a repo's root

Base `0d41e96` · depth: Light (a one-line script in the template's `package.json`, test cases, a CI step, doc sentences) · verdict: **the one BUG and every RISK and NIT fixed and locally verified; no outside seat has run.**

**Gate this got, and why:** one fresh-eyes pass by a read-only sub-agent of the host model, because the diff is small. No outside reviewer (Codex, ollama-cloud) ran and the owner was not asked for data-release consent; that is the owner's call before merge.

| Round | Head | Artifact | Reviewer | seconds, tokens | BUG/RISK/NIT |
|---|---|---|---|---|---|
| 1 | `4bed89c` | full, `0d41e96...4bed89c` | fresh-eyes: host-family model, read-only sub-agent | 599 s, 154 479 | 1 / 3 / 2 |

| id | Sev | Finding | Status | Evidence |
|---|---|---|---|---|
| P1 | BUG | A git hook that runs `npm install` in a linked worktree hands it an absolute `GIT_DIR`; git then takes the site's folder for the top of the working tree, so a nested site still rewired the enclosing repo | fixed: the line unsets `GIT_DIR` and `GIT_WORK_TREE` first · locally_verified (the new test case failed on `4bed89c`; sh, dash, bash and zsh: nested left alone, a root site in a linked worktree still wired) | this commit |
| P2 | RISK | `test_pre_push_hook.sh` inherited an exported `GIT_DIR` and aimed its throwaway repos' commands at the caller's repo | fixed: unset beside `ALLOW_MAIN_PUSH` · locally_verified (run with `GIT_DIR` set to a scratch repo: that repo untouched) | this commit |
| P3 | RISK | Existing sites keep the old line (`package.json` is site-owned, no refresh replaces it), and nothing said how to repair a repo already rewired | fixed: a repair note in `templates/SETUP.md` | this commit |
| P4 | RISK | `website-team-setup` named only "never ran `npm install`" as the reason the hook is not active | fixed: the bypass list and the "NOT blocked" hint name a site that is not at its repo's root | this commit |
| P5 | NIT | The CI step and the test read `core.hooksPath` from every config scope | fixed: `--local` | this commit |
| P6 | NIT | `README.md`, `clean.yml` and the `Makefile` help described the test without its new scope | fixed | this commit |

Not covered by any run: native Windows `cmd` (the line before this change used the same `2>/dev/null` and `true`), and the CI step on a real runner — the pull request's `template-tests` run settles that one.
