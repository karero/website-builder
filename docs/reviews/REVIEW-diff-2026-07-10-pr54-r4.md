# REVIEW — DIFF gate, PR #54, round 4 (2026-07-10)

Artifact: the fix diff for r3's findings, including a REDESIGN (not another patch) of
the agy host-family paragraph — one general rule ("reviewer model family != host
family") stated once, replacing the enumerated per-host list that produced a new bug
in each of r2 and r3.

## Reviewers
| Seat | Tool | Model | Sandbox | Outcome |
|---|---|---|---|---|
| cross-model | codex-cli 0.144.1 | gpt-5.6-terra / xhigh | `exec -s read-only` | 7 findings (4 BUG · 3 RISK) |

## Findings

Finding count rose (5 → 7) — flagged explicitly as a convergence-check concern, but
signals (b)/(c) still held (new findings target r3's own fresh content, no literal
oscillation of an already-dispositioned finding), so continued rather than hard-
stopping:

1. **BUG** — "fall back to Codex" on unconfirmed agy model is unconditional,
   contradicts the just-stated host-family rule on a Codex host. CONFIRMED.
2. **RISK** — `AGY_MODEL` claimed as agy's own env var; Google's docs show
   `agy --model`/settings.json instead. **Independently verified and REFUTED**: `agy
   --help` (installed locally) confirms `--model` is the real flag, AND
   `independent_review.sh:157,161` shows `AGY_MODEL` is this repo's OWN env var,
   correctly mapped to `agy --model "$AGY_MODEL"` — the isolated-diff reviewer had no
   visibility into that script.
3. **BUG** — host-family matrix groups "Claude Code or Codex" together requiring
   Gemini, but on a Codex host, Claude via agy would also be cross-model — the
   redesign's general rule was right but round 4's own restated matrix under-applied
   it. CONFIRMED.
4. **BUG** — `test -x` alone accepts executable directories, not just regular files;
   needs `-f` too. CONFIRMED, author error (should have been caught in r3).
5. **BUG** — `deepseek-coder-v2:16b` mislabeled Q4_K_M; **independently verified**:
   ollama.com/library/deepseek-coder-v2:16b confirms Q4_0. CONFIRMED.
6. **RISK** — "current task finishes even if you hit it mid-task" (Codex pricing
   claim) isn't guaranteed by the linked page. Pre-existing content (predates this
   PR's edits, only the surrounding citation was touched) — noted, not fixed in this
   PR; flagged to the owner as a separate, lower-priority item.
7. **RISK** — cited XDA URL claimed to return 502. **Independently verified and
   REFUTED**: `curl -sI` (twice, with and without a UA string) returns 200.

Checked CLEAN: model-confirmation disqualifier now fails closed; Gemini-on-Gemini
correctly rejected; `gpt-oss` tags correctly MXFP4; generic onboarding path requires
real verification; PowerShell `Test-Path -PathType Leaf` correct.

Disposition: fixed #1, #3, #4, #5. Refuted #2, #7 with evidence (not silently
dropped — refutation stated explicitly in the r5 review prompt so the reviewer
wouldn't re-flag them blind). #6 deferred as pre-existing/out-of-scope, surfaced to
the owner rather than silently skipped.
