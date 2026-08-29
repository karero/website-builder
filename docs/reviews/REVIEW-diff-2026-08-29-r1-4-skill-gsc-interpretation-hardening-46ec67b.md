# REVIEW — DIFF gate, search-console-insights careful-interpretation hardening (2026-08-29, rounds 1–4)

Artifact: branch `skill/gsc-interpretation-hardening` vs `origin/main` (3db064f), excluding
`docs/reviews/` per the trail-exclusion rule. Reviewed HEADs per round: r1 `6e60c26`,
r2 `7b43044`, r3 `6e7b0ce`, r4 `e94c253`. Final content HEAD at close: `46ec67b`
(round-4 fixes — locally verified only, see "Closing note").

Origin: a session review of the skill found that the 2026-08-27 "reading the numbers"
framework had codified one caught mistake slightly wrong (page-level sum blessed as "the"
site-wide figure) and left the larger interpretation-error classes uncovered. This branch
fixes the two structural gaps (property-level totals; query↔page attribution drill-downs)
plus doctrine, tracker, and messaging hardening across 10 files.

Consent/permissions (closeout audit duty): Codex and ollama-cloud each hold standing
per-destination consent for this repo, evidenced durably in-repo by the committed verbatim
captures `docs/reviews/RAW-diff-2026-08-29-r1-pr80.md` / `-r2-pr80.md` (PR #80) and earlier
trails. WORKTREE-WRITE and BRANCH-COMMIT: atom A — this session created both the worktree
`../website-builder-gsc-interpretation` and the branch. No PR exists yet, so POST
AUTHORITY / GATED-THIS-DIFF stamping is deferred to the PR when the owner approves opening
one; the raw captures and this trail are committed on the branch so the PR carries them.

## Reviewers (version / model / sandbox)

| Round | Seat | Tool / model | Outcome |
|---|---|---|---|
| r1 | cross-model 1 | Codex CLI (gpt-5.6-sol, read-only) | **no output — usage quota**; retried r2 |
| r1 | cross-model 2 | ollama-cloud glm-5.3-flash:cloud | 1 BUG · 4 RISK · 5 NIT + unverifiables |
| r1 | fresh-eyes | Claude subagent, no shared context, artifact-only | 1 BUG · 5 RISK · 4 NIT (empirically demonstrated) |
| r2 | cross-model 1 | Codex (gpt-5.6-sol, read-only) | verified 6/8 r1 fixes; 6 BUG · 3 RISK new |
| r2 | cross-model 2 | ollama-cloud glm-5.3-flash | 0 BUG · 3 RISK · 3 NIT; refutations A–E respected |
| r3 | cross-model 1 | Codex (as above) | verified 8/12 r2 fixes; 4 BUG · 1 RISK |
| r3 | cross-model 2 | ollama-cloud (as above) | 0 BUG · 1 RISK · 6 NIT; both refutations independently re-derived and upheld |
| r4 (scoped) | cross-model 1 | Codex (as above) | all 6 r3 fixes verified (5 VERIFIED, 1 propagation gap); 4 BUG-labeled · 1 RISK residuals |
| r4 (scoped) | cross-model 2 | ollama-cloud (as above) | 3 RISK · 4 NIT |

Round 1 ran degraded on the external half (single cross-model reviewer) — not by choice:
Codex hit its quota mid-run. The gate's independence requirement was still met each round
(ollama/GLM ≠ host family). Raw verbatim output per round:
`RAW-diff-2026-08-29-r{1,2,3,4}-skill-gsc-interpretation-hardening-<sha>.md` (home paths
redacted). The r1 fresh-eyes verbatim is not separately captured; its findings are fully
itemized below (f1–f10).

## Convergence

BUG+RISK per round: r1 **7** → r2 **9** (new scrutiny of new code — healthy per 7(a)) →
r3 **5** (one convergent substantive: legacy-CSV migration) → r4 **~6, all narrow**
(edges of the r3 migration code, capped-pull wording, phrasing propagation). Findings
consistently landed on code the previous round's fixes added (7(b)-passing); no oscillation
(7(c)) — no verified fix was re-broken in any round. Stopped after r4 fixes under
Procedure 6(c): every finding fixed or refuted, external re-verification of the final
(r4-fix) commit deferred.

## Dispositions — round 1 (found against 6e60c26, fixed in 7b43044)

Fresh-eyes = f, ollama = o. Verification statuses: LV = locally_verified (author
reproduced/demonstrated), XV = externally_reverified (a later round confirmed).

- **f1 BUG** `_history` thin-marker used `max()` — a fat-prev/thin-now move (the exact
  "AI-Resources-dropped" misread class) went unmarked. Fixed: `min()` over
  position-bearing sides. LV+XV (r2 Codex probe; r3 claim table).
- **f2 RISK** "no query rows" caveat gated on page rows — silent when only property data
  existed. Fixed: unconditional past the gate. LV+XV.
- **f3 RISK** 0/0 property row misreported as "totals unavailable". Fixed: distinguished;
  further corrected r2→r3 (all-zero rows = emptiness, not divergence). LV+XV.
- **f4/o4 RISK** clicks dropped from the mismatch checks. Fixed r1; hardened r2 (zero-safe,
  two-directional); split r3 (sitelinks = impressions-only; clicks → anomaly message).
  LV+XV (r4 Codex claim 4 VERIFIED).
- **f5 RISK** empty `--page` drill blamed anonymization; exact-URL-match pitfall named
  first now. LV+XV.
- **f6/o3 RISK** 90→28 tracker window level-break undocumented. Fixed: SKILL caveat (r1),
  then window+country recorded in the CSV schema + `‡` flag (r2), then in-place legacy
  migration (r3), then migration edge-cases (r4). LV+XV through r4.
- **o1 BUG** GSC filter `groupType` defaults to OR, so combined filters union. **REFUTED
  empirically**: live API returned the intersection for country+page (1 row/1 impr vs
  1/120 page-only and 34/123 country-only). `groupType: "and"` set explicitly anyway so
  it never needs re-litigating. Upheld independently by r3 ollama and r4.
- **o2 RISK** history CSV may lack `query`/`impressions` columns. **REFUTED**: the schema
  is `_history.FIELDS`, used by both writers; both columns exist. (The *values* concern
  resurfaced r3 as o-NIT and was fixed: `_impr` returns None for blank/garbled.)
- **o NIT** bing else-branch could quote an empty page-sum. **REFUTED**: that branch runs
  only when both pulls have rows (`if not page_rows / elif not rows / else`). Re-raised
  r4 (o3) with no new evidence — disposition unchanged, pooled per 7(c).
- **o unverifiables** (insights.py calling build_report; evals 1–5 stale doctrine)
  **REFUTED** by direct reading. Property-level aggregation semantics **CONFIRMED** live:
  property 1,295 < page-sum 1,456 < consistent with by-page counting; query-sum 364.
- f7–f10, o5 NITs (docstring count, top-25 promise, bing legend anchoring, worked-example
  attribution, row-cap note) — all fixed r1–r2. The r2 Codex re-raise of the bing legend
  ("must gate on an actual arrow") **REFUTED**: the damping note belongs on every rendered
  bing comparison including `→ 0` — a flat arrow on a ~6-month aggregate is exactly where
  the caveat matters; r3 ollama concurred, r4 Codex claim A VERIFIED.

## Dispositions — round 2 (found against 7b43044, fixed in 6e7b0ce)

- **BUG** eval 6 rewarded 123/150 without stated attribution → prompt now states the
  `--query` drill-down fact. XV (r4 claim 1 VERIFIED).
- **BUG** low-CTR heading/doctrine still pre-judged "title/meta problem" → reframed as
  snippet/SERP investigation; propagation completed across r3–r4 (frontmatter, playbook,
  evals, module docstrings, bing heading, reference row). Final sweep LV.
- **BUG** "cannibalization evidence" overclaim → benign explanations named; ordering fixed
  r3 (benign first). XV (r4 claim 3).
- **BUG** directional/zero-guard gaps in mismatch warnings → zero-safe `_div`, both
  directions, then r3 metric-class split. XV (r4 claim 4).
- **BUG** all-zero rows produced a false "disagree outright" → emptiness gate keys on
  zero data. XV (r3 claim 5).
- **BUG** GSC inclusive dates: `--days N` pulled N+1 days (pre-existing) → `end-(N-1)`,
  `--days ≥ 1` validated, in both callers. XV (r3 claim 6, r4).
- **RISK** 25k row cap vs "ceiling"/anonymization claims → row-cap note (r2), softened to
  "may be partial" (r3), capped labels + "and/or truncation" (r4). LV.
- **RISK** config changes unrecorded in history → window+country columns + `‡` (r2),
  migration (r3), edges (r4). LV.
- **BUG** insights caveat only on Top-10-boundary disagreements → prints under the table
  whenever both engines have data. XV (r3 claim 9).
- Totals pull isolated in its own try (ollama r3-2). XV (r3 claim 9).
- Symmetric page-level-missing caveat (ollama r3-1). XV (r3 claim 10).
- Country-filtered property label (ollama r3-4). XV (r3 claim 11).

## Dispositions — round 3 (found against 6e7b0ce, fixed in e94c253)

- **BUG/RISK convergent** legacy 7-column CSVs swallow the new config columns → in-place
  migration in `append_rows` (temp file + atomic replace); blank-vs-recorded config counts
  as a change. XV (r4 claim 1 VERIFIED) — semantics reworded r4 per below.
- Remaining items (message ordering, cov gating, bing direction-neutrality, row-cap
  wording, phrasing propagation, `any()` tautology, `_impr` None) — all fixed; r4 claim
  table: 5 of 6 VERIFIED, propagation gap closed in the r4 fix commit.

## Dispositions — round 4 (found against e94c253, fixed in 46ec67b — LV only)

- **Codex 4 BUG** zero-byte CSV got no header → `getsize == 0` counts as new. LV (test Z).
- **Codex 5 / ollama 1 RISK** migration too broad (foreign headers rewritten, BOM breaks
  the match, `extrasaction` drops columns) → migrate only the exact legacy 7-column
  schema, read utf-8-sig, leave any other header untouched with a stderr note. LV
  (tests Z2, Z3).
- **Codex 3 BUG / ollama 5 NIT** `‡` claimed a definite change against a pre-schema row;
  SKILL simultaneously understated that it fires → legend and SKILL now say "changed or
  previously unrecorded"; only pre-schema↔pre-schema moves are unflaggable. LV.
- **Codex 1 BUG** capped pulls: anonymization stated definitively, capped fallback called
  a ceiling → "and/or truncation" when capped; capped fallbacks labeled "partial, bounds
  unknown". LV (test Z4).
- **Codex 2 / ollama 4+6 BUG/NIT** last unconditional "title/meta targets" phrasing →
  swept via grep across the whole skill; rewrite is everywhere conditional on the
  live-SERP check result. LV.
- **ollama 2 RISK** unguarded `now.get(...)` could crash if `now` were None. **REFUTED**:
  `now = rs[-1]` of a non-empty group — structurally never None (ollama's own caveat
  anticipated this).
- **ollama 3 RISK** bing else-branch reachable with empty page_rows. **REFUTED** — same
  disposition as r1 (branch requires both pulls non-empty); no new evidence.
- **ollama 7 NIT** `--page`+`--query` together AND both filters into each drill section.
  **REFUTED**: the two drills are separate API calls, each passing only its own filter
  (+ country) — see `main()`.
- Both reviewers' "prompt injection" flags on the verification preamble: the preamble IS
  this gate's round protocol (prior findings + scope), sent by the host, not adversary
  content; noted each round, no action.

## Verification evidence

- 55-check offline suite (report branches, warnings both directions, zero-safety, drills,
  emptiness, striking floor, trend markers, CSV migration incl. zero-byte/foreign/BOM,
  capped labels) — all green at 46ec67b. Suite lives in the session scratchpad; it is
  fixture-based on `build_report`/`print_trend` and can be committed as a real test file
  if wanted.
- Live read-only runs against the connected production property (domain redacted here per
  the public-repo rule): three-totals output confirmed the doctrine (property 1,295 ≤
  page-sum 1,456; query-sum 364 = 28% coverage; page clicks 18 = property clicks 18,
  matching "clicks attribute once"); `--page`/`--query` drill-downs returned exact
  attribution; the 28-day window header shows exactly 28 inclusive days; the
  filter-semantics AND test (intersection, not union).

## Closing note (Procedure 6(c))

Rounds 1–3's fixes are externally re-verified by later rounds. The round-4 fix commit
(46ec67b) closed out with local verification only — recorded here explicitly: the closing
edits were NOT externally re-verified. Every BUG is fixed or refuted; every RISK/NIT is
fixed or refuted; no waivers were needed. A further scoped external pass on
`e94c253..46ec67b` is cheap to run on request.
