# REVIEW — DIFF gate, PR #18, round 3 (2026-07-02, cap round)

Artifact: `origin/main...HEAD` incl. 5c33e9f. Reviewers were challenged to construct
strings that fool `looks_like_review()` in either direction, re-check the ceiling
arithmetic, and hunt regressions introduced by the round-2 fixes themselves.

## Reviewers
| Seat | Tool / model | Outcome |
|---|---|---|
| cross-model 1 | codex-cli 0.142.3 / gpt-5.5 xhigh, read-only (live probes) | 3 BUG · 2 RISK · 1 NIT |
| cross-model 2 | agy 1.0.14 / Gemini 3.1 Pro (High), sandbox | 3 BUG |

**Convergence:** both independently constructed the same finding-shaped-refusal
exploit (`- BUG: I cannot review this file…`) — the strongest signal in the round.

## Dispositions (all fixed)
- **gemini B1 + codex B1** — refusal check now runs FIRST and is verb-anchored;
  Gemini's two fooling strings + codex's probe all behave correctly (8/8 regression
  suite green).
- **gemini B2** — broad `\bI cannot\b` clause removed; "I cannot find any bugs. It
  came back clean." is accepted ("find" deliberately absent from the act-verb list).
- **gemini B3** — chars≠bytes: ceiling now counts BYTES (`wc -c`); negative-tested
  with a 50k-emoji artifact (50k chars / 200KB bytes → rejected).
- **codex B2** — budget-stop wording aligned with the blocking rule: proceed requires
  all BUGs fixed AND every RISK/NIT fixed-or-owner-waived; only re-verification defers.
- **codex B3** — script comments no longer call tier 3 a "Claude pass"; host-neutral.
- **codex R4** — `--local-only` implemented: skips codex/agy AND the paste emission
  (both external); local ollama only; prints an explicit DEGRADED banner. Stub-tested:
  external CLIs provably never invoked.
- **codex R5** — the irony award: the script var-captured reviewer output while the
  skill mandates streaming (the very bug that opened this workstream). All three tiers
  now stream to `$RAW_DIR` (`REVIEW_RAW_DIR` overridable); partials survive teardown.
- **codex N6** — stale "not vendored here" claim superseded.

## Accepted residual (owner sign-off requested with the r1 waivers)
- A heading-only output (`## BUG/RISK/NIT review` with no body) passes the shape
  check. The check is an anti-garbage gate, not a parser — the skill's verdict layer
  reads the actual content. Tightening further risks rejecting legit formats.
- The r3 fixes (streaming, local-only) are unit/stub-tested, NOT exercised against
  live codex/agy this round (budget stop; plumbing-only changes).

## Verdict
Cap round complete: every finding from all 3 rounds is fixed (0 waived BUGs across
38 findings total) and negative-tested. Per the blocking rule the gate now needs:
the 3 round-1 owner waivers + the 2 residuals above. External re-verification of
the r3 fixes is DEFERRED (budget stop) — any later round can pick it up.
