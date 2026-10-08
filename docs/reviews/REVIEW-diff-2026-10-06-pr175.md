# DIFF review — karero/website-builder#175 (+ a companion PR in a site repo) — sync hook follow-ups
Base `e0e8a44` (website-builder), `746530d` (site) · depth: Normal (a hook that runs in every Claude Code session of a site, instructions agents follow; no site code, data or deploy) · verdict: CLEAN · authority used: POST AUTHORITY, WORKTREE-WRITE, BRANCH-COMMIT — atom A (this session created both PRs and works on its designated branch); owner's OK for sending both repos to Ollama Cloud, verbatim: "PLease send the new Agents.md to external review by CODEX and kimi k3" (2026-10-05, same feature); owner asked for these PRs: "open PRs for the follow-ups"

| Round | Head | Artifact | Reviewers | seconds, tokens per seat | BUG/RISK/NIT |
|---|---|---|---|---|---|
| 1 | wb `8bfede9`, site first commit of #29 | full: wb `e0e8a44...8bfede9`; site `746530d -- AGENTS.md .claude` | Kimi K3 (`kimi-k3:cloud`, ollama HTTP API, text only); Codex SKIPPED (no CLI, no credential) | 283 s, 26587 tok | 0/0/1 |
| 2 (verify) | wb `0d77743` | delta `8bfede9..0d77743` | Kimi K3 | 109 s, 10659 tok | 0/0/1 |
| 3 (verify) | wb `d52c33a`, site `3518532` | delta `0d77743..d52c33a`; site full `AGENTS.md` diff | Kimi K3 | 121 s, 12748 tok | 0/0/0 |

| id | Sev | Source | Round | Finding — one line | Status | Evidence |
|---|---|---|---|---|---|---|
| NIT-1 | NIT | Kimi | 1 | cloud-task rule: `ls-remote` prints nothing for a branch GitHub lacks; read as "GitHub has moved on" | fixed, externally_reverified (r2) | wb `0d77743`, site `3518532` |
| NIT-2 | NIT | Kimi | 2 | new clause and "Network off" both matched empty output | fixed, externally_reverified (r3) | wb `d52c33a`, site `3518532`; checked: missing ref exits 0 with no line, unreachable and no-access remotes exit 128 |

Unverifiable items the reviewer raised, checked here: the test script is bash (`#!/usr/bin/env bash`); its work repo is on branch `feat`; no case after the read-only block reads the marker; `os.tmpdir()` honours `TMPDIR` (Node 22); the read-only cases pass as a non-root user and all four new cases fail against the old hook.
Follow-ups: Windows without Git Bash (the hook does not start; AGENTS.md's fallback covers it).
Notes: Codex seat unavailable (cloud session): every round degraded to one cross-model seat. One artifact covered both repos; the site's hook file is byte-identical to the kit's (same blob in the diff).
