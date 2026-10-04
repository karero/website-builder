# DIFF review — karero/website-builder#151 (branch `fix/prepare-hook-any-shell`) — `prepare` becomes a Node script, run through real npm on three systems

Base `ae0381d` (the head of #149 when this started; #149 merged during the gate, the pull request now targets `main`, and the merge-base is still `ae0381d`) · depth: Normal (new code that runs on every recipient's `npm install`; nothing from the High row) · verdict: **CLEAN** — no BUG in any round; every RISK and NIT fixed · authority used: WORKTREE-WRITE and BRANCH-COMMIT — the app created this worktree for this session, and this session created the branch; POST — this session opened the pull request; GATED-THIS-DIFF — Codex saw `ae0381d...37e055b` in full, then each delta up to `edd2b94`; what follows `edd2b94` is this file alone.

**Data release consent** (owner, in this session, quoted verbatim): "2. Ok for  CODEX: Data-release OK for Codex". Codex only, so ollama-cloud did not run: one outside seat, by that choice. The script's start-up note names the ollama tag it would pick; each run's raw folder holds Codex files only.

| Round | Head | Artifact | Reviewers: CLI version, model, effort, sandbox | seconds, tokens | BUG/RISK/NIT |
|---|---|---|---|---|---|
| 1 | `bae56cf` | full, `ae0381d...bae56cf` | fresh-eyes: host-family mid-tier model (the Agent tool's `sonnet` option), read-only sub-agent | 1 115 s, 193 377 | 0 / 2 / 5 |
| 2 | `37e055b` | full, `ae0381d...37e055b` | codex-cli 0.159.3, gpt-6.1-sol, config effort, read-only (`--seat codex`) | 562 s, 87 547 | 0 / 1 / 0 |
| 3 | `e9de2ac` | delta since `37e055b`: two workflow files | codex-cli 0.159.3, gpt-6.1-sol, medium effort, read-only (`--seat codex --verify`) | 133 s, 28 546 | 0 / 1 / 0 |
| re-gate | `edd2b94` | delta since `e9de2ac`: one workflow step | the same | 80 s, 42 544 | 0 / 0 / 0 |

| id | Sev | Source | Round | Finding | Status | Evidence |
|---|---|---|---|---|---|---|
| F1 | RISK | fresh-eyes | 1 | The starter's own README lists the overlay's files without `scripts/wire-hooks.mjs`; a site put together from that list fails its first `npm install` | fixed · locally_verified | `37e055b`: the list names the script and says the install fails without it. Reproduced before the fix: the line without the file, `npm install` exits 1 with "Cannot find module" |
| F2 | RISK | fresh-eyes | 1 | `clean.yml`'s `pre-push-hook` job brought no node of its own. Without node the test skips the prepare cases and exits 0, so the job could stay green and test less | fixed · externally_reverified (see C1, D1) | `37e055b`: the job runs `actions/setup-node`. Its run on that head: node v22.23.3, 20 `ok   prepare` lines, no skip |
| F3 | NIT | fresh-eyes | 1 | Dropping `GIT_WORK_TREE` was untested, and no case was named where git sets it | fixed · externally_reverified (round 2 lists the removal of both variables as checked) | a hook of `git --git-dir=… --work-tree=… checkout` gets `GIT_WORK_TREE=.` (observed, git 2.33). New case with both variables; without either deletion it fails |
| F4 | NIT | fresh-eyes | 1 | At a repo's root, a `git config` write that fails left the hook unwired without a word | fixed · externally_reverified (round 2 lists the warning branch as checked) | one line on stderr, exit 0. New case with a locked config. Two mutations fail: no word there, and a word on every wiring |
| F5 | NIT | fresh-eyes | 1 | `whats-new`'s line for the script read as an order and did not give the `prepare` line | fixed · locally_verified | the line is quoted |
| F6 | NIT | fresh-eyes | 1 | A CI comment said SETUP.md has Windows users install from PowerShell; SETUP.md lists tool installs there and recommends WSL2 for building | fixed · locally_verified | the comment says "the runner's default one" |
| F7 | NIT | fresh-eyes | 1 | Ragged line wraps left by the edits | fixed | rewrapped |
| C1 | RISK | codex | 2 | F2's fix rested on `setup-node` alone: nothing in the job stopped it if node or npm were missing | fixed, then see D1 | `e9de2ac`: `command -v node` and `command -v npm` before the test |
| D1 | RISK | codex | 3 | Those two lines stopped the step only if GitHub starts the shell with `-e`, which the review could not check | fixed · externally_reverified (re-gate: "D1 fixed in full") | `edd2b94`: each line exits 1 itself. Run without `-e`: a missing command stops before the test |

Not findings, settled since: Codex marked as uncheckable from its sandbox that npm hands a script line to cmd.exe on Windows and sh elsewhere (rounds 2, 3 and the re-gate). The `prepare-any-shell` job now measures it. On `e9de2ac` the Windows leg logged `npm's script shell, given 'echo %ComSpec%', says: C:\Windows\system32\cmd.exe`, the Ubuntu and macOS legs `… says: %ComSpec%`, and every leg `root-site: core.hooksPath=scripts/hooks, big: core.hooksPath=unset`. The Windows installs start from `pwsh` (read in the log of the run on `37e055b`).

Waivers and deferrals: none. Owner decision, 2026-10-04, on a `package.json` that has the new line without the script file (its `npm install` fails): asked whether to keep that loud or make the line `node scripts/wire-hooks.mjs || exit 0`, answered "3. yes to: Judgment: I kept it loud, because the quiet alternative leaves the hook silently unwired."

Follow-ups: whether the pre-push hook itself runs on native Windows (line endings, `python3`) is outside this change and untested.

Notes: rounds ended after round 3, with no BUG in any round. D1 was fixed locally and Codex re-gated its delta; that is a re-gate, not a round. Fresh-eyes ran in round 1 only, as Normal depth has it, so F1 and F5–F7 rest on Codex's full round 2 not raising them again. The owner approved the push and the pull request in chat ("1. yes to your recommednastion: Push and open the pull request?"). The cost log could not be written from this session; the table above is the record.
