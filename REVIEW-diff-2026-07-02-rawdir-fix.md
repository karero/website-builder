# REVIEW — DIFF gate, independent_review.sh RAW_DIR fix (2026-07-02, rounds 1–2)

Artifact: working-tree diff of `skills/independent-review/scripts/independent_review.sh`.
Origin: defect hit live during PR #19's review — a caller-supplied `REVIEW_RAW_DIR`
that didn't exist made every tier's redirect fail and the run misreport as
"no reviewer available" (exit 4). Initial fix authored in a separate session
(spawned task); reviewed and hardened here. Dogfood note: round 1 was dispatched
through the fixed script itself with a deliberately non-existent `REVIEW_RAW_DIR`
— the run succeeding WAS the live functional test of the mkdir fix.

## Reviewers (version / model / sandbox)
| Round | Seat | Tool / model | Outcome |
|---|---|---|---|
| r1 | cross-model 1 | codex-cli 0.142.5, gpt-5.5/xhigh, read-only | 1 BUG · 2 RISK · 1 NIT |
| r1 | cross-model 2 | agy 1.0.15, Gemini 3.1 Pro (High), sandbox | 1 BUG (convergent w/ codex) · 2 RISK · 2 NIT |
| r1 | fresh-eyes | Claude host inline (did not author the fix) | clean; noted pre-existing `local out` dup |
| r2 | cross-model 1 | codex (as above) | r1 fixes confirmed; 2 BUG · 1 RISK on the fix code |
| r2 | cross-model 2 | agy (as above; first attempt timed out, retried) | r1 fixes ALL confirmed clean; 1 BUG (= codex r2 B1, already fixed) · 2 NIT |

## Dispositions

### Fixed + negative-tested
- **r1 codex B1 / gemini B1 (convergent)** — `mkdir -p` exits 0 on an existing
  UNWRITABLE dir, resurrecting the misreport. Fixed twice-over: r2 codex B1 /
  gemini-retry B1 showed `[ -w ]` is ALSO insufficient (writable-but-unsearchable
  dir) → final form is an actual WRITE PROBE (`: >"$RAW_DIR/.write-probe"`),
  exit 2 on failure. Tested: chmod 555 dir → exit 2; chmod 200 dir → exit 2.
- **r1 gemini R1** — a REUSED caller RAW_DIR served a previous run's partials for
  skipped tiers. Per-function `rm` was tried and rejected (cannot cover
  dispatcher-level skips like `command -v ollama && run_ollama`); final form is
  ONE central checked `rm` after the probe (r2 codex B2: unchecked rm → `|| exit 2`).
  Tested: pre-seeded stale files, all tiers skipped → dir left clean.
- **r1 gemini R2** — unconditional `cat` on a never-created `.out` leaked
  "No such file" noise; guard `[ rc -eq 0 ] && [ -s file ]` before the cat
  (mirrors run_ollama). Confirmed clean by both seats in r2.
- **r1 codex R3** — exit-4 message overclaimed (skipped tiers write no `.err`);
  reworded "for attempted reviewers". Confirmed clean.
- **r1 codex N1 / gemini N1+N2** — `mkdir --`, `printf` instead of `echo`,
  duplicate `local out` removed. Confirmed clean.

### Waiver PENDING OWNER SIGN-OFF
- **r1 codex R2 + r2 codex R3 (scope extension)** — a caller-created RAW_DIR
  inherits ambient umask; `.out`/`.err` files may be world-readable, and `.err`
  may carry local paths/auth traces beyond "content already sent to the provider".
  Proposed waiver: single-user dev machine; default RAW_DIR is `mktemp -d` (0700);
  matches the argv-visibility waiver precedent (REVIEW-diff-2026-07-02-r1.md).
  Alternative if declined: `umask 077` around RAW_DIR creation.

### Rejected, with reason
- **r2 gemini N1** (`local rc=$?` masking) — pre-existing script-wide pattern,
  functionally correct in bash ($? expands before `local` runs); gemini's own r1
  CLEAN list verified exactly this. Rule 3: outside this diff.
- **r2 gemini N2** (quote `$rc` in tests) — pre-existing style throughout; Rule 3/11.

## Residual honesty note
The two r2 one-liners (write probe, checked rm) were verified by negative tests
but NOT externally re-reviewed (gemini's retry reviewed the pre-probe state and
independently demanded the same fix; codex specified it). Deferred per
proportionality — no open BUG, waiver above is the only open item.

## Verdict
Gate satisfied (codex succeeded in both rounds; gemini seat confirmed r1 fully in
the retry). All BUGs fixed + negative-tested; one waiver pending owner sign-off.
