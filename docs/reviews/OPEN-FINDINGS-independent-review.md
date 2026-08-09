# Open findings — `skills/independent-review/SKILL.md`

Living tracker. Every row is a review finding that is **not** closed. Close a row by fixing or
refuting it (BUG), or by fixing, refuting, or recording an owner waiver (RISK/NIT) — then delete
the row, with the disposition recorded in that round's trail.

Last updated 2026-08-04, after the permission-table collapse. Reviewers to date: Codex
`gpt-5.6-sol` (read-only), ollama-cloud `glm-5.2`, Kimi `kimi-k3:cloud`, and a host fresh-eyes
pass (Claude Opus 5).

## Gate status: no open BUGs — but NOT externally re-verified

All BUGs raised through the Kimi round are closed. **No reviewer has seen the applied result.**
Kimi reviewed the *draft* and returned "ship with the listed fixes"; those fixes were then applied,
so the committed text is one edit-generation ahead of anything any reviewer has read. Per the
skill's own vocabulary: `locally_verified`, not `externally_reverified`. One more round would
close that, and is the single highest-value thing left here.

## RISK — open

| id | Location | Finding | Found |
|---|---|---|---|
| R-CI | clerk item 2 | The local `(base, head)` capture is fixed, but the marker still stamps a single SHA and nothing names **which platform field a CI gate should compare** — GitLab and GitHub differ, and "the commit actually being merged" ≠ source head under squash or merge-commit flows. **Blocked on a cross-repo decision**: `apreet-backend`'s `review-trail-posted-gate` job depends on the current single-SHA form, so changing it is a two-repo change. | Codex r4, Kimi |
| R-SEATS | clerk item 2 | "Every seat that participated in the verdict" is still undefined for attempted-but-failed, degraded, or manually excluded seats — an implementation can omit a required seat by declaring non-participation. Wants a required-seat roster persisted before execution. | Codex r4 |
| R1-8 | onboarding step 2 | "Installed and authenticated" can route local-only ollama into the skip branch; `ollama list` doesn't prove a `:cloud` tag is signed in. Needs a concrete cloud-readiness probe. | Codex r1 |
| R1-9 | Procedure step 1 | `grep` for secrets is too weak for customer data, encoded credentials, or creds in URLs; first-time owner approval goes stale as repo sensitivity changes. Needs real preflight tooling. | Codex r1 |
| R1-10 | reviewer stack §3 / step 3 | The "fresh session" fallback has no enforceable way to create or verify isolation; on hosts without sub-agents it can silently degrade into the authoring context while still counting as fresh-eyes. | Codex r1 |
| R1-11 | onboarding step 5 | Model-family confirmation depends on parsing human-oriented CLI output, with `agy`'s format admitted unconfirmed. Needs a maintained per-CLI compatibility table or a machine-readable probe. | Codex r1 |

## NIT — open

| id | Location | Finding | Found |
|---|---|---|---|
| N1-14 | clerk §1 vs §3 | Raw notes are posted verbatim to the PR, but the permanent trail keeps only dispositions — later audit depends on PR-comment survival. Decide: embed raw notes, link immutable comment ids, or store hashes plus a durable archive. | Codex r1 |

## Not a finding — deliberate follow-on work

- **A lint.** The permission table is now the single place that grants or denies, which is the
  precondition for mechanically checking it. Candidate checks: no section other than the table
  states a grant or a fallback; every `see X` cross-reference resolves; the marker token appears
  exactly once. A lint catches *regression* of what is now correct — it would have found none of
  the BUGs in this history, all of which were reasoning errors.
- **Policy: changes to this file go through the gate.** Across five rounds every single one found
  something real, including three that found defects in the immediately preceding round's fixes.
  Nothing else here has that hit rate.

## Closed — history, do not re-litigate

**Round 1 (Codex)** — 4 BUGs: the marker's stamp-current-HEAD inversion, "every configured
reviewer runs together" contradicting Antigravity opt-in, "run every tier", and the unconditional
trail write. All fixed in `99c89e3`.

**Round 2 (Codex + ollama)** — 3 BUGs in the *proposed* fixes: B4 closed only locally, a factually
wrong `git commit -a` claim (it does not stage untracked files), and a false "local ollama never
runs automatically" claim refuted against `independent_review.sh:112`. All fixed in `99c89e3`.

**Round 3 (Codex + ollama)** — gate FAILED; step 7(c) oscillation fired. The fix for one finding
had re-opened the hole another fix had just closed. Diagnosis: "ownership" was doing three jobs.
Redesign in `e45e5b9`.

**Round 4 (Codex + ollama)** — 5 BUGs, 2 of them introduced by the redesign itself. Codex
prescribed splitting three properties into five.

**Round 5 (Kimi)** — rejected that prescription and returned verdict (c): the taxonomy was stated
normatively in five places and the defects had become *pairwise non-entailment among redundant
statements*, so the cure was fewer normative statements, not more properties. Its prediction that
patching would keep leaking was confirmed within the hour, in a fix that added a third statement
about budget rather than reconciling the two that already conflicted.

**Round 6 (Kimi, on the draft)** — "ship with the listed fixes". Caught a real safety hole the
collapse had introduced: the generic atom-B definition would have let an owner instruction
("stamp it, I eyeballed the diff") certify GATED-THIS-DIFF, losing the `ONLY` the old text had.
Also caught that the count had fallen to four rather than one, that positional row references
decay more silently than named ones, that `9(a)` sat outside the replacement range still naming an
abolished term, and four pieces of coverage that survived only in the deleted restatements. All
applied.

**Round 1 wording items** fixed 2026-08-03: R6 (what "3 rounds" counts), R5 (`locally_verified` vs
`externally_reverified`), R12 (an owner round never satisfies cross-model), N13 (the Codex-host
recommendation no longer leads with scarce-credit Antigravity).
