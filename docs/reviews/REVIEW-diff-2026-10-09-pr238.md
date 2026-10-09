# DIFF review — PR #238 — Source the ai-seo content-type citation shares, drop the unsourced ones
Base `abfbca1` (merge-base `f412047` after merging main at `af15875`; the merge link was empty) · depth: Normal (SKILL.md is an instruction file agents follow; the owner's standing rule keeps those off Light) · verdict: CLEAN · authority used: POST AUTHORITY — atom A (this session opened PR #238); WORKTREE-WRITE — atom A (this session's own worktree); BRANCH-COMMIT — atom A (this session created the branch)

Data consent: the owner's task named the pair ("Codex + GLM 5.3 on melious", the GLM seat to get the source excerpts in the brief, marked as context). A grep of the diff for keys, tokens, passwords and secrets found nothing; the briefs add only public source text. ollama-cloud received nothing; Antigravity was not used.

| Round | Head | Artifact | Reviewers: CLI version, model, effort, sandbox | seconds, tokens per seat | BUG/RISK/NIT |
|---|---|---|---|---|---|
| 1 | `5bebf00` | full: `abfbca1...5bebf00`, 2 files, plus source excerpts | codex-cli 0.162.0, gpt-6.1-sol, effort from config, read-only; melious glm-5.3, HTTP API, text only; fresh-eyes: Claude Sonnet through the Agent tool, read-only by instruction, no shared context, no network | codex 120 s / 44,822; melious 28 s / 6,804; fresh-eyes 655 s / 198,727 | 2/2/6 (after dedup) |
| 2 | `1f085e7` | delta `5bebf00..1f085e7`, plus source excerpts | codex medium; melious glm-5.3 | codex 89 s / 24,790; melious 46 s / 14,073 | 0/1/2 |
| 3 | `120db1c` | delta `1f085e7..120db1c`, plus source excerpts | codex medium; melious glm-5.3 | codex 58 s / 28,585; melious 17 s / 8,226 | 0/0/0 |
| merge link | `af15875` | `merge_link.sh abfbca1 120db1c f412047`: empty (main's 35 new commits touch nothing under `skills/ai-seo`) | — | — | — |

| id | Sev | Source | Round | Finding — one line | Status | Evidence |
|---|---|---|---|---|---|---|
| F1 | BUG | codex, melious, fresh-eyes | 1 | "We found no study that gives a share for the other formats" is false: Peec AI gives product pages 13.66% and how-to guides 6.21% | fixed, externally_reverified (r2, r3) | `1f085e7`: a Peec bullet with its scope; the closing sentence now covers only the two complete tables, which have no row for definitive guides or original research |
| F2 | BUG | codex; melious (NIT); fresh-eyes (RISK) | 1 | the eval calls Profound's group "the most-cited" although "Other" (39.35%) is larger in April | fixed, externally_reverified (r2, r3) | `1f085e7`: "biggest named group"; the assertion rewritten |
| F3 | RISK | fresh-eyes | 1 | with the shares gone, the row order and "Prioritize" read as a ranking; Peec has Listicle 21.88% against Comparison 2.20% | fixed, externally_reverified (r2, r3) | `1f085e7`, `120db1c`: "in no particular order"; "in Profound's April table and in Peec's, list pages come first among the named types"; the table rows are unchanged on purpose |
| F4 | RISK | codex | 1 | the eval calls definitive guides, original research, product pages and how-to guides "high-citation" with no measurement | fixed, externally_reverified (r2, r3) | `1f085e7`: phrase removed; header "What Makes It Citable" |
| F5 | NIT | fresh-eyes | 1 | "pages", "cited sources" and "citations" for one unit | fixed, externally_reverified (r2, r3) | "citations" throughout; the deck's column is "Citations" |
| F6 | NIT | fresh-eyes | 1 | "that group was 25.37%" has an unclear antecedent and invites a trend reading | fixed, externally_reverified (r2, r3) | the September label quoted as on the slide; "two separate counts of different sizes" |
| F7 | NIT | fresh-eyes | 1 | one dense paragraph, Profound not introduced, style unlike the rest of the skill | fixed, externally_reverified (r2, r3) | bold lead-in, two bullets, "([Publisher](url), scope)" |
| F8 | NIT | fresh-eyes | 1 | the header "Why AI Cites It" states causes as fact | fixed, externally_reverified (r2, r3) | with F4 |
| F9 | NIT | fresh-eyes | 1 | the eval barely checks the new behaviour | fixed, externally_reverified (r2, r3) | assertion 1 reworded, assertion 3 added |
| F10 | NIT | fresh-eyes; codex and melious again outside scope in r2, r3 | 1 | other unsourced percentages elsewhere in `skills/ai-seo` (`references/content-patterns.md` lines 31, 64, 174, 182; `SKILL.md` lines 219-220) | follow-up | PR #237's head already removes or rewrites the four `content-patterns.md` lines; `SKILL.md` lines 219-220 remain, their scope sits in `references/platform-ranking-factors.md` line 49 |
| H1 | RISK | codex; melious (NIT) | 2 | the gloss "lists that compare options" defines a label the deck never defines | fixed, externally_reverified (r3) | `120db1c`: removed from `SKILL.md` and the eval |
| H2 | NIT | melious | 2 | "in both, list pages come first" rested on one September row | fixed, externally_reverified (r3) | `120db1c`: scoped to the April table and Peec's table |
| H3 | NIT | codex (UNVERIFIABLE, confirmed) | 2 | "differ in size and setup": the setups were not shown to differ | fixed, externally_reverified (r3) | `120db1c`: "two separate counts of different sizes" |

13 findings (2 BUG, 3 RISK, 8 NIT): 12 fixed, 1 follow-up. No refutation, waiver or deferral.

Follow-ups: F10; the eval's "citation probability" wording, which PR #237 changes. Whichever of #237 and #238 merges second will conflict on the one long `expected_output` line of eval 3 in `evals.json`: keep #238's middle and #237's ending.

Notes: UNVERIFIABLE entries asked / confirmed: round 1 12 / 6, round 2 6 / 2, round 3 6 / 0; every confirmed one is fixed above. Round 2 found no BUG and round 3 no finding, so the rounds stopped; the change to the eval's text in round 2 kept it off a prose-only wording pass. The source figures were recomputed by the seats and again by the author: the April table sums to 177,183,136 (32.50% and 9.91%), 666,086,560 at 25.37% is 2.63 billion, and Peec's eleven rows sum to 99.99%. The deck addresses (`...10000-000...`, `...40-million...`) disagree with the slide text (41,000,000+, 2.6B citations); no claim rests on an address. Judgment calls the owner may reverse: adding Peec AI's shares (the narrower fix was to say only what Profound's table lacks), and leaving the seven table rows as they were.
