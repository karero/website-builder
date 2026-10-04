# DIFF review — branch `fix/prepare-hook-any-shell` (no pull request yet; stacked on karero/website-builder#149) — `prepare` becomes a Node script, run through real npm on three systems

Base `ae0381d` (the head of #149, not merged when this started) · depth: Normal (new code that runs on every recipient's `npm install`; nothing from the High row) · verdict: **OPEN** — round 1 had the fresh-eyes seat only, and no outside seat has seen the diff: the owner's data-release consent for this session is still asked for · authority used: WORKTREE-WRITE and BRANCH-COMMIT — the app created this worktree for this session, and this session created the branch; POST and GATED-THIS-DIFF not used: no pull request, no stamp.

| Round | Head | Artifact | Reviewers: CLI version, model, effort, sandbox | seconds, tokens | BUG/RISK/NIT |
|---|---|---|---|---|---|
| 1 | `bae56cf` | full, `ae0381d...bae56cf` | fresh-eyes: host-family mid-tier model (the Agent tool's `sonnet` option), read-only sub-agent | 1 115 s, 193 377 | 0 / 2 / 5 |

| id | Sev | Source | Round | Finding | Status | Evidence |
|---|---|---|---|---|---|---|
| F1 | RISK | fresh-eyes | 1 | The starter's own README lists the overlay's files without `scripts/wire-hooks.mjs`; a site put together from that list fails its first `npm install` | fixed · locally_verified | the list names the script and says the install fails without it. Reproduced before the fix: the line without the file, `npm install` exits 1 with "Cannot find module" |
| F2 | RISK | fresh-eyes | 1 | `clean.yml`'s `pre-push-hook` job brings no node of its own. Without node the test skips the prepare cases and exits 0, so on an image without node the job would stay green and test less | fixed · locally_verified (the text) | the job runs `actions/setup-node` first; not run on GitHub yet |
| F3 | NIT | fresh-eyes | 1 | Dropping `GIT_WORK_TREE` was untested, and no case was named where git sets it | fixed · locally_verified | a hook of `git --git-dir=… --work-tree=… checkout` gets `GIT_WORK_TREE=.` (observed, git 2.33). New case with both variables; without either deletion it fails |
| F4 | NIT | fresh-eyes | 1 | At a repo's root, a `git config` write that fails left the hook unwired without a word | fixed · locally_verified | one line on stderr, exit 0. New case with a locked config. Two mutations fail: no word there, and a word on every wiring |
| F5 | NIT | fresh-eyes | 1 | `whats-new`'s line for the script read as an order and did not give the `prepare` line | fixed | the line is quoted |
| F6 | NIT | fresh-eyes | 1 | A CI comment said SETUP.md has Windows users install from PowerShell; SETUP.md lists tool installs there and recommends WSL2 for building | fixed | the comment says "the runner's default one" |
| F7 | NIT | fresh-eyes | 1 | Ragged line wraps left by the edits | fixed | rewrapped |

Waivers and deferrals: none.

Follow-ups: the `prepare-any-shell` job has not run anywhere but as a rehearsal of its commands on macOS; what happens on Windows is still unobserved until the branch is pushed. Whether the pre-push hook itself runs on native Windows (line endings, `python3`) is outside this change and untested.

Notes: round 1 is degraded: fresh-eyes only. The fixes for F1–F7 have been seen by no reviewer; the outside pair's first run is a full round over the whole diff, not a delta. Open with the owner: a `package.json` that has the new line without the script file fails `npm install`, on purpose (the quiet alternative is `node scripts/wire-hooks.mjs || exit 0`, which puts shell syntax back). The cost log could not be written from this session; the table above is the record.
