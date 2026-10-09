# DIFF review — PR #230 — facts-check: approved facts and positioning terms against every page of a live site

Base `746925c` (rounds up to R1), `5e15433` after the merge of `origin/main` · depth: Normal (new code that
fetches other sites and reports what a company says publicly; owner's choice, 2026-10-09). The standard
pair is incomplete: Codex could not run in the build environment (no CLI, no OpenAI credential), and
the Ollama seat answered HTTP 429. Round 2 (Codex) was handed to the owner to run locally; it ran on 2026-10-09 from a checkout of `578a67a`. Codex produced the review; the GLM 5.3 seat on Melious timed out at the 300 s limit set for the run (a 110,000-character artifact), and the Ollama stand-in answered HTTP 429, so round 2 counts one reviewer. Its eight BUGs were fixed in `9f030e3`.

| Round | Head | Artifact | Reviewers | seconds, tokens | BUG/RISK/NIT |
|---|---|---|---|---|---|
| CR1 | `936cc1b` | full, `746925c...936cc1b` | host seat: `/code-review` (Claude, read-only) | not logged | 10 findings, all fixed `826d6c4`, `fe11a8f` (plan doc, Status) |
| CR2 | `23217ab` | the positioning commit alone | host seat: `/code-review` | not logged | 9 findings, 8 fixed `cf49427`, 1 left as is (plan doc, Status) |
| R1 | `cf49427` | full, `746925c...cf49427` (2,027 lines) | melious (kimi-k3, HTTP API); ollama-cloud (kimi-k3) FAILED, HTTP 429 | melious 344 s, 48,026 | 1 / 2 / 3 |
| EV | `a53ec80` | skill-creator evals, 3 prompts with and without the skill | host seat, six agent runs | see the plan doc | 1 gap: retired phrases not searched in alt texts, share titles, links, `/llms.txt`; fixed `a53ec80` |
| ML | `1a66054` | merge link `746925c` to `5e15433` (merge of `origin/main`: PRs 227, 229) | `merge_link.sh` | empty: no file of this change moved | no review needed |
| 2 | `578a67a` | full, `5e15433...578a67a` (2,150 lines) | Codex (read-only); melious (glm-5.3) FAILED, curl exit 28 at the 300 s limit; ollama-cloud FAILED, HTTP 429 | codex 412 s, 91,401 tokens | 8 / 1 / 0 |

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

| F7 | BUG | codex | 2 | A redirect from a page to an address robots.txt disallows was followed: `/public` redirecting to `/private` fetched `/private` | fixed `9f030e3` | `FullRun.test_a_redirect_into_a_page_robots_txt_disallows_is_not_followed`, failed before; reproduced by hand on `578a67a`. Only page fetches are checked, not robots.txt or the sitemaps |
| F8 | BUG | codex | 2 | A truncated chunked response raised `http.client.IncompleteRead`, which escaped `Fetcher.get` and ended the whole run | fixed `9f030e3` | `FullRun.test_a_response_that_ends_in_the_middle_does_not_stop_the_run`, errored before; the page is listed as not read |
| F9 | BUG | codex | 2 | A minus sign was dropped: `NPS of -5` matched an approved 5 | fixed `9f030e3` | `FindMentions.test_a_minus_sign_is_part_of_the_number` and, end to end, `FullRun.test_a_sign_a_split_number_and_a_template_through_a_full_run`; reproduced by hand. No sign after a word character, digit, `.`, `,`, `/`, `+` or `±`, so `5-10`, `2024-10-09`, `COVID-19`, `+/-3%` stay unsigned |
| F10 | BUG | codex | 2 | A sitemap index with 201 child sitemaps gave 199 pages and no word about the other two | fixed `9f030e3` | `SitemapFileLimit`: the limit stays at 200 files and the report says how many were left unread |
| F11 | BUG | codex | 2 | The header charset was read with a regex that missed a quoted value: `charset="iso-8859-1"` turned every accent into a replacement character | fixed `9f030e3` | `FullRun.test_a_quoted_charset_in_the_header_is_honoured`; reproduced by hand. Parsed with `email.message.Message.get_content_charset()` |
| F12 | BUG | codex | 2 | `<span>27</span>,000 clients` became `27 ,000 clients` and reported MISMATCH 27 | fixed `9f030e3` | `CheckPage.test_a_span_does_not_split_a_number_but_still_separates_a_number_from_its_label`; reproduced by hand. `span`, `a`, `button` and `label` still separate words (`<span>27.000+</span><span>Agenten</span>` stays two words) but not where a tag cuts a number |
| F13 | BUG | codex | 2 | JSON-LD inside `<template>` was read: it was collected before the skip check | fixed `9f030e3` | `CheckPage.test_structured_data_inside_a_template_or_noscript_is_not_read` (template, noscript, svg) |
| F14 | BUG | codex | 2 | `"retired": 3` and `"retired_phrases": 3` raised TypeError: a traceback and exit 1, which reads as "findings" | fixed `9f030e3` | `LoadFacts.test_a_wrong_type_is_a_message_not_a_crash` (exit 2 through `main`); `"sitemap": 3` had the same flaw and is covered too |
| F15 | RISK | codex | 2 | `actions/checkout@v7` and `actions/setup-python@v7` may not exist (F3 again) | refuted, with evidence | both tags resolve upstream (`gh api repos/actions/checkout/git/ref/tags/v7` and `.../setup-python/...`); the workflow's other jobs pin the same tags. Pinning every action to a commit hash would be a change for the whole workflow |

Codex also listed, without a finding, what it could not check: complete runs on Python 3.9 and 3.12 (3.9 and 3.13 run here, 3.12 in CI), parity of the HTML reader with a browser, the RFC 9309 and 50 MB citations, and statements about AI engines. Also found, outside round 2, by both outside seats while they checked a claim about this script against its code: the module docstring said a zero is ignored "for a fact whose own value is not a year"; the code ignores it unless the fact is 0. Fixed in `9f030e3` (docstring and SKILL.md).

Raw output of R1: `RAW-diff-2026-10-09-pr230-r1-melious.md`. Raw output of R2: `RAW-diff-2026-10-09-pr230-r2-codex.md`.

Verdict: open until round 3 (Codex and GLM 5.3 on Melious, the fixes since `578a67a`) has run and its findings are fixed or refuted.
