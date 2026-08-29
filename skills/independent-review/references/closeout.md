# Close-out and the clerk procedure (Procedure step 9)

Read this when a review round is ready to close out — BEFORE writing the
trail file, posting findings to the PR/MR, or stamping the consolidated
marker. Numbered "point N" / "step N" references refer to SKILL.md's
Procedure section. The permission table below is the ONLY place that grants
or denies the close-out actions.

**Both halves, not just the trail file.** These are two separate artifacts;
doing one is not doing the other, and skipping the second is the single most likely way this
skill's real work goes invisible. **Before either half: for each property the actions below
need, establish atom A; if absent, ask the owner for atom B; if that's not available either,
apply the table's fallback — except GATED-THIS-DIFF, which has no atom B at all (see Evidence
below): absent atom A, go straight to its fallback, never ask the owner to supply what the
evidence rules say they structurally cannot — an owner saying "yes it's reviewed, stamp it" is
exactly the bare-marker forgery this property exists to refuse.** Don't reach the table only
after already deciding to write — the
commonest case (your own primary checkout, where WORKTREE-WRITE authority is usually
undeterminable per the table's own examples) would otherwise silently divert every trail to a
fallback location with nobody having decided that on purpose.

(a) Write the trail: `docs/reviews/REVIEW-<gate>-<date>-r<round>-pr<N>.md`, where `<N>` is
this diff's PR/MR number, or `docs/reviews/REVIEW-<gate>-<date>-r<round>-<branch-slug>-<sha>.md`
when no PR/MR is open yet (branch name, lowercased, `/` and other non-alphanumerics collapsed
to a single `-`, plus `<sha>` — HEAD's abbreviated commit SHA, 7 hex chars). The SHA is not
decoration: the slug alone is lossy — `feature/x`, `feature-x`, and `feature_x` all collapse
to the same string, so two genuinely different branches can still collide on the exact
scenario this suffix exists to prevent. Two branches sharing both a slug AND a HEAD SHA is not
a realistic collision. **The suffix is mandatory even when no other session looks concurrently
active** — a bare `-r<round>.md` collides the moment two sessions both land on round 1 the
same day, and neither can tell from inside its own session whether another is running.
(Codified 2026-08-09: two independent same-day PR sessions in this repo each wrote a bare
`r4.md`, then separately a bare `r5.md`; both were only caught and resolved by hand at merge
time — see the addendum in `docs/reviews/REVIEW-diff-2026-08-09-r7.md`. Files already on disk
before this rule were left unrenamed; this changes the convention going forward only.) Write
it, **wherever this session
holds WORKTREE-WRITE AUTHORITY** (the permission table below — for someone else's worktree the
content is identical and only the destination changes) — findings,
dispositions, and for each external reviewer its CLI version, model, and sandbox mode (for a
human round: who, and what they reviewed).
(b) **If you hold POST AUTHORITY on an actual PR/MR** (a DIFF gate almost always is):
post the review *to that PR/MR* per the clerk procedure below — raw findings (collapsed) + one
consolidated summary — **before merging, not after.** A trail file that merges into the repo is
not a substitute: it's the permanent record for someone who already knows to look in
`docs/reviews/`, but the PR/MR comment is what the repo owner, a teammate, or future-you
actually sees first. Do this even when — especially when — the repo's own convention is "no
human reviewers on this MR": that convention describes who approves, not whether the
AI review gets a visible record. A blocking gate this skill's frontmatter calls BLOCK is not
satisfied by work that only exists in a file nobody has a reason to open yet.
Treat (b) as a checklist item with the same weight as "did the tests pass" — check it
explicitly before calling the gate satisfied, don't rely on remembering the clerk-procedure
section below on your own.

### ⚠ The permission table — the one place that GRANTS or DENIES

Every recurring defect in this section came from one word, "ownership", doing several jobs at
once, restated in five places that then drifted apart pairwise. So: this table is the only
place that grants or denies. Elsewhere you will find sentences that *name which property
governs* an action — those are pointers, and pointers are fine. What must never appear twice is
the grant itself, or a fallback. If you find a second statement of either, it is stale: delete
it, don't reconcile it. **Reference properties by NAME, never by row number, and append new
rows rather than renumbering** — a wrong number leaves no textual trace and no grep can find it.

| Action | Property required | Absent → do this instead |
|---|---|---|
| Post review comments on a PR/MR — 9(b), clerk items 1–2 | **POST AUTHORITY** | Hand the consolidated findings to the human owner **in this session, in full**, name the owning session/branch/MR as far as you can establish it, and stop. |
| Create or edit the trail file in a worktree — 9(a) | **WORKTREE-WRITE AUTHORITY** | Write the same content where THIS session's own work durably lives — **not** a temp dir that gets cleaned, since the trail is the permanent record. If nowhere durable exists, hand it to the owner inline and say plainly that no durable trail was written. |
| Commit or push the trail onto a branch — clerk item 3 | **BRANCH-COMMIT AUTHORITY** | Leave it uncommitted in your own durable location and record in the trail that no in-repo copy was committed. **Never in their worktree.** |
| Stamp the consolidated marker — clerk item 2 | **GATED-THIS-DIFF** | Do not stamp. Re-gate per clerk item 2 (which bounds the retries), or block. |

**Evidence — exactly two kinds, and one of them does not apply to GATED-THIS-DIFF.**

- **Atom A — a record of the creating action itself.** For POST AUTHORITY, this session created
  that exact PR/MR; for WORKTREE-WRITE, this session created that worktree; for BRANCH-COMMIT,
  this session created that branch. For GATED-THIS-DIFF, the captured reviewer input recorded
  against a `(base, head)` pair that still matches at post time — the capture may be an earlier
  session's if its raw outputs and pair are quoted and the pair still matches.
- **Atom B — the human owner's instruction naming that action**, given in this session, or made
  durably earlier (an issue comment, a standing instruction) and quoted verbatim and
  re-confirmed here. "Review and comment on !72 for me" is atom B for POST AUTHORITY on !72 and
  nothing else. If an action isn't named, ask.
  **GATED-THIS-DIFF has no atom B.** No instruction — the owner's or anyone's — certifies that
  reviewers saw a pair; only atom A does. An owner can waive a RISK. An owner cannot waive into
  existence a review that never ran.

Leads are not evidence. A branch or SHA mentioned in some transcript, a reflog timestamp that
lines up with a session's last activity, a project-local convention if your setup has one (e.g.
a `ccd.owner` git config) — each is worth one cheap check to go find atom A or B, and proves
nothing alone. A guess is not a check.

**Three properties of the table, plus one audit duty.**

1. **Rows are independent.** Holding one grants nothing in another. Creating a branch is not
   authority over the worktree it is checked out in; creating a worktree is not authority to
   commit to its branch; neither bears on whether reviewers saw the diff.
2. **Every row fails closed.** No atom A and no atom B means you do not have the property.
   Undeterminable is the common case, not the edge case — an unattributed worktree, an archived
   session, a commit made in a primary checkout.
3. **Not applicable is not failure.** A PLAN gate has no PR/MR: POST AUTHORITY and
   GATED-THIS-DIFF do not apply, while the two write properties still govern where the trail
   lands.
4. **(Audit duty, not a property.)** For every gated action taken, the trail names the property
   and the atom relied on — a session record, or the owner's instruction quoted verbatim.

**Why these rules exist** — non-normative; incidents, not instructions. 2026-08-02: a session
gated its own abandoned branch, found real issues that also applied to a parallel session's MR,
and posted them onto that MR — the behaviour POST AUTHORITY now prohibits. 2026-08-03: a
session's uncommitted edit to a tracked file was swept into another session's `git commit -a`
under an unrelated message, and a new untracked file is swept the same way by `git add -A` or
`git add .` — hence the two write properties. Round 1 of this skill's own review:
A downstream repo's CI gate, as originally implemented in its MR branch,
matched a bare marker that any note containing the token would satisfy — caught by round-1
review (Codex) before merge, so it never reached the shared branch in that state — hence
GATED-THIS-DIFF, and the advice to describe the marker rather than spell it out. See the `loose-ends` skill, "Open ends belong to a session".

## The clerk procedure — who posts what (explain this to the user)

*(This is Procedure step 9(b) above, not a separate optional step — read together. **Which
permission each item below requires, and what to do without it, is in step 9's permission table;
this section does not restate it.**)*

The external reviewers **structurally cannot** comment on a PR: they run in
read-only sandboxes (codex) or sandboxed throwaway dirs (agy) and hold no
GitHub/GitLab credentials — deliberately, because they are *untrusted*; giving
a third-party model write access to your PR would undo the security posture.
The HOST agent is the clerk, and each artifact has a distinct job:

1. **Raw** (authentic): each reviewer's verbatim notes, captured to disk at run
time, posted as a collapsed (`<details>`) PR comment on the reviewer's
behalf — clearly labeled with tool, version, model, and sandbox mode.
2. **Consolidated** (actionable): the clerk's dedup + dispositions across all
reviewers, posted as the main PR comment. Begin the comment body with the
literal line `<!-- independent-review:consolidated sha=<full commit SHA> -->`
(an HTML comment — invisible when GitHub/GitLab renders it, but present in
the raw body the platform's API returns), where `<full commit SHA>` is the **head of the
`(base, head)` pair the reviewers actually saw.** A PR/MR diff is a function of both: if the
target branch advances, the diff that will merge changes while head stays identical, and a
head-only marker keeps passing. **Fetch the target ref first** (a stale local ref makes both
recorded values wrong and the re-check will happily match them), then record
`git merge-base <target> HEAD` and `git rev-parse HEAD`. Re-read BOTH immediately before
posting and stamp only when both still match. If either moved, re-run the gate against the new
pair — **every seat that participated in the verdict, including seats that came back CLEAN and
including the tier-3 fresh-eyes pass, not just the external half** (a seat with no findings
still has to have SEEN the diff you are certifying) — rebuild the consolidated verdict from
those re-runs alone rather than mixing in old-pair findings, mark the superseded raw comments
as such, then re-check both values again, since either can move during a re-run. **Bound it at
two attempts**, then stop and surface an actively-moving branch rather than spending the round
on re-gates; these re-gates do not count against step 6(b)'s cap. If re-running is impossible,
do NOT stamp — the gate stays blocked until a re-review of the current pair can run, exactly
like any other missing prerequisite under step 5. **No seen pair, no stamp**, whatever the
budget says: a moved diff is not a fix awaiting re-verification. This is a stable,
machine-checkable marker, not a nicety: it lets a repo wire a CI gate that
checks "did a trail file land without a posted review *for the commit
actually being merged*" by querying the PR/MR's notes for this exact
marker+SHA pair, instead of matching bare prose that (a) can get reworded
later or (b) would be satisfied by ANY note containing the marker,
including a stale one from an earlier round on a reused branch — a
downstream repo's CI gate (a `.gitlab-ci.yml` job) originally
shipped with the bare marker and exactly that bypass; round-1 review
(Codex) caught it before merge. Once a gate depends on this marker, don't
drop the SHA suffix or reword the fixed text around it — a rebase or a
later push is *supposed* to invalidate a prior post (post again against
the new HEAD), not silently keep passing.

**This discipline protects the posting moment, not indefinitely.** A push landing in the gap
between the final recheck and the POST call itself is not covered by "re-read immediately
before posting" alone — after posting, re-fetch the PR's head/diff-scope from the platform API
once more. **If only the SHA moved and the diff-scope is byte-identical** (a bare rebase, no
content change), re-post naming the new head — the findings still apply to the same code.
**If the diff-scope itself changed, do not re-stamp the new head with the findings you already
have** — that would certify code nobody reviewed, the exact failure this whole scheme exists to
prevent. Treat it like any other moved pair: re-run the gate per the recheck discipline above,
not a silent re-post. A target-branch advance *after* a successful, unmoved stamp
is a separate, currently open gap: the marker only names `head`, so it cannot encode that a
later advance happened. Closing it fully needs the marker to also carry `base` (or an
equivalent) — a cross-repo change, since that same downstream job hardcodes a match against the current
single-SHA form. Left open rather than silently claimed solved, pending that two-repo decision.

**When a re-gate's own trigger is itself prose (a fix commit's wording, a trail file), scope the
re-run narrow rather than skip it.** Judging a diff "too small/wordy to bother re-gating" by eye
is the exact shortcut this rule exists to close off — nothing in "diff-scope changed" carves out
an exception for comments or docs. Instead, tell every seat the diff changes only prose, and to
flag ONLY a factual contradiction or misleading claim against the code/behavior it describes —
not style, tone, or phrasing preference. A clean result on that narrow prompt IS the re-gate:
real evidence of convergence, not a shortcut around running one. Two incidents on the same
review track show why: an *un-scoped* re-review once re-litigated committed trail prose through
rounds 6–9 of one PR — ~40 findings, zero contract defects — before a narrow scope ended it in
one more pass. A second PR hit the same failure from a different trigger (fix commits repeatedly
moving the head) and the same fix converged it: 5 passes, 22 findings, ending on one
explicitly-scoped pass that came back clean. And prose diffs are where real findings live, not
just noise: on a third PR, a re-gate round caught its own prior round's fix overstating a claim
("ran in production" for something that had only run in a test environment) — proof a fix round
can introduce a new problem, not just resolve the old one — and the very next round then skipped
that same check on its own fixes, reasoning the diff was "just wording." Don't make that call
from the diff's size; run the narrow pass and let it tell you.

**What "prose-only" means, who decides, and which way it fails.** The clerk classifies,
from a changed-file/hunk inventory of the pair — never by eye. Prose-only means every
hunk in the pair is prose: Markdown body text, or comment text in a code file. A hunk
touching code is not prose, and neither is a fenced snippet, a YAML or config block, a
shell command, or a generated file — those are instructions someone will run or rely
on. A mixed commit is not prose-only either. **Anything you are unsure about is code:**
the asymmetry is the whole point. Misclassifying prose as code costs one wasted round;
misclassifying code as prose narrows every seat away from the code and then stamps it
under the full GATED-THIS-DIFF ceremony — a review that never happened, produced by
following the procedure rather than by cutting a corner. What makes the narrow scope
safe when the inventory IS clean is carry-over, so state it rather than leaving it
implied: every code hunk in the pair was gated in the round it entered and has not moved
since. Say the classification in the scoping instruction, and ask the seats to challenge
it if what they receive contradicts it — a seat that can see code in a diff it was told
is prose is the last check before the stamp.

**Send the full pair, and prepend the scope to the unchanged strict prompt.** Every seat
gets the same artifact any other re-gate would send it — not the prose delta alone. The
scoping instruction is prepended to the strict review prompt, which is otherwise
untouched: the BUG/RISK/NIT ranking still applies, reviewers simply do not raise style,
tone, or phrasing under this scope. Sending only the delta would leave atom A —
"captured reviewer input recorded against a `(base, head)` pair" — describing something
the seats were never given.
3. **Trail** (permanent): `docs/reviews/REVIEW-*.md` — committed on the branch when step 9's
permission table's WORKTREE-WRITE and BRANCH-COMMIT rows both permit it; see the table for the
fallback when either doesn't. Names, per gated action taken, the property and
the atom relied on —
dispositions, refuted (rejected-with-reason) findings, pending waivers, reviewer
versions. This is the record that survives PR-comment archaeology. Trails
(and other internal working notes, e.g. plans) go under `docs/reviews/`,
never at the repo root — they must not clutter the project's GitHub
frontpage.

Capture reviewer output by **streaming to a file**, never by buffering it in a
shell variable — a session teardown mid-run must leave the partial review on
disk, not vaporize it.

**Read the whole file, never a tail of it.** The prompt asks for a RANKED list, so the severe end is
at the TOP: piping a reviewer's output through `tail -n` hides exactly the findings the round was
run for. Caught live on a 7-round MR (the trail-exclusion incident in SKILL.md Procedure step 2) — a round read through `tail -40` showed only its NITs; re-running
it in full surfaced a BUG. The re-run also cost a second round AND produced a DIFFERENT list from
the same model on the same input, so three findings acted on from the first sample went unlogged and
a later round had to reconcile the trail's arithmetic. If output is too long to read at once, page
through it from the top or write it to disk and read the file — never sample the end.

4. **Cleanup**: once items 1–3 are posted/committed **and a durable copy of the raw verbatim
output exists somewhere other than `$RAW_DIR`** — a posted PR comment (item 1) always counts,
since it's explicitly the reviewers' verbatim notes by its own definition above; a committed
trail file (item 3) counts **only if it actually includes the reviewers' verbatim text, not
just dispositions/summary** (item 3's own spec above names dispositions, refuted findings, and
waivers — verbatim text isn't automatic). This matters most for a PLAN gate, which has no
PR/MR (item 1 is N/A per step 9's own "not applicable is not failure" rule for PLAN gates) — if the trail alone doesn't carry the verbatim
output, copy `$RAW_DIR`'s raw text into it before deleting, rather than assuming the
dispositions are enough. An inline hand-off to the owner under one of step 9's
permission-table fallbacks does NOT count, since nothing durable landed anywhere — delete the run's
`$RAW_DIR` (path printed to stderr as `raw output: <dir>`) — it held the full artifact content
plus every reviewer's raw output (owner-only permissions, but proprietary code sitting in
`$TMPDIR` indefinitely serves no purpose once something durable has captured it). **If a
fallback fired and nothing durable landed, `$RAW_DIR` is the only verbatim copy that exists —
do not delete it.** Say so plainly ("raw output remains only in `$RAW_DIR` until you take
custody of it") and leave deletion to the owner. **Independently — a second, separate reason
to hold off, not the only one** — also skip deletion while a verification round (Procedure
step 6) still needs this run's raw output.
