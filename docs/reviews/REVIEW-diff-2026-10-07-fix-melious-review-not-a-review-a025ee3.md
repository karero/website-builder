# DIFF review — branch fix/melious-review-not-a-review — independent-review: ask reviewers for list-marked finding lines; leave the validator alone

Base `bc3a63d` · depth: **Normal** (review tooling: it decides whether a reviewer counts; no user data, no production path) · verdict: **CLEAN at `5a5d72b`** · authority used: WORKTREE-WRITE and BRANCH-COMMIT — atom A (this session created the worktree `website-builder-melious-review` and branch `fix/melious-review-not-a-review`); POST AUTHORITY — atom A once this session opens the PR.

**Data release consent** (owner, this session, quoted verbatim): "Codex + ollama-cloud (Recommended)" and, for melious.ai, "Add Melious glm-5.3 (Recommended)" (both 2026-10-06). Session-scoped; the repo has no standing consent.

**Why:** a genuine melious kimi-k3 review (#179, round 1) was marked `FAILED (output is not a review)`. Its findings started "RISK 1 — ..." with no list marker, so `looks_like_review` counted none, and a quoted "can't open perl script" in its UNVERIFIABLE list tripped the refusal veto.

**Superseded artifact (rounds A1–A3, not this gate's count):** commits `db486ad`, `636e735`, `61a0173` taught the validator the unmarked shape. Each round's fix exposed the next false accept; A3 showed a refusal with the kimi reply's exact structure ("BUG: I will not review this file." / "RISK: I won't read it either." / "I cannot access the repository." / "No findings.") is accepted by any version that accepts the kimi reply, and `main` rejects it. Stopped: not converging. The host recommended moving the fix to the prompt; the owner answered "continue".

| Round | Head | Artifact | Reviewers | seconds, tokens per seat | BUG/RISK/NIT |
|---|---|---|---|---|---|
| A1 | `db486ad` | full `bc3a63d...db486ad`, `docs/reviews/` excluded | Codex CLI 0.160.1 gpt-6.1-sol, config effort, read-only; ollama `glm-5.3:cloud` FAILED (429 session limit); fresh-eyes claude-sonnet-5-5, read-only | codex 191 s, 61.4k · fresh-eyes 114 s, 104k | 1 / 1 / 2 |
| A2 | `636e735` | delta `db486ad..636e735` | Codex (medium); ollama `glm-5.3:cloud` | codex 126 s, 43.5k · ollama 282 s | 1 / 1 / 2 |
| A3 | `61a0173` | delta `636e735..61a0173` | Codex (medium); ollama `glm-5.3:cloud` | codex 145 s, 46.8k · ollama 482 s | 1 / 0 / 1 |
| 1 | `a025ee3` | full `bc3a63d...a025ee3`, `docs/reviews/` excluded | Codex CLI 0.160.1 gpt-6.1-sol, config effort, read-only; melious `glm-5.3`, text only (ollama CLI hidden); fresh-eyes claude-sonnet-5-5, read-only | codex 213 s, 65.6k · melious 94 s, 9.9k · fresh-eyes 86 s, 105k | 0 / 3 / 2 |
| 2 | `f878d30` | delta `a025ee3..f878d30` | Codex (medium); melious `glm-5.3` | codex 134 s, 43.5k · melious 68 s, 13.1k | 1 / 2 / 2 |
| 3 | `5a5d72b` | delta `f878d30..5a5d72b` + the whole OPEN-FINDINGS change vs base | Codex (medium), hand-counted; melious `glm-5.3` | codex 103 s, 48.3k · melious 64 s, 12.6k | 0 / 0 / 0 |

| id | Sev | Source | Round | Finding — one line | Status | Evidence |
|---|---|---|---|---|---|---|
| N1 | RISK | glm-5.3 | 1 | no accept case for the dictated shape without a number | fixed, externally_reverified (3) | `f878d30`, `5a5d72b` (adds `- BUG`) |
| N2 | RISK | fresh-eyes | 1 | "every version tried also accepted a refusal" not checkable | fixed, externally_reverified (2, 3) | reject case added; with `61a0173`'s validator swapped in it fails; Codex replayed `db486ad`/`636e735`/`61a0173` |
| N3 | RISK | fresh-eyes | 1 | KNOWN WRONG pin cites a B-REFUSAL-TEXT row that does not quote the input | fixed, externally_reverified (3) | row sentence added; owner sign-off recorded |
| N4 | NIT | fresh-eyes, glm-5.3 | 1 | overflowed line in both prompt copies | fixed, externally_reverified (2) | `check_prompt_sync.sh` ok |
| N5 | NIT | fresh-eyes | 1 | new comment mid-paragraph; "That" lost its antecedent | fixed, externally_reverified (2) | own paragraph |
| R2-C1 | BUG (record prose) | Codex | 2 | row said sign-off pending while Gate status says all deferred | fixed, externally_reverified (3) | owner signed off 2026-10-07 |
| R2-G1 | RISK | glm-5.3 | 2 | the refusal reject case may not hold | refuted | suite green on HEAD; fails with `61a0173`'s validator |
| R2-G2 | RISK | glm-5.3 | 2 | unnumbered accept case lacked `- BUG` | fixed, externally_reverified (3) | `5a5d72b` |
| R2-G3 | NIT | glm-5.3 | 2 | "pins both": unclear antecedent | fixed, externally_reverified (3) | names the three cases |
| R2-G4 | NIT | glm-5.3 | 2 | H comment said "quoted" | fixed, externally_reverified (3) | "on another line" |

**Deferral:** the validator still rejects a kimi-shaped reply (B-REFUSAL-TEXT), pinned KNOWN WRONG in `test_looks_like_review.sh`. Owner's sign-off, 2026-10-07, quoted: "Yes, sign off (Recommended)". Merge-base reproduction, the real 5,223-byte reply against `bc3a63d`'s validator: `list findings=0; refusal phrase: can't open` → `bc3a63d reject`. The validator is unchanged on this branch.

Follow-ups: B-REFUSAL-TEXT records its sign-off in the Finding cell where sibling rows use the Found column, and the "Last updated" line names only the pin (glm-5.3, round 3).

Notes: round 3's Codex seat was marked `FAILED (output is not a review)` though it opened with "No BUG/RISK/NIT findings."; counted by hand as clean. Cause: one VERIFIED bullet mentioning `- BUG` counted as a finding, and a quoted `cannot access` fired the veto — B-REFUSAL-TEXT again; `main` rejects it too. The stamp relies on melious glm-5.3, counted in every round. Compliance with the new instruction: a live melious kimi-k3 run on the #179 diff wrote `- BUG —` / `- RISK —` lines and counted (163 s); glm-5.3's round 1 and 2 replies used the same shape.
