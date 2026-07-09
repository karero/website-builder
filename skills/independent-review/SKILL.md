---
name: independent-review
description: >
  Domain-agnostic cross-model review gate: run a planning markdown (PLAN gate) or
  a branch/PR diff (DIFF gate) through INDEPENDENT reviewers — external models via
  scripts/independent_review.sh (Codex gpt-class, Gemini 3.1 Pro via the
  Antigravity CLI, ollama) PLUS a fresh-eyes no-shared-context pass by the host
  agent — consolidate a ranked BUG/RISK/NIT list, and BLOCK until every BUG is
  fixed and every RISK/NIT is fixed or explicitly waived by the human owner.
  Use BEFORE building from any non-trivial plan and BEFORE merging any
  non-trivial PR. On first use, if no reviewer that's cross-model for the
  current host is set up yet (ollama alone or a same-family cloud tool never
  counts — see the skill body), runs a guided ONBOARDING for non-technical
  users — explains
  the free-tier tradeoffs plainly (including realistic usage-limit
  expectations), walks the download/login steps, picks an ollama model sized
  to the user's actual RAM, then teaches how to use it. Trigger phrases:
  "cross-review this plan", "get a second model to review", "codex review",
  "gemini review", "antigravity review", "agy review", "adversarial review",
  "review before I merge", "independent review", "cross-model review", "set
  up independent review", "set up AI code review", "install codex for
  review", "install antigravity for review", "set up ollama for review",
  "which review tool should I use", "how do I get a second AI to review
  this".
---

# Independent review — the cross-model gate

A blocking review gate for two artifact types. The value is *independence*: a
model that did not write the artifact, ideally from a different model family,
cannot share the author's blind spots. Dogfooded on its own design plan — two
rounds caught 5 BUGs the author had shipped.

## The two gates

- **PLAN gate** — reviews a planning markdown *before* any code is written.
  Catches strategy errors, stale assumptions, internal contradictions.
- **DIFF gate** — reviews a branch/PR diff *before* merge. Catches test blind
  spots: a guard passing while the thing it protects regressed.

## Reviewer stack (run ALL available, not first-success)

1. **Codex CLI** (`codex exec -s read-only`) — genuine read-only sandbox; model +
   effort from `~/.codex/config.toml`.
2. **Gemini 3.1 Pro (High)** via the Antigravity CLI (`agy --sandbox -p`) — free
   Antigravity login. *(The old `@google/gemini-cli` path is deprecated: Google
   discontinued its free tier 2026-06-18.)*
3. **Fresh-eyes host-agent pass** — a read-only sub-agent (or the vendored
   `double-knuth` skill) with NO shared context: give it only the artifact and
   the strict prompt below. Never reuse the authoring conversation. If the host
   has no sub-agent primitive (some Codex installs), use a separate fresh
   session with only the artifact — or record the pass as *degraded* in the
   trail, not as no-shared-context.
4. **ollama cloud** (named via `OLLAMA_MODEL`, e.g. `glm-5.2:cloud`) — fallback.
5. **ollama local** — sanity pass only; the script never lets it satisfy the
   gate alone.
6. **Any model, copy & paste** — the script emits the prompt; a human pastes it
   into whatever is available and feeds findings back.

**Independence rule:** run every tier, but *classify* them — the tier matching
the HOST agent's model family counts as the fresh-eyes seat, never as
cross-model independence. **The gate is satisfied only when at least one
successful reviewer is cross-model (a different family than the host)**; if
only same-family reviewers ran, the gate is degraded and needs an explicit
owner waiver — codex reviewing codex-authored work shares the blind spots this
gate exists to catch. Per host: **Claude Code** — fresh-eyes = the Claude pass,
cross-model = Codex + Gemini. **Codex** — fresh-eyes = Codex, cross-model =
Gemini + Claude. **Antigravity/Gemini** — fresh-eyes = Gemini, cross-model =
Codex + Claude. On any non-Claude host the Anthropic seat is free via the
Antigravity CLI — `AGY_MODEL="Claude Opus 4.6 (Thinking)"` (verified headless
2026-07-02; Claude Code itself has no free tier — Pro/API only — and the free
claude.ai paste tier fits plans and small diffs at best).

## Onboarding — the agent runs this wizard on first use

**Everything below assumes a Claude Code host (the common case), where both
Codex and Antigravity are cross-model and either one satisfies the gate.**
If the current host is itself Codex or Antigravity/Gemini, substitute per
the Independence-rule table above wherever this wizard names a specific tool
as "the" recommended reviewer or as satisfying/not-satisfying the gate —
don't apply the Claude-host examples literally on a different host. This
applies to every step below, including the default recommendation in Step 3
and the fallback description in Step 6, not just the detection logic in
Step 2.

**When invoked and no reviewer that's gate-satisfying for the current host is
installed and working** (see Step 2's fuller definition below — not just
"nothing is installed at all"), do not dump install commands. Walk the user
through it like a friendly wizard.
Assume a non-technical user who has never used a terminal seriously — do the
heavy lifting yourself; clearly flag the few things only they can do. Full
install commands, the tool comparison table, and the ollama RAM/model tables
referenced below all live in `references/setup-guide.md` — pull from it as
needed rather than re-deriving any of this from general knowledge, since
exact free-tier limits and install commands drift and that file has current
sourcing plus an explicit "don't quote a stale number" caveat. **Numbers
belong in that reference file, not hardcoded in this wizard** — when a step
below needs a figure (a time estimate, a limit, a lockout report), pull it
from there rather than restating one here from memory, so there is exactly
one place to update when it goes stale.

**"Installed" is not "working" — three distinct checks, don't conflate them:**
1. *On PATH* — `command -v codex` / `command -v agy` / `command -v ollama`.
   Proves the binary exists, nothing more.
2. *Looks authenticated* — `test -f ~/.codex/auth.json` (Codex); `agy models`
   returns a model list, not an error (Antigravity); `ollama list` returns
   without error (ollama, though this only proves the daemon runs, not that
   any model is pulled yet). A stale/expired token can still pass this check.
3. *Actually works* — a real review request returns real review-shaped
   output. This is the only check that proves the tool is usable right now;
   see Step 5. Don't report "done" off checks 1–2 alone.

### Step 1 — Sell the benefit first (before asking for anything)

In 3–4 plain sentences:
- *"Before I hand you a finished plan, or before we merge a real change, I can
  get it checked by a completely different AI — one that didn't write it, so
  it can catch mistakes I might miss myself. Think of it as a second, more
  skeptical pair of eyes."*
- *"This is free to set up — no new subscription required. Most of the setup
  is something I can do for you; you'll just need to click a couple of
  sign-in prompts yourself."*

Then ask **"Want to set this up now?"** If they say **no**, don't proceed —
but don't silently treat the artifact as reviewed either: this skill's own
rule is BLOCK until reviewed or explicitly waived (see Procedure step 5).
Tell them plainly: *"OK — I won't set this up now. That means I can't run an
independent review until either you change your mind, or you explicitly tell
me to skip the review this time (I'll record that as your call, not mine)."*
Record a decline as a named owner waiver if a gated action (merge, ship) is
actually blocked on it — don't just drop the topic.

### Step 2 — Check what's already there; never re-onboard a returning user

Run the detection commands above. **The skip condition is "the user's actual
request is already satisfied AND the gate is actually satisfiable with
what's installed," not "any one tool works":** per this skill's own
Independence rule above, a reviewer only satisfies the gate if it's
**cross-model relative to the CURRENT host**, not just "installed" — ollama
alone never satisfies it regardless of host (tier 5 — sanity pass only), and
which cloud tool counts as cross-model depends on what's running this
wizard: on a Claude Code host, Codex and/or Antigravity both count; on a
Codex host, Codex CLI alone does NOT (same family as the host) — Antigravity
is the cross-model option there; on an Antigravity/Gemini host, the reverse.
- If the user asked generically for review setup, and ≥1 reviewer that is
  **cross-model for the current host** (per the table above — not ollama
  alone, and not same-family-as-host alone) is already installed and
  authenticated, skip straight to Step 6 (confirm it still works with one
  real test run per Step 5's evidence standard).
- If only ollama is set up so far, treat that the same as "nothing set up
  yet" for gate purposes — it's a fine backup to already have, but proceed to
  Step 3 to add a cloud reviewer, don't report the wizard as done.
- If the user asked for a **specific** tool that isn't set up yet (e.g. "set
  up ollama too" when only Codex is working), don't skip — go set up the one
  they actually asked for, even though the gate is already technically
  satisfiable without it.
- If a previously-working tool now fails (expired login, uninstalled), say
  plainly which one broke and offer to either fix it or move on with what's
  still working — don't restart the whole wizard for the tools that are fine.

### Step 3 — Help them choose (they don't need all three)

Present the three options as a short, plain-language summary — pull the full
comparison table from `references/setup-guide.md` if the user wants more
detail, but lead with this, not the table:

- **Codex CLI (OpenAI)** — free ChatGPT account, no payment. Of the two cloud
  options, the more predictable free tier (see `references/setup-guide.md`
  for what's currently known about its limits — pull the actual figures from
  there, don't restate a number from memory here).
- **Antigravity (Google)** — free personal Gmail account, no payment. Just as
  sharp a reviewer, but **its free-tier usage limit is tight and not clearly
  published.** Pull the current, sourced detail (including a dated real-world
  report of severe lockouts) from `references/setup-guide.md` and say it
  plainly — don't undersell it, and don't guess at numbers not in that file.
- **ollama (local, on your own computer)** — completely free, unlimited,
  private (nothing leaves the machine), no account at all. The tradeoff:
  quality depends on how much RAM the computer has, and even a well-equipped
  machine's best local model still lags the two cloud options on subtle
  bugs. Good as a free unlimited *backup*, not usually as the only reviewer.

**Default recommendation if they're unsure (Claude Code host — see the note
at the top of this section for any other host):** set up Codex CLI as the
main reviewer, and ollama alongside it as a free backup for whenever Codex's
free tier is temporarily tapped out. Antigravity is worth adding on top if
they want a third, independent model family and are comfortable with a less
predictable free tier — it is not required. **If the current host is itself
Codex, swap this recommendation: Codex CLI would be same-family and
wouldn't satisfy the gate — recommend Antigravity as the main reviewer
instead**, with ollama as the same free backup either way.

Ask which one(s) to set up, then proceed per tool below.

### Step 4 — The human-only steps ( 🧑 **you do this** )

Regardless of which tool(s): a sign-in step always needs the user's own
click, and installing anything means running a command in their terminal for
the first time — walk them to opening a terminal (Terminal.app on macOS,
PowerShell on Windows, their terminal of choice on Linux) if they've never
done it, one plain instruction at a time.

- 🧑 **Codex:** open a terminal, paste the install command I give you, press
  enter, wait for it to finish. Then run `codex` and follow the "Sign in with
  ChatGPT" prompt in the browser window that opens — one click to approve.
- 🧑 **Antigravity/`agy`:** same shape — paste the install command, then run
  `agy models` and follow the Google sign-in prompt (personal Gmail account).
- 🧑 **ollama:** for macOS/Windows, download and open the installer like any
  normal app (no terminal for the install itself) — but the model download
  in Step 4b still needs a terminal command; on Linux there's a single
  terminal install command. Then tell me your available RAM (or let me
  detect it) so I can recommend a model — do NOT let them guess a model size
  themselves; see Step 4b.

Hand these over **one at a time**, wait for confirmation each step landed,
don't paste all the commands at once.

### Step 4a — Your steps ( 🤖 **I do this** )

- 🤖 Give the exact install command for their OS (from
  `references/setup-guide.md`), one tool at a time.
- 🤖 After each install, verify it actually landed (`command -v codex` /
  `command -v agy` / `command -v ollama`) before declaring success — a
  "looks done" claim without checking is exactly the kind of thing this
  skill exists to prevent elsewhere; don't do it here either.
- 🤖 If a `PATH`/"command not found" issue comes up after an apparently
  successful install, try the standard fix (new terminal window) before
  escalating — see the Gotchas in `references/setup-guide.md`.

### Step 4b — ollama only: pick the model from RAM, don't guess

**This is a machine-capability decision, not a preference — check before
recommending.**

- 🤖 Detect available RAM using the OS-appropriate command from
  `references/setup-guide.md` (`sysctl hw.memsize` on macOS, `systeminfo` or
  Task Manager on Windows, `free -h` on Linux). If you can't run the command
  directly (e.g. the user is on a different machine than the one you have
  shell access to), ask them to run it and paste back the number.
- 🤖 Look up the matching row in the RAM → model table in
  `references/setup-guide.md` and recommend exactly ONE model tag — don't
  offer the full menu and make a non-technical user pick blind.
- 🤖 **Warn about the download before pulling it** — model files run
  multiple GB; say the size and ask before running `ollama pull <model>` on
  a metered or slow connection.
- 🤖 State the honest ceiling plainly: *"This will catch a lot of the
  obvious stuff for free, but it's not as sharp as Codex or Antigravity on
  subtle bugs — think of it as a backup, not a replacement."* Don't let
  "free and unlimited" imply "just as good."

### Step 5 — Confirm it's actually working (with evidence, not a claim)

Run one real, small test review with each newly-configured tool — a trivial
throwaway artifact is fine (e.g. a two-line diff). **Quote or closely
paraphrase one actual line the reviewer produced**, not just your own
success claim: *"✅ Codex is working — I gave it a small test diff and it
came back with: '[actual excerpt from its output]'."* An assertion of
success with no quoted output is not evidence and doesn't satisfy this step.
A tool that installed but can't produce a real review (bad auth, model
unavailable, `looks_like_review()` in the script would reject its output) is
not done — fix it or tell the user honestly it isn't working yet.

### Step 6 — THEN teach them how to use it. Don't skip this.

Tell the user they never need to touch the terminal again for this — from
now on, in any normal session, they just ask in plain language: *"get this
reviewed,"* *"codex review,"* *"antigravity review,"* *"independent review
this before we merge,"* or similar (see the trigger phrases in this skill's
frontmatter) and the review runs automatically using whichever tool(s) are
set up.

**Set the free-tier expectation now, not when it surprises them — and be
accurate about what "fallback" actually means:** *"Codex and Antigravity are
free but not unlimited — you may occasionally hit a limit (see
references/setup-guide.md for what's currently known about each). Here's
what actually happens if you do, depending on how review is run: by
default every configured reviewer runs together each time, so if Codex is
temporarily rate-limited, that round still runs with whichever of
Antigravity/ollama are set up. **That keeps you fully covered only if a
cross-model reviewer for this host is still available — if ollama is the
only thing left, that round is a lighter-weight, degraded pass, not a full
substitute** (same rule as everywhere else in this skill: ollama alone never
closes the gate on its own). If review is run in quick 'first available'
mode instead, it tries Codex first and only moves to the next one if Codex
fails outright. Either way, having ollama set
up means there's always a free, unlimited option in the mix — just know it's
a lighter-weight reviewer, not a like-for-like replacement."*

## Procedure

1. **Data check before anything leaves the machine.** External reviewers are
   third-party services: grep the artifact for secrets (keys, tokens, passwords,
   customer data) and get the owner's OK the first time a given repo's content
   is sent out. If the content must stay local, run the script with
   `--local-only` (skips codex/agy/paste entirely; local ollama only) plus the
   tier-3 host fresh-eyes pass — tier 6 (paste into any model) is just as
   external as the CLIs and is excluded. A local-only verdict is inherently
   DEGRADED; record that in the trail.
2. Run the external half (path relative to THIS skill's directory — after an
   install that is `<skills-root>/independent-review/scripts/…`):
   `scripts/independent_review.sh <artifact.md|diff-file|-> [--plan|--diff]`
   — default runs ALL authenticated externals and prints one section per
   reviewer; `--first-success` is the quick mode. Exit 4 = no reviewer ran =
   gate FAIL (never treat as clean).
3. Run tier 3 (fresh-eyes) with the same strict prompt.
4. **Consolidate**: dedup findings across reviewers; keep per finding — a stable
   id, severity (BUG/RISK/NIT), source reviewer(s), location, status
   (open/fixed/waived + waiver reason and owner).
5. **Enforce the verdict** (this is the skill's job — never the script's exit
   code): every BUG must be fixed, no exceptions; RISK/NIT may be waived only
   with a named reason from the human owner — no blanket waivers.
6. **Iterate — fix, then re-review.** Send the updated artifact back through
   the reviewers as a *verification round*: give them the prior round's BUG
   list, ask them to confirm each fix landed AND that the fixes introduced
   nothing new — and tell them the author expects clean **and that they must
   not oblige out of politeness** (expectation of cleanliness is exactly the
   bias that turns round 2 into a rubber stamp). Repeat until essentially
   clean. Stop conditions: (a) clean — done; (b) 3 rounds with BUG/RISK still
   open — hard gate-FAIL, surface and block; (c) **budget/credits exhausted**
   — you may proceed once all known BUGs are *fixed* AND every RISK/NIT is
   fixed or explicitly owner-waived (same bar as the blocking rule), deferring
   only the external re-verification of those fixes; record "last round not
   re-verified" in the trail and run a later round when resources allow.
   Deferring verification is legitimate; deferring a fix or a waiver never is.
7. **Convergence check — the rabbit-hole detector.** Iteration is only healthy
   while quality demonstrably rises each round. After every round, check three
   signals: (a) the finding count is falling; (b) new findings target code
   *added by the previous round's fixes*, not ground already ruled clean;
   (c) no oscillation — a fix that re-breaks something an earlier round fixed,
   or reviewers re-raising a finding already dispositioned, means you are
   running in circles. If (b) or (c) fails, or the count plateaus for two
   rounds: STOP patching. Step back and redesign the component (patch-churn on
   a wrong design converges never), or take the open items to the owner as a
   decision. Say so plainly in the trail — "stopped: not converging" is a
   legitimate, documented outcome; silent round 7 is not.
8. **Keep the human in the loop — narration is part of the gate.** Between
   rounds, tell the owner: what was found, what was fixed, what is pending,
   the convergence trend (e.g. 19 → 9 → 6), and roughly what each round
   costs. The owner steers — they can stop, waive, redirect, or run a
   **manual round of their own**; a human review round is a first-class
   reviewer seat and goes in the trail like any other (reviewer: owner,
   findings, dispositions). Never let rounds run silently back-to-back.
9. Write the trail: `docs/reviews/REVIEW-<gate>-<date>-r<round>.md` — findings, dispositions,
   and for each external reviewer its CLI version, model, and sandbox mode
   (for a human round: who, and what they reviewed).

## The clerk procedure — who posts what (explain this to the user)

The external reviewers **structurally cannot** comment on a PR: they run in
read-only sandboxes (codex) or sandboxed throwaway dirs (agy) and hold no
GitHub/GitLab credentials — deliberately, because they are *untrusted*; giving
a third-party model write access to your PR would undo the security posture.
The HOST agent is the clerk, and each artifact has a distinct job:

1. **Raw** (authentic): each reviewer's verbatim notes, captured to disk at run
   time, posted as a collapsed (`<details>`) PR comment on the reviewer's
   behalf — clearly labeled with tool, version, model, and sandbox mode.
2. **Consolidated** (actionable): the clerk's dedup + dispositions across all
   reviewers, posted as the main PR comment.
3. **Trail** (permanent): `docs/reviews/REVIEW-*.md` committed on the branch —
   dispositions, rejected-with-reason findings, pending waivers, reviewer
   versions. This is the record that survives PR-comment archaeology. Trails
   (and other internal working notes, e.g. plans) go under `docs/reviews/`,
   never at the repo root — they must not clutter the project's GitHub
   frontpage.

Capture reviewer output by **streaming to a file**, never by buffering it in a
shell variable — a session teardown mid-run must leave the partial review on
disk, not vaporize it.

## The strict review prompt (both gates)

> You are an adversarial, independent reviewer of the {plan | diff} below. The
> author cannot see their own blind spots, so be skeptical and specific. Return
> a RANKED list: BUG (wrong or self-contradictory now) / RISK (breaks under a
> normal future change, or a guard/test that cannot actually fire) / NIT — each
> with a location (file:line for repo-backed artifacts; a section anchor plus a
> short quote otherwise), a one-line why, and a concrete fix. Then list what you
> checked that came back CLEAN (silence is not coverage). Do NOT trust the
> artifact's own line numbers or claims. Review ONLY — do not modify files or
> run commands.

## Boundaries

- This skill depends on nothing domain-specific — website skills (e.g.
  `website-review`, `seo-reposition`) call it; it never calls them (no cycles).
- Read-only toward the artifact: reviewers report; the author fixes.
- Treat every external reviewer as untrusted: read-only sandboxes, throwaway
  working dirs, never a write/danger flag, never secrets in the prompt.
