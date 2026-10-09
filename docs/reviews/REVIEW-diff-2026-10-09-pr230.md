# DIFF review — PR #230 — facts-check: approved facts and positioning terms against every page of a live site

Base `746925c` (rounds up to R1), `5e15433` after the merge of `origin/main` · depth: Normal (new code that
fetches other sites and reports what a company says publicly; owner's choice, 2026-10-09). The standard
pair is incomplete: Codex could not run in the build environment (no CLI, no OpenAI credential), and
the Ollama seat answered HTTP 429. Round 2 (Codex) is handed to the owner to run locally.

| Round | Head | Artifact | Reviewers | seconds, tokens | BUG/RISK/NIT |
|---|---|---|---|---|---|
| CR1 | `936cc1b` | full, `746925c...936cc1b` | host seat: `/code-review` (Claude, read-only) | not logged | 10 findings, all fixed `826d6c4`, `fe11a8f` (plan doc, Status) |
| CR2 | `23217ab` | the positioning commit alone | host seat: `/code-review` | not logged | 9 findings, 8 fixed `cf49427`, 1 left as is (plan doc, Status) |
| R1 | `cf49427` | full, `746925c...cf49427` (2,027 lines) | melious (kimi-k3, HTTP API); ollama-cloud (kimi-k3) FAILED, HTTP 429 | melious 344 s, 48,026 | 1 / 2 / 3 |
| EV | `a53ec80` | skill-creator evals, 3 prompts with and without the skill | host seat, six agent runs | see the plan doc | 1 gap: retired phrases not searched in alt texts, share titles, links, `/llms.txt`; fixed `a53ec80` |
| ML | `1a66054` | merge link `746925c` to `5e15433` (merge of `origin/main`: PRs 227, 229) | `merge_link.sh` | empty: no file of this change moved | no review needed |
| 2 | — | open: Codex, full change (see the PR comment for the commands) | — | — | — |

Not yet seen by an outside reviewer: `cf49427...10131ad` (3 files: the R1 fixes, the retired-phrase places
from the evals, the description), covered by round 2's full artifact.

| id | Sev | Source | Round | Finding — one line | Status | Evidence |
|---|---|---|---|---|---|---|
| F1 | BUG | melious | 1 | A self-closing `<script .../>` leaves the parser skipping the rest of the page | refuted | HTML ignores the slash on a non-void element: a browser also treats what follows as script up to the next `</script>`, and the starter test sees the same |
| F2 | RISK | melious | 1 | Tags inside `<template>`, `<noscript>`, `<svg>` register as page structure; a `<p>` there takes the intro's place | fixed `a53ec80` | `MorePlaces.test_template_and_noscript_content_is_not_page_structure` |
| F3 | RISK | melious | 1 | `actions/checkout@v7` / `setup-python@v7` may not exist | refuted | the workflow's other jobs pin the same tags (`search-console-insights-tests`) |
| F4 | NIT | melious | 1 | `owner` and `checked` documented as provenance but never shown | fixed `a53ec80` | report prints source, owner, last confirmed; `FullRun` asserts it |
| F5 | NIT | melious | 1 | robots.txt answering 5xx or not at all meant "allow all" | fixed `a53ec80` | disallow all with the reason (RFC 9309); `FetcherRules.test_a_robots_txt_that_cannot_be_read_keeps_the_site_out` |
| F6 | NIT | melious | 1 | Pages over 5 MB cut silently | fixed `a53ec80` | note in the report; `FetcherRules.test_a_page_over_5_mb_is_reported_as_cut` |

Raw output of R1: `RAW-diff-2026-10-09-pr230-r1-melious.md`.

Verdict: open until round 2 (Codex) has run and its findings are fixed or refuted.
