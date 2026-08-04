# Open findings — `skills/independent-review/SKILL.md`

Living tracker. Every row is a review finding that is **not** closed. Close a row by fixing or
refuting it (BUG), or by fixing, refuting, or recording an owner waiver (RISK/NIT) — and delete
the row, with the disposition recorded in that round's trail file.

Last updated after round 4 (2026-08-03). Reviewers to date: Codex `gpt-5.6-sol` (read-only),
ollama-cloud `glm-5.2`, host fresh-eyes pass (Claude Opus 5). A third-family read
(`kimi-k3:cloud`) was requested on the current state; if its findings landed after this file was
written they are not yet reflected here.

## ⚠ Gate status: FAILED — 5 open BUGs

The section governing who may post a review, where the trail is written, and when the marker may
be stamped is **not** in a shippable state. Commits `99c89e3` and `e45e5b9` each improved it and
each introduced something new. Do not describe this skill as review-clean.

## BUG — open, blocking

| id | Location | Finding | Prescribed fix | Found |
|---|---|---|---|---|
| B4-1 | step 9 property table | The AUTHORSHIP row says it is established by "a handoff that names posting"; the paragraph below says a handoff "does not confer authorship". The central table contradicts itself. | Keep AUTHORSHIP purely factual (this session created the PR/MR). Add **POST AUTHORITY** = authorship OR an action-naming handoff. | r4, both reviewers |
| B4-2 | step 9(b) | Gated on "THIS SESSION AUTHORED", which excludes handoff-authorized posting — but the clerk intro authorizes exactly that. Following the checklist literally means the authorized post never happens. | Gate 9(b) on POST AUTHORITY, with authorship as one way to obtain it. | r4, both reviewers |
| B4-3 | clerk intro | The action-capability rule isn't enforced: a handoff naming "comment" silently expands into multiple raw comments, a consolidated comment, and potentially the certification marker. | Enumerate capabilities (`POST_REVIEW_COMMENTS`, `STAMP_GATE_MARKER`); require the handoff to cover each, or state that posting never entails certification unless separately named. | r4, Codex |
| B4-4 | clerk item 2 | A PR/MR diff is not identified by source HEAD alone. The target/base branch can move while source SHA is unchanged — the merge diff changes and the marker keeps passing. | Capture and verify source SHA **plus** base SHA (or a platform diff/version id); stamp and check both. **Blocked on a decision** — differs GitLab vs GitHub, and `apreet-backend`'s `review-trail-posted-gate` job depends on the current single-SHA form. | r4, Codex (was r3 RISK, escalated) |
| B4-5 | step 9 table | GATED-THIS-DIFF established by "the review ran against current HEAD" — local HEAD equality doesn't prove reviewers saw the PR's diff (wrong checkout, stale diff file, wrong base all pass). | Bind the reviewed artifact to the PR/MR identity and exact source/base revisions; record them with the captured reviewer input. **Same decision as B4-4.** | r4, Codex |

## RISK — open

| id | Location | Finding | Found |
|---|---|---|---|
| R4-1 | step 9 WRITE AUTHORITY | Conflates permissions that don't travel together: creating a branch ≠ authority over the worktree; creating a worktree ≠ authority to commit to its branch. Split into WORKTREE WRITE AUTHORITY and BRANCH COMMIT AUTHORITY. | r4, both |
| R4-2 | 9(a) vs clerk item 3 | Item 3 still categorically describes the trail as "committed on the branch", so the compliant no-authority fallback cannot satisfy the clerk checklist. Make item 3 conditional. | r4, Codex |
| R4-3 | clerk item 2 | "Every seat that participated in the verdict" is undefined for attempted-but-failed, degraded, manually excluded, or superseded seats — an implementation can omit a required seat by declaring non-participation. Persist a required-seat roster before execution. | r4, Codex |
| R4-4 | clerk items 1–2 | After a moved-HEAD re-run, old raw comments aren't required to be superseded — authentic-looking findings for the wrong revision sit beside the new verdict. | r4, Codex |
| R4-5 | clerk intro | "Stop" is ambiguous under the handoff exception. | r4, ollama |
| R1-8 | onboarding step 2 | "Installed and authenticated" can route local-only ollama into the skip branch; `ollama list` doesn't prove a `:cloud` tag is signed in. Needs a concrete cloud-readiness probe. | r1, Codex |
| R1-9 | Procedure step 1 | `grep` for secrets is too weak for customer data, encoded credentials, or creds in URLs; first-time owner approval goes stale as repo sensitivity changes. Needs real preflight tooling. | r1, Codex |
| R1-10 | reviewer stack §3 / step 3 | The "fresh session" fallback has no enforceable way to create or verify isolation; on hosts without sub-agents it can silently degrade into the authoring context while still counting as fresh-eyes. | r1, Codex |
| R1-11 | onboarding step 5 | Model-family confirmation depends on parsing human-oriented CLI output, with `agy`'s format admitted unconfirmed. Needs a maintained per-CLI compatibility table or a machine-readable probe. | r1, Codex |

## NIT — open

| id | Location | Finding | Found |
|---|---|---|---|
| N4-1 | step 9 evidence paragraph | Reintroduces the bare word "ownership" ("'probably mine' is not ownership") in the very passage that eliminated it, inviting readers to re-collapse the properties. | r4, Codex |
| N4-2 | step 9 WRITE AUTHORITY | Ambiguous "it" in the second establishment criterion. | r4, ollama |
| N1-14 | clerk §1 vs §3 | Raw notes are posted verbatim to the PR, but the permanent trail keeps only dispositions — later audit depends on PR-comment survival. Decide: embed raw notes, link immutable comment ids, or store hashes plus a durable archive. | r1, Codex |

## Closed since round 1 — for context, do not re-litigate

- 4 round-1 BUGs (marker/HEAD inversion, Antigravity-runs-by-default, "run every tier", the
  unconditional trail write) — fixed in `99c89e3`, confirmed by round 3.
- 3 round-2 BUGs in the proposed fixes (incomplete B4 closure, the wrong `git commit -a` claim,
  the false "local ollama never runs automatically" claim) — fixed in `99c89e3`.
- 2 round-3 BUGs (handoff→ownership over-grant, the CLEAN-seat re-run loophole) — the loophole
  fixed in `e45e5b9` and confirmed; the over-grant is **re-opened** as B4-1/B4-2 above.
- 4 round-1 findings fixed 2026-08-03: R6 (what "3 rounds" counts), R5 (`locally_verified` vs
  `externally_reverified`), R12 (an owner round never satisfies cross-model), N13 (the Codex-host
  recommendation no longer leads with scarce-credit Antigravity).
