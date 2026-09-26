# REVIEW — PLAN gate, weekly GEO check (search-console-insights), 2026-09-26

**Artifact:** the plan now committed as `SKILL-PLAN-geo-check.md`. Revisions 1–3 were reviewed; revision 4 is the owner-directed redesign, and no plan round reviewed it.
**Branch:** `feat/geo-check`, based on `origin/main` @ `b586b4b`.
**Verbatim reviewer output:** `RAW-plan-2026-09-26-geo-check-feat-geo-check-b586b4b.md`.

## Reviewers and independence

| Seat | Tool | Family vs. host (Claude) | Rounds |
|---|---|---|---|
| C | Codex CLI, read-only sandbox | cross-model | 1–3. In round 1 the first attempt FAILED because it was run from a non-git directory; it was re-run from the worktree. |
| K | ollama-cloud, auto-detected `:cloud` tag | cross-model | 1–3 |
| F | Claude sub-agent with no shared context | fresh-eyes (same family) | 1–3 |

The gate needs at least one successful cross-model reviewer, and every round had two (C and K).

**Data release consent** (owner, in this session, quoted verbatim): "Yes, Codex + ollama-cloud (Recommended)". It covers this plan's content going to Codex and Ollama Cloud. It is session-scoped and not a standing instruction.

## Rounds

| Round | Artifact | BUG | RISK | NIT | Note |
|---|---|---|---|---|---|
| 1 | rev 1 | 8 | 23 | 10 | 41 distinct (P1–P41) |
| 2 | rev 2 | 10 | 14 | 9 | 33 distinct (Q1–Q33); mostly consequences of round-1 fixes, plus two new external facts (Sonar retirement, GSC OAuth hang) |
| 3 | rev 3 | 7 | 19 | 11 | T1–T37 below |

**Convergence (step 7).** Two components kept producing findings across rounds:
- **Exit codes:** P10 → Q2/Q3 → T4/T6
- **Homepage drift:** P11 → Q14 → T8

P11's thread therefore reached the 3-round cap still open. **Stopped: not converging on those two components.** They went to the owner as a decision.

**Owner decision** (quoted verbatim): "Redesign both, then build (Recommended)". It meant three things:
- The two components are redesigned (rev 4) instead of patched again.
- All round-3 BUGs are fixed in rev 4, and the remaining RISK/NIT items become a build checklist that the tests must encode.
- There is **no 4th plan round**. Rev 4's fixes are `locally_verified` only, and the DIFF gate on the implementation is their external re-verification. The owner signed off on that deferral with the same answer.

## Round 1 (P) — dispositions as of rev 2

Sources: C = Codex, K = ollama-cloud, F = fresh-eyes.

| id | sev | src | finding | disposition |
|---|---|---|---|---|
| P1 | BUG | C1 F-R3 | `append_rows` can't take the GEO schema | fixed: copy the pattern, own writer (Design 5) |
| P2 | BUG | F-B1 C3 | ‡ question-changed can't fire (group key) | fixed: slot + rev |
| P3 | BUG | F-B2 C4 | e2e test can't reach GEO past GSC | fixed: HOME shim + stub server + reached-guard |
| P4 | BUG | F-B3 C5 | an engine failure exits 0 | fixed: exit 6, failed samples excluded from the score |
| P5 | BUG | F-B4 | Gemini citations are redirect URLs | fixed in design; shape verified at build |
| P6 | BUG | F-B5 K1 C7 | accent stripping fails S3 | fixed: `fold()` + NFKD, either form |
| P7 | BUG | F-B6 | track.sh would hide GEO output; no trend call | fixed |
| P8 | BUG | C12 C13 | Context claims wrong (AI calls exist; CSV shared) | fixed |
| P9 | RISK | F-R1 | shell `OPENAI_API_KEY` picked up | fixed: `GEO_*` names |
| P10 | RISK | F-R2 K9 | exit-code collisions and precedence | fixed |
| P11 | RISK | F-R4 K3 K11 | fingerprint ownership, fetch failure, normalization | fixed: `--confirm`, `--check-drift`, S4b, normalize |
| P12 | RISK | F-R5 | free-tier 429s | fixed: sequential, backoff |
| P13 | RISK | F-R6 K6 | country code formats; Gemini has no location | fixed |
| P14 | RISK | F-R7 C11 K4 | model ids may hide updates | fixed: S6 scoped to reported ids, both stored |
| P15 | RISK | F-R8 | check_clean misses `sk-ant-`/`sk-proj-`/`pplx-` | fixed: widen the patterns |
| P16 | RISK | F-R9 | "AI visibility" trigger collides with ai-seo | fixed |
| P17 | RISK | F-R10 | status doc would ship in the zip | fixed: `docs/reviews/` |
| P18 | RISK | F-R11 | tests in no CI | fixed: Makefile + CI |
| P19 | RISK | F-R12 C2 | GSC failure costs the GEO week | fixed: S9 |
| P20 | RISK | F-R13 | branded "named" always true | fixed: blank |
| P21 | RISK | F-R14 | provider terms/setup unknowns | open → "To verify at build time" |
| P22 | RISK | C6 K2 F-N3 | substring host match | fixed |
| P23 | RISK | C8 | names/country change silently shifts the trend | fixed: config_rev ‡ |
| P24 | RISK | C9 | answer files vs. history can diverge | fixed: run_id, evidence first |
| P25 | RISK | C10 | onboarding says "all free", Google-first | fixed: scope the claims, GEO step + eval |
| P26 | RISK | K5 | Perplexity has no no-search mode | refuted: `disable_search` exists (Perplexity API reference) |
| P27 | RISK | K7 K14 | CSV path and dedupe key undefined | fixed |
| P28 | RISK | K8 | no URL overrides for tests | fixed |
| P29 | RISK | K10 | redaction must cover all keys | fixed |
| P30 | RISK | K12 | budget claims unchecked | refuted: measured 991 chars / 457 lines (C and F agree) |
| P31 | RISK | host | the EEA free-tier restriction was unknown | fixed: EEA note (judgment) |
| P32 | NIT | K13 | "incognito by construction" overstated | fixed: softened |
| P33 | NIT | K15 | status evidence will drift | refuted: the repo rule mandates a hand-kept table; updating it is part of each step |
| P34 | NIT | K16 | `~` under launchd | refuted: launchd user agents set HOME; track.sh already relies on it |
| P35 | NIT | F-N1 | config name case | fixed: normalize_site |
| P36 | NIT | F-N2 | `\b` fails on "C&A" | fixed: lookarounds |
| P37 | NIT | F-N4 | "positioning" vs. homepage | fixed: "homepage changed" |
| P38 | NIT | F-N5 | ‡ cause unnamed | fixed |
| P39 | NIT | F-N6 | timeouts | fixed |
| P40 | NIT | F-N7 | "1 of 4" definition | fixed |
| P41 | NIT | F-N8 | model id retirement | fixed: documented in geo-check.md |

Later changes to round-1 rows:
- P26 was re-opened by Q1.
- P10 and P19 are superseded by Q2/Q3/Q5 and then by the rev-4 exit redesign.
- P11 is superseded by Q14 and then by the rev-4 drift redesign.
- P25 is superseded by Q6.

## Round 2 (Q) — dispositions as of rev 3

| id | sev | src | finding | disposition |
|---|---|---|---|---|
| Q1 | BUG | F-B1 | Sonar is retired 2026-09-27 | fixed: Agent API; knows mode only if verified |
| Q2 | BUG | F-B2 C1 K-B1 | GEO exit 3 would turn existing jobs red | fixed: track.sh maps 3→0; S7 asserts it |
| Q3 | BUG | K-B2 K-B6 F-R4 | track.sh precedence unclear; trend rc; `set -e` | fixed: one final-exit rule; trend `\|\| echo` |
| Q4 | BUG | F-B3 | the committed plan fails the private-name denylist | fixed: names removed; denylist check before the first commit |
| Q5 | BUG | C2 | GSC's interactive OAuth can hang unattended | fixed: `--no-browser` + a test (verified in code: gsc_query.py:72,111) |
| Q6 | BUG | C3 | SKILL.md says all calls are free | fixed: the opening paragraph is in Files |
| Q7 | BUG | F-B4 | `cited_own` bool vs. count | fixed: count |
| Q8 | BUG | K-B4 | CSV escaping | fixed: `csv` module, `\|`-joined sets |
| Q9 | BUG | K-B5 | `www.` only stripped on one side | fixed: both |
| Q10 | BUG | K-B3 | e2e runs all scenarios in one run | fixed: one run per scenario (wording) |
| Q11 | RISK | F-R1 C4 | mixed umlaut + accent names miss | fixed: forms strip(fold) and strip(casefold); S3 extended |
| Q12 | RISK | F-R2 K-R3 | nobody owns the rev bump | fixed: `--set-question`; the file is written only by the script |
| Q13 | RISK | F-R3 | "no" at S5 leaves the run red forever | fixed: `--confirm` path |
| Q14 | RISK | F-R5 C5 | bot-wall pages → permanently red / a false baseline | fixed: a fetch failure doesn't raise the exit; `--set-question` shows the extracted text |
| Q15 | RISK | F-R6 | `make check` would need `requests` | fixed: a separate `make test` |
| Q16 | RISK | F-R7 | the ~20/day free tier can't fit a rerun | fixed: Flash-Lite default |
| Q17 | RISK | F-R8 | ok=0 rows / denominators in the trend | fixed |
| Q18 | RISK | C6 F-N3 | one model cell for 3 samples | fixed: per-sample model in the answer header; `models_reported` set |
| Q19 | RISK | K-R2 | fingerprint vs. detector version | refuted: the fingerprint hashes page text, not detector output; the detector version is only in config_rev |
| Q20 | RISK | K-R1 | a GSC skip rc 3 masks GEO | refuted: gsc_query.py never exits 3 (its exits are 1, 2, 4) |
| Q21 | RISK | K-R4 | failed vs. not-set-up look the same | fixed: the header gives checked / failed / not set up |
| Q22 | RISK | K-R5 | S2 is flaky live | fixed: scenarios run on stubs; the live smoke test is separate |
| Q23 | RISK | K-R6 | "bare question" misread | fixed: clarified |
| Q24 | RISK | K-R7 | €0 scoped only to Gemini | fixed |
| Q25 | NIT | F-N1 | the shim must pass `_history.py` through | fixed |
| Q26 | NIT | F-N2 | same-day ordering | fixed: order by run_id |
| Q27 | NIT | F-N4 | ‡ is ambiguous across the two trends | fixed: cause in words |
| Q28 | NIT | F-N5 | exit 3 missing from precedence; no fingerprint | fixed |
| Q29 | NIT | F-N6 | standalone key loading | fixed |
| Q30 | NIT | F-N7 | a stray base-URL override leaks a key | fixed: `GEO_TEST_MODE` only |
| Q31 | NIT | F-N8 | Bing vs. GEO fail-loud conflict | noted: follow-up (Rule 7) |
| Q32 | NIT | F-N9 F-N10 | enumerations / SKILL sections not updated | fixed: Files |
| Q33 | NIT | K-N1 K-N2 K-N3 | genitive note; exact env var in the hint; run_id uniqueness | fixed |
| — | note | C | wrapper text flagged as prompt-shaped | acknowledged: the round-3 wrapper is shortened to a neutral note |

**Correction.** Q5 says "verified in code: gsc_query.py:72,111". That was wrong. `interactive=False` raises `RuntimeError` (gsc_query.py:97-100), and `main()` doesn't catch it. The author read the docstring, not the branch. See T1.

## Round 3 (T) — dispositions in rev 4

| id | sev | src | finding | disposition |
|---|---|---|---|---|
| T1 | BUG | F-B1 C2 | `--no-browser` doesn't exit 2: RuntimeError and RefreshError are uncaught | fixed: `main()` catches both → exit 2; tests for each case (locally_verified: the code was read at gsc_query.py:92-111, 495) |
| T2 | BUG | F-B2 | the description would exceed 1024 chars (~1065) | fixed: cut ≥45 chars; `check_skill_budgets` added to the checklist |
| T3 | BUG | F-B3 C1 | no command creates or updates the config | fixed: `--init`, `--set-names` |
| T4 | BUG | F-B4 C6 K4 F-R8 | a GEO or trend crash falls through to exit 0 | redesigned: problem list; any unexpected rc is a problem |
| T5 | BUG | K1 | Bing history-gap handling described inconsistently | fixed wording. Bing rc 4 IS handled today (track.sh:69-71); only other Bing errors are swallowed, which is a follow-up. |
| T6 | BUG | K2 | exit 4 + 6 collapse hides one of them | redesigned: every problem printed; one "problems" exit |
| T7 | BUG | C8 | "is committed" said before the commit | fixed: rev 4 is the committed file |
| T8 | RISK | C3 F-R5 K5 | HTTP-200 bot walls → false drift / false baseline / no escalation | redesigned: drift is a warning only; a page without a configured name/domain is "unreadable"; `--confirm` refuses such a page; the interactive session checks every time |
| T9 | RISK | C4 | one fingerprint, but per-slot question changes | redesigned: the fingerprint covers the question set; `--confirm` runs after every slot is reviewed |
| T10 | RISK | C5 | `_history.py` unguarded under `set -e` | fixed: guarded; entry test with a GSC fail + history fail |
| T11 | RISK | C7 | a failed latest run shows an old comparison as current | fixed: latest-attempt status + comparison dates |
| T12 | RISK | F-R1 | the S9 e2e test can't catch a missing `--no-browser` | fixed: the shim records argv |
| T13 | RISK | F-R3 | a RefreshError is the real weekly failure; Testing-mode tokens may expire | fixed: tested; the expiry is a follow-up (unverified) |
| T14 | RISK | F-R4 | a failed same-day rerun erases a good row | fixed: never replaced by a row with fewer ok |
| T15 | RISK | F-R6 | CI `pip install` hits PEP 668 | fixed: own job with setup-python |
| T16 | RISK | F-R7 | curly apostrophe / hyphenated names missed | fixed: strip() maps them; S3 extended |
| T17 | RISK | F-R9 | `GEO_TEST_MODE` from `.env` still leaks a key | fixed: loopback hosts only |
| T18 | RISK | F-R10 | model RPD limit vs. grounding limit | open → verify at build (both limits) |
| T19 | RISK | K3 | overlapping launchd runs race | refuted: launchd runs one instance per label; the CSV write is locked; answers are per run_id |
| T20 | RISK | K6 | title/desc/H1 misses body changes | addressed by the redesign: the interactive check reads the whole homepage + POSITIONING.md |
| T21 | RISK | K7 | config present + no keys stays green | fixed: S7b, a problem |
| T22 | RISK | K8 | GSC rc hides GEO problems | redesigned: all problems printed |
| T23 | RISK | K9 | question text through a shell string | fixed: `--text-file`/stdin |
| T24 | RISK | K10 | Makefile vs. CI interpreter | fixed: `PYTHON ?=`; the CI job sets up its own |
| T25 | RISK | K11 | fixtures trip the widened key patterns | fixed: placeholder keys that don't match |
| T26 | RISK | K12 | dedupe date semantics | fixed: UTC date |
| T27 | NIT | F-N1 | SKILL.md cost paragraph is 38-45 | fixed |
| T28 | NIT | F-N2 | exits for no fingerprint / partial failure / budget unspecified | fixed: homepage states are warnings; a budget cut-off is a failed sample |
| T29 | NIT | F-N3 | run_id format | fixed |
| T30 | NIT | F-N4 | rc 3 vs. no keys message | fixed: S7 vs. S7b |
| T31 | NIT | F-N5 | cited_own in knows mode | fixed: blank |
| T32 | NIT | F-N6 | host normalization (case, dot, port, IDNA) | fixed |
| T33 | NIT | F-N7 | `.PHONY`; "CI runs both" | fixed |
| T34 | NIT | F-N8 | `SKILL-PLAN-` prefix precedent | refuted: `SKILL-PLAN-seo-reposition.md` exists here, and package.sh:75 names the prefix |
| T35 | NIT | F-N9 F-N10 F-N11 | S2 wording; S4b not in e2e; "no refresh token" wording | fixed |
| T36 | NIT | K13 | `--set-question` syntax | fixed: flags |
| T37 | NIT | K14 K15 K16 | `make test` gating; denylist in CI; Perplexity knows | fixed (CI job gates merge); refuted for the denylist (private by design, so it can't live in a public repo); already conditional for Perplexity |

## Status at close

- **BUGs:** all fixed in rev 4 (`locally_verified`), or refuted with reasoning. None open.
- **RISK/NIT:** fixed in rev 4, refuted, or open-for-build (T18, plus the "To verify at build time" list). Their external re-verification is deferred to the DIFF gate by owner sign-off (above).
- **Verdict:** PLAN gate closed by owner decision after "stopped: not converging" on two components. **Last round not re-verified.**
