# Plan: facts-check, one approved facts list against every page of a live site

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

## Status

| Step | State | Evidence |
|---|---|---|
| Script and SKILL.md | built | `skills/facts-check/` |
| Scenarios 1 to 13 | done (stub site on 127.0.0.1) | `scripts/tests/test_facts_check.py`, 33 tests, Python 3.9 and 3.13 |
| Code review (`/code-review`, one round) | done: 10 findings, all fixed | 2026-10-09. Image and video entries read as pages; a run that read no page reported clean and wrote a zero history line; four-digit counts skipped as years; inline tags splitting numbers; sitemaps cut at 5 MB; `--only` applied after the cut; numbers in JSON-LD dropped; `<meta charset>` ignored; a plain space joining two numbers; no stop at a comma. Each fix has a test that fails on the code before it. A second run on the real site's pages then caught one regression from the year fix ("launched on 27 March 2026 with these skills" read as a skill count); month and season names now count as year cues, with that sentence as a test |
| CI | added | `.github/workflows/clean.yml`, job `facts-check-tests` (3.9, 3.12) |
| Run on a real site's pages | done, served locally | 2026-10-09: the production build of a real Astro site (14 pages), served on 127.0.0.1. Every tied number was about its fact; a deliberately wrong fact was caught in both places it appears; the run surfaced the repeated og/twitter description, fixed since. Outside sites were unreachable from the build environment, so a run over the network on a large non-Astro site is still open |
| Independent review (`independent-review`, outside models) | owner's choice | not run |

## Open decisions

- Copy `facts-check` into every scaffolded site, as `outgoing-link-audit` is? It needs no
  starter, so it is useful there too; it would change `new-website`'s copy list and count.
- Add a stack-independent positioning check of live pages (each page's term in title,
  description and heading) as a second mode, reusing the page reader? Named as the next
  gap in the same showcase.
