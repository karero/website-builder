# Review trail — DIFF gate — PR #66 — round 1

**Artifact:** `skills/independent-review/SKILL.md`, 27-line addition (branch
`independent-review/plan-progress-legibility`, commit `0f0298e`) — a new
"PLAN gate precondition" subsection asking whether a plan can report its own
progress.

**Reviewers:**
- Codex CLI 0.147.0 — model `gpt-5.6-sol`, sandbox `read-only`
- ollama-cloud — model `glm-5.2:cloud`

**Gate:** DIFF, standard pair (no `--first-success`, no `--with-antigravity`).
Input: `git diff -U40 origin/main...HEAD` (wide context so both reviewers see
the surrounding skill sections, not 27 orphaned lines).

## Findings and dispositions

| # | Sev | Source | Finding | Disposition |
|---|-----|--------|---------|--------------|
| F1 | BUG | Codex + GLM (independently) | `"don't spend an external round on it"` reads as "skip the standard pair for this plan" — would bypass the PLAN gate the section sits inside | **FIXED** — commit `2bfb6c6`: explicit "this does not gate the external round" clause |
| F2 | BUG | GLM | Text has the HOST perform the check but told the fresh-eyes seat to raise it; that seat receives only the artifact (Reviewer stack item 3) and cannot see repo state | **FIXED** — `2bfb6c6`: host both checks and records; reason the fresh-eyes seat can't stated explicitly |
| F3 | BUG | Codex | `"does not need another round"` contradicted Procedure step 6's required verification round | **FIXED** — `2bfb6c6`: reworded "not yet"; deferred round stated as still mandatory |
| F4 | RISK | Codex | Status and evidence conflated — `"not started"` is a status, not a checkable reference | **FIXED** — `2bfb6c6`: split into "backed by a checkable reference, OR explicitly marked not started" |
| F5 | RISK | Codex | Nothing required the tracker to be *updated* — could go stale exactly as the incident that motivated this section did | **FIXED** — `2bfb6c6`: added "updating a step's state is part of finishing that step" |
| F6 | NIT | Codex | Bare "PR number" ambiguous in multi-repo projects | **FIXED** — `2bfb6c6`: generalized to checkable references |
| F7 | NIT | GLM | 40-word run-on sentence in the core precondition question | **FIXED** — `2bfb6c6`: split into two questions |

**Not adopted** (declined, judged defensible by round-2 reviewers — see r2 trail):
- Codex's proposed status taxonomy (`not-started`/`in-progress`+ref/`blocked`+owner/`done`+evidence) — the section deliberately prescribes no format; a taxonomy would both contradict that and duplicate a format owned elsewhere.
- Codex's proposed stable step-ID requirement — same reason.

## Convergence

7 findings, 3 BUG / 2 RISK / 2 NIT. All fixed in one pass. No waivers. Next:
round 2 (verification of these fixes + fresh eyes on the revision).

## Author fresh-eyes pass

Not run as true no-shared-context this round (author wrote the artifact under
review). Standard pair alone satisfies the Independence rule on a Claude Code
host — Codex and ollama-cloud are both cross-model.
