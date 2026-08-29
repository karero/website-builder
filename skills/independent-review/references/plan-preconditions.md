# PLAN gate preconditions — the full reasoning

Read from SKILL.md's "PLAN gate preconditions" section, which summarizes the two
checks; this file carries the complete rationale, scope, and — just as important —
what each check does NOT establish. "Procedure step N", "the Reviewer stack", and
"item 3" (a Reviewer-stack entry) below refer to SKILL.md; "the clerk procedure"
refers to `references/closeout.md`.

(Codified 2026-08-16, after a multi-day build cleared seven PLAN rounds and still
left its owner unable to say which steps were finished.)

## 1. Can the plan report its own progress?

**The HOST agent runs this check itself** (the same orchestrating agent named throughout
this skill, e.g. in the clerk procedure — not item 3's "Fresh-eyes host-agent pass",
which is one specific reviewer seat), before the external pair goes out. Two different
reviewers are structurally unable to do it, for two different reasons: the fresh-eyes
seat receives only the artifact, per the Reviewer stack, and has no repo access at
all; the external pair (Codex, ollama) does have repo access but is never asked this
question — it's a precondition on the plan, not a content-review prompt, so nothing in
either tool's instructions would surface it.

Two questions. **Does the plan, or a sibling document it names, have a place where each
step's state is recorded?** And **does every state claiming progress or completion carry
a reference another person can actually open** — a commit SHA, a repository-qualified
pull request, a test-run link retained per the project's own policy rather than an
ephemeral CI console URL? "Not started" is the one state needing no reference; every
state asserting something happened does.

If either answer is no, record it as a **RISK, not a NIT**, in the host's own findings
and in the trail (Procedure step 9), and keep it out of the artifact sent to the
external pair — including a verification round's prior-findings list, which would
otherwise spend their attention on a host-only structural point. **This does not gate
the external round**: the standard pair still runs on the plan's content exactly as
usual, and the plan is never held back from them over it. The concern is orthogonal to
content quality — it's whether anyone can tell what's done once building starts. That
cost lands weeks later, on the human, and hardest on plans that PASS: a well-reviewed
plan gets built over days, which is exactly when memory of progress fails and the
conversation holding it is gone.

**What this establishes, and what it does not.** It is a structural check at review
time — the plan has somewhere to record state, and the convention demands a reference.
It cannot tell you a row is *accurate*, and it cannot police updates during the build
that follows: at review time most steps have not happened yet, and nothing here is
watching weeks later. A tracker can still go stale by simply not being updated, and the
rule below is stated in this skill's own documentation — if whoever executes the plan is a
different session, a different agent, or a human who never opens this skill, nothing
here reaches them. Say all of that plainly rather than imply a coverage this check does
not have: closing it needs the rule carried into wherever the builder actually looks —
the plan's own execution notes, or the handoff itself — which is a decision for that
handoff, not something this gate can reach into the future and enforce.

This prescribes no format. Whatever the project already uses is fine, on two conditions.
The record lives **in the repo**, not in a chat log or a session's to-do list — both die
with the session, and a plan reviewed in one session is usually built in another. And
**updating a step's state is part of finishing that step**, never a separate bookkeeping
pass afterwards — state this as the convention that makes the record worth keeping, not
as a promise this gate enforces: a tracker nobody updates goes stale silently, which is
worse than having none, because it still reads as authoritative.

## 2. Are the plan's own decisions settled?

**A plan whose steps are still changing does not need another round yet.** It needs its
open decisions closed first. If any finding from the last round was "this section
depends on an undecided question", get that decision, let the document settle, then run
the verification round on the result — Procedure step 6 still applies in full; this
defers that round, it never replaces it. Re-reviewing a moving target is how a plan
reaches round seven, and every round after the first grades a document that is no longer
the plan.
