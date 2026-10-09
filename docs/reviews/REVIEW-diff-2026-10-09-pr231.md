# DIFF review — PR #231 — Source the ai-seo figures; state Google's 2023 FAQ and HowTo limits
Base `a9f41b2` (merge-base `746925c` after merging main at `6da08ee`; the merge link was empty) · depth: Normal (named by the owner, "run the Codex + GLM review on #231"; a docs and eval change the skill would have allowed at Light) · verdict: CLEAN · authority used: POST AUTHORITY — atom A (this session opened PR #231); WORKTREE-WRITE — atom A (this session's own worktree); BRANCH-COMMIT — atom A (this session created the branch)

Data consent, quoted: the owner asked "run the Codex + GLM review on #231" (2026-10-09). A grep of the diff for keys, tokens and passwords found nothing. ollama-cloud received nothing (its CLI was kept off `PATH`); Antigravity was not used.

| Round | Head | Artifact | Reviewers: CLI version, model, effort, sandbox | seconds, tokens per seat | BUG/RISK/NIT |
|---|---|---|---|---|---|
| 1 | `5a8feb2` | full: `a9f41b2...5a8feb2`, 4 files | codex-cli 0.161.0, gpt-6.1-sol, effort from config (high), read-only; melious glm-5.3, HTTP API, text only; fresh-eyes: Claude Sonnet through the Agent tool, read-only by instruction, no shared context | codex 271 s / 70,198; melious 65 s / 9,660; fresh-eyes 78 s / 99,621 | 1/5/7 (13 after dedup) |
| 2 | `9ea91dc` | delta `5a8feb2..9ea91dc`, 204 lines (fixes plus owner-requested HowTo, 58% and 6.5x material) | codex medium; melious glm-5.3 | codex 155 s / 43,463; melious 199 s / 14,143 | 0/2/3 (+1 outside scope) |
| 3 | `99a2f6b` | delta `9ea91dc..99a2f6b`, 48 lines | codex medium; melious glm-5.3 | codex 61 s / 46,010; melious 61 s / 7,280 | 0/1/0 (+1 outside scope) |
| re-gate | `4bb4904` | delta `99a2f6b..4bb4904`, 27 lines (round 3 fix, eval assertion split; JSON, so full scope) | codex medium; melious FAILED (melious.ai out of credits) | codex 79 s / 25,131 | 0/0/0 |
| merge link | `6da08ee` | `merge_link.sh a9f41b2 4bb4904 746925c`: empty; the change's diff is byte-identical after the merge | — | — | — |

| id | Sev | Source | Round | Finding — one line | Status | Evidence |
|---|---|---|---|---|---|---|
| R1-1 | BUG | codex, fresh-eyes | 1 | `ai-seo/SKILL.md:69,416` still said "45% of Google searches" | fixed, externally_reverified (r2) | `9ea91dc`: "queries BrightEdge tracks" |
| R1-2 | RISK | codex, fresh-eyes | 1 | schema-markup eval 2 expected "rich result benefits" | fixed, externally_reverified (r2, r3, re-gate) | `9ea91dc`, `99a2f6b`, `4bb4904` |
| R1-3 | RISK | fresh-eyes | 1 | seo-audit eval 8 "may mention FAQ schema benefits / can enable rich results" | fixed, externally_reverified (r2) | `9ea91dc` |
| R1-4 | RISK | codex | 1 | Sellm 55% framed as citation likelihood; causal advice | fixed in part, externally_reverified (r2); see R2-1. Refuted in part: "strongest signal" is SE Ranking's own wording | seranking.com/blog/chatgpt-citation-factors/: "Among all factors, backlinks remain the strongest signal of trust and credibility" |
| R1-5 | RISK | codex | 1 | the reference claimed AI Overviews and Perplexity use schema | fixed, externally_reverified (r2); see R2-2 | `9ea91dc` |
| R1-6 | RISK | melious | 1 | Sellm attribution unverified | refuted | sellm.io/post/chatgpt-ranking-factors: "400,000 URLs across 10,000 different queries"; 55% / 14% / 12% in its factor table (fetched 2026-10-09) |
| R1-7 | NIT | melious | 1 | BrightEdge "(2026)" against "late 2025" | refuted | page published 2026-02-12; its table gives ~45% for Nov 2025, ~48% for Feb 2026 |
| R1-8 | NIT | melious | 1 | "update monthly" lost its source | fixed, externally_reverified (r2) | three places now "at least every three months" |
| R1-9 | NIT | fresh-eyes | 1 | the GEO paper also tested Perplexity | fixed, externally_reverified (r2, r3) | `9ea91dc`, `99a2f6b` |
| R1-10 | NIT | fresh-eyes | 1 | "Direct Q&A extraction" overpromised | fixed, externally_reverified (r2) | "Q&A in machine-readable form" |
| R1-11 | NIT | fresh-eyes | 1 | content-patterns.md "Essential for FAQ schema" | refuted | the line says a visible FAQ block carries FAQ schema; Google requires markup to match visible content |
| R1-12 | NIT | fresh-eyes | 1 | "since 8 August 2023": the rollout ran over a week | fixed, externally_reverified (r2) | "since August 2023" |
| R1-13 | NIT | fresh-eyes | 1 | website-seo-geo parenthetical too long mid-list | fixed, externally_reverified (r2) | own bullet |
| R2-1 | RISK | codex | 2 | Sellm paragraph still promised more citations | fixed, externally_reverified (r3) | "shows a link, not a tested cause" |
| R2-2 | RISK | codex | 2 | the reference asserted a Google preference for structured data | fixed, externally_reverified (r3); see R3-1 | `99a2f6b` |
| R2-3 | NIT | melious | 2 | eval assertion dropped "authoritative" | fixed, externally_reverified (r3) | `99a2f6b` |
| R2-4 | NIT | melious | 2 | "a research engine" too vague | fixed, externally_reverified (r3) | "the authors' own simulated engine" |
| R2-5 | NIT | melious | 2 | AirOps "13%" without "about" (13.2%) | fixed, externally_reverified (r3) | `99a2f6b` |
| R3-1 | RISK | codex | 3 | "seems to favour content that cites its sources" still a Google claim without Google evidence | fixed, externally_reverified (re-gate, codex) | `e678445`: "We found no Google-specific test of what the AI layer adds on top" |

19 findings (1 BUG, 8 RISK, 10 NIT): 15 fixed, 3 refuted, 1 fixed in part and refuted in part. No waiver, no deferral.

Follow-ups: `ai-seo/SKILL.md` Critical stats "Optimized content gets cited 3x more often" and "Statistics and citations boost visibility by 40%+" have no source (melious r2, codex r3 and re-gate, outside scope).

Notes: GLM's round 1 reply lacked the final-review marker; its content read as a finished review and it counted. GLM failed in the re-gate (melious.ai credits at −0.09 EUR), so its chain ends at round 3; the stamp relies on Codex, whose chain is unbroken. Round 3 found no BUG, so the rounds ended there; R3-1 was fixed and re-gated with the eval split. The owner also asked mid-gate for the HowTo limit, the 58% and 6.5x sources (reviewed in round 2) and a check against the skill-creator guidelines (the compound assertion split, re-gated).
