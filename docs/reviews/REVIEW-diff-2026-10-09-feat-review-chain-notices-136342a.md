# DIFF review — branch `feat/review-chain-notices` — independent-review: non-blocking notices and a fix standard, after a 13-round gate

Base `d717d3e` · depth: Normal (SKILL.md and a script of the review skill: instructions agents follow, never Light) · verdict: OPEN — the wording pass and its confirmation are pending; nothing is pushed and there is no PR yet · authority used: WORKTREE-WRITE — this session created the worktree and branch and stamped it (`ccd.owner`); BRANCH-COMMIT — the same. No POST AUTHORITY used.

**Data release consent** (owner, in this session, quoted verbatim): "Send your suggestion to CODEX" (Codex), "Yes run 2nd round include GLM" (melious.ai), "Go" (the change and its gate). The repo is public; the artifact was scanned for keys, passwords and client names first: none.

| Round | Head | Artifact (full / delta since <sha>) | Reviewers: CLI version, model, effort, sandbox | seconds, tokens per seat | BUG/RISK/NIT |
|---|---|---|---|---|---|
| 1 | `136342a` | full, `d717d3e...136342a` (5 files, 69 lines, -U25, plus a verbatim context appendix for the text-only seat) | codex-cli 0.162.0, gpt-6.1-sol, config, read-only · melious glm-5.3 (HTTP API) · fresh-eyes: mid-tier host-family sub-agent, read-only | codex 236 s, 73,432 · melious 56 s, 24,118 · fresh-eyes 336 s, 155,062 | 1 / 5 / 7 after dedup (codex 1/1/0, glm 0/0/3, fresh-eyes 0/4/6, one UNVERIFIABLE made a RISK) |
| 2 | `ede2931` | delta since `136342a` (5 files), `--verify` with round 1's dispositions | codex medium, read-only · melious glm-5.3 | codex 168 s, 70,220 · melious 96 s, 29,091 | 1 / 2 / 2 after dedup (codex 1/1/0, glm 0/1/4; two of glm's NITs fold into B2 and R6) |
| 3 | `2b862c9` | delta since `ede2931` (2 files), `--verify` with round 2's dispositions | codex medium, read-only · melious glm-5.3 | codex 77 s, 37,249 · melious 64 s, 13,116 | 0 / 0 / 1 (codex 0/0/0, glm 0/0/1) |

Findings, 19 after dedup: 2 BUG, 7 RISK, 10 NIT.

| id | Sev | Source | Round | Finding — one line | Status | Evidence |
|---|---|---|---|---|---|---|
| B1 | BUG | codex, fresh-eyes, glm | 1 | the round-claim paragraph stated its own fallback; the permission table is the one place for fallbacks | fixed — externally_reverified (2) | `ede2931`: a table row appended, the paragraph only points at POST AUTHORITY |
| R1 | RISK | codex | 1 | the claim check lived in closeout.md, read after the reviewers run | fixed — externally_reverified (2) | `ede2931`: step 2 starts with reading the PR comment |
| R2 | RISK | fresh-eyes | 1 | step 7 "rounds go on" clashed with step 6 past round 8 | fixed — externally_reverified (2) | "Within the budget (step 6)" |
| R3 | RISK | fresh-eyes | 1 | the `regression` value overlapped step 7's mandatory stop | fixed — externally_reverified (2) | defined as exactly that case |
| R4 | RISK | fresh-eyes | 1 | the notice asks for the owner's decision in the trail; the template had no slot | fixed — externally_reverified (2) | the Waivers line |
| R5 | RISK | fresh-eyes (UNVERIFIABLE, made a RISK) | 1 | "the same claim is not raised again" rests on reviewer behaviour the prompt does not state | fixed in two steps — externally_reverified (3) | `ede2931`, then `2b862c9`: "can check that evidence" |
| N1 | NIT | glm | 1 | "earns no round" read as the fix earning none | fixed — externally_reverified (2) | `ede2931` |
| N2 | NIT | glm, fresh-eyes | 1 | the notice needs `--round`, undocumented; step 2's output list omitted it | fixed — externally_reverified (2); its "carry the last round's number" caused B2 | `ede2931` |
| N3 | NIT | fresh-eyes | 1 | `caused-by` syntax and "chain of three" undefined | fixed — externally_reverified (2) | literal `caused-by: F12 (partial)` |
| N4 | NIT | fresh-eyes | 1 | the notice prints after the round ran | fixed — externally_reverified (2) | script string and test string |
| N5 | NIT | fresh-eyes | 1 | the claim line had no position or end; "head" clashes with the stamp's seen head | fixed — externally_reverified (2) | `ede2931` |
| N6 | NIT | fresh-eyes | 1 | step 4's coverage rule applied by analogy | fixed — externally_reverified (2) | "applies the same way" |
| N7 | NIT | fresh-eyes | 1 | rationale.md: over-long line, unsourced "ninth", overstated, undated figures | fixed — externally_reverified (2) | `ede2931` |
| B2 | BUG | codex (glm NIT) | 2 | `caused-by: N2 (introduced)`. Step 2 told a wording pass, final full read or re-gate to carry the last round's number; after round 1 that is `--round 1`, which starts a new gate | fixed — externally_reverified (3) | `2b862c9`: such runs leave `--round` off; test "a run with no --round joins the open gate and starts none" (`9fe45bb`), which fails on a copy of the script where such a run starts a gate |
| R6 | RISK | codex, glm | 2 | R5 again: "checks that evidence instead of deriving the claim again" | fixed — externally_reverified (3) | `2b862c9` |
| R7 | RISK | glm | 2 | "the round's rewrite replaces it" is not what clerk item 2 says | fixed — externally_reverified (3) | `2b862c9`: "Delete it when the round's findings are posted" |
| N8 | NIT | glm | 2 | claim position undefined while the comment has no marker | fixed — externally_reverified (3) | `2b862c9` |
| N9 | NIT | glm | 2 | no stated fallback for a gate with no PR/MR | fixed — externally_reverified (3) | `2b862c9`: in the table row |
| N10 | NIT | glm | 3 | the table row did not name "delete" | fixed — locally_verified; closing edit not externally re-verified | `9fe45bb` |

Waivers and deferrals: none. The owner's grant for rounds past 8: not applicable (3 rounds).
Follow-ups: judge the change by rounds per gate (`scripts/review_log.sh summary`) on the next gate that runs past round 3; it is unmeasured.
Notes: (1) Before this gate the proposal had two PLAN opinion rounds in the same session (Codex alone, 10 findings; Codex and GLM, 5), all fixed in the plan; they are not this gate's rounds. (2) Rounds past 3: none. Round 2 was earned by B1, round 3 by B2 (a BUG the round-1 fix N2 introduced). (3) Stop: (a2) at round 3: no BUG, no RISK. Convergence: findings fell 13, 5, 1 (after dedup); B2 was caused by a fix but re-broke nothing an earlier round fixed, so step 7(c) did not apply. (4) The claims sweep (`sweep_claims.sh`) before round 1 found two overclaims in rationale.md ("every round was earned", "the chain ended"), fixed before any reviewer saw the diff. (5) Pending: the wording pass (`--seat codex`) over what changed since `2b862c9`, with its confirmation; the PR comment and marker only after a push the owner confirms.
