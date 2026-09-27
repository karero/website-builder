# DIFF review — fix/agy-prompt-no-false-claim — agy gets its own prompt, without "You have NO tools"

Base `bbe4432` · depth: **Normal** (changes the prompt a reviewer tier is sent; tooling only, no
user data, no production path) · verdict: **CLEAN** · authority used: WORKTREE-WRITE and
BRANCH-COMMIT — atom A (this session created the worktree and the branch); POST AUTHORITY — atom A
(this session opens the PR, on the owner's "do the prompt fix as a PR").

Consent: Codex and ollama-cloud have reviewed this public repo in earlier gates; the diff was
grepped for key shapes first (none). Antigravity not used: its quota ran out 2026-09-27 18:38.

| Round | Head | Artifact | Reviewers | seconds, tokens | BUG/RISK/NIT |
|---|---|---|---|---|---|
| 1 | `3eacd90` | full: `origin/main...3eacd90`, `docs/reviews/` excluded (15 KB) | Codex CLI 0.157.1, `gpt-6-astra`, config effort, read-only | 96 s, 37,413 | 0/0/0 |
| 1 | `3eacd90` | same | ollama-cloud `kimi-k2.7-code` — FAILED: 429, weekly usage limit | 1 s | — |
| 1 | `3eacd90` | same | fresh-eyes, Claude Sonnet sub-agent, read-only | 331 s, 167,069 | 0/1/1 |
| wording pass | `fb13ae4` | delta `3eacd90..fb13ae4`, prose only (a comment, a docs reflow) | Codex, `gpt-6-astra`, effort medium, `--verify` | 71 s, 24,950 | 0/0/0 |

| id | Sev | Source | Round | Finding — one line | Status | Evidence |
|---|---|---|---|---|---|---|
| FE-1 | RISK | fresh-eyes | 1 | A comment edit made after Codex's round had not been reviewed | fixed — externally_reverified (wording pass) | `fb13ae4`; Codex wording pass: "comment edit landed and is now reviewed" |
| FE-2 | NIT | fresh-eyes | 1 | `setup-guide.md:195` broke the paragraph's wrap width | fixed — externally_reverified (wording pass) | `fb13ae4` |

UNVERIFIABLE, both Codex passes: that a refused command always ends an agy run. Not a finding. The
author checked every print-mode log on the maintainer's machine that logged a denial: eight,
2026-08-29 to 2026-09-27, each shut down 0.02–0.97 s after its first denial. Fresh-eyes checked the
same count independently, and the 2026-09-27 run against its transcript.

Follow-ups: none. R-AGY-PROMPT stays open in OPEN-FINDINGS until a live agy run shows the new
prompt working.

Notes: round 1 counted one cross-model seat (ollama-cloud out of weekly quota); Codex held an
unbroken chain to `fb13ae4`. Round 1 had zero BUG and zero RISK against the change, so it stopped
under step 6 (a2); the wording pass covered the two post-round edits. Stub tests only: no live
`agy` run (quota).
