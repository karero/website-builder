# DIFF review — fix/git-stand-hook-review — the site's Claude Code sync hook, first cross-model gate
Base `4e69534` (round 1 artifact: the hook, its settings wiring and test as merged by #166 and #175) · depth: Normal (runs by itself at every Claude Code session of a site; no data, money or deploy) · verdict: CLEAN · authority used: WORKTREE-WRITE, BRANCH-COMMIT — atom A (this session created worktree `../website-builder-hookfix` and branch `fix/git-stand-hook-review`); owner's OK for the reviewers, verbatim: "Yes, Codex + ollama-cloud" (option text: "The standard pair, plus a fresh-eyes Claude pass that stays on this machine. Melious only steps in if ollama is out of quota.")

| Round | Head | Artifact | Reviewers | seconds, tokens per seat | BUG/RISK/NIT |
|---|---|---|---|---|---|
| 1 | `4e69534` | full: #166 + #175 diffs, hook, settings and test at their current content (47 KB) | Codex (gpt-6.1-sol, read-only); ollama-cloud `kimi-k2.7-code:cloud` (text only); fresh-eyes Claude (sonnet sub-agent, read-only, could run the test) | codex 336 s, 72011 tok; kimi 483 s; fresh-eyes 364 s, 123392 tok | 4/6/10 raw → 18 after dedup |
| 2 | `488d3ce` | delta `4e69534..488d3ce` + round-1 dispositions | Codex (answer rejected by the refusal check, B-REFUSAL-TEXT; a real review, counted by hand); kimi | codex 342 s, 63922 tok; kimi 439 s | 1/3/5 |
| 3 | `b655450` | delta `488d3ce..b655450` + round-2 dispositions | Codex (effort medium); ollama-cloud FAILED (429, session usage limit); Melious `kimi-k3` in its place | codex 165 s, 38046 tok; melious 140 s, 7192 tok | 0/0/1 |

| id | Sev | Source | Round | Finding — one line | Status | Evidence |
|---|---|---|---|---|---|---|
| C1 | BUG | codex (fresh-eyes as NIT) | 1 | marker moved on before `git log` succeeded; those commits never reported | fixed — externally_reverified (r2) | `488d3ce`; test "git log works again: the commit is still reported" |
| C2 | BUG | codex | 1 | no origin/main ended mid-session as "no action needed" | fixed — externally_reverified (r2) | `488d3ce`; test "no origin/main, prompt: the assistant is told" |
| C3 | BUG | codex | 1 | failed `rev-list --count` read as 0 | fixed — externally_reverified (r2) | `488d3ce`; tests "rev-list fails: …" |
| C4 | RISK (codex: BUG) | codex | 1 | the 30 s kill stops git, not its helpers | comment fixed — externally_reverified (r2); residual waived | `488d3ce`; re-rated: the hook still returns (fresh-eyes measured 31 s) |
| C5 | RISK | codex, kimi, fresh-eyes | 1 | Claude Code hook contract unsupported | refuted | code.claude.com/docs/en/hooks read 2026-10-06: `source` startup/resume/clear/compact/fork; `systemMessage`, `hookSpecificOutput.additionalContext` for SessionStart and UserPromptSubmit; CLAUDE_PROJECT_DIR exported; shell form `sh -c`, Git Bash or PowerShell on Windows; `timeout`, `statusMessage` |
| K1 | BUG | kimi | 1 | settings.json command unescaped quotes | refuted | `JSON.parse` of the file succeeds |
| K2 | RISK | kimi | 1 | `@v7` actions may not resolve | refuted | every clean.yml job on @v7; `gh run list --branch main`: success on `562afd2`, `4e69534` |
| K3 | RISK | kimi | 1 | marker read/write errors swallowed | corrupt JSON half refuted; unwritable half waived | next save rewrites valid JSON |
| K4 | NIT | kimi | 1 | chmod restore loses the original mode | refuted | the test's own mktemp tree |
| F1 | RISK | fresh-eyes | 1 | GIT_SSH_COMMAND overrode core.sshCommand / GIT_SSH | fixed — externally_reverified (r2) | `488d3ce`; test "core.sshCommand: the person's ssh is used" |
| F2 | RISK | fresh-eyes | 1 | ssh failures reported as git's generic line | fixed — externally_reverified (r2) | `488d3ce`; test "ssh failure: the cause …" |
| F3 | RISK | fresh-eyes | 1 | no origin: "stop and ask" every 10 min; not a repo: every prompt | fixed — externally_reverified (r2) | `488d3ce`; tests "no origin: …", "not a repository, inside a project: …" |
| F4 | NIT | fresh-eyes | 1 | read-only .git comment and test name overclaimed the rhythm | fixed — externally_reverified (r2) | `488d3ce` |
| F5 | NIT | fresh-eyes | 1 | the test never ran the settings command | fixed — externally_reverified (r2) | `488d3ce`; runs it through `sh -c`, path with a space |
| F6 | NIT | fresh-eyes | 1 | offline: 20–30 s and the note every 10 min | waived | — |
| F7 | NIT | fresh-eyes | 1 | /clear and resume ask about the session's own unsaved work | refuted for /clear (context gone); resume waived | — |
| F8 | NIT | fresh-eyes | 1 | = C1 | merged into C1 | — |
| F9 | NIT | fresh-eyes | 1 | a commit title with >>> ended the data fence | fixed — externally_reverified (r2) | `488d3ce`; test "a title with >>> leaves one fence end" |
| F10 | NIT | fresh-eyes | 1 | trap could not clean a read-only dir | fixed — externally_reverified (r2) | `488d3ce` |
| R2-C2 | RISK | codex | 2 | a failed remote lookup became "not on GitHub yet" | fixed — externally_reverified (r3) | `b655450`; test "git remote fails: reported as a failure" |
| R2-NULL | BUG (outside scope, pre-existing) | codex | 2 | a marker holding JSON `null` crashed the hook | fixed — externally_reverified (r3) | `b655450`; test "marker reads null: the hook still reports" |
| R2-K2 | RISK | kimi | 2 | stale lastSync in the no-remote save | refuted — Codex VERIFIED (r3) | the schedule is the marker's mtime |
| R2-N1 | NIT | kimi | 2 | the noRemote ternary is unreachable | refuted — Codex VERIFIED (r3) | test "no origin, after 2 h: a quiet status" |
| R2-N2 | NIT | kimi | 2 | no-origin test never ages the marker | fixed — externally_reverified (r3) | `b655450` |
| R2-N3–N5 | NIT | kimi | 2 | test setup variables, branch `feat`, `$T/seed` | refuted — Codex VERIFIED (r3) | test setup lines |
| R3-N1 | NIT | melious | 3 | the fresh repo's marker path written out inline | fixed — locally_verified | `FM` beside `M`; closing edit not externally re-verified |

Waivers: signed off by the owner in chat, 2026-10-06, by ticking "Stuck helper outlives hook", "Nowhere to write marker", "Offline: repeat every 10 min", "Resume asks about own work" (C4 residual, including custom ssh commands, which get none of the hook's ssh options; K3 unwritable half; F6; F7 resume).
Follow-ups: none.
Notes: Every behaviour fix (C1, C2, C3, F1, F2, F3, F9, R2-C2, R2-NULL) has a test that fails on the hook it replaced (run by swapping in the earlier file); C4, F4, F5, F10 and R3-N1 change comments or the test itself. Wording pass (Codex, 85 s, 43403 tok): 1 contradiction (this sentence), fixed, confirmed by the same seat. Round 2's Codex answer failed the script's review check and was counted by hand (B-REFUSAL-TEXT). Round 3: ollama-cloud hit its session limit; Melious took the seat, so the pair was Codex + Melious. Round 3 had no BUG or RISK (stop condition a2).
