# REVIEW — DIFF gate, PR #18, round 2 (2026-07-02, verification round)

Artifact: updated `origin/main...HEAD` diff (round-1 fix commit 17487d7 included).
Both reviewers got the round-1 BUG list, were asked to verify each fix landed +
hunt regressions, and were explicitly told NOT to come back clean out of politeness.

## Reviewers
| Seat | Tool / model | Outcome |
|---|---|---|
| cross-model 1 | codex-cli 0.142.3 / gpt-5.5 xhigh, read-only | all 10 r1 classes VERIFIED (probed the guards itself: `--bogus` → exit 2, oversize artifact → exit 2); 3 BUG · 4 RISK remaining |
| cross-model 2 | agy 1.0.14 / Gemini 3.1 Pro (High), sandbox | all 9 cited r1 classes VERIFIED; 1 BUG · 1 RISK · 1 NIT remaining |

## Dispositions (all fixed this round unless noted)
- **codex B1 + gemini R1** — `looks_like_review()` still accepted refusals ("No
  findings because I cannot access the artifact"; sentence-mentions of BUG/RISK/NIT).
  → anchored to list/heading-formatted severity entries + a refusal-about-the-reviewing-act
  rejector (plain "cannot" stays legal — real findings say "a guard that cannot fire").
  Negative-tested against codex's exact probe string.
- **codex B2** — host-family mapping was wrong for Antigravity hosts (Gemini is
  same-family there; Codex is the cross-model seat). → per-host mapping spelled out.
- **codex B3** — "local-only = tiers 3/5/6" was self-contradictory (paste = external).
  → local-only = tiers 3 + 5 only.
- **gemini B1 (argv ceiling)** — direction right, fact wrong: it claimed macOS ARG_MAX
  = 256 KB; measured 1 MB here (900 KB single arg execs fine). The REAL limit is
  Linux's per-argument MAX_ARG_STRLEN = 128 KB. → ceiling lowered 512 KB → 117 KB
  with the correct rationale. (Recorded because the gate cuts both ways: reviewer
  claims get verified too.)
- **gemini N1 + codex R7** (independent convergence) — extra positional args were
  silently dropped → now exit 2.
- **codex R4/R5** — stale drop-through/`gl=us` wording in the design record's
  historical sections → supersession markers at each flagged spot.
- **codex R6** — check_clean denylist scope: unchanged, carried as the round-1
  pending owner waiver (separate task exists for the scope fix).

## Also in this commit (owner-requested, not reviewer findings)
- Clerk procedure documented in the skill (reviewers structurally can't post to
  PRs; raw/consolidated/trail artifact split; stream-to-disk rule).
- Iterate-until-clean loop with stop conditions, incl. budget stop: BUG fixes are
  never deferrable, re-verification of fixes is.

## Verdict
All round-1 fixes independently verified by both cross-model seats. All round-2
BUGs fixed and negative-tested. **Round 3 external re-verification: DEFERRED**
(budget stop per the skill's own rule — the r2 fixes are small, guard-level, and
each negative-tested; a later verification round can be run any time). Remaining
open: the 3 owner waivers from r1 (argv `ps` visibility · check_clean scope ·
website-review Claude-isms).
