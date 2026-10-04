# DIFF review — karero/website-builder#149 (branch `fix/prepare-hook-nested-repo`) — `prepare` wires the hook only at a repo's root

Base `0d41e96` · depth: Normal, at the owner's request (the diff alone would be Light: a one-line script, test cases, a CI step, doc sentences) · verdict: **CLEAN with one waiver** — every BUG fixed; C1 (RISK) waived by the owner, with a follow-up · authority used: POST, WORKTREE-WRITE and BRANCH-COMMIT — this session opened the pull request and created the branch; GATED-THIS-DIFF — Codex saw `0d41e96...4c4ca10` in full, then the prose delta to the wording pass's head.

**Data release consent** (owner, in this session, quoted verbatim): "Yes to: Do you want the Codex pair on either change before merge? That needs your data-release consent." Read as naming Codex only, so ollama-cloud did not run: one outside seat, by that choice.

| Round | Head | Artifact | Reviewers: CLI version, model, effort, sandbox | seconds, tokens | BUG/RISK/NIT |
|---|---|---|---|---|---|
| 1 | `4bed89c` | full, `0d41e96...4bed89c` | fresh-eyes: host-family model, read-only sub-agent | 599 s, 154 479 | 1 / 3 / 2 |
| 2 | `cbc7e57` | delta since `4bed89c` | the same sub-agent, resumed | 457 s, 185 275 | 0 / 2 / 2 — P1, P2, P4, P5, P6 verified fixed; P3 only partly |
| 3 | `4c4ca10` | full, `0d41e96...4c4ca10` | codex-cli 0.159.3, gpt-6.1-sol, config effort, read-only (`--seat codex`) | 297 s, 53 452 | 0 / 1 / 0 |
| wording pass | `e4f0835` | delta since `4c4ca10`: comment text in one shell test | codex-cli 0.159.3, gpt-6.1-sol, medium effort, read-only (`--seat codex`) | 123 s, 26 621 | 0 / 0 / 0 |

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

| C1 | RISK | codex, round 3: the `prepare` line is POSIX shell and the test forces `sh`; nothing shows it works where npm uses another shell (native Windows, which `SETUP.md` documents) | **waived** for this pull request — unchanged by it: the line it replaces used the same shell syntax | see Waivers |

Waivers and deferrals: C1 — the owner, 2026-10-04, asked "Waive it for this PR and log a follow-up (my recommendation), or have me turn it into a Node script with a Windows CI job here?", answered: "1. do a follow-up (my recommendation)".

Follow-ups: make `prepare` independent of the shell (a small Node script) and run it through real npm on a Windows runner (C1).

Notes: rounds ended after round 3 (no BUG). Codex marked as unverifiable the test comment's claim that an install in the template is what disabled this repo's guard; it was not observed, and the comment and the pull request's description now say so. Wording pass (Codex, on `e4f0835`): that comment is the only change since `4c4ca10` outside this file — "No BUG/RISK/NIT findings"; it confirmed the diff holds no code hunk. Not a round. The CI step added here ran green on the pull request (`template-tests`).
