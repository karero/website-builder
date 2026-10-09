# Plan: facts-check, one approved facts list and the positioning terms against every page of a live site

Requirements record for `skills/facts-check`. Where it and the shipped files disagree,
the files win. Names of sites and people stay out of this public repo on purpose.

## Why

A site that has grown for years states its key figures in many places, and they drift:
one page says 500 clients, another 700, the meta description an older number again. AI
answer engines quote whichever figure they find. A comparison found exactly this on a
real, established site (talent pool and client count each given two different values
on the company's own pages, a third on a review site). Nobody reads 400 pages side by
side; a script can, every week, the same way the AI check asks the assistants every week.

It closes the gap named in the established-sites showcase ("comparing pages with an
approved facts list: not built").

## Shape

- Read-only, any live site, any stack: it works from the sitemap (or a page list), not
  from a repository or a build.
- People keep the facts list (value, source, owner, date checked). The script only
  compares, and never decides which of two figures is right.
- Standard-library Python 3.9+, so it runs on a stock python3 with no installs.
- Exit 0 clean, 1 findings, 2 nothing could be checked. A run that read nothing is never
  clean.

## Scenarios

| # | Given | When | Then | Test |
|---|---|---|---|---|
| 1 | a page says "27,000+ agents", the list says 27000 | the check runs | OK | `FindMentions.test_term_after_the_number` |
| 2 | another page says "30,000 agents" | the check runs | MISMATCH, with page, place and sentence | same, and `FullRun` (structured data) |
| 3 | the meta description still says 25,000, listed as retired | the check runs | OUTDATED, not MISMATCH | `FullRun` |
| 4 | "27,000 agents in 60 countries", "in 60 countries, clients love us" | the check runs | 60 is neither an agent nor a client count | `test_other_numbers_near_the_term_are_not_tied`, `test_a_comma_ends_the_search` |
| 5 | "founded in 2016 clients ..." and a count-up showing 0; "über 2000 Kunden" | the client fact runs | the first two are not client counts; 2000 is | `test_years_and_zero_are_ignored_unless_the_fact_is_one`, `test_a_plain_four_digit_count_is_not_taken_for_a_year` |
| 6 | German notation (27.000, 2,5 Mio.) | the check runs | read as the same numbers | `ParseNumber.test_formats` |
| 7 | a stat block with the number and its label in two elements | the check runs | still tied | `FullRun` ("27.000+" / "Agenten") |
| 8 | the old company name in the text | the check runs | RETIRED phrase with its note | `FullRun` |
| 9 | robots.txt disallows a page; a page is a PDF; a page is gone | the check runs | listed under "Not checked" with the reason; `--ignore-robots` reads the disallowed page | `FullRun`, `test_ignore_robots_reads_disallowed_pages` |
| 10 | the sitemap cannot be found | the check runs | exit 2 and "No pages were found", never a clean report | `test_no_pages_is_an_error_not_a_pass` |
| 11 | a facts file with several mistakes | the check starts | every problem listed at once, exit 2 | `LoadFacts.test_problems_are_listed_together` |
| 12 | a profile on a review site in `extra_urls` | the check runs | its findings marked "not your site" | `test_only_and_extra_urls` |
| 13 | weekly runs | `--history` | one CSV line of counts per run; none when nothing was read | `FullRun`, `test_a_run_that_reads_no_page_is_never_clean` |
| 14 | a page redirects to an address robots.txt disallows | the check runs | the redirect is not followed; the page is listed as skipped, with the address; `--ignore-robots` follows it | `FullRun.test_a_redirect_into_a_page_robots_txt_disallows_is_not_followed` |
| 15 | a response ends before it is complete | the check runs | that page is listed as not read; the run goes on | `FullRun.test_a_response_that_ends_in_the_middle_does_not_stop_the_run` |
| 16 | "NPS of -5"; "5-10", "2024-10-09", "+/-3%" | the check runs | -5 is minus five and differs from an approved 5; the others carry no sign | `FindMentions.test_a_minus_sign_is_part_of_the_number`, `FullRun.test_a_sign_a_split_number_and_a_template_through_a_full_run` |
| 17 | a sitemap index lists more than 200 sitemap files | the check runs | it stops at 200 and the report says how many were left unread | `SitemapFileLimit` |
| 18 | the header says `charset="iso-8859-1"` (quoted) | the check runs | accents read right | `FullRun.test_a_quoted_charset_in_the_header_is_honoured` |
| 19 | `<span>27</span>,000 clients`; `<span>27.000+</span><span>Agenten</span>` | the check runs | 27,000; the stat block stays two words | `CheckPage.test_a_span_does_not_split_a_number_but_still_separates_a_number_from_its_label` |
| 20 | JSON-LD inside `<template>`, `<noscript>` or `<svg>` | the check runs | not read | `CheckPage.test_structured_data_inside_a_template_or_noscript_is_not_read` |
| 21 | `"retired": 3`, `"retired_phrases": 3`, `"sitemap": 3` in the facts file | the check starts | a message and exit 2, never a traceback | `LoadFacts.test_a_wrong_type_is_a_message_not_a_crash` |
| P1 | a rule `{"pages": "/", "term": "X"}` | the page lacks X in the title, description or H1/intro | each missing surface is named; exit 1 | `Positioning.test_term_rule_needs_title_description_and_h1_or_intro`, `FullRun.test_positioning_on_the_stub_site` |
| P2 | a human H1 ("Help when you need it") and the term in the first paragraph of `<main>` | the check runs | the term counts; a header paragraph before `<main>` does not | `test_surfaces_as_the_starter_test_reads_them`, `test_intro_falls_back_to_article_then_page` |
| P3 | per-surface clauses with alternatives and `body` | the check runs | all clauses must match; one alternative per list is enough | `test_surface_rules_alternatives_and_body` |
| P4 | `/en/business/*` and a specific rule for one page; `/about/`, `/about.html` | rules are matched | the first matching rule wins; the address forms read alike | `test_paths_and_first_matching_rule` |
| P5 | a page with no rule, and a legal page in `exempt` | the check runs | the first is listed as a warning, the second not at all | `FullRun.test_positioning_on_the_stub_site`, real-site run |
| P6 | a facts file with only positioning rules | it loads | valid; a file with nothing to check is refused | `test_positioning_alone_is_enough`, `test_positioning_rules_are_validated` |

## Status

| Step | State | Evidence |
|---|---|---|
| Script and SKILL.md | built | `skills/facts-check/` |
| Scenarios 1 to 13 | done (stub site on 127.0.0.1) | `scripts/tests/test_facts_check.py`, Python 3.9 and 3.13 |
| Positioning check (P1 to P6), owner request 2026-10-09 | done | same file, 45 tests in all. Real site: its own `positioning.spec.ts` map, converted, run against its production build: 12 of 12 pages carry their term, as its test gate says. With one term changed, that page is reported on all three surfaces, and a page no longer exempt is listed as having no rule |
| Code review (`/code-review`, one round) | done: 10 findings, all fixed | 2026-10-09. Image and video entries read as pages; a run that read no page reported clean and wrote a zero history line; four-digit counts skipped as years; inline tags splitting numbers; sitemaps cut at 5 MB; `--only` applied after the cut; numbers in JSON-LD dropped; `<meta charset>` ignored; a plain space joining two numbers; no stop at a comma. Each fix has a test that fails on the code before it. A second run on the real site's pages then caught one regression from the year fix ("launched on 27 March 2026 with these skills" read as a skill count); month and season names now count as year cues, with that sentence as a test |
| Code review of the positioning commit (`/code-review`) | done: 9 findings, 8 fixed, 1 left as is | 2026-10-09. Fixed: a malformed `positioning` block crashed (exit 1) instead of a message (exit 2); the intro ran past a `<p>` closed by its parent or a new list item (now an open-element stack ends it where a browser does); an exempt page under a wildcard rule was still checked; a redirecting address was checked as its target; a later `<main>` or `<title>` counted; no-break spaces in the title collapsed; patterns normalised per page; the facts default set twice. Each fix has a test that fails on the code before it. Left as is: older history files keep the 8-column header, because no 8-column version was ever released. The real-site runs give the same results after the fixes |
| Description, trigger test (skill-creator `run_loop`) | done: 20/20 | 2026-10-09: 10 requests that should use the skill and 10 near misses (link audits, the AI check, the positioning check, schema, a journalist fact sheet, a spreadsheet check), 3 runs each, 40% held out. The description scored 100% in round 1, so the loop had nothing to improve. After adding alt texts and `llms.txt` to it: 20/20 again (one query at 2 of 3 runs). Note: the skill-creator's parallel runs each add a copy of the skill with the same description, and a load of another worker's copy counted as "not triggered" (recall near 10%); a local patch counting any copy fixed the measurement. The query set is kept outside this repo, because its example domains could be real sites |
| CI | added | `.github/workflows/clean.yml`, job `facts-check-tests` (3.9, 3.12) |
| Run on a real site's pages | done, served locally | 2026-10-09: the production build of a real Astro site (14 pages), served on 127.0.0.1. Every tied number was about its fact; a deliberately wrong fact was caught in both places it appears; the run surfaced the repeated og/twitter description, fixed since. Outside sites were unreachable from the build environment, so a run over the network on a large non-Astro site is still open |
| Independent review (`independent-review`, one outside model) | done: 1 round, 6 findings, 4 fixed, 2 refuted | 2026-10-09, Kimi K3 via Melious (`--seat melious --depth normal`; Codex was not available in the build environment, and the Ollama seat answered HTTP 429). Fixed: tags inside `<template>`/`<noscript>` counted as page structure; a robots.txt answering 5xx meant "allow all"; pages cut at 5 MB without a note; `owner`/`checked` never shown. Refuted: a self-closing `<script/>` swallowing the rest of the page (HTML ignores the slash; a browser does the same); `actions/*@v7` pins (the file's other jobs use them) |
| Independent review, round 2 (Codex; the GLM and Ollama seats failed) | done: 9 findings (8 BUG, 1 RISK), all fixed or closed | 2026-10-09, `--diff --depth normal --round 2`, run from a checkout of `578a67a`. Fixed, each with a test that failed before: a redirect into a page robots.txt disallows was followed; an incomplete response ended the run; a minus sign was dropped; a sitemap index stopped at 200 files without a word; a quoted charset garbled accents; `<span>27</span>,000` read as `27 ,000`; JSON-LD inside `<template>` was read; a wrong type in the facts file crashed. Closed with evidence: `actions/checkout@v7` and `actions/setup-python@v7` exist upstream. 60 tests on Python 3.9 and 3.13. Details in the trail |
| Skill-creator evals, round 1 | done | 2026-10-09: three realistic prompts (wrong figures and an old name across a site; pages that lost their positioning term; set up a weekly check), each run once with and once without the skill against a real site's build with three planted drifts. Checks passed: 16/17 with the skill (the one miss: the environment blocked the agent's write of its report file), 17/17 without. Time and tokens favour the skill every time: 74 vs 93 s, 62 vs 72 s, 131 vs 379 s; 77k vs 98k tokens on average. Without the skill the agent wrote its own checker in 2 of 3 runs. One run showed retired phrases were not searched in image alt texts, share titles, link addresses or `/llms.txt`; fixed, with tests |

## Open decisions

- Copy `facts-check` into every scaffolded site, as `outgoing-link-audit` is? It needs no
  starter, so it is useful there too; it would change `new-website`'s copy list and count.
- A `--snapshot` mode that stores each page's text as a file in git, so the weekly run
  also shows what changed on the site (the base for Q&A and content work on large sites).
