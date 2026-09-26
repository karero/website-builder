# Independent review — DIFF gate — PR #119, round 2 (verification)

**Artifact:** generated from HEAD at review time, `docs/reviews/` excluded, with round 1's
findings and their claimed dispositions as a preamble.
**Session:** `epic-cohen-c64754`. **Date:** 2026-09-26. **Round:** 2.

## Reviewer seats

| seat | model | result | counts toward gate |
|---|---|---|---|
| codex | `gpt-6-astra`, read-only | OK | yes — cross-model |
| ollama-cloud | `kimi-k2.7-code:cloud` | **FAILED** — `429 ... weekly usage limit` (again) | no |
| fresh-eyes (host sub-agent) | Claude, no shared context, read-only + tools | OK | no — same family |

**Round status: DEGRADED again — 1 of 2 external seats.** ollama-cloud's limit is weekly and
had not reset. Recorded, not papered over.

## Verdict on round 1's findings

| id | claimed | round-2 verdict |
|---|---|---|
| F1 `whats-new.sh:165` | fixed | **VERIFIED CLEAN** by both seats; hostile-CDPATH execution selected the real directory |
| F2 the guard | fixed | **WRONG** — see below. The guard was the problem, not the fix |
| F3 stale artifact | fixed | verified generated from HEAD; one disclosure gap, see N9 |
| F4 README `docs/` | fixed | **VERIFIED CLEAN**, 9-for-9 |
| F5 `check_ship_push.sh` | left open | still open; codex ranks it **BUG**, not NIT. Pre-existing, not a regression |
| F6 `dirname --` | fixed | **VERIFIED CLEAN** |

## The guard failed its own verification round

Both seats attacked `scripts/check_cdpath_safe.sh` — code introduced by round 1's own
remediation — and it did not survive. **Every claim below was reproduced by the host before
being accepted; none was taken on the reviewers' word.**

| what | result |
|---|---|
| broken scanner (`xargs` → 127) | printed **OK**, exit 0 — a false pass |
| `CDPATH= cd -- "..."; cd "$(dirname "$0")"` (second cd, same line) | **evaded**, exit 0 |
| backslash-newline continuation | **evaded**, exit 0 |
| `pushd "$(dirname "$0")"` | **evaded** (bash's `pushd` does consult CDPATH) |
| `SELF=$(dirname "$0"); cd "$SELF"` | **evaded** |
| `cd "${0%/*}"` | **evaded** |
| `CDPATH="" cd -- ...` (safe) | **false FAIL** |
| `unset CDPATH; cd ...` (safe) | **false FAIL** |
| extensionless `hooks/pre-push` (tracked, shipped, wired as a git hook) | never scanned — `-name '*.sh'` |
| **reverting F1 itself** | **exit 0 — the guard missed the very bug that started this PR** |

The last row is the decisive one. A guard whose commit message says the fix "cannot silently
regress", and which does not catch the motivating regression, is worse than no guard: it
converts an open risk into a false assurance.

The host's own "hardening" comment from round 1 was also **false**. It claimed the
`scanned -lt 10` floor covered a broken scan. It did not: `scanned` came from a second,
independent `find` and never touched `grep`, so removing `grep` alone still printed OK. The
repo already handles this correctly one file over — `check_model_agnostic.sh` documents that
grep is tri-state and an I/O error must not fall through to the OK line.

**Disposition: redesigned, not patched.** Per the gate's step 7, patch-churn on a wrong design
converges never. Three evasions and two false positives in a single pass is a design verdict,
not a bug list. The owner was given the choice (redesign / drop the guard / keep patching) and
chose redesign. Per step 6 that starts a **new artifact**; a round on it is round 1 of that
artifact, not round 3 of this one.

### What replaced it

A behavioural guard. Each subject script is run twice — once clean, once with a hostile
`CDPATH` — and the two runs are compared to **each other**, not to a known-good result. That
last detail is deliberate: a subject failing for its own unrelated reason fails identically
both times, so a leaked model name no longer turns this job red as well (round-2 NIT 7).

There is no regex, so none of the evasions above exist. Plus:

- a **regression case for F1 specifically** — a real `./myproj` and a same-named decoy on
  `CDPATH`, asserting the resolved project is the real one;
- a **completeness check** — every shebang-discovered script must be in `SUBJECTS` or in
  `NOT_RUN` with a written reason, so a new script forces a choice instead of being silently
  uncovered. This is `check_template_coverage.sh`'s bucket discipline, applied here. It caught
  three template scripts on its first run that the host had missed.
- discovery by **shebang**, not a `*.sh` glob, so extensionless scripts count (round-2 RISK 3).

**Re-trapped, 7 for 7.** F1 reverted → 1. `${0%/*}` → 1. `SELF=$(dirname $0); cd "$SELF"` → 1.
`pushd` → 1. New unlisted script → 1. `CDPATH=""` (safe) → 0. `unset CDPATH` (safe) → 0.
Every case that defeated the regex version is caught; both false positives are gone.

## Other round-2 findings

- **N9 — the round-2 artifact said "the full diff follows" but excluded `docs/reviews/`.**
  Correct catch, and the same class as F3. The exclusion is the gate's own prescribed practice
  (it stops reviewers reviewing the trail instead of the change); the defect was not disclosing
  it in the preamble. Noted for future rounds.
- **N10 — the README `docs/` block advertised `DECISIONS_PENDING.md` as handoff material.**
  Accurate (it does ship) but misleading. Reworded as maintainer-internal. The `scripts/` block
  ordering was also fixed to keep the `check_*`-then-`test_*` grouping.
- **Codex flagged the verification preamble itself as prompt injection** — "confirm each fix"
  and "do not oblige out of politeness" address the reviewer directly. It treated them as
  untrusted and reviewed anyway. Not a defect: that preamble is prescribed by the gate. Worth
  recording that a reviewer noticing it is correct behaviour, not a malfunction.

## Convergence (step 7)

Round 1: 1 BUG, 3 RISK, 2 NIT. Round 2: 2 BUG, 3 RISK, 5 NIT.

The count rose, and that is **healthy, not divergence**: round 2's findings are almost entirely
against code round 1's remediation introduced, which is an explicit (b)-PASS — genuinely new
ground, not re-covered ground. No oscillation: nothing round 1 fixed was re-broken. The actual
subject of the PR (the CDPATH conversions, F1, F4, F6) verified clean in both rounds and has
not moved since.

## Verification status (step 6)

The CDPATH conversions, F1, F4 and F6 are `externally_reverified` — confirmed clean by an
independent round.

The **redesigned guard is `locally_verified` only.** It is new code written after round 2's
reviewers reported, so no external seat has seen it. Saying otherwise would claim coverage this
gate did not have. F5 remains **open** pending the owner's waive-or-fix call.
