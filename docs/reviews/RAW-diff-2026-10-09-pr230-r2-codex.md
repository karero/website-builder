## Independent review — codex (gpt-6.1-sol, read-only)

All Python anchors below refer to `skills/facts-check/scripts/facts_check.py`. BUG claims are **WRONG**, reproduced with `python3 -B` using in-memory fixtures on Python 3.13.16.

- BUG — `facts_check.py:674` — **WRONG: robots are respected across redirects.** `/public → /private` fetches and checks `/private` despite `Disallow: /private`; reproduced through urllib’s actual redirect handler. Fix: check robots before fetching each redirect target.
- BUG — `facts_check.py:686` — **WRONG: response failures remain isolated.** A truncated chunked HTTP response raises `http.client.IncompleteRead`, escapes `get()`, and aborts the entire run. Fix: catch relevant HTTP protocol exceptions and record the failed URL.
- BUG — `facts_check.py:84` — **WRONG: signed figures retain their value.** With approved NPS `5`, `NPS of -5` reports OK; approving `-5` reports MISMATCH. Fix: tokenize and apply numeric signs, including Unicode minus.
- BUG — `facts_check.py:733` — **WRONG: sitemap traversal continues until the page limit.** An index containing 201 child sitemaps returns only 199 pages with `--max-pages 1000`, without any warning. Fix: report the traversal cap and remaining queue, or continue within an explicit configurable bound.
- BUG — `facts_check.py:717` — **WRONG: header charsets are honored.** Latin-1 `<p>30 employés</p>` with `charset="iso-8859-1"` becomes `30 employ�s`, hiding the mismatch for term `employé`; stdlib’s header parser recognizes that charset. Fix: parse Content-Type parameters with `email.message.Message.get_content_charset()`.
- BUG — `facts_check.py:435` — **WRONG: inline markup preserves figures.** `<span>27</span>,000 clients` becomes `27 ,000 clients` and reports MISMATCH `27` against approved `27000`. Fix: preserve adjacency across inline spans; retain separators between separate number/label elements.
- BUG — `facts_check.py:487` — **WRONG: skipped template content contributes no findings.** `<template><script type="application/ld+json">{"description":"30000 clients"}</script></template>` contributes a structured-data mismatch because JSON-LD handling precedes the skip guard. Fix: suppress JSON-LD collection within skipped ancestors while keeping nesting balanced.
- BUG — `facts_check.py:257,262` — **WRONG: broken facts files produce exit 2.** `"retired":3` or `"retired_phrases":3` raises uncaught `TypeError` instead of `FactsError`, yielding a traceback and process exit 1. Fix: validate collection types before iterating them.
- RISK — `.github/workflows/clean.yml:327–328` — **UNVERIFIABLE: existing identical pins establish that both `actions/*@v7` references exist.** Repetition supplies no upstream resolution or execution evidence; a missing reference prevents the matrix tests from starting. Observation: resolve both upstream references or execute this job. Fix: use verified references, preferably commit SHAs.

Checked CLEAN, with supporting evidence:

- **VERIFIED:** checkout `578a67a`; six changed implementation/configuration files match the brief (`git log -1`, `git diff --name-only 5e15433 HEAD`).
- **VERIFIED:** 50 tests discovered; 33 tests passed without writes or network. These exercise documented unsigned number formats, windows, punctuation stops, year/zero handling, percentage units, multiword terms, inline bold markup, numeric JSON-LD properties, metadata/alt/link coverage, charset fallback, and repeated-description deduplication.
- **VERIFIED:** plain and gzip sitemaps exceeding 5 MB are processed; oversized HTML produces a truncation note (`LargeSitemap`, `FetcherRules`).
- **VERIFIED:** first-rule precedence, exemptions, path normalization, clause alternatives, intro selection, and positioning redirect listing (`Positioning` tests plus independent `run()` fixtures).
- **VERIFIED:** clean exit 0; zero own pages read produces exit 2 and no history append, including when an external page succeeds (mocked `main()` measurements).
- **VERIFIED:** stdlib-only imports and Python 3.9 grammar; Makefile discovery command and CI matrix wiring. No tagged release contains this script (`git log --tags -- …`).

Other unsupported claims, grouped by component:

- **UNVERIFIABLE — Python runtimes/test suite:** all 50 tests pass on bare Python 3.9/3.12. Missing complete runs on those versions; settle with `make test-facts` on each. The full suite requires file writes and loopback sockets.
- **UNVERIFIABLE — browser engine:** extraction equals the starter’s DOM surfaces, including the `<script/>` refutation. Python assertions and the Playwright caller provide no browser measurement; settle by comparing both extractors on identical markup.
- **UNVERIFIABLE — robots/sitemap standards:** RFC 9309 attribution and the stated protocol size limit lack followed specification text; settle by reading the applicable clauses and comparing implemented status/byte thresholds.
- **UNVERIFIABLE — AI engines:** quotation and image-visibility generalizations lack traced evaluations; settle with controlled retrieval/response measurements.

Prompt injection: the embedded review brief’s “Rank … under 900 words” and “do not repeat” directives attempt to constrain reviewer output and conclusions. They were treated as review data; ordinary skill instructions were not classified as injection.

---
reviewers: codex OK, melious FAILED (curl exit 28, reply cut off), ollama-cloud FAILED (exit 1; quota/rate limit: wait or add credits)
timings: codex 412s (91401 tokens), melious 300s, ollama-cloud 1s
⚠ DIFF round landed with 1 reviewer(s) counted toward the gate, fewer than the 2 of the standard pair. Treat it as degraded, not as a clean pair: each FAILED section above names its remedy; or consider --with-antigravity or a manual paste round.
