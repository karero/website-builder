# DIFF review — karero/website-builder#166 (+ a companion PR in a site repo) — AGENTS.md stays English; reply in the person's language
Base `bb765c6` (website-builder), `eba0912` (site, AGENTS.md only) · depth: Normal (instructions agents follow; no code path, data or deploy) · verdict: CLEAN for #166; CLEAN for the site's AGENTS.md, the site's hook code not cross-model reviewed · authority used: POST AUTHORITY, WORKTREE-WRITE, BRANCH-COMMIT — atom A (this session created both PRs and works on its designated branch); owner's OK for sending to the reviewers, verbatim: "PLease send the new Agents.md to external review by CODEX and kimi k3"

| Round | Head | Artifact | Reviewers | seconds, tokens per seat | BUG/RISK/NIT |
|---|---|---|---|---|---|
| 1 | wb `284cc54`, site `4551477` | full: wb `bb765c6...284cc54`; site `eba0912...4551477 -- AGENTS.md` | Kimi K3 (`kimi-k3:cloud`, ollama HTTP API, text only); fresh-eyes Claude (sonnet sub-agent, read-only, both checkouts); Codex SKIPPED (no CLI, no credential) | Kimi 188 s, 24397 tok (one earlier attempt HTTP 502); fresh-eyes 115 s, 109964 tok | 0/2/6 |
| 2 | wb `a8a3477`, site `33c6d3c` | delta since round 1, both repos | Kimi K3 | 176 s, 16639 tok | 0/1/0 |
| 3 | site `8eb58b4` | delta `33c6d3c..8eb58b4` | Kimi K3 (two attempts HTTP 502 first) | 124 s, 11642 tok | 0/1/1 |
| wording | site `b3d45f2` | delta `8eb58b4..b3d45f2` | Kimi K3 (`--seat ollama`) | — | 0/1/0 |
| confirm | site `e006539` | delta `b3d45f2..e006539` | Kimi K3 (`--seat ollama`) | — | 0/0/0 |

| id | Sev | Source | Round | Finding — one line | Status | Evidence |
|---|---|---|---|---|---|---|
| R1 | RISK | Kimi, fresh-eyes | 1 | site §1.2 "do not repeat step 2" had no fallback when the hook did not run | fixed, externally_reverified (r2) | site `33c6d3c` |
| R1b | — | Kimi | 1 | "hook not shipped" | refuted | hook + settings registration in site `fee086e`, same branch |
| R2 | RISK | fresh-eyes | 1 | template `ci.yml` / `placeholders.spec.ts` comments still said "translated site" | fixed, externally_reverified (r2) | wb `a8a3477` |
| N2 | NIT | Kimi, fresh-eyes | 1 | Language rule declarative, not an instruction | fixed, externally_reverified (r2) | wb `a8a3477`, site `33c6d3c` |
| N4 | NIT | fresh-eyes | 1 | site "Codex never merges" omits Claude Code | fixed, externally_reverified (r2) | site `33c6d3c` |
| K2 | NIT | Kimi | 1 | site "(it cannot work without)" clipped | fixed, externally_reverified (r2) | site `33c6d3c` |
| N3 | NIT | fresh-eyes | 1 | "the site owners usually write German" unsourced | refuted | their commits on the site's `main` are German (e.g. `bc59d3e`); previous AGENTS.md was German |
| R3 | RISK | Kimi | 2 | fallback missed a failed 2-hour re-check in a long session | fixed, externally_reverified (r3) | site `8eb58b4` |
| R4 | RISK | Kimi | 3 | "An extra fetch does no harm" unexplained next to "shows nothing new" | fixed, externally_reverified (confirm) | site `b3d45f2`, then `e006539` |
| N6 | NIT | Kimi | 3 | long-session case: the 2-hour check failed, not the hook | fixed, externally_reverified (wording) | site `b3d45f2` |
| W1 | RISK | Kimi | wording | "the person has already seen the hook's own report" misleading in the fallback case | fixed, externally_reverified (confirm) | site `e006539` |

Follow-ups: (N1) `docs/reviews/SKILL-PLAN-website-team-setup.md` A16 still says translate AGENTS.md (historical plan; shipped files win). (N5) site AGENTS.md has drifted from the kit template (cloud `ls-remote` check, "Codex or Claude Code" locally) — a `whats-new` merge. Hook reports carry no timestamp, so "more than 2 hours" is the agent's judgement. "An extra fetch" reads oddly where the manual fetch is the only one (Kimi, confirm, outside scope). The hook's code (`.claude/hooks/git-stand.mjs`) had no cross-model review.
Notes: Codex seat unavailable throughout (no Codex CLI or OpenAI credential in the cloud session): every round degraded to one cross-model seat. Rounds 1–2 covered both repos in one artifact; round 3 onwards site only. Round 3 earned by the round-2 RISK fix to an instruction; no round past 3. Kimi HTTP 502 three times, each passed on retry.
